use std::{collections::HashMap, ops::RangeInclusive};

pub use buttplug_core::message::{FeatureType, OutputType};
use buttplug_server_device_config::{DeviceDefinition, UserDeviceCustomization, UserDeviceIdentifier, ServerUserDeviceFeatureOutput, save_user_config};
use flutter_rust_bridge::frb;
use uuid::Uuid;

use crate::api::DEVICE_CONFIG_MANAGER;

//
// Identifiers
//

#[frb(unignore, ignore_all)]
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ExposedUserDeviceIdentifier {
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

#[frb(unignore, ignore_all)]
#[derive(Debug, Clone)]
pub struct ExposedDeviceDefinition {
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

  #[frb(sync)]
  pub fn update_output(&mut self, user_output: ExposedFeatureOutput) {
    let feature_id = user_output.feature_uuid_;
    let output_type = user_output.output_type();
    let rust_type = user_output.into();
    self.definition.update_user_output(feature_id, output_type, rust_type);
  }

  #[frb(sync)]
  pub fn outputs(&self) -> Vec<ExposedFeatureOutput> {
    let mut outputs = Vec::new();
    for (index, feature) in self.definition.features().iter().enumerate() {
      if let Some(output_map) = feature.output() {
        for (output_type, output) in output_map {
          outputs.push(ExposedFeatureOutput {
            feature_index_: index as u32,
            feature_uuid_: feature.id(),
            feature_type_: feature.feature_type(),
            description_: feature.description().clone(),
            output_type_: *output_type,
            step_range_: (*output.base_feature().step_range().start(), *output.base_feature().step_range().end()),
            step_limit_: (*output.step_limit().start(), *output.step_limit().end())
          });
        }
      }
    }
    outputs
  }
}

#[frb(unignore, opaque, ignore_all)]
#[derive(Debug, Clone)]
pub struct ExposedFeatureOutput {
  feature_index_: u32,
  feature_uuid_: Uuid,
  feature_type_: FeatureType,
  description_: String,
  output_type_: OutputType,
  step_range_: (u32, u32),
  step_limit_: (u32, u32),
}

impl ExposedFeatureOutput {
  #[frb(sync, getter)]
  pub fn feature_index(&self) -> u32 {
    self.feature_index_
  }

  #[frb(ignore)]
  pub fn feature_uuid(&self) -> Uuid {
    self.feature_uuid_
  }

  #[frb(sync, getter)]
  pub fn feature_type(&self) -> FeatureType {
    self.feature_type_
  }

  #[frb(sync, getter)]
  pub fn description(&self) -> String {
    self.description_.clone()
  }

  #[frb(sync, getter)]
  pub fn output_type(&self) -> OutputType {
    self.output_type_
  }

  #[frb(sync, getter)]
  pub fn step_range(&self) -> (u32, u32) {
    self.step_range_.clone()
  }

  #[frb(sync, getter)]
  pub fn step_limit(&self) -> (u32, u32) {
    self.step_limit_.clone()
  }

  #[frb(sync)]
  pub fn set_step_limit(&mut self, limit: (u32, u32)) {
    self.step_limit_ = limit;
  }
}

impl Into<ServerUserDeviceFeatureOutput> for ExposedFeatureOutput {
  fn into(self) -> ServerUserDeviceFeatureOutput {
    ServerUserDeviceFeatureOutput::new(Some(RangeInclusive::<u32>::new(self.step_limit_.0, self.step_limit_.1)), None, None)
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
