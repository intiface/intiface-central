use flutter_rust_bridge::StreamSink;
use intiface_engine::{Frontend, EngineMessage, IntifaceError};
use async_trait::async_trait;

#[derive(Clone)]
pub struct FlutterIntifaceEngineFrontend {
  sink: StreamSink<String>,
}

impl FlutterIntifaceEngineFrontend {
  pub fn new(
    sink: StreamSink<String>,
  ) -> Self {
    Self { sink }
  }
}

#[async_trait]
impl Frontend for FlutterIntifaceEngineFrontend {
  async fn connect(&self) -> Result<(), IntifaceError> { Ok(()) }
  fn disconnect(self) {}
  async fn send(&self, msg: EngineMessage) {
    self.sink.add(serde_json::to_string(&msg).unwrap());
  }
}
