use std::{collections::HashMap, ops::RangeInclusive};

use buttplug_core::message::OutputType;
use buttplug_server_device_config::{RangeWithLimit, ServerDeviceDefinition, ServerDeviceDefinitionBuilder, ServerDeviceFeature, ServerDeviceFeatureInput, ServerDeviceFeatureOutput, ServerDeviceFeatureOutputPositionProperties, ServerDeviceFeatureOutputPositionWithDurationProperties, ServerDeviceFeatureOutputValueProperties, UserDeviceIdentifier, save_user_config};
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
  
  #[frb(sync, setter)]
  pub fn set_display_name(&mut self, display_name: Option<String>) {
    let mut builder = ServerDeviceDefinitionBuilder::from_user(&self.definition);
    builder.display_name(&display_name);
    self.definition = builder.finish();
  }

  #[frb(sync, getter)]
  pub fn allow(&self) -> bool {
    self.definition.allow()
  }

   #[frb(sync, setter)]
  pub fn set_allow(&mut self, allow: bool) {
    let mut builder = ServerDeviceDefinitionBuilder::from_user(&self.definition);
    builder.allow(allow);
    self.definition = builder.finish();
  }

  #[frb(sync, getter)]
  pub fn deny(&self) -> bool {
    self.definition.deny()
  }

  #[frb(sync, setter)]
  pub fn set_deny(&mut self, deny: bool) {
    let mut builder = ServerDeviceDefinitionBuilder::from_user(&self.definition);
    builder.deny(deny);
    self.definition = builder.finish();
  }

  #[frb(sync, getter)]
  pub fn index(&self) -> u32 {
    self.definition.index()
  }

  #[frb(sync, getter)]
  pub fn features(&self) -> Vec<ExposedServerDeviceFeature> {
    self.definition.features().iter().map(|x| x.into()).collect()
  }

  #[frb(sync)]
  pub fn update_feature(&mut self, feature: &ExposedServerDeviceFeature) {
    if let Some(f) = self.definition.features().iter().find(|x| x.id() == feature.id()) {
      ServerDeviceDefinitionBuilder::from_user(&self.definition).replace_feature(&feature.feature);
    }
  }

  #[frb(sync)]
  pub fn update_feature_output_properties(&mut self, props: &ExposedServerDeviceFeatureOutputProperties) {
    if let Some(f) = self.definition.features().iter().find(|x| x.id() == props.feature_id) {
      let mut f = f.clone();
      info!("Has feature");
      // Why let chaining won't work here, I don't know. Something is conflicting with the edition setting in Cargo.
      if let Some(output) = f.output() {
        info!("Has output");
        let mut output = output.clone();
        if output.contains(props.output_type) {
          info!("Has output type");
          match props.output_type {
            OutputType::Constrict => output.set_constrict(Some(props.clone().into())),
            OutputType::Heater => output.set_heater(Some(props.clone().into())),
            OutputType::Led => output.set_led(Some(props.clone().into())),
            OutputType::Oscillate => output.set_oscillate(Some(props.clone().into())),
            OutputType::Position => output.set_position(Some(props.clone().into())),
            OutputType::PositionWithDuration => output.set_position_with_duration(Some(props.clone().into())),
            OutputType::Rotate => output.set_rotate(Some(props.clone().into())),
            OutputType::Spray => output.set_spray(Some(props.clone().into())),
            OutputType::Vibrate => output.set_vibrate(Some(props.clone().into())),
            _ => return
          };
          f.set_output(Some(output));
          self.definition = ServerDeviceDefinitionBuilder::from_user(&self.definition).replace_feature(&f).finish();
        }        
      }
    }
  }
}

#[frb(unignore, opaque, ignore_all)]
#[derive(Debug, Clone)]
pub struct ExposedServerDeviceFeature {
  feature: ServerDeviceFeature
}

impl ExposedServerDeviceFeature {
  #[frb(sync, getter)]
  pub fn id(&self) -> Uuid {
    self.feature.id()
  }

  #[frb(sync, getter)]
  pub fn description(&self) -> String {
    self.feature.description().clone()
  }

  #[frb(sync, getter)]
  pub fn output(&self) -> Option<ExposedServerDeviceFeatureOutput> {
    self.feature.output().clone().map(|x| ExposedServerDeviceFeatureOutput::new(self.feature.id(), x))
  }

  #[frb(sync, setter)]
  pub fn set_output(&mut self, output: Option<ExposedServerDeviceFeatureOutput>) {
    self.feature.set_output(output.map(|x| x.output));
  }

  #[frb(sync, getter)]
  pub fn input(&self) -> Option<ExposedServerDeviceFeatureInput> {
    self.feature.input().clone().map(|x| x.into())
  }
}

impl From<&ServerDeviceFeature> for ExposedServerDeviceFeature {
  fn from(value: &ServerDeviceFeature) -> Self {
    info!("{}", value.id());
    Self {
      feature: value.clone()
    }
  }
}

#[frb(unignore, opaque, ignore_all)]
#[derive(Debug, Clone)]
pub struct ExposedServerDeviceFeatureOutput {
  #[ignore]
  feature_id: Uuid,
  #[ignore]
  output: ServerDeviceFeatureOutput
}

impl ExposedServerDeviceFeatureOutput {
  fn new(feature_id: Uuid, value: ServerDeviceFeatureOutput) -> Self {
    Self {
      feature_id,
      output: value.clone()
    }
  }

  #[frb(sync, getter)]
  pub fn vibrate(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.vibrate().clone().map(|x| ExposedServerDeviceFeatureOutputProperties::new_from_value(self.feature_id, OutputType::Vibrate, x))
  }

  #[frb(sync, getter)]
  pub fn rotate(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.rotate().clone().map(|x| ExposedServerDeviceFeatureOutputProperties::new_from_value(self.feature_id, OutputType::Rotate, x))
  }

  #[frb(sync, getter)]
  pub fn oscillate(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.oscillate().clone().map(|x| ExposedServerDeviceFeatureOutputProperties::new_from_value(self.feature_id, OutputType::Oscillate, x))
  }

  #[frb(sync, getter)]
  pub fn constrict(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.constrict().clone().map(|x| ExposedServerDeviceFeatureOutputProperties::new_from_value(self.feature_id, OutputType::Constrict, x))
  }

  #[frb(sync, getter)]
  pub fn heater(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.heater().clone().map(|x| ExposedServerDeviceFeatureOutputProperties::new_from_value(self.feature_id, OutputType::Heater, x))
  }

  #[frb(sync, getter)]
  pub fn led(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.led().clone().map(|x| ExposedServerDeviceFeatureOutputProperties::new_from_value(self.feature_id, OutputType::Led, x))
  }

  #[frb(sync, getter)]
  pub fn spray(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.spray().clone().map(|x| ExposedServerDeviceFeatureOutputProperties::new_from_value(self.feature_id, OutputType::Spray, x))
  }

  #[frb(sync, getter)]
  pub fn position(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.position().clone().map(|x| ExposedServerDeviceFeatureOutputProperties::new_from_position(self.feature_id, OutputType::Position, x))
  }

  #[frb(sync, getter)]
  pub fn position_with_duration(&self) -> Option<ExposedServerDeviceFeatureOutputProperties> {
    self.output.position_with_duration().clone().map(|x| ExposedServerDeviceFeatureOutputProperties::new_from_position_with_duration(self.feature_id, OutputType::PositionWithDuration, x))
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
  feature_id: Uuid,
  output_type: OutputType,
  value: Option<ExposedRangeWithLimit>,
  position: Option<ExposedRangeWithLimit>,
  duration: Option<ExposedRangeWithLimit>,
  disabled: bool,
  reverse_position: bool,
}

impl ExposedServerDeviceFeatureOutputProperties {
  fn new_from_value(feature_id: Uuid, output_type: OutputType, props: ServerDeviceFeatureOutputValueProperties) -> Self {
    Self {
      feature_id,
      output_type,
      value: Some(props.value().into()),
      position: None,
      duration: None,
      disabled: props.disabled(),
      reverse_position: false
    }
  }

  fn new_from_position_with_duration(feature_id: Uuid, output_type: OutputType, props: ServerDeviceFeatureOutputPositionWithDurationProperties) -> Self {
    Self {
      feature_id,
      output_type,
      value: None,
      position: Some(props.position().into()),
      duration: Some(props.duration().into()),
      disabled: props.disabled(),
      reverse_position: props.reverse_position()
    }
  }

  fn new_from_position(feature_id: Uuid, output_type: OutputType, props: ServerDeviceFeatureOutputPositionProperties) -> Self {
    Self {
      feature_id,
      output_type,
      value: None,
      position: Some(props.position().into()),
      duration: None,
      disabled: props.disabled(),
      reverse_position: props.reverse_position()
    }
  }

  #[frb(sync, getter)]
  pub fn value(&self) -> Option<ExposedRangeWithLimit> {
    self.value.clone()
  }

  #[frb(sync, setter)]
  pub fn set_value(&mut self, value: Option<ExposedRangeWithLimit>) {
    self.value = value;
  }

  #[frb(sync, getter)]
  pub fn position(&self) -> Option<ExposedRangeWithLimit> {
    self.position.clone()
  }

  #[frb(sync, setter)]
  pub fn set_position(&mut self, position: Option<ExposedRangeWithLimit>) {
    self.position = position;
  }

  #[frb(sync, getter)]
  pub fn duration(&self) -> Option<ExposedRangeWithLimit> {
    self.duration.clone()
  }

  #[frb(sync, setter)]
  pub fn set_duration(&mut self, duration: Option<ExposedRangeWithLimit>) {
    self.duration = duration;
  }  

  #[frb(sync, getter)]
  pub fn disabled(&self) -> bool {
    self.disabled
  }    

  #[frb(sync, getter)]
  pub fn reverse_position(&self) -> bool {
    self.reverse_position
  }

  #[frb(sync, setter)]
  pub fn set_disabled(&mut self, v: bool) {
    self.disabled = v;
  }    

  #[frb(sync, setter)]
  pub fn set_reverse_position(&mut self, v: bool) {
    self.reverse_position = v;
  }   
}

// TODO This should be TryFrom, just in case we try to convert the wrong type.
impl From<ExposedServerDeviceFeatureOutputProperties> for ServerDeviceFeatureOutputValueProperties {
  fn from(value: ExposedServerDeviceFeatureOutputProperties) -> Self {
    ServerDeviceFeatureOutputValueProperties::new(&value.value.unwrap().into(), value.disabled)
  }
}

// TODO This should be TryFrom, just in case we try to convert the wrong type.
impl From<ExposedServerDeviceFeatureOutputProperties> for ServerDeviceFeatureOutputPositionProperties {
  fn from(value: ExposedServerDeviceFeatureOutputProperties) -> Self {
    ServerDeviceFeatureOutputPositionProperties::new(&value.position.unwrap().into(), value.disabled, value.reverse_position)
  } 
}

// TODO This should be TryFrom, just in case we try to convert the wrong type.
impl From<ExposedServerDeviceFeatureOutputProperties> for ServerDeviceFeatureOutputPositionWithDurationProperties {
  fn from(value: ExposedServerDeviceFeatureOutputProperties) -> Self {
    ServerDeviceFeatureOutputPositionWithDurationProperties::new(&value.position.unwrap().into(), &value.duration.unwrap().into(), value.disabled, value.reverse_position)
  }
}

#[frb(unignore, opaque, ignore_all)]
#[derive(Debug, Clone)]
pub struct ExposedRangeWithLimit {
  base: RangeInclusive<i32>,
  user: Option<RangeInclusive<u32>>
}

impl ExposedRangeWithLimit {
  #[frb(sync, getter)]
  pub fn base(&self) -> (i32, i32) {
    (*self.base.start(), *self.base.end())
  }

  #[frb(sync, getter)]
  pub fn user(&self) -> (u32, u32) {
    if let Some(user) = &self.user {
      (*user.start(), *user.end())
    } else {
      (0, *self.base.end() as u32)
    }
  }

  #[frb(sync, setter)]
  pub fn set_user(&mut self, range: (u32, u32)) {
    self.user = Some(RangeInclusive::new(range.0, range.1));
  }
}

impl From<&RangeWithLimit> for ExposedRangeWithLimit {
  fn from(value: &RangeWithLimit) -> Self {
    Self {
      base: value.base().clone(),
      user: value.user().clone()
    }
  }
}

impl From<ExposedRangeWithLimit> for RangeWithLimit {
  fn from(value: ExposedRangeWithLimit) -> Self {
    RangeWithLimit::new_with_user(&value.base, &value.user)
  }
}

pub fn update_user_config(
  identifier: ExposedUserDeviceIdentifier,
  config: ExposedServerDeviceDefinition,
) {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  info!("adding device definition");
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

pub fn get_device_definitions(
) -> HashMap<ExposedUserDeviceIdentifier, ExposedServerDeviceDefinition> {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  dcm
    .user_device_definitions()
    .iter()
    .map(|kv| {
      info!("{:?}", kv.value());
      (kv.key().clone().into(), kv.value().clone().into())
    })
    .collect()
}
