
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

use crate::api::DEVICE_CONFIG_MANAGER;

//
// Identifiers
//

#[frb(unignore)]
#[derive(Debug, Clone)]
pub struct ExposedUserDeviceIdentifier {
  pub address: String,
  pub protocol: String,
  pub identifier: Option<String>,
}

impl From<UserDeviceIdentifier> for ExposedUserDeviceIdentifier {
  fn from(value: UserDeviceIdentifier) -> Self {
    Self {
      address: value.address().clone(),
      protocol: value.protocol().clone(),
      identifier: value.identifier().clone(),
    }
  }
}

impl Into<UserDeviceIdentifier> for ExposedUserDeviceIdentifier {
  fn into(self) -> UserDeviceIdentifier {
    UserDeviceIdentifier::new(&self.address, &self.protocol, &self.identifier)
  }
}

//
// Definitions
//
/*
#[derive(Debug, Clone)]
pub struct ExposedDeviceDefinition {
  // Leave base_device opaque, we'll allow access through struct methods
  pub base_device: BaseDeviceDefinition,
  pub user_device: ExposedUserDeviceDefinition,
  pub features: Vec<ServerDeviceFeature>
}

impl From<DeviceDefinition> for ExposedDeviceDefinition {
  fn from(value: DeviceDefinition) -> Self {
    Self {
      base_device: value.base_device().clone(),
      user_device: value.user_device().clone(),
      features: value.features().clone()
    }
  }
}

impl Into<DeviceDefinition> for ExposedDeviceDefinition {
  fn into(self) -> DeviceDefinition {
    DeviceDefinition::new(&self.base_device, &self.user_device)
  }
}

impl ExposedDeviceDefinition {
  #[frb(sync, getter)]
  pub fn id(&self) -> Uuid {
    self.user_device.id()
  }

  #[frb(sync, getter)]
  pub fn name(&self) -> &str {
    self.base_device.name()
  }

  #[frb(sync, getter)]
  pub fn user_config(&self) -> ExposedUserDeviceCustomization {
    self.user_device.user_config().clone().into()
  }
}
  */

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

#[derive(Debug, Clone)]
pub struct ExposedBaseDeviceDefinition {
  
}

//
// Features
//


#[derive(Debug, Clone)]
pub struct ExposedDeviceFeature {
  pub description: String,
  pub id: String,
  pub base_id: String,
  pub feature_type: FeatureType,
  pub output: Option<HashMap<OutputType, ExposedDeviceFeatureOutput>>,
  pub input: Option<HashMap<InputType, ExposedDeviceFeatureInput>>,
  // Leave out raw here, we'll never need it in the UI anyways
}

impl From<ServerDeviceFeature> for ExposedDeviceFeature {
  fn from(value: ServerDeviceFeature) -> Self {
    Self {
      description: value.description().clone(),
      feature_type: value.feature_type(),
      id: value.id().to_string().to_owned(),
      base_id: value.base_id().to_string(),
      output: value
        .output()
        .clone()
        .and_then(|x| Some(x.iter().map(|(t, x)| (*t, x.clone().into()) ).collect())),
      input: value
        .input()
        .clone()
        .and_then(|x| Some(x.iter().map(|(t, x)| (*t, x.clone().into()) ).collect())),
    }
  }
}
/*
impl Into<ServerDeviceFeature> for ExposedDeviceFeature {
  fn into(self) -> ServerDeviceFeature {
    ServerDeviceFeature::new(
      &self.description,
      &Uuid::try_parse(&self.id).unwrap(),
      &self.base_id.and_then(|x| Some(Uuid::try_parse(&x).unwrap())),
      self.feature_type,
      &self.output.and_then(|x| Some(x.iter().map(|t| (t.output_type, t.output.clone().into())).collect())),
      &self.input.and_then(|x| Some(x.iter().map(|t| (t.input_type, t.input.clone().into())).collect())),
    )
  }
}
  */

//
// Outputs
//

#[derive(Debug, Clone)]
pub struct ExposedServerBaseDeviceFeatureOutput {
  pub step_range: (u32, u32),
}

impl From<ServerBaseDeviceFeatureOutput> for ExposedServerBaseDeviceFeatureOutput {
  fn from(value: ServerBaseDeviceFeatureOutput) -> Self {
    Self {
      step_range: (*value.step_range().start(), *value.step_range().end()),
    }
  }
}

impl Into<ServerBaseDeviceFeatureOutput> for ExposedServerBaseDeviceFeatureOutput {
  fn into(self) -> ServerBaseDeviceFeatureOutput {
    ServerBaseDeviceFeatureOutput::new(
      &RangeInclusive::new(self.step_range.0, self.step_range.1),
    )
  }
}

#[derive(Debug, Clone)]
pub struct ExposedServerUserDeviceFeatureOutput {
  pub step_limit: Option<RangeInclusive<u32>>,
  pub reverse_position: Option<bool>,
  pub ignore: Option<bool>
}

impl From<ServerUserDeviceFeatureOutput> for ExposedServerUserDeviceFeatureOutput {
  fn from(value: ServerUserDeviceFeatureOutput) -> Self {
    Self {
      step_limit: /*if let Some(limit) = value.step_limit() {
        Some((*limit.start(), *limit.end()))
      } else {
        None
      }*/ value.step_limit().clone(),
      reverse_position: *value.reverse_position(),
      ignore: *value.ignore()
    }
  }
}

impl Into<ServerUserDeviceFeatureOutput> for ExposedServerUserDeviceFeatureOutput {
  fn into(self) -> ServerUserDeviceFeatureOutput {
    ServerUserDeviceFeatureOutput::new(
      self.step_limit,
      self.reverse_position,
      self.ignore
    )
  }
}

#[derive(Debug, Clone)]
pub struct ExposedDeviceFeatureOutput {
  pub base_feature: ExposedServerBaseDeviceFeatureOutput,
  pub user_feature: ExposedServerUserDeviceFeatureOutput
}

impl From<ServerDeviceFeatureOutput> for ExposedDeviceFeatureOutput {
  fn from(value: ServerDeviceFeatureOutput) -> Self {
    Self {
      base_feature: value.base_feature().clone().into(),
      user_feature: value.user_feature().clone().into()
    }
  }
}

impl Into<ServerDeviceFeatureOutput> for ExposedDeviceFeatureOutput {
  fn into(self) -> ServerDeviceFeatureOutput {
    ServerDeviceFeatureOutput::new(
      &self.base_feature.into(),
      &self.user_feature.into()
    )
  }
}

//
// Inputs
//

#[derive(Debug, Clone)]
pub struct ExposedDeviceFeatureInput {
  pub value_range: Vec<(i32, i32)>,
  pub input_commands: Vec<InputCommandType>
}

impl From<ServerDeviceFeatureInput> for ExposedDeviceFeatureInput {
  fn from(value: ServerDeviceFeatureInput) -> Self {
    Self {
      value_range: value
        .value_range()
        .iter()
        .map(|val| (*val.start(), *val.end()))
        .collect(),
      input_commands: value.input_commands().iter().cloned().collect()
    }
  }
}

impl Into<ServerDeviceFeatureInput> for ExposedDeviceFeatureInput {
  fn into(self) -> ServerDeviceFeatureInput {
    ServerDeviceFeatureInput::new(
      &self
        .value_range
        .iter()
        .map(|val| RangeInclusive::new(val.0, val.1))
        .collect(),
      &HashSet::from_iter(self.input_commands.iter().cloned()),
    )
  }
}
/*
pub fn update_user_config(
  identifier: ExposedUserDeviceIdentifier,
  config: ExposedDeviceDefinition,
) {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  dcm.add_user_device_definition(&identifier.into(), &config.into());
}
*/
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
/*
pub fn get_user_device_definitions(
) -> Vec<(ExposedUserDeviceIdentifier, ExposedDeviceDefinition)> {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  dcm
    .user_device_definitions()
    .iter()
    .map(|kv| (kv.key().clone().into(), kv.value().clone().into()))
    .collect()
}
*/