use crossbeam_channel::{bounded, Sender};
use flutter_rust_bridge::StreamSink;
use std::{
  sync::{atomic::AtomicBool, Arc},
  thread::JoinHandle,
  time::Duration,
};
use tracing::Level;
use tracing_subscriber::{
  filter::{EnvFilter, LevelFilter},
  layer::SubscriberExt,
  util::SubscriberInitExt,
};

use tracing_subscriber::fmt::MakeWriter;

pub struct BroadcastWriter {
  log_sender: Sender<String>,
}

impl BroadcastWriter {
  pub fn new(sender: Sender<String>) -> Self {
    Self { log_sender: sender }
  }
}

impl std::io::Write for BroadcastWriter {
  fn write(&mut self, buf: &[u8]) -> Result<usize, std::io::Error> {
    let sender = self.log_sender.clone();
    let len = buf.len();
    let send_buf = buf.to_vec();
    if let Ok(log_str) = std::str::from_utf8(&send_buf.to_vec()) {
      let _ = sender.send(log_str.to_owned());
    }
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

pub struct FlutterTracingWriter {
  thread_handle: Option<JoinHandle<()>>,
  cancel: Arc<AtomicBool>,
}

impl FlutterTracingWriter {
  pub fn new(sink: StreamSink<String>) -> Self {
    // Add panic hook for emitting backtraces through the logging system.
    log_panics::init();
    let (external_sender, external_receiver) = bounded(255);
    let external_sender_clone = external_sender.clone();
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
            .with_writer(move || BroadcastWriter::new(external_sender_clone.clone())),
        )
        //.with(sentry_tracing::layer())
        .try_init()
        .unwrap();
    } else {
      tracing_subscriber::registry()
        .with(LevelFilter::from(Level::DEBUG))
        .with(
          tracing_subscriber::fmt::layer()
            .json()
            //.with_max_level(log_level)
            .with_ansi(false)
            .with_writer(move || BroadcastWriter::new(external_sender_clone.clone())),
        )
        //.with(sentry_tracing::layer())
        .try_init()
        .unwrap();
    }
    info!("Logging subscriber added to registry");
    let cancel = Arc::new(AtomicBool::new(false));
    let cancel_clone = cancel.clone();
    let handle = std::thread::spawn(move || {
      loop {
        let should_quit = cancel_clone.load(std::sync::atomic::Ordering::Relaxed);
        if should_quit {
          info!("Breaking out of logging loop.");
          // Exhaust all waiting messages.
          while let Ok(msg) = external_receiver.try_recv() {
            sink.add(msg);
          }
          break;
        }
        // Wait on the receiver, as while getting 255 messages in the time between our quit calls is
        // unlikely, backpressure locks are worse than waiting 10ms.
        if let Ok(msg) = external_receiver.recv_timeout(Duration::from_millis(10)) {
          sink.add(msg);
        }
      }
    });
    Self {
      thread_handle: Some(handle),
      cancel,
    }
  }

  pub fn stop(&mut self) {
    self
      .cancel
      .store(true, std::sync::atomic::Ordering::Relaxed);
    let thread = self.thread_handle.take().unwrap();
    let _ = thread.join();
  }
}

impl Drop for FlutterTracingWriter {
  fn drop(&mut self) {
    self.stop();
  }
}
