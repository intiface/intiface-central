
pub use buttplug_core::message::{InputCommandType, InputType, OutputType};
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
  Rssi,
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
  Oscillate,
  Constrict,
  Spray,
  Heater,
  Led,
  // For instances where we specify a position to move to ASAP. Usually servos, probably for the
  // OSR-2/SR-6.
  Position,
  PositionWithDuration,
}
