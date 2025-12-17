use async_trait::async_trait;
use crate::frb_generated::StreamSink;
use futures::FutureExt;
use intiface_engine::{EngineMessage, Frontend, IntifaceError, IntifaceMessage};
use std::{future::Future, sync::{Arc, atomic::{AtomicBool, Ordering}}};
use tokio::sync::{broadcast, Notify};

pub struct FlutterIntifaceEngineFrontend {
  sender: Arc<broadcast::Sender<IntifaceMessage>>,
  sink: StreamSink<String>,
  notify: Arc<Notify>,
  disconnect_notifier: Arc<Notify>,
  /// Flag to indicate the frontend is closed and should not send messages.
  /// Prevents "Error dispatching event: SendError { kind: Disconnected }"
  /// during shutdown when the Dart stream has already been closed.
  closed: AtomicBool,
}

impl FlutterIntifaceEngineFrontend {
  pub fn new(sink: StreamSink<String>, sender: Arc<broadcast::Sender<IntifaceMessage>>) -> Self {
    Self {
      sink,
      sender,
      notify: Arc::new(Notify::new()),
      disconnect_notifier: Arc::new(Notify::new()),
      closed: AtomicBool::new(false),
    }
  }

  pub fn notify_on_creation(&self) -> impl Future + use<> {
    let notify = self.notify.clone();
    async move { notify.notified().await }.boxed()
  }

  /// Mark the frontend as closed to prevent sending messages after shutdown.
  pub fn close(&self) {
    self.closed.store(true, Ordering::SeqCst);
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
    // Check if frontend is closed before sending to avoid SendError during shutdown
    if self.closed.load(Ordering::SeqCst) {
      return;
    }
    if let EngineMessage::EngineServerCreated {} = msg {
      self.notify.notify_waiters();
    }
    let _ = self.sink.add(serde_json::to_string(&msg).unwrap());
  }
}
