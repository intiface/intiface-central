#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
typedef struct _Dart_Handle* Dart_Handle;

typedef struct DartCObject DartCObject;

typedef int64_t DartPort;

typedef bool (*DartPostCObjectFnType)(DartPort port_id, void *message);

typedef struct wire_uint_8_list {
  uint8_t *ptr;
  int32_t len;
} wire_uint_8_list;

typedef struct wire_EngineOptionsExternal {
  struct wire_uint_8_list *device_config_json;
  struct wire_uint_8_list *user_device_config_json;
  struct wire_uint_8_list *user_device_config_path;
  struct wire_uint_8_list *server_name;
  bool websocket_use_all_interfaces;
  uint16_t *websocket_port;
  uint16_t *frontend_websocket_port;
  bool frontend_in_process_channel;
  uint32_t max_ping_time;
  bool allow_raw_messages;
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
  struct wire_uint_8_list *websocket_client_address;
  bool broadcast_server_mdns;
  struct wire_uint_8_list *mdns_suffix;
  bool repeater_mode;
  uint16_t *repeater_local_port;
  struct wire_uint_8_list *repeater_remote_address;
} wire_EngineOptionsExternal;

typedef struct wire_ExposedUserDeviceIdentifier {
  struct wire_uint_8_list *address;
  struct wire_uint_8_list *protocol;
  struct wire_uint_8_list *identifier;
} wire_ExposedUserDeviceIdentifier;

typedef struct wire___record__u32_u32 {
  uint32_t field0;
  uint32_t field1;
} wire___record__u32_u32;

typedef struct wire_list_buttplug_actuator_feature_message_type {
  int32_t *ptr;
  int32_t len;
} wire_list_buttplug_actuator_feature_message_type;

typedef struct wire_ExposedDeviceFeatureActuator {
  struct wire___record__u32_u32 step_range;
  struct wire___record__u32_u32 step_limit;
  struct wire_list_buttplug_actuator_feature_message_type *messages;
} wire_ExposedDeviceFeatureActuator;

typedef struct wire___record__i32_i32 {
  int32_t field0;
  int32_t field1;
} wire___record__i32_i32;

typedef struct wire_list___record__i32_i32 {
  struct wire___record__i32_i32 *ptr;
  int32_t len;
} wire_list___record__i32_i32;

typedef struct wire_list_buttplug_sensor_feature_message_type {
  int32_t *ptr;
  int32_t len;
} wire_list_buttplug_sensor_feature_message_type;

typedef struct wire_ExposedDeviceFeatureSensor {
  struct wire_list___record__i32_i32 *value_range;
  struct wire_list_buttplug_sensor_feature_message_type *messages;
} wire_ExposedDeviceFeatureSensor;

typedef struct wire_ExposedDeviceFeature {
  struct wire_uint_8_list *description;
  int32_t feature_type;
  struct wire_ExposedDeviceFeatureActuator *actuator;
  struct wire_ExposedDeviceFeatureSensor *sensor;
} wire_ExposedDeviceFeature;

typedef struct wire_list_exposed_device_feature {
  struct wire_ExposedDeviceFeature *ptr;
  int32_t len;
} wire_list_exposed_device_feature;

typedef struct wire_ExposedUserDeviceCustomization {
  struct wire_uint_8_list *display_name;
  bool allow;
  bool deny;
  uint32_t index;
} wire_ExposedUserDeviceCustomization;

typedef struct wire_ExposedUserDeviceDefinition {
  struct wire_uint_8_list *name;
  struct wire_list_exposed_device_feature *features;
  struct wire_ExposedUserDeviceCustomization user_config;
} wire_ExposedUserDeviceDefinition;

typedef struct DartCObject *WireSyncReturn;

void store_dart_post_cobject(DartPostCObjectFnType ptr);

Dart_Handle get_dart_object(uintptr_t ptr);

void drop_dart_object(uintptr_t ptr);

uintptr_t new_dart_opaque(Dart_Handle handle);

intptr_t init_frb_dart_api_dl(void *obj);

void wire_runtime_started(int64_t port_);

void wire_run_engine(int64_t port_, struct wire_EngineOptionsExternal *args);

void wire_send(int64_t port_, struct wire_uint_8_list *msg_json);

void wire_stop_engine(int64_t port_);

void wire_send_backend_server_message(int64_t port_, struct wire_uint_8_list *msg);

void wire_setup_device_configuration_manager(int64_t port_,
                                             struct wire_uint_8_list *base_config,
                                             struct wire_uint_8_list *user_config);

void wire_get_user_websocket_communication_specifiers(int64_t port_);

void wire_get_user_serial_communication_specifiers(int64_t port_);

void wire_get_user_device_definitions(int64_t port_);

void wire_get_protocol_names(int64_t port_);

void wire_add_websocket_specifier(int64_t port_,
                                  struct wire_uint_8_list *protocol,
                                  struct wire_uint_8_list *name);

void wire_remove_websocket_specifier(int64_t port_,
                                     struct wire_uint_8_list *protocol,
                                     struct wire_uint_8_list *name);

void wire_add_serial_specifier(int64_t port_,
                               struct wire_uint_8_list *protocol,
                               struct wire_uint_8_list *port,
                               uint32_t baud_rate,
                               uint8_t data_bits,
                               uint8_t stop_bits,
                               struct wire_uint_8_list *parity);

void wire_remove_serial_specifier(int64_t port_,
                                  struct wire_uint_8_list *protocol,
                                  struct wire_uint_8_list *port);

void wire_update_user_config(int64_t port_,
                             struct wire_ExposedUserDeviceIdentifier *identifier,
                             struct wire_ExposedUserDeviceDefinition *config);

void wire_remove_user_config(int64_t port_, struct wire_ExposedUserDeviceIdentifier *identifier);

void wire_get_user_config_str(int64_t port_);

void wire_setup_logging(int64_t port_);

void wire_shutdown_logging(int64_t port_);

void wire_crash_reporting(int64_t port_, struct wire_uint_8_list *sentry_api_key);

struct wire_EngineOptionsExternal *new_box_autoadd_engine_options_external_0(void);

struct wire_ExposedDeviceFeatureActuator *new_box_autoadd_exposed_device_feature_actuator_0(void);

struct wire_ExposedDeviceFeatureSensor *new_box_autoadd_exposed_device_feature_sensor_0(void);

struct wire_ExposedUserDeviceDefinition *new_box_autoadd_exposed_user_device_definition_0(void);

struct wire_ExposedUserDeviceIdentifier *new_box_autoadd_exposed_user_device_identifier_0(void);

uint16_t *new_box_autoadd_u16_0(uint16_t value);

struct wire_list___record__i32_i32 *new_list___record__i32_i32_0(int32_t len);

struct wire_list_buttplug_actuator_feature_message_type *new_list_buttplug_actuator_feature_message_type_0(int32_t len);

struct wire_list_buttplug_sensor_feature_message_type *new_list_buttplug_sensor_feature_message_type_0(int32_t len);

struct wire_list_exposed_device_feature *new_list_exposed_device_feature_0(int32_t len);

struct wire_uint_8_list *new_uint_8_list_0(int32_t len);

void free_WireSyncReturn(WireSyncReturn ptr);

static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) wire_runtime_started);
    dummy_var ^= ((int64_t) (void*) wire_run_engine);
    dummy_var ^= ((int64_t) (void*) wire_send);
    dummy_var ^= ((int64_t) (void*) wire_stop_engine);
    dummy_var ^= ((int64_t) (void*) wire_send_backend_server_message);
    dummy_var ^= ((int64_t) (void*) wire_setup_device_configuration_manager);
    dummy_var ^= ((int64_t) (void*) wire_get_user_websocket_communication_specifiers);
    dummy_var ^= ((int64_t) (void*) wire_get_user_serial_communication_specifiers);
    dummy_var ^= ((int64_t) (void*) wire_get_user_device_definitions);
    dummy_var ^= ((int64_t) (void*) wire_get_protocol_names);
    dummy_var ^= ((int64_t) (void*) wire_add_websocket_specifier);
    dummy_var ^= ((int64_t) (void*) wire_remove_websocket_specifier);
    dummy_var ^= ((int64_t) (void*) wire_add_serial_specifier);
    dummy_var ^= ((int64_t) (void*) wire_remove_serial_specifier);
    dummy_var ^= ((int64_t) (void*) wire_update_user_config);
    dummy_var ^= ((int64_t) (void*) wire_remove_user_config);
    dummy_var ^= ((int64_t) (void*) wire_get_user_config_str);
    dummy_var ^= ((int64_t) (void*) wire_setup_logging);
    dummy_var ^= ((int64_t) (void*) wire_shutdown_logging);
    dummy_var ^= ((int64_t) (void*) wire_crash_reporting);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_engine_options_external_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_exposed_device_feature_actuator_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_exposed_device_feature_sensor_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_exposed_user_device_definition_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_exposed_user_device_identifier_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_u16_0);
    dummy_var ^= ((int64_t) (void*) new_list___record__i32_i32_0);
    dummy_var ^= ((int64_t) (void*) new_list_buttplug_actuator_feature_message_type_0);
    dummy_var ^= ((int64_t) (void*) new_list_buttplug_sensor_feature_message_type_0);
    dummy_var ^= ((int64_t) (void*) new_list_exposed_device_feature_0);
    dummy_var ^= ((int64_t) (void*) new_uint_8_list_0);
    dummy_var ^= ((int64_t) (void*) free_WireSyncReturn);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    dummy_var ^= ((int64_t) (void*) get_dart_object);
    dummy_var ^= ((int64_t) (void*) drop_dart_object);
    dummy_var ^= ((int64_t) (void*) new_dart_opaque);
    return dummy_var;
}
