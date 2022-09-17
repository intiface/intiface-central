#[cfg(target_os = "android")]
mod android;
#[cfg(target_os = "android")]
pub use android::*;

#[cfg(target_os = "ios")]
mod ios;
#[cfg(target_os = "ios")]
pub use ios::*;

// Dummy functions to silence rust-analyzer
#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub static RUNTIME: OnceCell<Runtime> = once_cell::sync::OnceCell::new();
#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub fn create_runtime(sink: flutter_rust_bridge::StreamSink<String>) -> Result<(), super::Error> {
  Ok(())
}
