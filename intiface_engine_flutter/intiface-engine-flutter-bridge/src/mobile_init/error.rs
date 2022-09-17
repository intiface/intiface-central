use thiserror::Error;

#[derive(Debug, Error)]
pub enum Error {
  #[error("Btleplug error: {0}")]
  Btleplug(#[from] btleplug::Error),

  #[error("JNI {0}")]
  Jni(#[from] jni::errors::Error),

  #[error("Cannot initialize CLASS_LOADER")]
  ClassLoader,

  #[error("Cannot initialize RUNTIME")]
  Runtime,

  #[error("Java vm not initialized")]
  JavaVM,
}
