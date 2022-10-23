use crate::mobile_init::Error;
use std::sync::atomic::{AtomicUsize, Ordering};
use once_cell::sync::OnceCell;
use tokio::runtime::Runtime;
use flutter_rust_bridge::StreamSink;

pub static RUNTIME: OnceCell<Runtime> = OnceCell::new();

pub fn create_runtime(_: StreamSink<String>) -> Result<(), Error> {
  let runtime = {
    tokio::runtime::Builder::new_multi_thread()
      .enable_all()
      .thread_name_fn(|| {
        static ATOMIC_ID: AtomicUsize = AtomicUsize::new(0);
        let id = ATOMIC_ID.fetch_add(1, Ordering::SeqCst);
        format!("intiface-thread-{}", id)
      })
      .on_thread_start(|| {})
      .build()
      .unwrap()
  };
  RUNTIME.set(runtime).map_err(|_| Error::Runtime)?;
  Ok(())
}
