use crate::{
  api::device_config_manager::DEVICE_CONFIG_MANAGER, in_process_frontend::FlutterIntifaceEngineFrontend, mobile_init
};
use std::sync::Weak;
use anyhow::Result;
use flutter_rust_bridge::frb;
use crate::frb_generated::{StreamSink};
use futures::{pin_mut, StreamExt};
use lazy_static::lazy_static;
use std::{
  sync::{
    atomic::{AtomicBool, Ordering},
    Arc, Mutex, RwLock,
  },
  thread,
  time::Duration,
};
use tokio::{
  runtime::Runtime,
  select,
  sync::{broadcast, Notify},
};
use log::*;
use tracing::{info_span};
use tracing_futures::Instrument;

pub use intiface_engine::{EngineOptionsExternal, IntifaceEngine, IntifaceMessage};

// Use RwLock<Option<...>> instead of OnceCell so the notifier can be properly reset between runs.
// OnceCell can only be set once per process lifetime, causing stale state on app restart.
lazy_static! {
  static ref ENGINE_NOTIFIER: RwLock<Option<Arc<Notify>>> = RwLock::new(None);
  static ref RUNTIME: Arc<Mutex<Option<Runtime>>> = Arc::new(Mutex::new(None));
  static ref RUN_STATUS: Arc<AtomicBool> = Arc::new(AtomicBool::new(false));
  static ref ENGINE_BROADCASTER: Arc<broadcast::Sender<IntifaceMessage>> =
    Arc::new(broadcast::channel(255).0);
  static ref BACKDOOR_INCOMING_BROADCASTER: Arc<broadcast::Sender<String>> =
    Arc::new(broadcast::channel(255).0);
  /// Weak reference to the frontend for closing during shutdown.
  /// Uses Weak to avoid preventing cleanup, and RwLock for thread-safe access.
  static ref ENGINE_FRONTEND: RwLock<Option<Weak<FlutterIntifaceEngineFrontend>>> = RwLock::new(None);
  /// Global shutdown flag to prevent SendError messages during shutdown.
  /// Checked by all sink.add() operations to avoid sending to closed streams.
  static ref ENGINE_SHUTDOWN: AtomicBool = AtomicBool::new(false);
}

#[frb(mirror(EngineOptionsExternal))]
pub struct _EngineOptionsExternal {
  pub device_config_json: Option<String>,
  pub user_device_config_json: Option<String>,
  pub user_device_config_path: Option<String>,
  pub server_name: String,
  pub websocket_use_all_interfaces: bool,
  pub websocket_port: Option<u16>,
  pub frontend_websocket_port: Option<u16>,
  pub frontend_in_process_channel: bool,
  pub max_ping_time: u32,
  pub use_bluetooth_le: bool,
  pub use_serial_port: bool,
  pub use_hid: bool,
  pub use_lovense_dongle_serial: bool,
  pub use_lovense_dongle_hid: bool,
  pub use_xinput: bool,
  pub use_lovense_connect: bool,
  pub use_device_websocket_server: bool,
  pub device_websocket_server_port: Option<u16>,
  pub crash_main_thread: bool,
  pub crash_task_thread: bool,
  pub websocket_client_address: Option<String>,
  pub broadcast_server_mdns: bool,
  pub mdns_suffix: Option<String>,
  pub repeater_mode: bool,
  pub repeater_local_port: Option<u16>,
  pub repeater_remote_address: Option<String>,
  pub rest_api_port: Option<u16>
}

pub fn rust_runtime_started() -> bool {
  RUNTIME.lock().unwrap().is_some()
}

/// Check if the engine is currently shutting down.
/// Used by other modules to prevent sending messages to closed streams.
pub fn is_engine_shutdown() -> bool {
  ENGINE_SHUTDOWN.load(Ordering::SeqCst)
}

pub fn run_engine(sink: StreamSink<String>, args: EngineOptionsExternal) -> Result<()> {
  if RUN_STATUS.load(Ordering::Relaxed) {
    return Err(anyhow::Error::msg("Server already running!"));
  }
  RUN_STATUS.store(true, Ordering::Relaxed);
  // Clear the shutdown flag for the new engine run
  ENGINE_SHUTDOWN.store(false, Ordering::SeqCst);

  let mut runtime_storage = RUNTIME.lock().unwrap();

  if runtime_storage.is_some() {
    return Err(anyhow::Error::msg("Runtime already created!"));
  }

  let runtime = mobile_init::create_runtime(sink.clone())
    .expect("Runtime should work, otherwise we can't function.");

  // Always create a fresh notifier for each engine run to avoid stale state from previous runs.
  // This is critical for proper cleanup when the app restarts without full process termination.
  info!("Creating fresh notifier for engine run");
  let notify = Arc::new(Notify::new());
  {
    let mut notifier_guard = ENGINE_NOTIFIER.write().unwrap();
    *notifier_guard = Some(notify.clone());
  }

  let frontend = Arc::new(FlutterIntifaceEngineFrontend::new(
    sink.clone(),
    ENGINE_BROADCASTER.clone(),
  ));
  // Store weak reference to frontend for closing during shutdown
  {
    let mut frontend_guard = ENGINE_FRONTEND.write().unwrap();
    *frontend_guard = Some(Arc::downgrade(&frontend));
  }
  info!("Frontend logging set up.");
  let frontend_waiter = frontend.notify_on_creation();
  let engine = Arc::new(IntifaceEngine::default());
  let engine_clone = engine.clone();
  let engine_clone_clone = engine.clone();
  let notify_clone = notify.clone();
  let notify_clone_clone = notify.clone();
  let options = args.into();

  let mut backdoor_incoming = BACKDOOR_INCOMING_BROADCASTER.subscribe();

  // TODO This is not doing what its supposed to. We're taking our Arc from the read guard, then
  // just dropping the read guard.
  let dcm = (*DEVICE_CONFIG_MANAGER.read().unwrap()).clone();
  runtime.spawn(
    async move {
      info!("Entering main join.");

      tokio::join!(
        // Backdoor server task
        async move {
          // Once we finish our waiter, continue. If we cancel the server run before then, just kill the
          // task.
          info!("Entering backdoor waiter task");
          select! {
            _ = frontend_waiter => {
              // This firing means the frontend is set up, and we just want to continue to creating our backdoor server.
            }
            _ = notify_clone.notified() => {
              return;
            }
          };
          // At this point we know we'll have a server.
          let backdoor_server = if let Some(backdoor_server) = engine_clone.backdoor_server() {
            backdoor_server
          } else {
            // If we somehow *don't* have a server here, something has gone very wrong. Just die.
            error!("No backdoor server available!");
            return;
          };
          let backdoor_server_stream = backdoor_server.event_stream();
          pin_mut!(backdoor_server_stream);
          loop {
            select! {
              msg = backdoor_incoming.recv() => {
                match msg {
                  Ok(msg) => {
                    let backdoor_server_clone = backdoor_server.clone();
                    backdoor_server_clone.parse_message(&msg).await;
                  }
                  Err(_) => break
                }
              },
              outgoing = backdoor_server_stream.next() => {
                match outgoing {
                  Some(msg) => {
                    // Check shutdown flag before sending to avoid SendError
                    if !ENGINE_SHUTDOWN.load(Ordering::SeqCst) {
                      let _ = sink.add(msg);
                    }
                  },
                  None => break
                }
              },
              _ = notify_clone.notified() => break
            }
          }
          info!("Exiting backdoor waiter task");
        }
        .instrument(info_span!("IC Backdoor server task")),
        // Main engine task.
        async move {
          info!("Entering main engine waiter task");
          if let Err(e) = engine.run(&options, Some(frontend), &Some(dcm)).await {
            error!("Error running engine: {:?}", e);
          }
          info!("Exiting main engine waiter task");
          notify_clone_clone.notify_waiters();
        }
        .instrument(info_span!("IC main engine task")),
        // Our notifier needs to run in a task by itself, because we don't want our engine future to get
        // cancelled, so we can't select between it and the notifier. It needs to shutdown gracefully.
        async move {
          info!("Entering engine stop notification task");
          notify.notified().await;
          info!("Notifier called, stopping engine");
          engine_clone_clone.stop();
        }
      );
      // Set shutdown flag to prevent any more sink messages from being sent.
      // This is critical for preventing SendError when engine completes naturally.
      ENGINE_SHUTDOWN.store(true, Ordering::SeqCst);
      RUN_STATUS.store(false, Ordering::Relaxed);
      info!("Exiting main join.");
    }
    .instrument(info_span!("IC main engine task")),
  );
  *runtime_storage = Some(runtime);
  Ok(())
}

pub fn send_runtime_msg(msg_json: String) {
  let msg: IntifaceMessage = serde_json::from_str(&msg_json).unwrap();
  if ENGINE_BROADCASTER.receiver_count() > 0 {
    ENGINE_BROADCASTER
      .send(msg)
      .expect("This should be infallible since we already checked for receivers");
  }
}

pub fn stop_engine() {
  info!("Stop engine called in rust.");

  // NOTE: We do NOT set ENGINE_SHUTDOWN or close the frontend here.
  // The engine needs to send the "engineStopped" message to Dart before cleanup.
  // The shutdown flag and frontend close happen automatically in the async task
  // after the engine has finished and sent its final messages.
  // The btleplug SendError is handled by log filtering in logging.rs.

  // Notify all waiters to stop the engine
  {
    let notifier_guard = ENGINE_NOTIFIER.read().unwrap();
    if let Some(ref notifier) = *notifier_guard {
      notifier.notify_waiters();
    }
  }

  // Need to park ourselves real quick to let the other runtime threads finish out.
  //
  // Platform-specific Bluetooth cleanup times vary significantly:
  // - Android JNI drop calls: 100ms+
  // - Windows UWP calls: 100ms+
  // - macOS CoreBluetooth: Can take significantly longer due to delegate callbacks
  //
  // If cleanup doesn't complete, the runtime won't shutdown properly and everything stalls.
  // This isn't optimal but we don't have a good way to know when shutdown is finished.
  #[cfg(target_os = "macos")]
  {
    info!("macOS detected - using extended cleanup timeout for CoreBluetooth");
    thread::sleep(Duration::from_millis(1000));
  }
  #[cfg(not(target_os = "macos"))]
  {
    thread::sleep(Duration::from_millis(500));
  }

  let runtime;
  {
    runtime = RUNTIME.lock().unwrap().take();
  }
  if let Some(rt) = runtime {
    info!("Shutting down runtime");
    // Use shutdown_background to avoid blocking - the runtime will clean up in background
    // shutdown_timeout can hang indefinitely if there are deadlocked tasks
    rt.shutdown_background();
    info!("Runtime shutdown initiated");
  } else {
    info!("No runtime to shutdown");
  }

  // Clear the notifier so a fresh one is created on next run.
  // This prevents stale state from accumulating across app restarts.
  {
    let mut notifier_guard = ENGINE_NOTIFIER.write().unwrap();
    *notifier_guard = None;
    info!("Engine notifier cleared for next run");
  }

  // Clear the frontend reference
  {
    let mut frontend_guard = ENGINE_FRONTEND.write().unwrap();
    *frontend_guard = None;
    info!("Engine frontend reference cleared for next run");
  }

  RUN_STATUS.store(false, Ordering::Relaxed);
}

pub fn send_backend_server_message(msg: String) {
  if BACKDOOR_INCOMING_BROADCASTER.receiver_count() > 0 {
    BACKDOOR_INCOMING_BROADCASTER
      .send(msg)
      .expect("This should be infallible since we already checked for receivers");
  }
}