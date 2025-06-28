
pub use buttplug::core::message::{InputCommandType, InputType, OutputType, FeatureType};
use flutter_rust_bridge::frb;

#[frb(mirror(InputCommandType), unignore)]
pub enum _InputCommandType {
  Read,
  Subscribe,
  Unsubscribe,
}

#[frb(mirror(InputType), unignore)]
pub enum _InputType {
  Unknown,
  Battery,
  RSSI,
  Button,
  Pressure,
  // Temperature,
  // Accelerometer,
  // Gyro,
}

#[frb(mirror(OutputType), unignore)]
pub enum _OutputType {
  Unknown,
  Vibrate,
  // Single Direction Rotation Speed
  Rotate,
  // Two Direction Rotation Speed
  RotateWithDirection,
  Oscillate,
  Constrict,
  Inflate,
  Heater,
  Led,
  // For instances where we specify a position to move to ASAP. Usually servos, probably for the
  // OSR-2/SR-6.
  Position,
  PositionWithDuration,
}

#[frb(mirror(FeatureType), unignore)]
pub enum _FeatureType {
  Unknown,
  Vibrate,
  // Single Direction Rotation Speed
  Rotate,
  Oscillate,
  Constrict,
  Inflate,
  // For instances where we specify a position to move to ASAP. Usually servos, probably for the
  // OSR-2/SR-6.
  Position,
  // Sensor Types
  Battery,
  RSSI,
  Button,
  Pressure,
  // Currently unused but possible sensor features:
  // Temperature,
  // Accelerometer,
  // Gyro,
  //
  RotateWithDirection,
  PositionWithDuration,
  Heater,
  Led,
}