use crate::{
  in_process_frontend::FlutterIntifaceEngineFrontend,
  mobile_init::{self, RUNTIME},
};
use std::sync::Arc;
use anyhow::Result;
use tokio::{
  select,
  sync::Notify
};
use flutter_rust_bridge::{frb, StreamSink};
use once_cell::sync::OnceCell;

pub use intiface_engine::{EngineOptions, EngineOptionsExternal, IntifaceEngine};

pub static ENGINE_NOTIFIER: OnceCell<Arc<Notify>> = OnceCell::new();

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
  if RUNTIME.get().is_none() {
    mobile_init::create_runtime(sink.clone()).expect("Runtime should work");
  }
  if ENGINE_NOTIFIER.get().is_none() {
    ENGINE_NOTIFIER.set(Arc::new(Notify::new()));
  }
  let runtime = RUNTIME.get().expect("Runtime not initialized");
  let frontend = FlutterIntifaceEngineFrontend::new(sink.clone());
  let engine = Arc::new(IntifaceEngine::default());
  let engine_clone = engine.clone();
  let notify = ENGINE_NOTIFIER.get().expect("Should be set").clone();
  let options = args.into();
  runtime.spawn(async move {
    engine.run(&options, Some(Arc::new(frontend))).await;
  });
  runtime.spawn(async move {
    notify.notified().await;
    engine_clone.stop();
  });
  Ok(())
}

pub fn stop_engine() {
  ENGINE_NOTIFIER.get().expect("Should be set").notify_waiters();
}
