#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
// EXTRA BEGIN
typedef struct DartCObject *WireSyncRust2DartDco;
typedef struct WireSyncRust2DartSse {
  uint8_t *ptr;
  int32_t len;
} WireSyncRust2DartSse;

typedef int64_t DartPort;
typedef bool (*DartPostCObjectFnType)(DartPort port_id, void *message);
void store_dart_post_cobject(DartPostCObjectFnType ptr);
// EXTRA END
typedef struct _Dart_Handle* Dart_Handle;

typedef struct wire_cst_record_u_32_u_32 {
  uint32_t field0;
  uint32_t field1;
} wire_cst_record_u_32_u_32;

typedef struct wire_cst_list_prim_u_8_strict {
  uint8_t *ptr;
  int32_t len;
} wire_cst_list_prim_u_8_strict;

typedef struct wire_cst_engine_options_external {
  struct wire_cst_list_prim_u_8_strict *device_config_json;
  struct wire_cst_list_prim_u_8_strict *user_device_config_json;
  struct wire_cst_list_prim_u_8_strict *user_device_config_path;
  struct wire_cst_list_prim_u_8_strict *server_name;
  bool websocket_use_all_interfaces;
  uint16_t *websocket_port;
  uint16_t *frontend_websocket_port;
  bool frontend_in_process_channel;
  uint32_t max_ping_time;
  bool use_bluetooth_le;
  bool use_serial_port;
  bool use_hid;
  bool use_lovense_dongle_serial;
  bool use_lovense_dongle_hid;
  bool use_xinput;
  bool use_lovense_connect;
  bool use_device_websocket_server;
  uint16_t *device_websocket_server_port;
  bool crash_main_thread;
  bool crash_task_thread;
  struct wire_cst_list_prim_u_8_strict *websocket_client_address;
  bool broadcast_server_mdns;
  struct wire_cst_list_prim_u_8_strict *mdns_suffix;
  bool repeater_mode;
  uint16_t *repeater_local_port;
  struct wire_cst_list_prim_u_8_strict *repeater_remote_address;
  uint16_t *rest_api_port;
} wire_cst_engine_options_external;

typedef struct wire_cst_list_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeature {
  uintptr_t *ptr;
  int32_t len;
} wire_cst_list_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeature;

typedef struct wire_cst_list_String {
  struct wire_cst_list_prim_u_8_strict **ptr;
  int32_t len;
} wire_cst_list_String;

typedef struct wire_cst_record_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_user_device_identifier_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_server_device_definition {
  uintptr_t field0;
  uintptr_t field1;
} wire_cst_record_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_user_device_identifier_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_server_device_definition;

typedef struct wire_cst_list_record_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_user_device_identifier_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_server_device_definition {
  struct wire_cst_record_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_user_device_identifier_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_server_device_definition *ptr;
  int32_t len;
} wire_cst_list_record_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_user_device_identifier_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_server_device_definition;

typedef struct wire_cst_exposed_serial_specifier {
  uint32_t baud_rate;
  uint8_t data_bits;
  uint8_t stop_bits;
  struct wire_cst_list_prim_u_8_strict *parity;
  struct wire_cst_list_prim_u_8_strict *port;
} wire_cst_exposed_serial_specifier;

typedef struct wire_cst_record_string_exposed_serial_specifier {
  struct wire_cst_list_prim_u_8_strict *field0;
  struct wire_cst_exposed_serial_specifier field1;
} wire_cst_record_string_exposed_serial_specifier;

typedef struct wire_cst_list_record_string_exposed_serial_specifier {
  struct wire_cst_record_string_exposed_serial_specifier *ptr;
  int32_t len;
} wire_cst_list_record_string_exposed_serial_specifier;

typedef struct wire_cst_exposed_websocket_specifier {
  struct wire_cst_list_prim_u_8_strict *name;
} wire_cst_exposed_websocket_specifier;

typedef struct wire_cst_record_string_exposed_websocket_specifier {
  struct wire_cst_list_prim_u_8_strict *field0;
  struct wire_cst_exposed_websocket_specifier field1;
} wire_cst_record_string_exposed_websocket_specifier;

typedef struct wire_cst_list_record_string_exposed_websocket_specifier {
  struct wire_cst_record_string_exposed_websocket_specifier *ptr;
  int32_t len;
} wire_cst_list_record_string_exposed_websocket_specifier;

typedef struct wire_cst_record_i_32_i_32 {
  int32_t field0;
  int32_t field1;
} wire_cst_record_i_32_i_32;

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedRangeWithLimit_base(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedRangeWithLimit_set_user(uintptr_t that,
                                                                                                             struct wire_cst_record_u_32_u_32 *range);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedRangeWithLimit_user(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_allow(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_deny(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_display_name(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_features(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_id(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_index(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_message_gap_ms(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_name(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_set_allow(uintptr_t that,
                                                                                                                      bool allow);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_set_deny(uintptr_t that,
                                                                                                                     bool deny);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_set_display_name(uintptr_t that,
                                                                                                                             struct wire_cst_list_prim_u_8_strict *display_name);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_set_message_gap_ms(uintptr_t that,
                                                                                                                               uint32_t *message_gap_ms);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_update_feature(uintptr_t that,
                                                                                                                           uintptr_t feature);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_update_feature_output_properties(uintptr_t that,
                                                                                                                                             uintptr_t props);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_disabled(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_duration(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_position(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_reverse_position(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_set_disabled(uintptr_t that,
                                                                                                                                      bool v);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_set_duration(uintptr_t that,
                                                                                                                                      uintptr_t *duration);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_set_position(uintptr_t that,
                                                                                                                                      uintptr_t *position);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_set_reverse_position(uintptr_t that,
                                                                                                                                              bool v);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_set_value(uintptr_t that,
                                                                                                                                   uintptr_t *value);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_value(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_constrict(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_led(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_oscillate(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_position(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_position_with_duration(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_rotate(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_spray(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_temperature(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_vibrate(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeature_description(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeature_id(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeature_input(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeature_output(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeature_set_output(uintptr_t that,
                                                                                                                    uintptr_t *output);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedUserDeviceIdentifier_address(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedUserDeviceIdentifier_identifier(uintptr_t that);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedUserDeviceIdentifier_new(struct wire_cst_list_prim_u_8_strict *address,
                                                                                                              struct wire_cst_list_prim_u_8_strict *protocol,
                                                                                                              struct wire_cst_list_prim_u_8_strict *identifier);

WireSyncRust2DartDco frbgen_intiface_central_wire__crate__api__device_config__ExposedUserDeviceIdentifier_protocol(uintptr_t that);

void frbgen_intiface_central_wire__crate__api__specifiers__add_serial_specifier(int64_t port_,
                                                                                struct wire_cst_list_prim_u_8_strict *protocol,
                                                                                struct wire_cst_list_prim_u_8_strict *port,
                                                                                uint32_t baud_rate,
                                                                                uint8_t data_bits,
                                                                                uint8_t stop_bits,
                                                                                struct wire_cst_list_prim_u_8_strict *parity);

void frbgen_intiface_central_wire__crate__api__specifiers__add_websocket_specifier(int64_t port_,
                                                                                   struct wire_cst_list_prim_u_8_strict *protocol,
                                                                                   struct wire_cst_list_prim_u_8_strict *name);

void frbgen_intiface_central_wire__crate__api__util__crash_reporting(int64_t port_,
                                                                     struct wire_cst_list_prim_u_8_strict *sentry_api_key);

void frbgen_intiface_central_wire__crate__api__device_config__get_device_definitions(int64_t port_);

void frbgen_intiface_central_wire__crate__api__specifiers__get_protocol_names(int64_t port_);

void frbgen_intiface_central_wire__crate__api__device_config__get_user_config_str(int64_t port_);

void frbgen_intiface_central_wire__crate__api__specifiers__get_user_serial_communication_specifiers(int64_t port_);

void frbgen_intiface_central_wire__crate__api__specifiers__get_user_websocket_communication_specifiers(int64_t port_);

void frbgen_intiface_central_wire__crate__api__runtime__is_engine_shutdown(int64_t port_);

void frbgen_intiface_central_wire__crate__api__specifiers__remove_serial_specifier(int64_t port_,
                                                                                   struct wire_cst_list_prim_u_8_strict *protocol,
                                                                                   struct wire_cst_list_prim_u_8_strict *port);

void frbgen_intiface_central_wire__crate__api__device_config__remove_user_config(int64_t port_,
                                                                                 uintptr_t identifier);

void frbgen_intiface_central_wire__crate__api__specifiers__remove_websocket_specifier(int64_t port_,
                                                                                      struct wire_cst_list_prim_u_8_strict *protocol,
                                                                                      struct wire_cst_list_prim_u_8_strict *name);

void frbgen_intiface_central_wire__crate__api__runtime__run_engine(int64_t port_,
                                                                   struct wire_cst_list_prim_u_8_strict *sink,
                                                                   struct wire_cst_engine_options_external *args);

void frbgen_intiface_central_wire__crate__api__runtime__rust_runtime_started(int64_t port_);

void frbgen_intiface_central_wire__crate__api__runtime__send_backend_server_message(int64_t port_,
                                                                                    struct wire_cst_list_prim_u_8_strict *msg);

void frbgen_intiface_central_wire__crate__api__runtime__send_runtime_msg(int64_t port_,
                                                                         struct wire_cst_list_prim_u_8_strict *msg_json);

void frbgen_intiface_central_wire__crate__api__device_config_manager__setup_device_configuration_manager(int64_t port_,
                                                                                                         struct wire_cst_list_prim_u_8_strict *base_config,
                                                                                                         struct wire_cst_list_prim_u_8_strict *user_config);

void frbgen_intiface_central_wire__crate__api__util__setup_logging(int64_t port_,
                                                                   struct wire_cst_list_prim_u_8_strict *sink);

void frbgen_intiface_central_wire__crate__api__util__shutdown_logging(int64_t port_);

void frbgen_intiface_central_wire__crate__api__runtime__stop_engine(int64_t port_);

void frbgen_intiface_central_wire__crate__api__device_config__update_user_config(int64_t port_,
                                                                                 uintptr_t identifier,
                                                                                 uintptr_t config);

void frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedRangeWithLimit(const void *ptr);

void frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedRangeWithLimit(const void *ptr);

void frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceDefinition(const void *ptr);

void frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceDefinition(const void *ptr);

void frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeature(const void *ptr);

void frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeature(const void *ptr);

void frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureInput(const void *ptr);

void frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureInput(const void *ptr);

void frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureOutput(const void *ptr);

void frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureOutput(const void *ptr);

void frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureOutputProperties(const void *ptr);

void frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureOutputProperties(const void *ptr);

void frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedUserDeviceIdentifier(const void *ptr);

void frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedUserDeviceIdentifier(const void *ptr);

uintptr_t *frbgen_intiface_central_cst_new_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedRangeWithLimit(uintptr_t value);

uintptr_t *frbgen_intiface_central_cst_new_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureInput(uintptr_t value);

uintptr_t *frbgen_intiface_central_cst_new_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureOutput(uintptr_t value);

uintptr_t *frbgen_intiface_central_cst_new_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureOutputProperties(uintptr_t value);

struct wire_cst_engine_options_external *frbgen_intiface_central_cst_new_box_autoadd_engine_options_external(void);

struct wire_cst_record_u_32_u_32 *frbgen_intiface_central_cst_new_box_autoadd_record_u_32_u_32(void);

uint16_t *frbgen_intiface_central_cst_new_box_autoadd_u_16(uint16_t value);

uint32_t *frbgen_intiface_central_cst_new_box_autoadd_u_32(uint32_t value);

struct wire_cst_list_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeature *frbgen_intiface_central_cst_new_list_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeature(int32_t len);

struct wire_cst_list_String *frbgen_intiface_central_cst_new_list_String(int32_t len);

struct wire_cst_list_prim_u_8_strict *frbgen_intiface_central_cst_new_list_prim_u_8_strict(int32_t len);

struct wire_cst_list_record_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_user_device_identifier_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_server_device_definition *frbgen_intiface_central_cst_new_list_record_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_user_device_identifier_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_server_device_definition(int32_t len);

struct wire_cst_list_record_string_exposed_serial_specifier *frbgen_intiface_central_cst_new_list_record_string_exposed_serial_specifier(int32_t len);

struct wire_cst_list_record_string_exposed_websocket_specifier *frbgen_intiface_central_cst_new_list_record_string_exposed_websocket_specifier(int32_t len);

jint JNI_OnLoad(JavaVM vm, const void *_res);
static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedRangeWithLimit);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureInput);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureOutput);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_box_autoadd_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureOutputProperties);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_box_autoadd_engine_options_external);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_box_autoadd_record_u_32_u_32);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_box_autoadd_u_16);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_box_autoadd_u_32);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_list_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeature);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_list_String);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_list_prim_u_8_strict);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_list_record_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_user_device_identifier_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_exposed_server_device_definition);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_list_record_string_exposed_serial_specifier);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_cst_new_list_record_string_exposed_websocket_specifier);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedRangeWithLimit);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceDefinition);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeature);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureInput);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureOutput);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureOutputProperties);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedUserDeviceIdentifier);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedRangeWithLimit);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceDefinition);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeature);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureInput);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureOutput);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedServerDeviceFeatureOutputProperties);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerExposedUserDeviceIdentifier);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedRangeWithLimit_base);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedRangeWithLimit_set_user);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedRangeWithLimit_user);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_allow);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_deny);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_display_name);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_features);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_id);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_index);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_message_gap_ms);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_name);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_set_allow);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_set_deny);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_set_display_name);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_set_message_gap_ms);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_update_feature);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceDefinition_update_feature_output_properties);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_disabled);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_duration);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_position);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_reverse_position);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_set_disabled);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_set_duration);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_set_position);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_set_reverse_position);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_set_value);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutputProperties_value);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_constrict);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_led);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_oscillate);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_position);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_position_with_duration);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_rotate);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_spray);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_temperature);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeatureOutput_vibrate);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeature_description);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeature_id);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeature_input);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeature_output);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedServerDeviceFeature_set_output);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedUserDeviceIdentifier_address);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedUserDeviceIdentifier_identifier);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedUserDeviceIdentifier_new);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__ExposedUserDeviceIdentifier_protocol);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__get_device_definitions);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__get_user_config_str);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__remove_user_config);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config__update_user_config);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__device_config_manager__setup_device_configuration_manager);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__runtime__is_engine_shutdown);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__runtime__run_engine);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__runtime__rust_runtime_started);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__runtime__send_backend_server_message);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__runtime__send_runtime_msg);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__runtime__stop_engine);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__specifiers__add_serial_specifier);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__specifiers__add_websocket_specifier);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__specifiers__get_protocol_names);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__specifiers__get_user_serial_communication_specifiers);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__specifiers__get_user_websocket_communication_specifiers);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__specifiers__remove_serial_specifier);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__specifiers__remove_websocket_specifier);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__util__crash_reporting);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__util__setup_logging);
    dummy_var ^= ((int64_t) (void*) frbgen_intiface_central_wire__crate__api__util__shutdown_logging);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    return dummy_var;
}
