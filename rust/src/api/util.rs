use std::sync::Arc;

use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use once_cell::sync::OnceCell;
use sentry::ClientInitGuard;
use log::*;
use parking_lot::Mutex;

use crate::{frb_generated::StreamSink, logging::FlutterTracingWriter};


static CRASH_REPORTING: OnceCell<ClientInitGuard> = OnceCell::new();
lazy_static! {
  #[frb(ignore)]
  static ref LOGGER: Arc<Mutex<Option<FlutterTracingWriter>>> = Arc::new(Mutex::new(None));
}

pub fn setup_logging(sink: StreamSink<String>) {
  // Default log to debug, we'll filter in UI if we need it.
  unsafe {
    std::env::set_var(
      "RUST_LOG",
      format!("debug,h2=warn,reqwest=warn,rustls=warn,hyper=warn"),
    );
  }
  // Shut down the old writer first, so its Drop doesn't clear the new sender
  // that FlutterTracingWriter::new() is about to install.
  shutdown_logging();
  *LOGGER.lock() = Some(FlutterTracingWriter::new(sink));
}

pub fn shutdown_logging() {
  *LOGGER.lock() = None;
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
