use std::sync::{
    Arc,
    atomic::{AtomicBool, Ordering},
};

use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use log::*;
use once_cell::sync::OnceCell;
use parking_lot::Mutex;
use sentry::ClientInitGuard;

use crate::sentry_limiter::NativeSentryFilter;
use crate::{frb_generated::StreamSink, logging::FlutterTracingWriter};

static CRASH_REPORTING: OnceCell<ClientInitGuard> = OnceCell::new();
static CRASH_CONSENT: OnceCell<Arc<AtomicBool>> = OnceCell::new();

/// Update native Sentry consent without reinstalling the process-global client.
pub fn set_crash_reporting_consent(enabled: bool) {
    if let Some(consent) = CRASH_CONSENT.get() {
        consent.store(enabled, Ordering::Relaxed);
    }
}
lazy_static! {
  #[frb(ignore)]
  static ref LOGGER: Arc<Mutex<Option<FlutterTracingWriter>>> = Arc::new(Mutex::new(None));
}

pub fn setup_logging(sink: StreamSink<String>) {
    // Default log to debug, we'll filter in UI if we need it.
    unsafe {
        std::env::set_var(
            "RUST_LOG",
            "debug,h2=warn,reqwest=warn,rustls=warn,hyper=warn",
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
    set_crash_reporting_consent(true);
    if CRASH_REPORTING.get().is_some() {
        return;
    }

    info!("Initializing native crash reporting.");
    let consent = CRASH_CONSENT
        .get_or_init(|| Arc::new(AtomicBool::new(true)))
        .clone();
    let filter = Arc::new(NativeSentryFilter::new(consent));
    let callback_filter = filter.clone();
    let options = sentry::ClientOptions {
        release: sentry::release_name!(),
        before_send: Some(Arc::new(move |event| {
            // The limiter is deliberately defensive: a malformed event or poisoned lock is dropped,
            // never allowed to panic from Sentry's failure path.
            std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
                callback_filter.before_send(event)
            }))
            .ok()
            .flatten()
        })),
        ..Default::default()
    };
    let _ = CRASH_REPORTING.set(sentry::init((sentry_api_key, options)));
    info!("Native crash reporting initialized");
}
