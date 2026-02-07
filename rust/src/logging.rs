use crossbeam_channel::{bounded, Sender};
use crate::frb_generated::StreamSink;
use crate::api::runtime::is_engine_shutdown;
use std::{
  sync::{atomic::AtomicBool, Arc, Once},
  thread::JoinHandle,
  time::Duration,
};
use tracing::Level;
use tracing_subscriber::{
  filter::{EnvFilter, LevelFilter},
  layer::SubscriberExt,
  util::SubscriberInitExt,
};
use log::*;
use tracing_subscriber::fmt::MakeWriter;
use lazy_static::lazy_static;
use parking_lot::Mutex;

/// Log messages matching these patterns are filtered out (not sent to Flutter).
/// These are benign errors from third-party libraries that would confuse users.
const FILTERED_LOG_PATTERNS: &[&str] = &[
  // btleplug logs this during macOS Bluetooth permission flow - benign
  "Error dispatching event: SendError",
];

/// Check if a log message should be filtered out.
fn should_filter_log(msg: &str) -> bool {
  FILTERED_LOG_PATTERNS.iter().any(|pattern| msg.contains(pattern))
}

/// Guards subscriber initialization so it only runs once per process lifetime.
/// On Android, the Rust .so stays loaded across Dart isolate restarts, so we
/// must not attempt to set the global tracing subscriber more than once.
static TRACING_INIT: Once = Once::new();

lazy_static! {
  /// Dynamically swappable channel sender for log messages. When a new Dart
  /// isolate calls setup_logging(), we replace the sender so log messages flow
  /// to the new StreamSink. The tracing subscriber (which can only be set once)
  /// writes through BroadcastWriter, which reads from this global.
  static ref LOG_SENDER: Mutex<Option<Sender<String>>> = Mutex::new(None);
}

pub struct BroadcastWriter;

impl BroadcastWriter {
  pub fn new() -> Self {
    Self
  }
}

impl std::io::Write for BroadcastWriter {
  fn write(&mut self, buf: &[u8]) -> Result<usize, std::io::Error> {
    let len = buf.len();
    if let Ok(log_str) = std::str::from_utf8(buf)
      && let Some(sender) = LOG_SENDER.lock().as_ref()
    {
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
    BroadcastWriter::new()
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

    // Create a new channel and install the sender globally so the (potentially
    // already-existing) tracing subscriber's BroadcastWriter picks it up.
    let (sender, receiver) = bounded(255);
    *LOG_SENDER.lock() = Some(sender);

    // Initialize the tracing subscriber exactly once. On Android, the Rust
    // shared library persists across Dart isolate restarts, so subsequent
    // calls to setup_logging() must NOT attempt to set the global subscriber
    // again — that would panic with SetGlobalDefaultError.
    TRACING_INIT.call_once(|| {
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
              .with_ansi(false)
              .with_writer(BroadcastWriter::new),
          )
          .try_init()
          .unwrap();
      } else {
        tracing_subscriber::registry()
          .with(LevelFilter::from(Level::DEBUG))
          .with(
            tracing_subscriber::fmt::layer()
              .json()
              .with_ansi(false)
              .with_writer(BroadcastWriter::new),
          )
          .try_init()
          .unwrap();
      }
    });

    info!("Logging subscriber added to registry");
    let cancel = Arc::new(AtomicBool::new(false));
    let cancel_clone = cancel.clone();
    let handle = std::thread::spawn(move || {
      loop {
        let should_quit = cancel_clone.load(std::sync::atomic::Ordering::Relaxed);
        if should_quit {
          info!("Breaking out of logging loop.");
          // Exhaust all waiting messages, but only if engine is not shutting down.
          while let Ok(msg) = receiver.try_recv() {
            if !is_engine_shutdown() && !should_filter_log(&msg) {
              let _ = sink.add(msg);
            }
          }
          break;
        }
        // Wait on the receiver, as while getting 255 messages in the time between our quit calls is
        // unlikely, backpressure locks are worse than waiting 10ms.
        // Check shutdown flag before sending to avoid SendError.
        // Also filter out benign third-party library errors.
        if let Ok(msg) = receiver.recv_timeout(Duration::from_millis(10))
          && !is_engine_shutdown() && !should_filter_log(&msg)
        {
          let _ = sink.add(msg);
        }
      }
    });
    Self {
      thread_handle: Some(handle),
      cancel,
    }
  }

  pub fn stop(&mut self) {
    // Clear the global sender so BroadcastWriter silently drops messages
    // during the shutdown window.
    *LOG_SENDER.lock() = None;
    self
      .cancel
      .store(true, std::sync::atomic::Ordering::Relaxed);
    if let Some(thread) = self.thread_handle.take() {
      let _ = thread.join();
    }
  }
}

impl Drop for FlutterTracingWriter {
  fn drop(&mut self) {
    self.stop();
  }
}
