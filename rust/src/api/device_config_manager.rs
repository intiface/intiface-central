
use std::sync::Arc;
use parking_lot::RwLock;
use buttplug_server_device_config::{DeviceConfigurationManager, load_protocol_configs};
use lazy_static::lazy_static;
use anyhow;

lazy_static! {
  // This is a weird wrapping, but there's a reason for it. The DCM has internal mutability, but we
  // also want to be able to completely replace it (if the user clears configurations and starts
  // over, as is possible with central). However, we also want to share the DCM with the Buttplug
  // Server while it's running. Therefore, we pull Read versions of the lock while the server is
  // running, which means we can't stop the Arc and start over until we're clear of the owning
  // process.
  pub(crate) static ref DEVICE_CONFIG_MANAGER: Arc<RwLock<Arc<DeviceConfigurationManager>>> =
    Arc::new(RwLock::new(Arc::new(load_protocol_configs(&None, &None, false).unwrap().finish().unwrap())));
}

pub fn setup_device_configuration_manager(
  base_config: Option<String>,
  user_config: Option<String>,
) -> Result<(), anyhow::Error> {
  if let Some(mut dcm) = DEVICE_CONFIG_MANAGER.try_write() {
    *dcm = Arc::new(
      load_protocol_configs(&base_config, &user_config, false)
        .map_err(|x| anyhow::anyhow!(format!("{:?}", x)))?
        .finish()
        .map_err(|x| anyhow::anyhow!(format!("{:?}", x)))?);
  }
  Ok(())
}