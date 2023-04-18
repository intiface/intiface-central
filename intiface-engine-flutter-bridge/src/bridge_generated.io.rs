use super::*;
// Section: wire functions

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
pub extern "C" fn wire_get_user_device_configs(
  port_: i64,
  device_config_json: *mut wire_uint_8_list,
  user_config_json: *mut wire_uint_8_list,
) {
  wire_get_user_device_configs_impl(port_, device_config_json, user_config_json)
}

#[no_mangle]
pub extern "C" fn wire_generate_user_device_config_file(
  port_: i64,
  user_config: *mut wire_list_exposed_user_device_config,
) {
  wire_generate_user_device_config_file_impl(port_, user_config)
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_box_autoadd_bool_0(value: bool) -> *mut bool {
  support::new_leak_box_ptr(value)
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_engine_options_external_0() -> *mut wire_EngineOptionsExternal {
  support::new_leak_box_ptr(wire_EngineOptionsExternal::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_u16_0(value: u16) -> *mut u16 {
  support::new_leak_box_ptr(value)
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_u32_0(value: u32) -> *mut u32 {
  support::new_leak_box_ptr(value)
}

#[no_mangle]
pub extern "C" fn new_list_exposed_user_device_config_0(
  len: i32,
) -> *mut wire_list_exposed_user_device_config {
  let wrap = wire_list_exposed_user_device_config {
    ptr: support::new_leak_vec_ptr(<wire_ExposedUserDeviceConfig>::new_with_null_ptr(), len),
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

impl Wire2Api<bool> for *mut bool {
  fn wire2api(self) -> bool {
    unsafe { *support::box_from_leak_ptr(self) }
  }
}
impl Wire2Api<EngineOptionsExternal> for *mut wire_EngineOptionsExternal {
  fn wire2api(self) -> EngineOptionsExternal {
    let wrap = unsafe { support::box_from_leak_ptr(self) };
    Wire2Api::<EngineOptionsExternal>::wire2api(*wrap).into()
  }
}
impl Wire2Api<u16> for *mut u16 {
  fn wire2api(self) -> u16 {
    unsafe { *support::box_from_leak_ptr(self) }
  }
}
impl Wire2Api<u32> for *mut u32 {
  fn wire2api(self) -> u32 {
    unsafe { *support::box_from_leak_ptr(self) }
  }
}
impl Wire2Api<EngineOptionsExternal> for wire_EngineOptionsExternal {
  fn wire2api(self) -> EngineOptionsExternal {
    EngineOptionsExternal {
      sentry_api_key: self.sentry_api_key.wire2api(),
      device_config_json: self.device_config_json.wire2api(),
      user_device_config_json: self.user_device_config_json.wire2api(),
      server_name: self.server_name.wire2api(),
      crash_reporting: self.crash_reporting.wire2api(),
      websocket_use_all_interfaces: self.websocket_use_all_interfaces.wire2api(),
      websocket_port: self.websocket_port.wire2api(),
      frontend_websocket_port: self.frontend_websocket_port.wire2api(),
      frontend_in_process_channel: self.frontend_in_process_channel.wire2api(),
      max_ping_time: self.max_ping_time.wire2api(),
      log_level: self.log_level.wire2api(),
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
    }
  }
}
impl Wire2Api<ExposedUserDeviceConfig> for wire_ExposedUserDeviceConfig {
  fn wire2api(self) -> ExposedUserDeviceConfig {
    ExposedUserDeviceConfig {
      identifier: self.identifier.wire2api(),
      name: self.name.wire2api(),
      display_name: self.display_name.wire2api(),
      allow: self.allow.wire2api(),
      deny: self.deny.wire2api(),
      reserved_index: self.reserved_index.wire2api(),
    }
  }
}
impl Wire2Api<Vec<ExposedUserDeviceConfig>> for *mut wire_list_exposed_user_device_config {
  fn wire2api(self) -> Vec<ExposedUserDeviceConfig> {
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
impl Wire2Api<UserConfigDeviceIdentifier> for wire_UserConfigDeviceIdentifier {
  fn wire2api(self) -> UserConfigDeviceIdentifier {
    UserConfigDeviceIdentifier {
      address: self.address.wire2api(),
      protocol: self.protocol.wire2api(),
      identifier: self.identifier.wire2api(),
    }
  }
}
// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire_EngineOptionsExternal {
  sentry_api_key: *mut wire_uint_8_list,
  device_config_json: *mut wire_uint_8_list,
  user_device_config_json: *mut wire_uint_8_list,
  server_name: *mut wire_uint_8_list,
  crash_reporting: bool,
  websocket_use_all_interfaces: bool,
  websocket_port: *mut u16,
  frontend_websocket_port: *mut u16,
  frontend_in_process_channel: bool,
  max_ping_time: u32,
  log_level: *mut wire_uint_8_list,
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
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_ExposedUserDeviceConfig {
  identifier: wire_UserConfigDeviceIdentifier,
  name: *mut wire_uint_8_list,
  display_name: *mut wire_uint_8_list,
  allow: *mut bool,
  deny: *mut bool,
  reserved_index: *mut u32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_list_exposed_user_device_config {
  ptr: *mut wire_ExposedUserDeviceConfig,
  len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_uint_8_list {
  ptr: *mut u8,
  len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_UserConfigDeviceIdentifier {
  address: *mut wire_uint_8_list,
  protocol: *mut wire_uint_8_list,
  identifier: *mut wire_uint_8_list,
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

impl NewWithNullPtr for wire_EngineOptionsExternal {
  fn new_with_null_ptr() -> Self {
    Self {
      sentry_api_key: core::ptr::null_mut(),
      device_config_json: core::ptr::null_mut(),
      user_device_config_json: core::ptr::null_mut(),
      server_name: core::ptr::null_mut(),
      crash_reporting: Default::default(),
      websocket_use_all_interfaces: Default::default(),
      websocket_port: core::ptr::null_mut(),
      frontend_websocket_port: core::ptr::null_mut(),
      frontend_in_process_channel: Default::default(),
      max_ping_time: Default::default(),
      log_level: core::ptr::null_mut(),
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
    }
  }
}

impl Default for wire_EngineOptionsExternal {
  fn default() -> Self {
    Self::new_with_null_ptr()
  }
}

impl NewWithNullPtr for wire_ExposedUserDeviceConfig {
  fn new_with_null_ptr() -> Self {
    Self {
      identifier: Default::default(),
      name: core::ptr::null_mut(),
      display_name: core::ptr::null_mut(),
      allow: core::ptr::null_mut(),
      deny: core::ptr::null_mut(),
      reserved_index: core::ptr::null_mut(),
    }
  }
}

impl Default for wire_ExposedUserDeviceConfig {
  fn default() -> Self {
    Self::new_with_null_ptr()
  }
}

impl NewWithNullPtr for wire_UserConfigDeviceIdentifier {
  fn new_with_null_ptr() -> Self {
    Self {
      address: core::ptr::null_mut(),
      protocol: core::ptr::null_mut(),
      identifier: core::ptr::null_mut(),
    }
  }
}

impl Default for wire_UserConfigDeviceIdentifier {
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
