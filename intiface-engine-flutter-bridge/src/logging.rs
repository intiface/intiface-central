use intiface_engine::{EngineMessage, Frontend};
use lazy_static::lazy_static;
use once_cell::sync::OnceCell;
use std::sync::Arc;
use tokio::{select, sync::broadcast};
use tracing::Level;
use tracing_subscriber::{
  filter::{EnvFilter, LevelFilter},
  layer::SubscriberExt,
  util::SubscriberInitExt,
};

static FRONTEND_LOGGING_SET: OnceCell<bool> = OnceCell::new();
lazy_static! {
  static ref LOG_BROADCASTER: Arc<broadcast::Sender<Vec<u8>>> = Arc::new(broadcast::channel(255).0);
}

use tracing_subscriber::fmt::MakeWriter;

pub struct BroadcastWriter {
  log_sender: Arc<broadcast::Sender<Vec<u8>>>,
}

impl BroadcastWriter {
  pub fn new(sender: Arc<broadcast::Sender<Vec<u8>>>) -> Self {
    Self { log_sender: sender }
  }
}

impl std::io::Write for BroadcastWriter {
  fn write(&mut self, buf: &[u8]) -> Result<usize, std::io::Error> {
    let sender = self.log_sender.clone();
    let len = buf.len();
    let send_buf = buf.to_vec();
    let _ = sender.send(send_buf.to_vec());
    Ok(len)
  }

  fn flush(&mut self) -> Result<(), std::io::Error> {
    Ok(())
  }
}

impl MakeWriter<'_> for BroadcastWriter {
  type Writer = BroadcastWriter;
  fn make_writer(&self) -> Self::Writer {
    BroadcastWriter::new(self.log_sender.clone())
  }
}

pub fn setup_frontend_logging(log_level: Level, frontend: Arc<dyn Frontend>) {
  // Add panic hook for emitting backtraces through the logging system.
  log_panics::init();
  let mut receiver = LOG_BROADCASTER.subscribe();
  let log_sender = frontend.clone();
  let notifier = log_sender.disconnect_notifier();
  tokio::spawn(async move {
    // We can log until our receiver disappears at this point.
    loop {
      select! {
        log = receiver.recv() => {
          match log {
            Ok(log) => {
              log_sender
                .send(EngineMessage::EngineLog {
                  message: std::str::from_utf8(&log).unwrap().to_owned(),
                })
                .await;
            }
            Err(_) => return
          }
        }
        _ = notifier.notified() => return
      }
    }
  });

  if FRONTEND_LOGGING_SET.get().is_none() {
    FRONTEND_LOGGING_SET.set(true).unwrap();
    if std::env::var("RUST_LOG").is_ok() {
      tracing_subscriber::registry()
        .with(
          EnvFilter::try_from_default_env()
            .or_else(|_| EnvFilter::try_new("info"))
            .unwrap(),
        )
        .with(
          tracing_subscriber::fmt::layer()
            .json()
            //.with_max_level(log_level)
            .with_ansi(false)
            .with_writer(move || BroadcastWriter::new(LOG_BROADCASTER.clone())),
        )
        //.with(sentry_tracing::layer())
        .try_init()
        .unwrap();
    } else {
      tracing_subscriber::registry()
        .with(LevelFilter::from(log_level))
        .with(
          tracing_subscriber::fmt::layer()
            .json()
            //.with_max_level(log_level)
            .with_ansi(false)
            .with_writer(move || BroadcastWriter::new(LOG_BROADCASTER.clone())),
        )
        //.with(sentry_tracing::layer())
        .try_init()
        .unwrap();
      info!("Logging subscriber added to registry");
    }
  }
}
