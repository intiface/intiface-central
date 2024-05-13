import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:intiface_central/ffi.dart';
import 'package:loggy/loggy.dart';

class UserDeviceConfigurationState {}

class UserDeviceConfigurationStateInitial extends UserDeviceConfigurationState {}

class UserDeviceConfigurationStateUpdated extends UserDeviceConfigurationState {}

class UserDeviceConfigurationCubit extends Cubit<UserDeviceConfigurationState> {
  UserDeviceConfigurationCubit._() : super(UserDeviceConfigurationStateInitial());
  Map<ExposedUserDeviceIdentifier, ExposedUserDeviceDefinition> _configs = {};
  List<String> _protocols = List.empty(growable: true);
  List<(String, ExposedWebsocketSpecifier)> _specifiers = [];
  List<(String, ExposedSerialSpecifier)> _serialSpecifiers = [];
  Map<ExposedUserDeviceIdentifier, ExposedUserDeviceDefinition> get configs => _configs;
  List<(String, ExposedWebsocketSpecifier)> get specifiers => _specifiers;
  List<(String, ExposedSerialSpecifier)> get serialSpecifiers => _serialSpecifiers;
  List<String> get protocols => _protocols;

  static Future<UserDeviceConfigurationCubit> create() async {
    var cubit = UserDeviceConfigurationCubit._();
    await cubit.loadConfig();
    return cubit;
  }

  Future<void> loadConfig() async {
    try {
      if (!IntifacePaths.userDeviceConfigFile.existsSync()) {
        return;
      }
      String? deviceConfig;
      String? userConfig;
      if (IntifacePaths.deviceConfigFile.existsSync()) {
        deviceConfig = IntifacePaths.deviceConfigFile.readAsStringSync();
      }
      if (IntifacePaths.userDeviceConfigFile.existsSync()) {
        userConfig = IntifacePaths.userDeviceConfigFile.readAsStringSync();
      }
      // TODO This should throw if loading doesn't work.
      await api!.setupDeviceConfigurationManager(baseConfig: deviceConfig, userConfig: userConfig);
    } catch (e) {
      logError("Error loading cubit! Deleting configs and creating new ones.");
      logError(e);
      try {
        if (await IntifacePaths.deviceConfigFile.exists()) {
          await IntifacePaths.deviceConfigFile.delete();
        }
      } catch (e) {
        logError("Error deleting device configs");
        logError(e);
      }
      try {
        if (await IntifacePaths.userDeviceConfigFile.exists()) {
          await IntifacePaths.userDeviceConfigFile.delete();
        }
      } catch (e) {
        logError("Error deleting user device configs");
        logError(e);
      }
      await api!.setupDeviceConfigurationManager(baseConfig: null, userConfig: null);
    }
    await update();
  }

  Future<void> update() async {
    _protocols = await api!.getProtocolNames();
    _specifiers = await api!.getUserWebsocketCommunicationSpecifiers();
    _serialSpecifiers = await api!.getUserSerialCommunicationSpecifiers();
    _configs = <ExposedUserDeviceIdentifier, ExposedUserDeviceDefinition>{
      for (var (k, v) in await api!.getUserDeviceDefinitions()) k: v
    };
    emit(UserDeviceConfigurationStateUpdated());
  }

  Future<void> addWebsocketDeviceName(String protocol, String name) async {
    await api!.addWebsocketSpecifier(protocol: protocol, name: name);
    await _saveConfigFile();
  }

  Future<void> removeWebsocketDeviceName(String protocol, String name) async {
    await api!.removeWebsocketSpecifier(protocol: protocol, name: name);
    await _saveConfigFile();
  }

  Future<void> addSerialPort(
      String protocol, String port, int baudRate, int dataBits, int stopBits, String parity) async {
    await api!.addSerialSpecifier(
        protocol: protocol, port: port, baudRate: baudRate, dataBits: dataBits, stopBits: stopBits, parity: parity);
    await _saveConfigFile();
  }

  Future<void> removeSerialPort(String protocol, String port) async {
    await api!.removeSerialSpecifier(protocol: protocol, port: port);
    await _saveConfigFile();
  }

  Future<void> updateDeviceAllow(
      ExposedUserDeviceIdentifier deviceIdentifier, ExposedUserDeviceDefinition def, bool allow) async {
    var newUserConfig = ExposedUserDeviceCustomization(
        allow: allow, deny: def.userConfig.deny, index: def.userConfig.index, displayName: def.userConfig.displayName);
    var newConfig = ExposedUserDeviceDefinition(name: def.name, features: def.features, userConfig: newUserConfig);
    await updateDefinition(deviceIdentifier, newConfig);
  }

  Future<void> updateDeviceDeny(
      ExposedUserDeviceIdentifier deviceIdentifier, ExposedUserDeviceDefinition def, bool deny) async {
    var newUserConfig = ExposedUserDeviceCustomization(
        allow: def.userConfig.allow, deny: deny, index: def.userConfig.index, displayName: def.userConfig.displayName);
    var newConfig = ExposedUserDeviceDefinition(name: def.name, features: def.features, userConfig: newUserConfig);
    await updateDefinition(deviceIdentifier, newConfig);
  }

  Future<void> updateDisplayName(
      ExposedUserDeviceIdentifier deviceIdentifier, ExposedUserDeviceDefinition def, String displayName) async {
    var newUserConfig = ExposedUserDeviceCustomization(
        allow: def.userConfig.allow, deny: def.userConfig.deny, index: def.userConfig.index, displayName: displayName);
    var newConfig = ExposedUserDeviceDefinition(name: def.name, features: def.features, userConfig: newUserConfig);
    await updateDefinition(deviceIdentifier, newConfig);
  }

  Future<void> updateFeature(ExposedUserDeviceIdentifier deviceIdentifier, ExposedUserDeviceDefinition def, int index,
      ExposedDeviceFeature feature) async {
    var newFeatureArray = def.features;
    newFeatureArray[index] = feature;
    var newDeviceDefinition =
        ExposedUserDeviceDefinition(name: def.name, features: newFeatureArray, userConfig: def.userConfig);
    await updateDefinition(deviceIdentifier, newDeviceDefinition);
  }

  Future<void> updateDefinition(ExposedUserDeviceIdentifier deviceIdentifier, ExposedUserDeviceDefinition def) async {
    await api!.updateUserConfig(identifier: deviceIdentifier, config: def);
    await _saveConfigFile();
  }

  Future<void> removeDeviceConfig(ExposedUserDeviceIdentifier deviceIdentifier) async {
    await api!.removeUserConfig(identifier: deviceIdentifier);
    await _saveConfigFile();
  }

  Future<void> _saveConfigFile() async {
    var configStr = await api!.getUserConfigStr();
    await IntifacePaths.userDeviceConfigFile.writeAsString(configStr);
    await update();
  }
}
