use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_runtime_started(port_: i64) {
  wire_runtime_started_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_run_engine(port_: i64, args: *mut wire_EngineOptionsExternal) {
  wire_run_engine_impl(port_, args)
}

#[no_mangle]
pub extern "C" fn wire_send(port_: i64, msg_json: *mut wire_uint_8_list) {
  wire_send_impl(port_, msg_json)
}

#[no_mangle]
pub extern "C" fn wire_stop_engine(port_: i64) {
  wire_stop_engine_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_send_backend_server_message(port_: i64, msg: *mut wire_uint_8_list) {
  wire_send_backend_server_message_impl(port_, msg)
}

#[no_mangle]
pub extern "C" fn wire_setup_device_configuration_manager(
  port_: i64,
  base_config: *mut wire_uint_8_list,
  user_config: *mut wire_uint_8_list,
) {
  wire_setup_device_configuration_manager_impl(port_, base_config, user_config)
}

#[no_mangle]
pub extern "C" fn wire_get_user_websocket_communication_specifiers(port_: i64) {
  wire_get_user_websocket_communication_specifiers_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_get_user_serial_communication_specifiers(port_: i64) {
  wire_get_user_serial_communication_specifiers_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_get_user_device_definitions(port_: i64) {
  wire_get_user_device_definitions_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_get_protocol_names(port_: i64) {
  wire_get_protocol_names_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_add_websocket_specifier(
  port_: i64,
  protocol: *mut wire_uint_8_list,
  name: *mut wire_uint_8_list,
) {
  wire_add_websocket_specifier_impl(port_, protocol, name)
}

#[no_mangle]
pub extern "C" fn wire_remove_websocket_specifier(
  port_: i64,
  protocol: *mut wire_uint_8_list,
  name: *mut wire_uint_8_list,
) {
  wire_remove_websocket_specifier_impl(port_, protocol, name)
}

#[no_mangle]
pub extern "C" fn wire_add_serial_specifier(
  port_: i64,
  protocol: *mut wire_uint_8_list,
  port: *mut wire_uint_8_list,
  baud_rate: u32,
  data_bits: u8,
  stop_bits: u8,
  parity: *mut wire_uint_8_list,
) {
  wire_add_serial_specifier_impl(
    port_, protocol, port, baud_rate, data_bits, stop_bits, parity,
  )
}

#[no_mangle]
pub extern "C" fn wire_remove_serial_specifier(
  port_: i64,
  protocol: *mut wire_uint_8_list,
  port: *mut wire_uint_8_list,
) {
  wire_remove_serial_specifier_impl(port_, protocol, port)
}

#[no_mangle]
pub extern "C" fn wire_update_user_config(
  port_: i64,
  identifier: *mut wire_ExposedUserDeviceIdentifier,
  config: *mut wire_ExposedUserDeviceDefinition,
) {
  wire_update_user_config_impl(port_, identifier, config)
}

#[no_mangle]
pub extern "C" fn wire_remove_user_config(
  port_: i64,
  identifier: *mut wire_ExposedUserDeviceIdentifier,
) {
  wire_remove_user_config_impl(port_, identifier)
}

#[no_mangle]
pub extern "C" fn wire_get_user_config_str(port_: i64) {
  wire_get_user_config_str_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_setup_logging(port_: i64) {
  wire_setup_logging_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_shutdown_logging(port_: i64) {
  wire_shutdown_logging_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_crash_reporting(port_: i64, sentry_api_key: *mut wire_uint_8_list) {
  wire_crash_reporting_impl(port_, sentry_api_key)
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_box_autoadd_engine_options_external_0() -> *mut wire_EngineOptionsExternal {
  support::new_leak_box_ptr(wire_EngineOptionsExternal::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_exposed_device_feature_actuator_0(
) -> *mut wire_ExposedDeviceFeatureActuator {
  support::new_leak_box_ptr(wire_ExposedDeviceFeatureActuator::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_exposed_device_feature_sensor_0(
) -> *mut wire_ExposedDeviceFeatureSensor {
  support::new_leak_box_ptr(wire_ExposedDeviceFeatureSensor::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_exposed_user_device_definition_0(
) -> *mut wire_ExposedUserDeviceDefinition {
  support::new_leak_box_ptr(wire_ExposedUserDeviceDefinition::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_exposed_user_device_identifier_0(
) -> *mut wire_ExposedUserDeviceIdentifier {
  support::new_leak_box_ptr(wire_ExposedUserDeviceIdentifier::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_u16_0(value: u16) -> *mut u16 {
  support::new_leak_box_ptr(value)
}

#[no_mangle]
pub extern "C" fn new_list___record__i32_i32_0(len: i32) -> *mut wire_list___record__i32_i32 {
  let wrap = wire_list___record__i32_i32 {
    ptr: support::new_leak_vec_ptr(<wire___record__i32_i32>::new_with_null_ptr(), len),
    len,
  };
  support::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn new_list_buttplug_actuator_feature_message_type_0(
  len: i32,
) -> *mut wire_list_buttplug_actuator_feature_message_type {
  let wrap = wire_list_buttplug_actuator_feature_message_type {
    ptr: support::new_leak_vec_ptr(Default::default(), len),
    len,
  };
  support::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn new_list_buttplug_sensor_feature_message_type_0(
  len: i32,
) -> *mut wire_list_buttplug_sensor_feature_message_type {
  let wrap = wire_list_buttplug_sensor_feature_message_type {
    ptr: support::new_leak_vec_ptr(Default::default(), len),
    len,
  };
  support::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn new_list_exposed_device_feature_0(
  len: i32,
) -> *mut wire_list_exposed_device_feature {
  let wrap = wire_list_exposed_device_feature {
    ptr: support::new_leak_vec_ptr(<wire_ExposedDeviceFeature>::new_with_null_ptr(), len),
    len,
  };
  support::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn new_uint_8_list_0(len: i32) -> *mut wire_uint_8_list {
  let ans = wire_uint_8_list {
    ptr: support::new_leak_vec_ptr(Default::default(), len),
    len,
  };
  support::new_leak_box_ptr(ans)
}

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for *mut wire_uint_8_list {
  fn wire2api(self) -> String {
    let vec: Vec<u8> = self.wire2api();
    String::from_utf8_lossy(&vec).into_owned()
  }
}
impl Wire2Api<(i32, i32)> for wire___record__i32_i32 {
  fn wire2api(self) -> (i32, i32) {
    (self.field0.wire2api(), self.field1.wire2api())
  }
}
impl Wire2Api<(u32, u32)> for wire___record__u32_u32 {
  fn wire2api(self) -> (u32, u32) {
    (self.field0.wire2api(), self.field1.wire2api())
  }
}

impl Wire2Api<EngineOptionsExternal> for *mut wire_EngineOptionsExternal {
  fn wire2api(self) -> EngineOptionsExternal {
    let wrap = unsafe { support::box_from_leak_ptr(self) };
    Wire2Api::<EngineOptionsExternal>::wire2api(*wrap).into()
  }
}
impl Wire2Api<ExposedDeviceFeatureActuator> for *mut wire_ExposedDeviceFeatureActuator {
  fn wire2api(self) -> ExposedDeviceFeatureActuator {
    let wrap = unsafe { support::box_from_leak_ptr(self) };
    Wire2Api::<ExposedDeviceFeatureActuator>::wire2api(*wrap).into()
  }
}
impl Wire2Api<ExposedDeviceFeatureSensor> for *mut wire_ExposedDeviceFeatureSensor {
  fn wire2api(self) -> ExposedDeviceFeatureSensor {
    let wrap = unsafe { support::box_from_leak_ptr(self) };
    Wire2Api::<ExposedDeviceFeatureSensor>::wire2api(*wrap).into()
  }
}
impl Wire2Api<ExposedUserDeviceDefinition> for *mut wire_ExposedUserDeviceDefinition {
  fn wire2api(self) -> ExposedUserDeviceDefinition {
    let wrap = unsafe { support::box_from_leak_ptr(self) };
    Wire2Api::<ExposedUserDeviceDefinition>::wire2api(*wrap).into()
  }
}
impl Wire2Api<ExposedUserDeviceIdentifier> for *mut wire_ExposedUserDeviceIdentifier {
  fn wire2api(self) -> ExposedUserDeviceIdentifier {
    let wrap = unsafe { support::box_from_leak_ptr(self) };
    Wire2Api::<ExposedUserDeviceIdentifier>::wire2api(*wrap).into()
  }
}
impl Wire2Api<u16> for *mut u16 {
  fn wire2api(self) -> u16 {
    unsafe { *support::box_from_leak_ptr(self) }
  }
}

impl Wire2Api<EngineOptionsExternal> for wire_EngineOptionsExternal {
  fn wire2api(self) -> EngineOptionsExternal {
    EngineOptionsExternal {
      device_config_json: self.device_config_json.wire2api(),
      user_device_config_json: self.user_device_config_json.wire2api(),
      user_device_config_path: self.user_device_config_path.wire2api(),
      server_name: self.server_name.wire2api(),
      websocket_use_all_interfaces: self.websocket_use_all_interfaces.wire2api(),
      websocket_port: self.websocket_port.wire2api(),
      frontend_websocket_port: self.frontend_websocket_port.wire2api(),
      frontend_in_process_channel: self.frontend_in_process_channel.wire2api(),
      max_ping_time: self.max_ping_time.wire2api(),
      allow_raw_messages: self.allow_raw_messages.wire2api(),
      use_bluetooth_le: self.use_bluetooth_le.wire2api(),
      use_serial_port: self.use_serial_port.wire2api(),
      use_hid: self.use_hid.wire2api(),
      use_lovense_dongle_serial: self.use_lovense_dongle_serial.wire2api(),
      use_lovense_dongle_hid: self.use_lovense_dongle_hid.wire2api(),
      use_xinput: self.use_xinput.wire2api(),
      use_lovense_connect: self.use_lovense_connect.wire2api(),
      use_device_websocket_server: self.use_device_websocket_server.wire2api(),
      device_websocket_server_port: self.device_websocket_server_port.wire2api(),
      crash_main_thread: self.crash_main_thread.wire2api(),
      crash_task_thread: self.crash_task_thread.wire2api(),
      websocket_client_address: self.websocket_client_address.wire2api(),
      broadcast_server_mdns: self.broadcast_server_mdns.wire2api(),
      mdns_suffix: self.mdns_suffix.wire2api(),
      repeater_mode: self.repeater_mode.wire2api(),
      repeater_local_port: self.repeater_local_port.wire2api(),
      repeater_remote_address: self.repeater_remote_address.wire2api(),
    }
  }
}
impl Wire2Api<ExposedDeviceFeature> for wire_ExposedDeviceFeature {
  fn wire2api(self) -> ExposedDeviceFeature {
    ExposedDeviceFeature {
      description: self.description.wire2api(),
      feature_type: self.feature_type.wire2api(),
      actuator: self.actuator.wire2api(),
      sensor: self.sensor.wire2api(),
    }
  }
}
impl Wire2Api<ExposedDeviceFeatureActuator> for wire_ExposedDeviceFeatureActuator {
  fn wire2api(self) -> ExposedDeviceFeatureActuator {
    ExposedDeviceFeatureActuator {
      step_range: self.step_range.wire2api(),
      step_limit: self.step_limit.wire2api(),
      messages: self.messages.wire2api(),
    }
  }
}
impl Wire2Api<ExposedDeviceFeatureSensor> for wire_ExposedDeviceFeatureSensor {
  fn wire2api(self) -> ExposedDeviceFeatureSensor {
    ExposedDeviceFeatureSensor {
      value_range: self.value_range.wire2api(),
      messages: self.messages.wire2api(),
    }
  }
}
impl Wire2Api<ExposedUserDeviceCustomization> for wire_ExposedUserDeviceCustomization {
  fn wire2api(self) -> ExposedUserDeviceCustomization {
    ExposedUserDeviceCustomization {
      display_name: self.display_name.wire2api(),
      allow: self.allow.wire2api(),
      deny: self.deny.wire2api(),
      index: self.index.wire2api(),
    }
  }
}
impl Wire2Api<ExposedUserDeviceDefinition> for wire_ExposedUserDeviceDefinition {
  fn wire2api(self) -> ExposedUserDeviceDefinition {
    ExposedUserDeviceDefinition {
      name: self.name.wire2api(),
      features: self.features.wire2api(),
      user_config: self.user_config.wire2api(),
    }
  }
}
impl Wire2Api<ExposedUserDeviceIdentifier> for wire_ExposedUserDeviceIdentifier {
  fn wire2api(self) -> ExposedUserDeviceIdentifier {
    ExposedUserDeviceIdentifier {
      address: self.address.wire2api(),
      protocol: self.protocol.wire2api(),
      identifier: self.identifier.wire2api(),
    }
  }
}

impl Wire2Api<Vec<(i32, i32)>> for *mut wire_list___record__i32_i32 {
  fn wire2api(self) -> Vec<(i32, i32)> {
    let vec = unsafe {
      let wrap = support::box_from_leak_ptr(self);
      support::vec_from_leak_ptr(wrap.ptr, wrap.len)
    };
    vec.into_iter().map(Wire2Api::wire2api).collect()
  }
}
impl Wire2Api<Vec<ButtplugActuatorFeatureMessageType>>
  for *mut wire_list_buttplug_actuator_feature_message_type
{
  fn wire2api(self) -> Vec<ButtplugActuatorFeatureMessageType> {
    let vec = unsafe {
      let wrap = support::box_from_leak_ptr(self);
      support::vec_from_leak_ptr(wrap.ptr, wrap.len)
    };
    vec.into_iter().map(Wire2Api::wire2api).collect()
  }
}
impl Wire2Api<Vec<ButtplugSensorFeatureMessageType>>
  for *mut wire_list_buttplug_sensor_feature_message_type
{
  fn wire2api(self) -> Vec<ButtplugSensorFeatureMessageType> {
    let vec = unsafe {
      let wrap = support::box_from_leak_ptr(self);
      support::vec_from_leak_ptr(wrap.ptr, wrap.len)
    };
    vec.into_iter().map(Wire2Api::wire2api).collect()
  }
}
impl Wire2Api<Vec<ExposedDeviceFeature>> for *mut wire_list_exposed_device_feature {
  fn wire2api(self) -> Vec<ExposedDeviceFeature> {
    let vec = unsafe {
      let wrap = support::box_from_leak_ptr(self);
      support::vec_from_leak_ptr(wrap.ptr, wrap.len)
    };
    vec.into_iter().map(Wire2Api::wire2api).collect()
  }
}

impl Wire2Api<Vec<u8>> for *mut wire_uint_8_list {
  fn wire2api(self) -> Vec<u8> {
    unsafe {
      let wrap = support::box_from_leak_ptr(self);
      support::vec_from_leak_ptr(wrap.ptr, wrap.len)
    }
  }
}
// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire___record__i32_i32 {
  field0: i32,
  field1: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire___record__u32_u32 {
  field0: u32,
  field1: u32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_EngineOptionsExternal {
  device_config_json: *mut wire_uint_8_list,
  user_device_config_json: *mut wire_uint_8_list,
  user_device_config_path: *mut wire_uint_8_list,
  server_name: *mut wire_uint_8_list,
  websocket_use_all_interfaces: bool,
  websocket_port: *mut u16,
  frontend_websocket_port: *mut u16,
  frontend_in_process_channel: bool,
  max_ping_time: u32,
  allow_raw_messages: bool,
  use_bluetooth_le: bool,
  use_serial_port: bool,
  use_hid: bool,
  use_lovense_dongle_serial: bool,
  use_lovense_dongle_hid: bool,
  use_xinput: bool,
  use_lovense_connect: bool,
  use_device_websocket_server: bool,
  device_websocket_server_port: *mut u16,
  crash_main_thread: bool,
  crash_task_thread: bool,
  websocket_client_address: *mut wire_uint_8_list,
  broadcast_server_mdns: bool,
  mdns_suffix: *mut wire_uint_8_list,
  repeater_mode: bool,
  repeater_local_port: *mut u16,
  repeater_remote_address: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_ExposedDeviceFeature {
  description: *mut wire_uint_8_list,
  feature_type: i32,
  actuator: *mut wire_ExposedDeviceFeatureActuator,
  sensor: *mut wire_ExposedDeviceFeatureSensor,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_ExposedDeviceFeatureActuator {
  step_range: wire___record__u32_u32,
  step_limit: wire___record__u32_u32,
  messages: *mut wire_list_buttplug_actuator_feature_message_type,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_ExposedDeviceFeatureSensor {
  value_range: *mut wire_list___record__i32_i32,
  messages: *mut wire_list_buttplug_sensor_feature_message_type,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_ExposedUserDeviceCustomization {
  display_name: *mut wire_uint_8_list,
  allow: bool,
  deny: bool,
  index: u32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_ExposedUserDeviceDefinition {
  name: *mut wire_uint_8_list,
  features: *mut wire_list_exposed_device_feature,
  user_config: wire_ExposedUserDeviceCustomization,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_ExposedUserDeviceIdentifier {
  address: *mut wire_uint_8_list,
  protocol: *mut wire_uint_8_list,
  identifier: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_list___record__i32_i32 {
  ptr: *mut wire___record__i32_i32,
  len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_list_buttplug_actuator_feature_message_type {
  ptr: *mut i32,
  len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_list_buttplug_sensor_feature_message_type {
  ptr: *mut i32,
  len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_list_exposed_device_feature {
  ptr: *mut wire_ExposedDeviceFeature,
  len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_uint_8_list {
  ptr: *mut u8,
  len: i32,
}

// Section: impl NewWithNullPtr

pub trait NewWithNullPtr {
  fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
  fn new_with_null_ptr() -> Self {
    std::ptr::null_mut()
  }
}

impl NewWithNullPtr for wire___record__i32_i32 {
  fn new_with_null_ptr() -> Self {
    Self {
      field0: Default::default(),
      field1: Default::default(),
    }
  }
}

impl Default for wire___record__i32_i32 {
  fn default() -> Self {
    Self::new_with_null_ptr()
  }
}

impl NewWithNullPtr for wire___record__u32_u32 {
  fn new_with_null_ptr() -> Self {
    Self {
      field0: Default::default(),
      field1: Default::default(),
    }
  }
}

impl Default for wire___record__u32_u32 {
  fn default() -> Self {
    Self::new_with_null_ptr()
  }
}

impl NewWithNullPtr for wire_EngineOptionsExternal {
  fn new_with_null_ptr() -> Self {
    Self {
      device_config_json: core::ptr::null_mut(),
      user_device_config_json: core::ptr::null_mut(),
      user_device_config_path: core::ptr::null_mut(),
      server_name: core::ptr::null_mut(),
      websocket_use_all_interfaces: Default::default(),
      websocket_port: core::ptr::null_mut(),
      frontend_websocket_port: core::ptr::null_mut(),
      frontend_in_process_channel: Default::default(),
      max_ping_time: Default::default(),
      allow_raw_messages: Default::default(),
      use_bluetooth_le: Default::default(),
      use_serial_port: Default::default(),
      use_hid: Default::default(),
      use_lovense_dongle_serial: Default::default(),
      use_lovense_dongle_hid: Default::default(),
      use_xinput: Default::default(),
      use_lovense_connect: Default::default(),
      use_device_websocket_server: Default::default(),
      device_websocket_server_port: core::ptr::null_mut(),
      crash_main_thread: Default::default(),
      crash_task_thread: Default::default(),
      websocket_client_address: core::ptr::null_mut(),
      broadcast_server_mdns: Default::default(),
      mdns_suffix: core::ptr::null_mut(),
      repeater_mode: Default::default(),
      repeater_local_port: core::ptr::null_mut(),
      repeater_remote_address: core::ptr::null_mut(),
    }
  }
}

impl Default for wire_EngineOptionsExternal {
  fn default() -> Self {
    Self::new_with_null_ptr()
  }
}

impl NewWithNullPtr for wire_ExposedDeviceFeature {
  fn new_with_null_ptr() -> Self {
    Self {
      description: core::ptr::null_mut(),
      feature_type: Default::default(),
      actuator: core::ptr::null_mut(),
      sensor: core::ptr::null_mut(),
    }
  }
}

impl Default for wire_ExposedDeviceFeature {
  fn default() -> Self {
    Self::new_with_null_ptr()
  }
}

impl NewWithNullPtr for wire_ExposedDeviceFeatureActuator {
  fn new_with_null_ptr() -> Self {
    Self {
      step_range: Default::default(),
      step_limit: Default::default(),
      messages: core::ptr::null_mut(),
    }
  }
}

impl Default for wire_ExposedDeviceFeatureActuator {
  fn default() -> Self {
    Self::new_with_null_ptr()
  }
}

impl NewWithNullPtr for wire_ExposedDeviceFeatureSensor {
  fn new_with_null_ptr() -> Self {
    Self {
      value_range: core::ptr::null_mut(),
      messages: core::ptr::null_mut(),
    }
  }
}

impl Default for wire_ExposedDeviceFeatureSensor {
  fn default() -> Self {
    Self::new_with_null_ptr()
  }
}

impl NewWithNullPtr for wire_ExposedUserDeviceCustomization {
  fn new_with_null_ptr() -> Self {
    Self {
      display_name: core::ptr::null_mut(),
      allow: Default::default(),
      deny: Default::default(),
      index: Default::default(),
    }
  }
}

impl Default for wire_ExposedUserDeviceCustomization {
  fn default() -> Self {
    Self::new_with_null_ptr()
  }
}

impl NewWithNullPtr for wire_ExposedUserDeviceDefinition {
  fn new_with_null_ptr() -> Self {
    Self {
      name: core::ptr::null_mut(),
      features: core::ptr::null_mut(),
      user_config: Default::default(),
    }
  }
}

impl Default for wire_ExposedUserDeviceDefinition {
  fn default() -> Self {
    Self::new_with_null_ptr()
  }
}

impl NewWithNullPtr for wire_ExposedUserDeviceIdentifier {
  fn new_with_null_ptr() -> Self {
    Self {
      address: core::ptr::null_mut(),
      protocol: core::ptr::null_mut(),
      identifier: core::ptr::null_mut(),
    }
  }
}

impl Default for wire_ExposedUserDeviceIdentifier {
  fn default() -> Self {
    Self::new_with_null_ptr()
  }
}

// Section: sync execution mode utility

#[no_mangle]
pub extern "C" fn free_WireSyncReturn(ptr: support::WireSyncReturn) {
  unsafe {
    let _ = support::box_from_leak_ptr(ptr);
  };
}
