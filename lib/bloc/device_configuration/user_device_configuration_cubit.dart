import 'package:bloc/bloc.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:intiface_central/ffi.dart';
import 'package:loggy/loggy.dart';

class UserDeviceConfigurationState {}

class UserDeviceConfigurationStateInitial extends UserDeviceConfigurationState {}

class UserDeviceConfigurationStateUpdated extends UserDeviceConfigurationState {}

class UserDeviceConfigurationCubit extends Cubit<UserDeviceConfigurationState> {
  Map<ExposedUserDeviceIdentifier, ExposedUserDeviceDefinition> _configs = {};
  List<String> _protocols = List.empty(growable: true);
  Map<String, ExposedWebsocketSpecifier> _specifiers = {};

  UserDeviceConfigurationCubit._() : super(UserDeviceConfigurationStateInitial());

  Map<ExposedUserDeviceIdentifier, ExposedUserDeviceDefinition> get configs => _configs;
  Map<String, ExposedWebsocketSpecifier> get specifiers => _specifiers;
  List<String> get protocols => _protocols;

  static Future<UserDeviceConfigurationCubit> create() async {
    var cubit = UserDeviceConfigurationCubit._();
    await cubit.updateFromDisk();
    return cubit;
  }

  Future<void> updateFromDisk() async {
    try {
      if (!IntifacePaths.userDeviceConfigFile.existsSync()) {
        return;
      }
      if (IntifacePaths.deviceConfigFile.existsSync() && IntifacePaths.userDeviceConfigFile.existsSync()) {
        //var jsonDeviceConfig = IntifacePaths.deviceConfigFile.readAsStringSync();
        var userConfig = IntifacePaths.userDeviceConfigFile.readAsStringSync();
        // Can't get this out of frb v1 as a map, so we have to convert here.
        _configs = <ExposedUserDeviceIdentifier, ExposedUserDeviceDefinition>{
          for (var (k, v) in await api!.getUserDeviceDefinitions(userConfig: userConfig)) k: v
        };
        _specifiers = <String, ExposedWebsocketSpecifier>{
          for (var (k, v) in await api!.getUserCommunicationSpecifiers(userConfig: userConfig)) k: v
        };
      }
      _protocols = await api!.getProtocolNames();
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
    }
  }

  Future<void> addWebsocketDeviceName(String protocol, String name) async {
    /*
    if (!_specifiers.containsKey(protocol)) {
      _specifiers[protocol] = ExposedWritableUserDeviceSpecifier([name]);
    } else {
      _specifiers[protocol]!.addWebsocketDeviceName(name);
    }
    await _saveConfigFile();
    */
  }

  Future<void> removeWebsocketDeviceName(String protocol, String name) async {
    /*
    if (_specifiers.containsKey(protocol)) {
      _specifiers[protocol]!.removeWebsocketDeviceName(name);
      await _saveConfigFile();
    }
    */
  }

  Future<void> updateDeviceAllow(ExposedUserDeviceIdentifier deviceIdentifier, bool allow) async {
    var def = _configs[deviceIdentifier]!;
    var newUserConfig = ExposedUserDeviceCustomization(
        allow: allow, deny: def.userConfig.deny, index: def.userConfig.index, displayName: def.userConfig.displayName);
    var newConfig = ExposedUserDeviceDefinition(name: def.name, features: def.features, userConfig: newUserConfig);
    await _updateConfig(deviceIdentifier, newConfig);
  }

  Future<void> updateDeviceDeny(ExposedUserDeviceIdentifier deviceIdentifier, bool deny) async {
    var def = _configs[deviceIdentifier]!;
    var newUserConfig = ExposedUserDeviceCustomization(
        allow: def.userConfig.allow, deny: deny, index: def.userConfig.index, displayName: def.userConfig.displayName);
    var newConfig = ExposedUserDeviceDefinition(name: def.name, features: def.features, userConfig: newUserConfig);
    await _updateConfig(deviceIdentifier, newConfig);
  }

  Future<void> updateDisplayName(ExposedUserDeviceIdentifier deviceIdentifier, String displayName) async {
    var def = _configs[deviceIdentifier]!;
    var newUserConfig = ExposedUserDeviceCustomization(
        allow: def.userConfig.allow,
        deny: def.userConfig.deny,
        index: def.userConfig.index,
        displayName: def.userConfig.displayName);
    var newConfig = ExposedUserDeviceDefinition(name: def.name, features: def.features, userConfig: newUserConfig);
    await _updateConfig(deviceIdentifier, newConfig);
  }

  Future<void> removeDeviceConfig(ExposedUserDeviceIdentifier deviceIdentifier) async {
    _configs.remove(deviceIdentifier);
    await _saveConfigFile();
  }

  Future<void> _updateConfig(
      ExposedUserDeviceIdentifier deviceIdentifier, ExposedUserDeviceDefinition newConfig) async {
    _configs[deviceIdentifier] = newConfig;
    await _saveConfigFile();
  }

  Future<void> _saveConfigFile() async {
    emit(UserDeviceConfigurationStateUpdated());
  }
}
