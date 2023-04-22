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

class UserDeviceConfigurationStateUpdated extends UserDeviceConfigurationState {}

class UserDeviceConfigurationCubit extends Cubit<UserDeviceConfigurationState> {
  List<ExposedUserDeviceConfig> _configs = List.empty();

  UserDeviceConfigurationCubit._() : super(UserDeviceConfigurationStateInitial());

  List<ExposedUserDeviceConfig> get configs => _configs;

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
    ExposedUserDeviceConfig? newConfig;
    for (var config in _configs) {
      if (config.identifier == deviceIdentifier) {
        newConfig = ExposedUserDeviceConfig(
            identifier: deviceIdentifier,
            name: config.name,
            displayName: config.displayName,
            reservedIndex: index,
            allow: config.allow,
            deny: config.deny);
      }
    }
    if (newConfig != null) {
      await _updateConfig(deviceIdentifier, newConfig);
    }
  }

  Future<void> updateDisplayName(UserConfigDeviceIdentifier deviceIdentifier, String displayName) async {
    // See if device already exists in config
    ExposedUserDeviceConfig? newConfig;
    for (var config in _configs) {
      if (config.identifier == deviceIdentifier) {
        newConfig = ExposedUserDeviceConfig(
            identifier: deviceIdentifier,
            name: config.name,
            displayName: displayName,
            reservedIndex: config.reservedIndex,
            allow: config.allow,
            deny: config.deny);
      }
    }
    if (newConfig != null) {
      await _updateConfig(deviceIdentifier, newConfig);
    }
  }

  Future<void> _updateConfig(UserConfigDeviceIdentifier deviceIdentifier, ExposedUserDeviceConfig newConfig) async {
    _configs.removeWhere((element) =>
        element.identifier.address == deviceIdentifier.address &&
        element.identifier.protocol == deviceIdentifier.protocol &&
        element.identifier.identifier == deviceIdentifier.identifier);
    _configs.add(newConfig);
    await _saveConfigFile();
  }

  Future<void> _saveConfigFile() async {
    var jsonString = await api.generateUserDeviceConfigFile(userConfig: _configs);
    await IntifacePaths.userDeviceConfigFile.writeAsString(jsonString);
    emit(UserDeviceConfigurationStateUpdated());
  }
}
