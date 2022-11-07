use crate::{
  in_process_frontend::FlutterIntifaceEngineFrontend,
  mobile_init::{self, RUNTIME},
};
use std::sync::{Arc, atomic::{AtomicBool, Ordering}};
use anyhow::Result;
use tokio::{
  select,
  sync::{Notify, broadcast}
};
use flutter_rust_bridge::{frb, StreamSink};
use once_cell::sync::OnceCell;
use lazy_static::lazy_static;

pub use intiface_engine::{EngineOptions, EngineOptionsExternal, IntifaceEngine, IntifaceMessage};

static ENGINE_NOTIFIER: OnceCell<Arc<Notify>> = OnceCell::new();
lazy_static! {
  static ref RUN_STATUS: Arc<AtomicBool> = Arc::new(AtomicBool::new(false));
  static ref ENGINE_BROADCASTER: Arc<broadcast::Sender<IntifaceMessage>> = Arc::new(broadcast::channel(255).0);
}

#[frb(mirror(EngineOptionsExternal))]
pub struct _EngineOptionsExternal {
  pub sentry_api_key: Option<String>,
  pub ipc_pipe_name: Option<String>,
  pub device_config_json: Option<String>,
  pub user_device_config_json: Option<String>,
  pub server_name: String,
  pub crash_reporting: bool,
  pub websocket_use_all_interfaces: bool,
  pub websocket_port: Option<u16>,
  pub frontend_websocket_port: Option<u16>,
  pub frontend_in_process_channel: bool,
  pub max_ping_time: u32,
  pub log_level: Option<String>,
  pub allow_raw_messages: bool,
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
}

pub fn run_engine(sink: StreamSink<String>, args: EngineOptionsExternal) -> Result<()> {
  if RUN_STATUS.load(Ordering::SeqCst) {
    return Err(anyhow::Error::msg("Server already running!"));
  }
  RUN_STATUS.store(true, Ordering::SeqCst);
  if RUNTIME.get().is_none() {    
    mobile_init::create_runtime(sink.clone()).expect("Runtime should work, otherwise we can't function.");
  }
  if ENGINE_NOTIFIER.get().is_none() {
    ENGINE_NOTIFIER.set(Arc::new(Notify::new()));
  }
  let runtime = RUNTIME.get().expect("Runtime not initialized");
  let frontend = FlutterIntifaceEngineFrontend::new(sink.clone(), ENGINE_BROADCASTER.clone());
  let engine = Arc::new(IntifaceEngine::default());
  let engine_clone = engine.clone();
  let notify = ENGINE_NOTIFIER.get().expect("Should be set").clone();
  let options = args.into();
  runtime.spawn(async move {
    info!("Entering main engine waiter task");
    // These futures need to run in parallel, but the frontend will always notify before the engine
    // comes down, and we want the engine to run to completion after stop is called, so we can't
    // call this in a select, as the engine future will be truncated. So, join it is.
    //
    // If the engine somehow exits first, make sure we still leave by triggering our notifier
    // anyways.
    let notify_clone = notify.clone();
    futures::join!(
      async move {
        if let Err(e) = engine.run(&options, Some(Arc::new(frontend))).await {
          error!("Error running engine: {:?}", e);
        }
        notify_clone.notify_waiters();
      }, 
      async move {
        notify.notified().await;
        engine_clone.stop();
      });
    RUN_STATUS.store(false, Ordering::SeqCst);
    info!("Exiting main engine waiter task");
  }.instrument(info_span!("IC main engine task")));
  Ok(())
}

pub fn send(msg_json: String) {
  let msg: IntifaceMessage = serde_json::from_str(&msg_json).unwrap();  
  ENGINE_BROADCASTER.send(msg).unwrap();
}

pub fn stop_engine() {
  ENGINE_NOTIFIER.get().expect("Should be set").notify_waiters();
}
