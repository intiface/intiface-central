use flutter_rust_bridge::StreamSink;
use intiface_engine::{Frontend, EngineMessage, IntifaceError, IntifaceMessage};
use async_trait::async_trait;
use tokio::sync::broadcast;
use std::sync::Arc;

#[derive(Clone)]
pub struct FlutterIntifaceEngineFrontend {
  sender: Arc<broadcast::Sender<IntifaceMessage>>,
  sink: StreamSink<String>,
}

impl FlutterIntifaceEngineFrontend {
  pub fn new(
    sink: StreamSink<String>,
    sender: Arc<broadcast::Sender<IntifaceMessage>>
  ) -> Self {
    Self { sink, sender }
  }
}

#[async_trait]
impl Frontend for FlutterIntifaceEngineFrontend {
  async fn connect(&self) -> Result<(), IntifaceError> { Ok(()) }
  fn disconnect(self) {}
  fn event_stream(&self) -> broadcast::Receiver<IntifaceMessage> {
    self.sender.subscribe()
  }
  async fn send(&self, msg: EngineMessage) {
    self.sink.add(serde_json::to_string(&msg).unwrap());
  }
}
