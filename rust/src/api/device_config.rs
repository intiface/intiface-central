use std::{collections::HashMap, ops::RangeInclusive};

use buttplug_server_device_config::{RangeWithLimit, ServerDeviceDefinition, ServerDeviceFeature, ServerDeviceFeatureInput, ServerDeviceFeatureOutput, ServerDeviceFeatureOutputPositionProperties, ServerDeviceFeatureOutputPositionWithDurationProperties, ServerDeviceFeatureOutputValueProperties, UserDeviceIdentifier, save_user_config};
use flutter_rust_bridge::frb;
use uuid::Uuid;

use crate::api::device_config_manager::DEVICE_CONFIG_MANAGER;

//
// Identifiers
//

#[frb(unignore, ignore_all, opaque)]
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

#[frb(unignore, ignore_all, opaque)]
#[derive(Debug, Clone)]
pub struct ExposedServerDeviceDefinition {
  #[frb(ignore)]
  definition: ServerDeviceDefinition,
}

impl From<ServerDeviceDefinition> for ExposedServerDeviceDefinition {
  fn from(value: ServerDeviceDefinition) -> Self {
    Self {
      definition: value
    }
  }
}

impl Into<ServerDeviceDefinition> for ExposedServerDeviceDefinition {
  fn into(self) -> ServerDeviceDefinition {
    self.definition
  }
}

impl ExposedServerDeviceDefinition {
  #[frb(sync, getter)]
  pub fn id(&self) -> Uuid {
    self.definition.id()
  }

  #[frb(sync, getter)]
  pub fn name(&self) -> String {
    self.definition.name().to_owned()
  }

  #[frb(sync, getter)]
  pub fn message_gap_ms(&self) -> Option<u32> {
    self.definition.message_gap_ms().clone()
  }

  #[frb(sync, getter)]
  pub fn display_name(&self) -> Option<String> {
    self.definition.display_name().clone()
  }

  #[frb(sync, getter)]
  pub fn allow(&self) -> bool {
    self.definition.allow()
  }

  #[frb(sync, getter)]
  pub fn deny(&self) -> bool {
    self.definition.deny()
  }

  #[frb(sync, getter)]
  pub fn index(&self) -> u32 {
    self.definition.index()
  }

  #[frb(sync, getter)]
  pub fn features(&self) -> Vec<ExposedServerDeviceFeature> {
    self.definition.features().iter().map(|x| x.into()).collect()
  }
}

#[frb(unignore, opaque, ignore_all)]
#[derive(Debug, Clone)]
pub struct ExposedServerDeviceFeature {
  feature: ServerDeviceFeature
}

impl ExposedServerDeviceFeature {
  #[frb(sync, getter)]
  pub fn output(&self) -> Option<ExposedServerDeviceFeatureOutput> {
    self.feature.output().clone().map(|x| x.into())
  }

  #[frb(sync, getter)]
  pub fn input(&self) -> Option<ExposedServerDeviceFeatureInput> {
    self.feature.input().clone().map(|x| x.into())
  }
}

impl From<&ServerDeviceFeature> for ExposedServerDeviceFeature {
  fn from(value: &ServerDeviceFeature) -> Self {
    Self {
      feature: value.clone()
    }
  }
}

#[frb(unignore, opaque, ignore_all)]
#[derive(Debug, Clone)]
pub struct ExposedServerDeviceFeatureOutput {
  #[ignore]
  output: ServerDeviceFeatureOutput
}

impl ExposedServerDeviceFeatureOutput {
  #[frb(sync, getter)]
  pub fn vibrate(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.vibrate().clone().map(|x| x.into())
  }

  #[frb(sync, getter)]
  pub fn rotate(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.rotate().clone().map(|x| x.into())
  }

  #[frb(sync, getter)]
  pub fn rotate_with_direction(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.rotate_with_direction().clone().map(|x| x.into())
  }

  #[frb(sync, getter)]
  pub fn oscillate(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.oscillate().clone().map(|x| x.into())
  }

  #[frb(sync, getter)]
  pub fn constrict(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.constrict().clone().map(|x| x.into())
  }

  #[frb(sync, getter)]
  pub fn heater(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.heater().clone().map(|x| x.into())
  }

  #[frb(sync, getter)]
  pub fn led(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.led().clone().map(|x| x.into())
  }

  #[frb(sync, getter)]
  pub fn position(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.position().clone().map(|x| x.into())
  }

  #[frb(sync, getter)]
  pub fn position_with_duration(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.position().clone().map(|x| x.into())
  }

  #[frb(sync, getter)]
  pub fn spray(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.spray().clone().map(|x| x.into())
  }
}

impl From<ServerDeviceFeatureOutput> for ExposedServerDeviceFeatureOutput {
  fn from(value: ServerDeviceFeatureOutput) -> Self {
    Self {
      output: value.clone()
    }
  }
}

#[frb(unignore, opaque, ignore_all)]
#[derive(Debug, Clone)]
pub struct ExposedServerDeviceFeatureInput {
  #[ignore]
  input: ServerDeviceFeatureInput
}

impl ExposedServerDeviceFeatureInput {
}

impl From<ServerDeviceFeatureInput> for ExposedServerDeviceFeatureInput {
  fn from(value: ServerDeviceFeatureInput) -> Self {
    Self {
      input: value.clone()
    }
  }
}

#[frb(unignore, opaque, ignore_all)]
#[derive(Debug, Clone)]
pub struct ExposedServerDeviceFeatureOutputProperties {
  value: Option<ExposedRangeWithLimit>,
  position: Option<ExposedRangeWithLimit>,
  duration: Option<ExposedRangeWithLimit>,
  disabled: bool,
  reverse_position: bool,
}

impl From<ServerDeviceFeatureOutputValueProperties> for ExposedServerDeviceFeatureOutputProperties {
  fn from(props: ServerDeviceFeatureOutputValueProperties) -> Self {
    Self {
      value: Some(props.value().into()),
      position: None,
      duration: None,
      disabled: props.disabled(),
      reverse_position: false
    }
  }
}

impl From<ServerDeviceFeatureOutputPositionWithDurationProperties> for ExposedServerDeviceFeatureOutputProperties {
  fn from(props: ServerDeviceFeatureOutputPositionWithDurationProperties) -> Self {
    Self {
      value: None,
      position: Some(props.position().into()),
      duration: Some(props.duration().into()),
      disabled: props.disabled(),
      reverse_position: props.reverse_position()
    }
  }
}

impl From<ServerDeviceFeatureOutputPositionProperties> for ExposedServerDeviceFeatureOutputProperties {
  fn from(props: ServerDeviceFeatureOutputPositionProperties) -> Self {
    Self {
      value: None,
      position: Some(props.position().into()),
      duration: None,
      disabled: props.disabled(),
      reverse_position: props.reverse_position()
    }
  }
}

#[frb(unignore, opaque, ignore_all)]
#[derive(Debug, Clone)]
pub struct ExposedRangeWithLimit {
  base: RangeInclusive<i32>,
  user: Option<RangeInclusive<u32>>
}

impl From<&RangeWithLimit> for ExposedRangeWithLimit {
  fn from(value: &RangeWithLimit) -> Self {
    Self {
      base: value.base().clone(),
      user: value.user().clone()
    }
  }
}

pub fn update_user_config(
  identifier: ExposedUserDeviceIdentifier,
  config: ExposedServerDeviceDefinition,
) {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  //dcm.add_user_device_definition(&identifier, &config);
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

pub fn get_device_definitions(
) -> HashMap<ExposedUserDeviceIdentifier, ExposedServerDeviceDefinition> {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  dcm
    .user_device_definitions()
    .iter()
    .map(|kv| (kv.key().clone().into(), kv.value().clone().into()))
    .collect()
}
