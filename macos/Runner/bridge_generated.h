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
  struct wire_uint_8_list *sentry_api_key;
  struct wire_uint_8_list *device_config_json;
  struct wire_uint_8_list *user_device_config_json;
  struct wire_uint_8_list *server_name;
  bool crash_reporting;
  bool websocket_use_all_interfaces;
  uint16_t *websocket_port;
  uint16_t *frontend_websocket_port;
  bool frontend_in_process_channel;
  uint32_t max_ping_time;
  struct wire_uint_8_list *log_level;
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
} wire_EngineOptionsExternal;

typedef struct wire_StringList {
  struct wire_uint_8_list **ptr;
  int32_t len;
} wire_StringList;

typedef struct wire_ExposedWebsocketSpecifier {
  struct wire_StringList *names;
} wire_ExposedWebsocketSpecifier;

typedef struct wire_ExposedUserDeviceSpecifiers {
  struct wire_ExposedWebsocketSpecifier *websocket;
} wire_ExposedUserDeviceSpecifiers;

typedef struct wire___record__String_exposed_user_device_specifiers {
  struct wire_uint_8_list *field0;
  struct wire_ExposedUserDeviceSpecifiers field1;
} wire___record__String_exposed_user_device_specifiers;

typedef struct wire_list___record__String_exposed_user_device_specifiers {
  struct wire___record__String_exposed_user_device_specifiers *ptr;
  int32_t len;
} wire_list___record__String_exposed_user_device_specifiers;

typedef struct wire_UserConfigDeviceIdentifier {
  struct wire_uint_8_list *address;
  struct wire_uint_8_list *protocol;
  struct wire_uint_8_list *identifier;
} wire_UserConfigDeviceIdentifier;

typedef struct wire_ExposedUserDeviceConfig {
  struct wire_UserConfigDeviceIdentifier identifier;
  struct wire_uint_8_list *name;
  struct wire_uint_8_list *display_name;
  bool *allow;
  bool *deny;
  uint32_t *reserved_index;
} wire_ExposedUserDeviceConfig;

typedef struct wire_list_exposed_user_device_config {
  struct wire_ExposedUserDeviceConfig *ptr;
  int32_t len;
} wire_list_exposed_user_device_config;

typedef struct wire_ExposedUserConfig {
  struct wire_list___record__String_exposed_user_device_specifiers *specifiers;
  struct wire_list_exposed_user_device_config *configurations;
} wire_ExposedUserConfig;

typedef struct DartCObject *WireSyncReturn;

void store_dart_post_cobject(DartPostCObjectFnType ptr);

Dart_Handle get_dart_object(uintptr_t ptr);

void drop_dart_object(uintptr_t ptr);

uintptr_t new_dart_opaque(Dart_Handle handle);

intptr_t init_frb_dart_api_dl(void *obj);

void wire_run_engine(int64_t port_, struct wire_EngineOptionsExternal *args);

void wire_send(int64_t port_, struct wire_uint_8_list *msg_json);

void wire_stop_engine(int64_t port_);

void wire_send_backend_server_message(int64_t port_, struct wire_uint_8_list *msg);

void wire_get_user_device_configs(int64_t port_,
                                  struct wire_uint_8_list *device_config_json,
                                  struct wire_uint_8_list *user_config_json);

void wire_generate_user_device_config_file(int64_t port_,
                                           struct wire_ExposedUserConfig *user_config);

void wire_get_protocol_names(int64_t port_);

struct wire_StringList *new_StringList_0(int32_t len);

bool *new_box_autoadd_bool_0(bool value);

struct wire_EngineOptionsExternal *new_box_autoadd_engine_options_external_0(void);

struct wire_ExposedUserConfig *new_box_autoadd_exposed_user_config_0(void);

struct wire_ExposedWebsocketSpecifier *new_box_autoadd_exposed_websocket_specifier_0(void);

uint16_t *new_box_autoadd_u16_0(uint16_t value);

uint32_t *new_box_autoadd_u32_0(uint32_t value);

struct wire_list___record__String_exposed_user_device_specifiers *new_list___record__String_exposed_user_device_specifiers_0(int32_t len);

struct wire_list_exposed_user_device_config *new_list_exposed_user_device_config_0(int32_t len);

struct wire_uint_8_list *new_uint_8_list_0(int32_t len);

void free_WireSyncReturn(WireSyncReturn ptr);

jint JNI_OnLoad(JavaVM vm, const void *_res);

static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) wire_run_engine);
    dummy_var ^= ((int64_t) (void*) wire_send);
    dummy_var ^= ((int64_t) (void*) wire_stop_engine);
    dummy_var ^= ((int64_t) (void*) wire_send_backend_server_message);
    dummy_var ^= ((int64_t) (void*) wire_get_user_device_configs);
    dummy_var ^= ((int64_t) (void*) wire_generate_user_device_config_file);
    dummy_var ^= ((int64_t) (void*) wire_get_protocol_names);
    dummy_var ^= ((int64_t) (void*) new_StringList_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_bool_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_engine_options_external_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_exposed_user_config_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_exposed_websocket_specifier_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_u16_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_u32_0);
    dummy_var ^= ((int64_t) (void*) new_list___record__String_exposed_user_device_specifiers_0);
    dummy_var ^= ((int64_t) (void*) new_list_exposed_user_device_config_0);
    dummy_var ^= ((int64_t) (void*) new_uint_8_list_0);
    dummy_var ^= ((int64_t) (void*) free_WireSyncReturn);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    dummy_var ^= ((int64_t) (void*) get_dart_object);
    dummy_var ^= ((int64_t) (void*) drop_dart_object);
    dummy_var ^= ((int64_t) (void*) new_dart_opaque);
    return dummy_var;
}
