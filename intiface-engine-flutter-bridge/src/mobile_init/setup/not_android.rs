use crate::mobile_init::Error;
use flutter_rust_bridge::StreamSink;
use std::sync::atomic::{AtomicUsize, Ordering};
use tokio::runtime::Runtime;

pub fn create_runtime(_: StreamSink<String>) -> Result<Runtime, Error> {
  let runtime = {
    tokio::runtime::Builder::new_multi_thread()
      .enable_all()
      .thread_name_fn(|| {
        static ATOMIC_ID: AtomicUsize = AtomicUsize::new(0);
        let id = ATOMIC_ID.fetch_add(1, Ordering::SeqCst);
        format!("intiface-thread-{id}")
      })
      .on_thread_start(|| {})
      .build()
      .unwrap()
  };
  Ok(runtime)
}
