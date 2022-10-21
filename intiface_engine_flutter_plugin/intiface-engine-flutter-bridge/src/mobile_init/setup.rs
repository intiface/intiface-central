#[cfg(target_os = "android")]
mod android;
#[cfg(target_os = "android")]
pub use android::*;

#[cfg(not(target_os = "android"))]
mod not_android;
#[cfg(not(target_os = "android"))]
pub use not_android::*;
