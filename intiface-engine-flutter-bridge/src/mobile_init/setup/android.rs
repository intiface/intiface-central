use flutter_rust_bridge::StreamSink;
use jni::objects::GlobalRef;
use jni::{AttachGuard, JNIEnv, JavaVM};
use once_cell::sync::OnceCell;
use std::cell::RefCell;
use std::sync::atomic::{AtomicUsize, Ordering};
use tokio::runtime::Runtime;

use crate::mobile_init::Error;

static CLASS_LOADER: OnceCell<GlobalRef> = OnceCell::new();
pub static JAVAVM: OnceCell<JavaVM> = OnceCell::new();

std::thread_local! {
  static JNI_ENV: RefCell<Option<AttachGuard<'static>>> = RefCell::new(None);
}

pub fn create_runtime(_: StreamSink<String>) -> Result<Runtime, Error> {
  let vm = JAVAVM.get().ok_or(Error::JavaVM)?;
  let env = vm.attach_current_thread().unwrap();

  // We create runtimes multiple times. Only run our loader setup once.
  if CLASS_LOADER.get().is_none() {
    setup_class_loader(&env).unwrap();
  }
  let runtime = {
    tokio::runtime::Builder::new_multi_thread()
      .enable_all()
      .thread_name_fn(|| {
        static ATOMIC_ID: AtomicUsize = AtomicUsize::new(0);
        let id = ATOMIC_ID.fetch_add(1, Ordering::SeqCst);
        format!("intiface-thread-{}", id)
      })
      .on_thread_stop(move || {
        JNI_ENV.with(|f| *f.borrow_mut() = None);
      })
      .on_thread_start(move || {
        // We now need to call the following code block via JNI calls. God help us.
        //
        //  java.lang.Thread.currentThread().setContextClassLoader(
        //    java.lang.ClassLoader.getSystemClassLoader()
        //  );
        let vm = JAVAVM.get().unwrap();
        let env = vm.attach_current_thread().unwrap();
        let thread = env
          .call_static_method(
            "java/lang/Thread",
            "currentThread",
            "()Ljava/lang/Thread;",
            &[],
          )
          .unwrap()
          .l()
          .unwrap();
        env
          .call_method(
            thread,
            "setContextClassLoader",
            "(Ljava/lang/ClassLoader;)V",
            &[CLASS_LOADER.get().unwrap().as_obj().into()],
          )
          .unwrap();
        JNI_ENV.with(|f| *f.borrow_mut() = Some(env));
      })
      .build()
      .unwrap()
  };
  Ok(runtime)
}

fn setup_class_loader(env: &JNIEnv) -> Result<(), Error> {
  let thread = env
    .call_static_method(
      "java/lang/Thread",
      "currentThread",
      "()Ljava/lang/Thread;",
      &[],
    )?
    .l()?;
  let class_loader = env
    .call_method(
      thread,
      "getContextClassLoader",
      "()Ljava/lang/ClassLoader;",
      &[],
    )?
    .l()?;

  CLASS_LOADER
    .set(env.new_global_ref(class_loader)?)
    .map_err(|_| Error::ClassLoader)
}

// THIS HAS TO BE COMMENTED OUT OR REMOVED FROM GENERATED CODE WHEN BUILDING IOS CODEGEN OTHERWISE
// IOS BUILDS WILL FAIL
#[cfg(target_os = "android")]
#[no_mangle]
pub extern "C" fn JNI_OnLoad(vm: jni::JavaVM, _res: *const std::os::raw::c_void) -> jni::sys::jint {
  let env = vm.get_env().unwrap();
  jni_utils::init(&env).unwrap();
  btleplug::platform::init(&env).unwrap();
  let _ = JAVAVM.set(vm);
  jni::JNIVersion::V6.into()
}
