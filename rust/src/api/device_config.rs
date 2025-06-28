
// "Exposed" types are mirrors of internal Buttplug types, but with all public members and typing
// that's amiable to FlutterRustBridge translation. These types can't be directly mirrored because
// the library itself has private members.
//
// "But don't you own the library also?" I mean, yes, I do, but I cannot emotionally handle bringing
// myself to set the struct members public there just for this application. I hate having ethics.

use std::{collections::{HashMap, HashSet}, ops::RangeInclusive, time::Duration};

use buttplug::util::device_configuration::save_user_config;
pub use buttplug::{core::message::{FeatureType, InputCommandType, InputType, OutputType}, server::device::{configuration::{BaseDeviceDefinition, DeviceDefinition, UserDeviceCustomization, UserDeviceDefinition, UserDeviceIdentifier}, server_device_feature::{ServerBaseDeviceFeatureOutput, ServerDeviceFeature, ServerDeviceFeatureInput, ServerDeviceFeatureOutput, ServerUserDeviceFeatureOutput}}};
use flutter_rust_bridge::frb;
use uuid::Uuid;
use log::*;

use crate::api::DEVICE_CONFIG_MANAGER;

//
// Identifiers
//

#[frb(unignore)]
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ExposedUserDeviceIdentifier {
  #[frb(ignore)]
  identifier: UserDeviceIdentifier
}

impl ExposedUserDeviceIdentifier {
  #[frb(sync, getter)]
  pub fn address(&self) -> String {
    self.identifier.address().to_owned()
  }

  #[frb(sync, getter)]
  pub fn identifier(&self) -> Option<String> {
    self.identifier.identifier().to_owned()
  }

  #[frb(sync, getter)]
  pub fn protocol(&self) -> String {
    self.identifier.protocol().to_owned()
  }
}

impl ExposedUserDeviceIdentifier {
  #[frb(unignore, sync)]
  pub fn new(address: String, protocol: String,identifier: Option<String>) -> Self {
    Self {
      identifier: UserDeviceIdentifier::new(&address, &protocol, &identifier)
    }
  }
}

impl From<UserDeviceIdentifier> for ExposedUserDeviceIdentifier {
  fn from(value: UserDeviceIdentifier) -> Self {
    Self {
      identifier: value
    }
  }
}

impl Into<UserDeviceIdentifier> for ExposedUserDeviceIdentifier {
  fn into(self) -> UserDeviceIdentifier {
    self.identifier
  }
}

//
// Definitions
//

#[frb(unignore)]
#[derive(Debug, Clone)]
pub struct ExposedDeviceDefinition {
  #[frb(ignore)]
  definition: DeviceDefinition,
}

impl From<DeviceDefinition> for ExposedDeviceDefinition {
  fn from(value: DeviceDefinition) -> Self {
    Self {
      definition: value
    }
  }
}

impl Into<DeviceDefinition> for ExposedDeviceDefinition {
  fn into(self) -> DeviceDefinition {
    self.definition
  }
}

impl ExposedDeviceDefinition {
  #[frb(sync, getter)]
  pub fn id(&self) -> Uuid {
    self.definition.user_device().id()
  }

  #[frb(sync, getter)]
  pub fn name(&self) -> String {
    self.definition.base_device().name().to_owned()
  }

  #[frb(sync, getter)]
  pub fn user_config(&self) -> ExposedUserDeviceCustomization {
    self.definition.user_device().user_config().clone().into()
  }

  #[frb(sync)]
  pub fn set_user_config(&mut self, config: ExposedUserDeviceCustomization) {
    *self.definition.user_device_mut().user_config_mut() = config.into();
  }
}

#[frb(unignore)]
#[derive(Debug, Clone)]
pub struct ExposedUserDeviceCustomization {
  pub display_name: Option<String>,
  pub allow: bool,
  pub deny: bool,
  pub index: u32,
  pub message_gap_ms: Option<u32>,
}

impl From<UserDeviceCustomization> for ExposedUserDeviceCustomization {
  fn from(value: UserDeviceCustomization) -> Self {
    Self {
      display_name: value.display_name().clone(),
      allow: value.allow(),
      deny: value.deny(),
      index: value.index(),
      message_gap_ms: value.message_gap_ms()
    }
  }
}

impl Into<UserDeviceCustomization> for ExposedUserDeviceCustomization {
  fn into(self) -> UserDeviceCustomization {
    UserDeviceCustomization::new(
      &self.display_name.clone(),
      self.allow,
      self.deny,
      self.index,
      self.message_gap_ms
    )
  }
}

pub fn update_user_config(
  identifier: ExposedUserDeviceIdentifier,
  config: ExposedDeviceDefinition,
) {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  dcm.add_user_device_definition(&identifier.into(), &config.into());
}

pub fn remove_user_config(identifier: ExposedUserDeviceIdentifier) {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  dcm.remove_user_device_definition(&identifier.into());
}

pub fn get_user_config_str() -> String {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  save_user_config(&dcm).unwrap()
}

pub fn get_user_device_definitions(
) -> HashMap<ExposedUserDeviceIdentifier, ExposedDeviceDefinition> {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  dcm
    .user_device_definitions()
    .iter()
    .map(|kv| (kv.key().clone().into(), kv.value().clone().into()))
    .collect()
}
