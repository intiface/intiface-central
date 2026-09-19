use crate::{
  api::device_config_manager::DEVICE_CONFIG_MANAGER,
  frb_generated::StreamSink,
  in_process_frontend::FlutterIntifaceEngineFrontend,
  mobile_init,
};
use anyhow::{Result, anyhow};
use flutter_rust_bridge::frb;
use futures::{StreamExt, pin_mut};
use log::*;
use parking_lot::{Condvar, Mutex};
use std::{
  fmt,
  sync::{
    Arc,
    LazyLock,
    atomic::{AtomicBool, Ordering},
  },
  thread,
  time::{Duration, Instant},
};
use tokio::{
  runtime::Runtime,
  select,
  sync::{Notify, broadcast},
};
use tracing::info_span;
use tracing_futures::Instrument;

pub use intiface_engine::{EngineOptionsExternal, IntifaceEngine, IntifaceMessage};

const ENGINE_CLEANUP_TIMEOUT: Duration = Duration::from_secs(10);

#[derive(Debug)]
struct EngineCleanupTimeout {
  generation: u64,
  timeout: Duration,
}

impl fmt::Display for EngineCleanupTimeout {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    write!(
      f,
      "EngineCleanupTimeout: generation {} did not finish within {:?}",
      self.generation, self.timeout
    )
  }
}

impl std::error::Error for EngineCleanupTimeout {
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum LifecycleState {
  Vacant,
  Starting(u64),
  Running(u64),
  Stopping(u64),
  Reaping(u64),
}

struct StopSignal {
  requested: AtomicBool,
  changed: Notify,
}

impl StopSignal {
  fn new() -> Self {
    Self {
      requested: AtomicBool::new(false),
      changed: Notify::new(),
    }
  }

  fn request(&self) {
    self.requested.store(true, Ordering::Release);
    self.changed.notify_waiters();
  }

  async fn notified(&self) {
    loop {
      let notified = self.changed.notified();
      if self.requested.load(Ordering::Acquire) {
        return;
      }
      notified.await;
    }
  }
}

struct SharedLifecycle {
  state: LifecycleState,
  next_generation: u64,
  notifier: Option<Arc<StopSignal>>,
}

struct ReaperStart {
  generation: u64,
  runtime: Runtime,
  runner: Box<dyn FnOnce(Arc<StopSignal>) -> futures::future::BoxFuture<'static, ()> + Send>,
  notifier: Arc<StopSignal>,
  close: Box<dyn FnOnce() + Send>,
  accepted: crossbeam_channel::Sender<Result<(), String>>,
}

enum ReaperCommand {
  Start(ReaperStart),
  Completed {
    generation: u64,
    #[cfg(test)]
    acknowledged: Option<crossbeam_channel::Sender<()>>,
  },
}

struct LifecycleCoordinator {
  shared: Arc<(Mutex<SharedLifecycle>, Condvar)>,
  commands: crossbeam_channel::Sender<ReaperCommand>,
  #[cfg(test)]
  fail_next_handoff: AtomicBool,
}

impl LifecycleCoordinator {
  fn new() -> Self {
    let shared = Arc::new((
      Mutex::new(SharedLifecycle {
        state: LifecycleState::Vacant,
        next_generation: 1,
        notifier: None,
      }),
      Condvar::new(),
    ));
    let (commands, receiver) = crossbeam_channel::unbounded();
    let reaper_shared = shared.clone();
    let reaper_commands = commands.clone();
    thread::Builder::new()
      .name("intiface-runtime-reaper".to_owned())
      .spawn(move || Self::reaper_loop(reaper_shared, receiver, reaper_commands))
      .expect("lifecycle reaper thread must be available");
    Self {
      shared,
      commands,
      #[cfg(test)]
      fail_next_handoff: AtomicBool::new(false),
    }
  }

  fn reserve_start(&self) -> Result<u64> {
    let (lock, _) = &*self.shared;
    let mut shared = lock.lock();
    if shared.state != LifecycleState::Vacant {
      return Err(anyhow!("Server already running!"));
    }
    let generation = shared.next_generation;
    shared.next_generation += 1;
    shared.state = LifecycleState::Starting(generation);
    Ok(generation)
  }

  fn rollback_start(&self, generation: u64) {
    let (lock, changed) = &*self.shared;
    let mut shared = lock.lock();
    if shared.state == LifecycleState::Starting(generation) {
      shared.state = LifecycleState::Vacant;
      shared.notifier = None;
      changed.notify_all();
    }
  }

  fn rollback_published_start(&self, generation: u64) {
    let (lock, changed) = &*self.shared;
    let mut shared = lock.lock();
    if shared.state == LifecycleState::Running(generation) {
      shared.state = LifecycleState::Vacant;
      shared.notifier = None;
      changed.notify_all();
    }
  }

  fn dispose_runtime(runtime: Runtime) {
    thread::Builder::new()
      .name("intiface-runtime-disposer".to_owned())
      .spawn(move || drop(runtime))
      .expect("runtime disposer thread must be available");
  }

  #[cfg(test)]
  fn start<F, Fut, C>(&self, runtime: Runtime, runner: F, close: C) -> Result<u64>
  where
    F: FnOnce(Arc<StopSignal>) -> Fut + Send + 'static,
    Fut: std::future::Future<Output = ()> + Send + 'static,
    C: FnOnce() + Send + 'static,
  {
    let generation = self.reserve_start()?;
    self.start_reserved(generation, runtime, runner, close)
  }

  fn start_reserved<F, Fut, C>(
    &self,
    generation: u64,
    runtime: Runtime,
    runner: F,
    close: C,
  ) -> Result<u64>
  where
    F: FnOnce(Arc<StopSignal>) -> Fut + Send + 'static,
    Fut: std::future::Future<Output = ()> + Send + 'static,
    C: FnOnce() + Send + 'static,
  {
    #[cfg(test)]
    if self.fail_next_handoff.swap(false, Ordering::AcqRel) {
      Self::dispose_runtime(runtime);
      self.rollback_start(generation);
      return Err(anyhow!("Injected runtime handoff failure"));
    }

    let notifier = Arc::new(StopSignal::new());
    let reservation_valid = {
      let mut shared = self.shared.0.lock();
      if shared.state == LifecycleState::Starting(generation) {
        // Publish the complete active generation before handing its runtime to
        // the reaper. The reaper can therefore never complete an unpublished run.
        shared.notifier = Some(notifier.clone());
        shared.state = LifecycleState::Running(generation);
        true
      } else {
        false
      }
    };
    if !reservation_valid {
      Self::dispose_runtime(runtime);
      return Err(anyhow!("Engine generation {generation} is not reserved"));
    }

    let (accepted, acceptance) = crossbeam_channel::bounded(1);
    let command = ReaperCommand::Start(ReaperStart {
      generation,
      runtime,
      runner: Box::new(move |notify| Box::pin(runner(notify))),
      notifier,
      close: Box::new(close),
      accepted,
    });
    if let Err(error) = self.commands.send(command) {
      let ReaperCommand::Start(start) = error.into_inner() else {
        unreachable!("only Start commands are sent here");
      };
      Self::dispose_runtime(start.runtime);
      self.rollback_published_start(generation);
      return Err(anyhow!("Runtime reaper stopped unexpectedly"));
    }

    match acceptance.recv() {
      Ok(Ok(())) => Ok(generation),
      Ok(Err(error)) => {
        self.rollback_published_start(generation);
        Err(anyhow!(error))
      }
      Err(_) => {
        self.rollback_published_start(generation);
        Err(anyhow!(
          "Runtime reaper stopped before accepting generation {generation}"
        ))
      }
    }
  }

  fn stop(&self, timeout: Duration) -> Result<()> {
    let (lock, changed) = &*self.shared;
    let (generation, notifier) = {
      let mut shared = lock.lock();
      match shared.state {
        LifecycleState::Vacant => return Ok(()),
        LifecycleState::Starting(generation) => {
          return Err(anyhow!("Engine generation {generation} is still starting"));
        }
        LifecycleState::Running(generation) => {
          shared.state = LifecycleState::Stopping(generation);
          (generation, shared.notifier.clone())
        }
        LifecycleState::Stopping(generation) | LifecycleState::Reaping(generation) => {
          (generation, None)
        }
      }
    };
    if let Some(notifier) = notifier {
      notifier.request();
    }

    let deadline = Instant::now() + timeout;
    let mut shared = lock.lock();
    loop {
      match shared.state {
        LifecycleState::Vacant => return Ok(()),
        LifecycleState::Starting(current)
        | LifecycleState::Running(current)
        | LifecycleState::Stopping(current)
        | LifecycleState::Reaping(current)
          if current != generation =>
        {
          return Err(anyhow!("Engine generation changed while stopping"));
        }
        _ => {}
      }
      let now = Instant::now();
      if now >= deadline {
        return Err(
          EngineCleanupTimeout {
            generation,
            timeout,
          }
          .into(),
        );
      }
      changed.wait_for(&mut shared, deadline - now);
    }
  }

  fn is_started(&self) -> bool {
    self.shared.0.lock().state != LifecycleState::Vacant
  }

  fn reaper_loop(
    shared: Arc<(Mutex<SharedLifecycle>, Condvar)>,
    receiver: crossbeam_channel::Receiver<ReaperCommand>,
    commands: crossbeam_channel::Sender<ReaperCommand>,
  ) {
    let mut active: Option<ReaperStart> = None;
    while let Ok(command) = receiver.recv() {
      match command {
        ReaperCommand::Start(start) => {
          let published = shared.0.lock().state == LifecycleState::Running(start.generation);
          if active.is_some() || !published {
            let reason = if active.is_some() {
              "Reaper received overlapping runtime generation".to_owned()
            } else {
              format!(
                "Generation {} was not published before handoff",
                start.generation
              )
            };
            error!("{reason}");
            let accepted = start.accepted;
            drop(start.runtime);
            let _ = accepted.send(Err(reason));
            continue;
          }
          let ReaperStart {
            generation,
            runtime,
            runner,
            notifier,
            close,
            accepted,
          } = start;
          let completion = commands.clone();
          active = Some(ReaperStart {
            generation,
            runtime,
            runner: Box::new(|_| Box::pin(async {})),
            notifier: notifier.clone(),
            close,
            accepted: accepted.clone(),
          });
          let _ = accepted.send(Ok(()));
          active.as_ref().unwrap().runtime.spawn(async move {
            runner(notifier).await;
            let _ = completion.send(ReaperCommand::Completed {
              generation,
              #[cfg(test)]
              acknowledged: None,
            });
          });
        }
        ReaperCommand::Completed {
          generation,
          #[cfg(test)]
          acknowledged,
        } => {
          let Some(start) = active.take() else {
            warn!("Ignoring completion for unknown generation {generation}");
            #[cfg(test)]
            if let Some(acknowledged) = acknowledged {
              let _ = acknowledged.send(());
            }
            continue;
          };
          if start.generation != generation {
            warn!("Ignoring stale completion for generation {generation}");
            active = Some(start);
            #[cfg(test)]
            if let Some(acknowledged) = acknowledged {
              let _ = acknowledged.send(());
            }
            continue;
          }
          {
            let mut state = shared.0.lock();
            state.state = LifecycleState::Reaping(generation);
            shared.1.notify_all();
          }
          (start.close)();
          // The runner future has completed before this point, so dropping the
          // Runtime synchronously on this dedicated reaper thread is the
          // coordinator's deterministic, infallible disposal boundary. There is
          // no fallible disposal path after the joined task/resource invariant.
          drop(start.runtime);
          {
            let mut state = shared.0.lock();
            if state.state == LifecycleState::Reaping(generation) {
              state.notifier = None;
              state.state = LifecycleState::Vacant;
              shared.1.notify_all();
            }
          }
        }
      }
    }
  }
}

static LIFECYCLE: LazyLock<LifecycleCoordinator> = LazyLock::new(LifecycleCoordinator::new);
static ENGINE_BROADCASTER: LazyLock<Arc<broadcast::Sender<IntifaceMessage>>> =
  LazyLock::new(|| Arc::new(broadcast::channel(255).0));
static BACKDOOR_INCOMING_BROADCASTER: LazyLock<Arc<broadcast::Sender<String>>> =
  LazyLock::new(|| Arc::new(broadcast::channel(255).0));
/// Prevents backdoor sends after the engine has emitted its final messages.
static ENGINE_SHUTDOWN: AtomicBool = AtomicBool::new(false);

#[frb(mirror(EngineOptionsExternal))]
pub struct _EngineOptionsExternal {
  pub device_config_json: Option<String>,
  pub user_device_config_json: Option<String>,
  pub user_device_config_path: Option<String>,
  pub server_name: String,
  pub websocket_listen_address: Option<String>,
  pub websocket_client_address: Option<String>,
  pub frontend_websocket_port: Option<u16>,
  pub frontend_in_process_channel: bool,
  pub max_ping_time: u32,
  pub use_bluetooth_le: bool,
  pub use_serial_port: bool,
  pub use_lovense_dongle_serial: bool,
  pub use_lovense_dongle_hid: bool,
  pub use_sdl_gamepad: bool,
  pub use_lovense_connect: bool,
  pub use_device_websocket_server: bool,
  pub use_simulated_devices: bool,
  pub device_websocket_server_port: Option<u16>,
  pub crash_main_thread: bool,
  pub crash_task_thread: bool,
  pub broadcast_server_mdns: bool,
  pub mdns_suffix: Option<String>,
  pub repeater_mode: bool,
  pub repeater_local_port: Option<u16>,
  pub repeater_remote_address: Option<String>,
  pub rest_api_port: Option<u16>,
  pub emit_output_observations: bool,
}

pub fn rust_runtime_started() -> bool {
  LIFECYCLE.is_started()
}

/// Check if the engine is currently shutting down.
/// Used by other modules to prevent sending messages to closed streams.
pub fn is_engine_shutdown() -> bool {
  ENGINE_SHUTDOWN.load(Ordering::SeqCst)
}

pub fn run_engine(sink: StreamSink<String>, args: EngineOptionsExternal) -> Result<()> {
  let generation = LIFECYCLE.reserve_start()?;
  let runtime = match mobile_init::create_runtime(sink.clone()) {
    Ok(runtime) => runtime,
    Err(err) => {
      LIFECYCLE.rollback_start(generation);
      return Err(err.into());
    }
  };

  let frontend = Arc::new(FlutterIntifaceEngineFrontend::new(
    sink.clone(),
    ENGINE_BROADCASTER.clone(),
  ));
  let close_frontend = frontend.clone();
  let frontend_waiter = frontend.notify_on_creation();
  let engine = Arc::new(IntifaceEngine::default());
  let options = args.into();
  let dcm = (*DEVICE_CONFIG_MANAGER.read()).clone();
  let mut backdoor_incoming = BACKDOOR_INCOMING_BROADCASTER.subscribe();
  ENGINE_SHUTDOWN.store(false, Ordering::SeqCst);

  let result = LIFECYCLE.start_reserved(
    generation,
    runtime,
    move |notify| async move {
      let backdoor_engine = engine.clone();
      let stop_engine = engine.clone();
      let backdoor_notify = notify.clone();
      let stop_notify = notify.clone();
      info!("Entering main engine join for generation {generation}");
      tokio::join!(
        async move {
          select! {
            _ = frontend_waiter => {}
            _ = backdoor_notify.notified() => return,
          }
          let Some(backdoor_server) = backdoor_engine.backdoor_server() else {
            error!("No backdoor server available!");
            return;
          };
          let events = backdoor_server.event_stream();
          pin_mut!(events);
          loop {
            select! {
              incoming = backdoor_incoming.recv() => match incoming {
                Ok(message) => backdoor_server.clone().parse_message(&message).await,
                Err(_) => break,
              },
              outgoing = events.next() => match outgoing {
                Some(message) if !ENGINE_SHUTDOWN.load(Ordering::SeqCst) => {
                  let _ = sink.add(message);
                }
                Some(_) => {}
                None => break,
              },
              _ = backdoor_notify.notified() => break,
            }
          }
        }
        .instrument(info_span!("IC Backdoor server task")),
        async move {
          if let Err(err) = engine.run(&options, Some(frontend), &Some(dcm)).await {
            error!("Error running engine: {err:?}");
          }
          // Wake the stop task on natural exit so all joined futures converge.
          notify.request();
        }
        .instrument(info_span!("IC main engine task")),
        async move {
          stop_notify.notified().await;
          stop_engine.stop();
        }
        .instrument(info_span!("IC engine stop task")),
      );
      info!("Engine generation {generation} completed graceful cleanup");
    },
    move || {
      // IntifaceEngine::run has returned, so EngineStopped and every other final
      // message have already passed through the frontend before it is closed.
      ENGINE_SHUTDOWN.store(true, Ordering::SeqCst);
      close_frontend.close();
    },
  );
  if result.is_err() {
    ENGINE_SHUTDOWN.store(true, Ordering::SeqCst);
  }
  result.map(|_| ())
}

pub fn stop_engine() -> Result<()> {
  info!("Stop engine called in rust");
  LIFECYCLE.stop(ENGINE_CLEANUP_TIMEOUT)
}

pub fn send_runtime_msg(msg_json: String) {
  let msg: IntifaceMessage = serde_json::from_str(&msg_json).unwrap();
  if ENGINE_BROADCASTER.receiver_count() > 0 {
    ENGINE_BROADCASTER
      .send(msg)
      .expect("This should be infallible since we already checked for receivers");
  }
}

pub fn send_backend_server_message(msg: String) {
  if BACKDOOR_INCOMING_BROADCASTER.receiver_count() > 0 {
    BACKDOOR_INCOMING_BROADCASTER
      .send(msg)
      .expect("This should be infallible since we already checked for receivers");
  }
}

#[cfg(test)]
mod tests {
  use super::*;
  use std::sync::{
    Barrier,
    atomic::{AtomicUsize, Ordering},
  };

  fn runtime() -> Runtime {
    tokio::runtime::Builder::new_multi_thread()
      .worker_threads(2)
      .enable_all()
      .build()
      .unwrap()
  }

  fn stoppable_run(
    lifecycle: &LifecycleCoordinator,
    cleanup_count: Arc<AtomicUsize>,
    close_count: Arc<AtomicUsize>,
  ) {
    lifecycle
      .start(
        runtime(),
        move |stop| async move {
          stop.notified().await;
          cleanup_count.fetch_add(1, Ordering::SeqCst);
        },
        move || {
          close_count.fetch_add(1, Ordering::SeqCst);
        },
      )
      .unwrap();
  }

  #[test]
  fn restart_after_completed_stop_succeeds() {
    let lifecycle = LifecycleCoordinator::new();
    let cleaned = Arc::new(AtomicUsize::new(0));
    let closed = Arc::new(AtomicUsize::new(0));
    stoppable_run(&lifecycle, cleaned.clone(), closed.clone());
    lifecycle.stop(Duration::from_secs(2)).unwrap();
    stoppable_run(&lifecycle, cleaned.clone(), closed.clone());
    lifecycle.stop(Duration::from_secs(2)).unwrap();
    assert!(!lifecycle.is_started());
    assert_eq!(cleaned.load(Ordering::SeqCst), 2);
    assert_eq!(closed.load(Ordering::SeqCst), 2);
  }

  #[test]
  fn natural_exit_is_reaped_before_next_start() {
    let lifecycle = LifecycleCoordinator::new();
    lifecycle.start(runtime(), |_| async {}, || {}).unwrap();
    let deadline = Instant::now() + Duration::from_secs(2);
    while lifecycle.is_started() && Instant::now() < deadline {
      thread::yield_now();
    }
    assert!(!lifecycle.is_started());
    lifecycle.start(runtime(), |_| async {}, || {}).unwrap();
    lifecycle.stop(Duration::from_secs(2)).unwrap();
  }

  #[test]
  fn immediate_natural_exit_never_exposes_unpublished_start() {
    let lifecycle = LifecycleCoordinator::new();
    for _ in 0..100 {
      lifecycle.start(runtime(), |_| async {}, || {}).unwrap();
      assert!(!matches!(
        lifecycle.shared.0.lock().state,
        LifecycleState::Starting(_)
      ));
      let deadline = Instant::now() + Duration::from_secs(2);
      while lifecycle.is_started() && Instant::now() < deadline {
        thread::yield_now();
      }
      assert_eq!(lifecycle.shared.0.lock().state, LifecycleState::Vacant);
    }
  }

  #[test]
  fn repeated_start_stop_cycles_leave_no_runtime() {
    let lifecycle = LifecycleCoordinator::new();
    for _ in 0..10 {
      stoppable_run(
        &lifecycle,
        Arc::new(AtomicUsize::new(0)),
        Arc::new(AtomicUsize::new(0)),
      );
      lifecycle.stop(Duration::from_secs(2)).unwrap();
      assert!(!lifecycle.is_started());
    }
  }

  #[test]
  fn old_generation_cleanup_cannot_clear_new_generation() {
    let lifecycle = LifecycleCoordinator::new();
    stoppable_run(
      &lifecycle,
      Arc::new(AtomicUsize::new(0)),
      Arc::new(AtomicUsize::new(0)),
    );
    let old_generation = match lifecycle.shared.0.lock().state {
      LifecycleState::Running(generation) => generation,
      state => panic!("expected first generation to be running, got {state:?}"),
    };
    lifecycle.stop(Duration::from_secs(2)).unwrap();

    stoppable_run(
      &lifecycle,
      Arc::new(AtomicUsize::new(0)),
      Arc::new(AtomicUsize::new(0)),
    );
    let new_generation = match lifecycle.shared.0.lock().state {
      LifecycleState::Running(generation) => generation,
      state => panic!("expected second generation to be running, got {state:?}"),
    };
    assert_ne!(old_generation, new_generation);

    // Inject a late completion from the previous generation directly through the
    // coordinator command seam. It must not reap or clear the active generation.
    let (acknowledged, processed) = crossbeam_channel::bounded(1);
    lifecycle
      .commands
      .send(ReaperCommand::Completed {
        generation: old_generation,
        acknowledged: Some(acknowledged),
      })
      .unwrap();
    processed
      .recv_timeout(Duration::from_secs(2))
      .expect("stale completion should be processed by the reaper");
    assert_eq!(
      lifecycle.shared.0.lock().state,
      LifecycleState::Running(new_generation)
    );

    lifecycle.stop(Duration::from_secs(2)).unwrap();
    assert!(!lifecycle.is_started());
  }

  #[test]
  fn failed_start_handoff_rolls_back_and_allows_restart() {
    let lifecycle = LifecycleCoordinator::new();
    lifecycle.fail_next_handoff.store(true, Ordering::Release);
    let error = lifecycle.start(runtime(), |_| async {}, || {}).unwrap_err();
    assert!(
      error
        .to_string()
        .contains("Injected runtime handoff failure")
    );
    assert_eq!(lifecycle.shared.0.lock().state, LifecycleState::Vacant);
    assert!(!lifecycle.is_started());

    stoppable_run(
      &lifecycle,
      Arc::new(AtomicUsize::new(0)),
      Arc::new(AtomicUsize::new(0)),
    );
    lifecycle.stop(Duration::from_secs(2)).unwrap();
    assert!(!lifecycle.is_started());
  }

  #[test]
  fn stop_waits_for_engine_cleanup_before_returning() {
    let lifecycle = Arc::new(LifecycleCoordinator::new());
    let cleanup_release = Arc::new(Notify::new());
    let runner_release = cleanup_release.clone();
    let (runner_stop_seen, stop_seen) = crossbeam_channel::bounded(1);
    let close_count = Arc::new(AtomicUsize::new(0));
    let close_count_for_runner = close_count.clone();
    lifecycle
      .start(
        runtime(),
        move |stop| async move {
          stop.notified().await;
          runner_stop_seen.send(()).unwrap();
          runner_release.notified().await;
        },
        move || {
          close_count_for_runner.fetch_add(1, Ordering::SeqCst);
        },
      )
      .unwrap();
    let waiter = lifecycle.clone();
    let stopped = Arc::new(AtomicBool::new(false));
    let stopped_clone = stopped.clone();
    let handle = thread::spawn(move || {
      waiter.stop(Duration::from_secs(2)).unwrap();
      stopped_clone.store(true, Ordering::SeqCst);
    });
    stop_seen
      .recv_timeout(Duration::from_secs(2))
      .expect("runner should observe stop before cleanup blocks");
    assert!(!stopped.load(Ordering::SeqCst));
    assert_eq!(close_count.load(Ordering::SeqCst), 0);
    cleanup_release.notify_waiters();
    handle.join().unwrap();
    assert_eq!(close_count.load(Ordering::SeqCst), 1);
  }

  #[test]
  fn engine_stopped_precedes_frontend_close() {
    let lifecycle = LifecycleCoordinator::new();
    let milestones = Arc::new(Mutex::new(Vec::new()));
    let runner_milestones = milestones.clone();
    let close_milestones = milestones.clone();
    lifecycle
      .start(
        runtime(),
        move |_| async move {
          runner_milestones.lock().push("engine-stopped");
        },
        move || close_milestones.lock().push("frontend-close"),
      )
      .unwrap();
    lifecycle.stop(Duration::from_secs(2)).unwrap();
    assert_eq!(*milestones.lock(), ["engine-stopped", "frontend-close"]);
  }

  #[test]
  fn duplicate_start_does_not_poison_next_start() {
    let lifecycle = LifecycleCoordinator::new();
    stoppable_run(
      &lifecycle,
      Arc::new(AtomicUsize::new(0)),
      Arc::new(AtomicUsize::new(0)),
    );
    assert!(lifecycle.start(runtime(), |_| async {}, || {}).is_err());
    lifecycle.stop(Duration::from_secs(2)).unwrap();
    lifecycle.start(runtime(), |_| async {}, || {}).unwrap();
    lifecycle.stop(Duration::from_secs(2)).unwrap();
  }

  #[test]
  fn concurrent_stop_callers_observe_same_generation() {
    let lifecycle = Arc::new(LifecycleCoordinator::new());
    let cleanup_count = Arc::new(AtomicUsize::new(0));
    stoppable_run(
      &lifecycle,
      cleanup_count.clone(),
      Arc::new(AtomicUsize::new(0)),
    );
    let barrier = Arc::new(Barrier::new(3));
    let mut handles = Vec::new();
    for _ in 0..2 {
      let lifecycle = lifecycle.clone();
      let barrier = barrier.clone();
      handles.push(thread::spawn(move || {
        barrier.wait();
        lifecycle.stop(Duration::from_secs(2))
      }));
    }
    barrier.wait();
    for handle in handles {
      handle.join().unwrap().unwrap();
    }
    assert_eq!(cleanup_count.load(Ordering::SeqCst), 1);
  }

  #[test]
  fn stop_retry_after_timeout_reaps_same_generation() {
    let lifecycle = LifecycleCoordinator::new();
    let cleanup_release = Arc::new(Notify::new());
    let runner_release = cleanup_release.clone();
    lifecycle
      .start(
        runtime(),
        move |stop| async move {
          stop.notified().await;
          runner_release.notified().await;
        },
        || {},
      )
      .unwrap();
    let error = lifecycle.stop(Duration::from_millis(20)).unwrap_err();
    assert!(error.downcast_ref::<EngineCleanupTimeout>().is_some());
    assert!(lifecycle.is_started());
    assert!(lifecycle.start(runtime(), |_| async {}, || {}).is_err());
    cleanup_release.notify_waiters();
    lifecycle.stop(Duration::from_secs(2)).unwrap();
    assert!(!lifecycle.is_started());
  }
}
