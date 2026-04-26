
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
  Battery,
  Rssi,
  Button,
  Pressure,
  Depth,
  Position,
}

#[frb(mirror(OutputType), unignore)]
pub enum _OutputType {
  Vibrate,
  Rotate,
  Oscillate,
  Constrict,
  Temperature,
  Led,
  Position,
  HwPositionWithDuration,
  Spray,
}
