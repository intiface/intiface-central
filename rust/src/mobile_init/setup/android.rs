use crate::frb_generated::StreamSink;
use jni::objects::{Global, JObject};
use jni::{jni_sig, jni_str, JavaVM};
use once_cell::sync::OnceCell;
use std::sync::atomic::{AtomicUsize, Ordering};
use tokio::runtime::Runtime;

use crate::mobile_init::MobileInitError;

static CLASS_LOADER: OnceCell<Global<JObject<'static>>> = OnceCell::new();
pub static JAVAVM: OnceCell<JavaVM> = OnceCell::new();

pub fn create_runtime(_: StreamSink<String>) -> Result<Runtime, MobileInitError> {
  let vm = JAVAVM.get().ok_or(MobileInitError::JavaVM)?;
  // We create runtimes multiple times. Only run our loader setup once.
  if CLASS_LOADER.get().is_none() {
    setup_class_loader(vm)?;
  }
  let runtime = {
    tokio::runtime::Builder::new_multi_thread()
      .enable_all()
      .thread_name_fn(|| {
        static ATOMIC_ID: AtomicUsize = AtomicUsize::new(0);
        let id = ATOMIC_ID.fetch_add(1, Ordering::SeqCst);
        format!("intiface-thread-{}", id)
      })
      .on_thread_start(move || {
        // Give each tokio worker thread the app's context class loader so
        // JNI class lookups work from runtime threads. jni 0.22's
        // attach_current_thread attaches the thread permanently by default;
        // the closure only scopes the JNI calls.
        let vm = JAVAVM.get().unwrap();
        vm.attach_current_thread(|env| {
          let thread = env
            .call_static_method(
              jni_str!("java/lang/Thread"),
              jni_str!("currentThread"),
              jni_sig!("()Ljava/lang/Thread;"),
              &[],
            )?
            .l()?;
          env.call_method(
            &thread,
            jni_str!("setContextClassLoader"),
            jni_sig!("(Ljava/lang/ClassLoader;)V"),
            &[CLASS_LOADER.get().unwrap().as_obj().into()],
          )?;
          Ok::<_, jni::errors::Error>(())
        })
        .unwrap();
      })
      .build()
      .unwrap()
  };
  Ok(runtime)
}

fn setup_class_loader(vm: &JavaVM) -> Result<(), MobileInitError> {
  let class_loader: Global<JObject<'static>> = vm
    .attach_current_thread(|env| -> Result<Global<JObject<'static>>, jni::errors::Error> {
      let thread = env
        .call_static_method(
          jni_str!("java/lang/Thread"),
          jni_str!("currentThread"),
          jni_sig!("()Ljava/lang/Thread;"),
          &[],
        )?
        .l()?;
      let class_loader = env
        .call_method(
          &thread,
          jni_str!("getContextClassLoader"),
          jni_sig!("()Ljava/lang/ClassLoader;"),
          &[],
        )?
        .l()?;
      Ok(env.new_global_ref(class_loader)?)
    })
    .map_err(MobileInitError::Jni)?;

  CLASS_LOADER
    .set(class_loader)
    .map_err(|_| MobileInitError::ClassLoader)
}

// THIS HAS TO BE COMMENTED OUT OR REMOVED FROM GENERATED CODE WHEN BUILDING IOS CODEGEN OTHERWISE
// IOS BUILDS WILL FAIL
#[cfg(target_os = "android")]
#[unsafe(no_mangle)]
pub extern "C" fn JNI_OnLoad(vm: jni::JavaVM, _res: *const std::os::raw::c_void) -> jni::sys::jint {
  vm.attach_current_thread(|env| {
    btleplug::platform::init(env).map_err(|_| jni::errors::Error::JavaException)
  })
  .unwrap();
  let _ = JAVAVM.set(vm);
  jni::JNIVersion::V1_6.into()
}
