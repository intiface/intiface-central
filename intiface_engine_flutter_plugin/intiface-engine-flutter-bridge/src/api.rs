use crate::{
  in_process_frontend::FlutterIntifaceEngineFrontend,
  mobile_init::{self, RUNTIME, JAVAVM},
};
use std::sync::Arc;
use anyhow::Result;
use flutter_rust_bridge::{frb, StreamSink};
use tokio::runtime::Runtime;

pub use intiface_engine::{EngineOptions, EngineOptionsExternal, IntifaceEngine};

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
  //let sink = library_stream_sink.get().expect("Should've set library sink already");
  mobile_init::create_runtime(sink.clone()).expect("Runtime should work");
  let runtime = RUNTIME.get().expect("Runtime not initialized");
  let frontend = FlutterIntifaceEngineFrontend::new(sink.clone());
  let engine = IntifaceEngine::default();
  runtime.spawn(async move {
    engine.run(&args.into(), Some(Arc::new(frontend))).await;
  });
  Ok(())
}

pub fn stop_engine() {}
