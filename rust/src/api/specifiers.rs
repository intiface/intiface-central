use crate::api::device_config_manager::DEVICE_CONFIG_MANAGER;

use buttplug_server::device::protocol_impl::get_default_protocol_map;
use buttplug_server_device_config::{
  ProtocolCommunicationSpecifier,
  SerialSpecifier,
  WebsocketSpecifier,
};

#[derive(Debug, Clone)]
pub struct ExposedSerialSpecifier {
  pub baud_rate: u32,
  pub data_bits: u8,
  pub stop_bits: u8,
  pub parity: String,
  pub port: String,
}

impl From<SerialSpecifier> for ExposedSerialSpecifier {
  fn from(value: SerialSpecifier) -> Self {
    Self {
      port: value.port().clone(),
      parity: (*value.parity()).into(),
      baud_rate: *value.baud_rate(),
      data_bits: *value.data_bits(),
      stop_bits: *value.stop_bits(),
    }
  }
}

impl From<ExposedSerialSpecifier> for SerialSpecifier {
  fn from(value: ExposedSerialSpecifier) -> Self {
    SerialSpecifier::new(
      &value.port,
      value.baud_rate,
      value.data_bits,
      value.stop_bits,
      value.parity.chars().next().unwrap_or('N'),
    )
  }
}

#[derive(Debug, Clone)]
pub struct ExposedWebsocketSpecifier {
  pub name: String,
}

impl From<WebsocketSpecifier> for ExposedWebsocketSpecifier {
  fn from(value: WebsocketSpecifier) -> Self {
    Self {
      name: value.name().clone(),
    }
  }
}

impl From<ExposedWebsocketSpecifier> for WebsocketSpecifier {
  fn from(value: ExposedWebsocketSpecifier) -> Self {
    WebsocketSpecifier::new(&value.name)
  }
}

pub fn get_user_websocket_communication_specifiers() -> Vec<(String, ExposedWebsocketSpecifier)> {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  let mut ws_specs = vec![];
  for kv in dcm.user_communication_specifiers() {
    for comm_spec in kv.value() {
      if let ProtocolCommunicationSpecifier::Websocket(ws) = comm_spec {
        ws_specs.push((
          kv.key().to_owned(),
          ExposedWebsocketSpecifier::from(ws.clone()),
        ))
      }
    }
  }
  ws_specs
}

pub fn get_user_serial_communication_specifiers() -> Vec<(String, ExposedSerialSpecifier)> {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  let mut port_specs = vec![];
  for kv in dcm.user_communication_specifiers() {
    for comm_spec in kv.value() {
      if let ProtocolCommunicationSpecifier::Serial(port) = comm_spec {
        port_specs.push((
          kv.key().to_owned(),
          ExposedSerialSpecifier::from(port.clone()),
        ))
      }
    }
  }
  port_specs
}

pub fn add_websocket_specifier(protocol: String, name: String) {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  let _ = dcm.add_user_communication_specifier(
    &protocol,
    &ProtocolCommunicationSpecifier::Websocket(WebsocketSpecifier::new(&name)),
  );
}

pub fn remove_websocket_specifier(protocol: String, name: String) {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  dcm.remove_user_communication_specifier(
    &protocol,
    &ProtocolCommunicationSpecifier::Websocket(WebsocketSpecifier::new(&name)),
  );
}

pub fn add_serial_specifier(
  protocol: String,
  port: String,
  baud_rate: u32,
  data_bits: u8,
  stop_bits: u8,
  parity: String,
) {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  let _ = dcm.add_user_communication_specifier(
    &protocol,
    &ProtocolCommunicationSpecifier::Serial(SerialSpecifier::new(
      &port,
      baud_rate,
      data_bits,
      stop_bits,
      parity.chars().next().unwrap_or('N'),
    )),
  );
}

pub fn remove_serial_specifier(protocol: String, port: String) {
  let dcm = DEVICE_CONFIG_MANAGER
    .try_read()
    .expect("We should have a reader at this point");
  dcm.remove_user_communication_specifier(
    &protocol,
    &ProtocolCommunicationSpecifier::Serial(SerialSpecifier::new_from_name(&port)),
  );
}

pub fn get_protocol_names() -> Vec<String> {
  get_default_protocol_map().keys().cloned().collect()
}
