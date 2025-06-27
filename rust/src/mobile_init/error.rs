use thiserror::Error;

#[derive(Debug, Error)]
pub enum Error {
  #[error("Btleplug error: {0}")]
  Btleplug(#[from] btleplug::Error),

  #[cfg(target_os = "android")]
  #[error("JNI {0}")]
  Jni(#[from] jni::errors::Error),

  #[cfg(target_os = "android")]
  #[error("Cannot initialize CLASS_LOADER")]
  ClassLoader,

  //#[error("Cannot initialize RUNTIME")]
  //Runtime,
  #[cfg(target_os = "android")]
  #[error("Java vm not initialized")]
  JavaVM,
}
