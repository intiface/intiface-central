import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intiface_central/device_configuration/user_device_configuration_file.dart';

void checkConfigFile(UserDeviceConfigurationFile configFile) {
  expect(configFile.version.major, 2);
  expect(configFile.version.minor, 6);
  expect(configFile.userConfigs.specifiers["lovense"]!.websocket.names.contains("LVSDevice"), isTrue);
  UserConfigDeviceIdentifier ident = const UserConfigDeviceIdentifier("8A3D9FAC2A45", "lovense", "Z");
  expect(configFile.userConfigs.deviceMap.length, 1);
  expect(configFile.userConfigs.deviceMap.keys.contains(ident), isTrue);
  expect(configFile.userConfigs.deviceMap[ident]!.displayName, "Test Device");
  expect(configFile.userConfigs.deviceMap[ident]!.index, 1);
}

void main() {
  test("test user config file loading", () {
    String jsonConfigFile = """
{
  "version": {
    "major": 2,
    "minor": 6
  },
  "user-configs": {
    "specifiers": {
      "lovense": {
        "websocket": {
          "names": ["LVSDevice"]
        }
      }
    },
    "devices": [
      [
        {
          "identifier": "Z",
          "address": "8A3D9FAC2A45",
          "protocol": "lovense"
        },
        {
          "displayName": "Test Device",
          "index": 1
        }
      ]
    ]
  }
}
""";
    var configFile = UserDeviceConfigurationFile.fromJson(jsonDecode(jsonConfigFile));
    checkConfigFile(configFile);
  });

  test("creation of user config JSON file", () {
    var configFile = UserDeviceConfigurationFile();
    configFile.version.major = 2;
    configFile.version.minor = 6;
    configFile.userConfigs.specifiers["lovense"] = UserProtocolDefinition();
    configFile.userConfigs.specifiers["lovense"]!.websocket.names.add("LVSDevice");
    UserConfigDeviceIdentifier ident = const UserConfigDeviceIdentifier("8A3D9FAC2A45", "lovense", "Z");
    UserConfig config = UserConfig();
    config.displayName = "Test Device";
    config.index = 1;
    configFile.userConfigs.devices.add(UserConfigDevice(ident, config));
    checkConfigFile(configFile);
    var jsonConfig = jsonEncode(configFile.toJson());
    var decodedConfig = UserDeviceConfigurationFile.fromJson(jsonDecode(jsonConfig));
    checkConfigFile(decodedConfig);
  });
}
