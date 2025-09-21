use crate::{
  api::device_config_manager::DEVICE_CONFIG_MANAGER, in_process_frontend::FlutterIntifaceEngineFrontend, logging::FlutterTracingWriter, mobile_init
};
use anyhow::Result;
use flutter_rust_bridge::frb;
use crate::frb_generated::{StreamSink};
use futures::{pin_mut, StreamExt};
use lazy_static::lazy_static;
use once_cell::sync::OnceCell;
use std::{
  sync::{
    atomic::{AtomicBool, Ordering},
    Arc, Mutex,
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

static ENGINE_NOTIFIER: OnceCell<Arc<Notify>> = OnceCell::new();
lazy_static! {
  static ref RUNTIME: Arc<Mutex<Option<Runtime>>> = Arc::new(Mutex::new(None));
  static ref RUN_STATUS: Arc<AtomicBool> = Arc::new(AtomicBool::new(false));
  static ref ENGINE_BROADCASTER: Arc<broadcast::Sender<IntifaceMessage>> =
    Arc::new(broadcast::channel(255).0);
  static ref BACKDOOR_INCOMING_BROADCASTER: Arc<broadcast::Sender<String>> =
    Arc::new(broadcast::channel(255).0);
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

pub fn run_engine(sink: StreamSink<String>, args: EngineOptionsExternal) -> Result<()> {
  if RUN_STATUS.load(Ordering::Relaxed) {
    return Err(anyhow::Error::msg("Server already running!"));
  }
  RUN_STATUS.store(true, Ordering::Relaxed);

  let mut runtime_storage = RUNTIME.lock().unwrap();

  if runtime_storage.is_some() {
    return Err(anyhow::Error::msg("Runtime already created!"));
  }

  let runtime = mobile_init::create_runtime(sink.clone())
    .expect("Runtime should work, otherwise we can't function.");

  if ENGINE_NOTIFIER.get().is_none() {
    info!("Creating notifier");
    ENGINE_NOTIFIER
      .set(Arc::new(Notify::new()))
      .expect("We already checked creation so this shouldn't fail");
  } else {
    info!("Notifier already created");
  }

  let frontend = Arc::new(FlutterIntifaceEngineFrontend::new(
    sink.clone(),
    ENGINE_BROADCASTER.clone(),
  ));
  info!("Frontend logging set up.");
  let frontend_waiter = frontend.notify_on_creation();
  let engine = Arc::new(IntifaceEngine::default());
  let engine_clone = engine.clone();
  let engine_clone_clone = engine.clone();
  let notify = ENGINE_NOTIFIER.get().expect("Should be set").clone();
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
                    let _ = sink.add(msg);
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
  if let Some(notifier) = ENGINE_NOTIFIER.get() {
    notifier.notify_waiters();
  }
  // Need to park ourselves real quick to let the other runtime threads finish out.
  //
  // HACK The android JNI drop calls (and sometimes windows UWP calls) are slow (100ms+) and need
  // quite a while to get everything disconnected if there are currently connected devices. If they
  // don't run to completion, the runtime won't shutdown properly and everything will stall. Running
  // runtime_shutdown() doesn't work here because these are all tasks that may be stalled at the OS
  // level so we don't have enough info. Waiting on this is not the optimal way to do it, but I also
  // don't have a good way to know when shutdown is finished right now. So waiting it is. This isn't
  // super noticable from an UX standpoint.
  thread::sleep(Duration::from_millis(500));
  let runtime;
  {
    runtime = RUNTIME.lock().unwrap().take();
  }
  if let Some(rt) = runtime {
    info!("Shutting down runtime");
    rt.shutdown_timeout(Duration::from_secs(1));
    info!("Runtime shutdown complete");
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