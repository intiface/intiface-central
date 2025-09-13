use std::sync::Arc;

use lazy_static::lazy_static;
use once_cell::sync::OnceCell;
use sentry::ClientInitGuard;
use log::*;
use std::sync::Mutex;

use crate::{frb_generated::StreamSink, logging::FlutterTracingWriter};


static CRASH_REPORTING: OnceCell<ClientInitGuard> = OnceCell::new();
lazy_static! {
  static ref LOGGER: Arc<Mutex<Option<FlutterTracingWriter>>> = Arc::new(Mutex::new(None));
}

pub fn setup_logging(sink: StreamSink<String>) {
  // Default log to debug, we'll filter in UI if we need it.
  std::env::set_var(
    "RUST_LOG",
    format!("debug,h2=warn,reqwest=warn,rustls=warn,hyper=warn"),
  );
  *LOGGER.lock().unwrap() = Some(FlutterTracingWriter::new(sink));
}

pub fn shutdown_logging() {
  *LOGGER.lock().unwrap() = None;
}

pub fn crash_reporting(sentry_api_key: String) {
  // Set up Sentry
  info!("Initializing native crash reporting.");
  let _ = CRASH_REPORTING.set(sentry::init((
    sentry_api_key,
    sentry::ClientOptions {
      release: sentry::release_name!(),
      ..Default::default()
    },
  )));
  info!("Native crash reporting initialized");
}
