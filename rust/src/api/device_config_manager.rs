
use std::sync::{Arc, RwLock};
use buttplug_server_device_config::{DeviceConfigurationManager, load_protocol_configs};
use lazy_static::lazy_static;

lazy_static! {
  // This is a weird wrapping, but there's a reason for it. The DCM has internal mutability, but we
  // also want to be able to completely replace it (if the user clears configurations and starts
  // over, as is possible with central). However, we also want to share the DCM with the Buttplug
  // Server while it's running. Therefore, we pull Read versions of the lock while the server is
  // running, which means we can't stop the Arc and start over until we're clear of the owning
  // process.
  //
  // The cavaet here is that, if the engine task/isolate panics, we'll be stuck with a poisoned read
  // lock. While this probably shouldn't happen, it does. A lot. So we'll need to check for an
  // active runtime whenever we try to get write locks, and clear poisoning if there's no runtime
  // active.
  pub(crate) static ref DEVICE_CONFIG_MANAGER: Arc<RwLock<Arc<DeviceConfigurationManager>>> =
    Arc::new(RwLock::new(Arc::new(load_protocol_configs(&None, &None, false).unwrap().finish().unwrap())));
}