import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:intiface_central/bridge_generated.dart';
//import 'package:intiface_central/device_configuration/user_device_configuration_file.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:intiface_central/ffi.dart';
import 'package:loggy/loggy.dart';

class UserDeviceConfigurationState {}

class UserDeviceConfigurationStateInitial extends UserDeviceConfigurationState {}

class UserDeviceConfigurationCubit extends Cubit<UserDeviceConfigurationState> {
  List<ExposedUserDeviceConfig> _configs = List.empty();

  UserDeviceConfigurationCubit._() : super(UserDeviceConfigurationStateInitial());

  static Future<UserDeviceConfigurationCubit> create() async {
    var cubit = UserDeviceConfigurationCubit._();
    if (!IntifacePaths.userDeviceConfigFile.existsSync()) {
      await cubit._saveConfigFile();
    }
    if (IntifacePaths.deviceConfigFile.existsSync() && IntifacePaths.userDeviceConfigFile.existsSync()) {
      var jsonDeviceConfig = IntifacePaths.deviceConfigFile.readAsStringSync();
      var jsonConfig = IntifacePaths.userDeviceConfigFile.readAsStringSync();
      cubit._configs = await api.getUserDeviceConfigs(deviceConfigJson: jsonDeviceConfig, userConfigJson: jsonConfig);
    }
    return cubit;
  }

  Future<void> updateDeviceIndex(UserConfigDeviceIdentifier deviceIdentifier, int index) async {
    // See if device already exists in config
    var new_config = ExposedUserDeviceConfig(
        identifier: deviceIdentifier,
        name: "Does not matter",
        displayName: null,
        reservedIndex: index,
        allow: null,
        deny: null);
    for (var config in _configs) {
      if (config.identifier == deviceIdentifier) {
        new_config = ExposedUserDeviceConfig(
            identifier: deviceIdentifier,
            name: config.name,
            displayName: config.displayName,
            reservedIndex: index,
            allow: config.allow,
            deny: config.deny);
      }
    }
    _configs.clear();
    _configs.add(new_config);
    await _saveConfigFile();
  }

  Future<void> _saveConfigFile() async {
    var jsonString = await api.generateUserDeviceConfigFile(userConfig: _configs);
    await IntifacePaths.userDeviceConfigFile.writeAsString(jsonString);
  }
}
