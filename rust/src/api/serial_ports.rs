use intiface_engine::{available_serial_ports, AvailableSerialPort};

#[derive(Debug, Clone)]
pub struct ExposedSerialPortInfo {
  pub port_name: String,
  pub product: Option<String>,
  pub manufacturer: Option<String>,
  pub vid: Option<u16>,
  pub pid: Option<u16>,
}

impl From<AvailableSerialPort> for ExposedSerialPortInfo {
  fn from(value: AvailableSerialPort) -> Self {
    Self {
      port_name: value.port_name,
      product: value.product,
      manufacturer: value.manufacturer,
      vid: value.vid,
      pid: value.pid,
    }
  }
}

pub fn list_serial_ports() -> Vec<ExposedSerialPortInfo> {
  available_serial_ports()
    .into_iter()
    .map(ExposedSerialPortInfo::from)
    .collect()
}
