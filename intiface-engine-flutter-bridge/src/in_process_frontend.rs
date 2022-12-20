use async_trait::async_trait;
use flutter_rust_bridge::StreamSink;
use futures::FutureExt;
use intiface_engine::{EngineMessage, Frontend, IntifaceError, IntifaceMessage};
use std::{future::Future, sync::Arc};
use tokio::sync::{broadcast, Notify};

pub struct FlutterIntifaceEngineFrontend {
  sender: Arc<broadcast::Sender<IntifaceMessage>>,
  sink: StreamSink<String>,
  notify: Arc<Notify>,
  disconnect_notifier: Arc<Notify>,
}

impl FlutterIntifaceEngineFrontend {
  pub fn new(sink: StreamSink<String>, sender: Arc<broadcast::Sender<IntifaceMessage>>) -> Self {
    Self {
      sink,
      sender,
      notify: Arc::new(Notify::new()),
      disconnect_notifier: Arc::new(Notify::new()),
    }
  }

  pub fn notify_on_creation(&self) -> impl Future {
    let notify = self.notify.clone();
    async move { notify.notified().await }.boxed()
  }
}

#[async_trait]
impl Frontend for FlutterIntifaceEngineFrontend {
  async fn connect(&self) -> Result<(), IntifaceError> {
    Ok(())
  }
  fn disconnect(&self) {
    self.disconnect_notifier.notify_waiters();
  }
  fn disconnect_notifier(&self) -> Arc<Notify> {
    self.disconnect_notifier.clone()
  }
  fn event_stream(&self) -> broadcast::Receiver<IntifaceMessage> {
    self.sender.subscribe()
  }
  async fn send(&self, msg: EngineMessage) {
    if let EngineMessage::EngineServerCreated {} = msg {
      self.notify.notify_waiters();
    }
    self.sink.add(serde_json::to_string(&msg).unwrap());
  }
}
