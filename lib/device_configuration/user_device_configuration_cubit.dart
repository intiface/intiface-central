import 'package:bloc/bloc.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:intiface_central/ffi.dart';

class UserDeviceConfigurationState {}

class UserDeviceConfigurationStateInitial extends UserDeviceConfigurationState {}

class UserDeviceConfigurationStateUpdated extends UserDeviceConfigurationState {}

class ExposedWritableUserDeviceConfig {
  UserConfigDeviceIdentifier identifier;
  String name;
  String? displayName;
  bool? allow;
  bool? deny;
  int? reservedIndex;

  ExposedWritableUserDeviceConfig(
      this.identifier, this.name, this.reservedIndex, this.displayName, this.allow, this.deny);

  static ExposedWritableUserDeviceConfig fromRust(ExposedUserDeviceConfig config) {
    return ExposedWritableUserDeviceConfig(
        config.identifier, config.name, config.reservedIndex, config.displayName, config.allow, config.deny);
  }

  ExposedUserDeviceConfig toRust() {
    return ExposedUserDeviceConfig(
        identifier: identifier,
        name: name,
        reservedIndex: reservedIndex,
        displayName: displayName,
        allow: allow,
        deny: deny);
  }
}

class UserDeviceConfigurationCubit extends Cubit<UserDeviceConfigurationState> {
  List<ExposedWritableUserDeviceConfig> _configs = List.empty();

  UserDeviceConfigurationCubit._() : super(UserDeviceConfigurationStateInitial());

  List<ExposedWritableUserDeviceConfig> get configs => _configs;

  static Future<UserDeviceConfigurationCubit> create() async {
    var cubit = UserDeviceConfigurationCubit._();
    if (!IntifacePaths.userDeviceConfigFile.existsSync()) {
      await cubit._saveConfigFile();
    }
    if (IntifacePaths.deviceConfigFile.existsSync() && IntifacePaths.userDeviceConfigFile.existsSync()) {
      var jsonDeviceConfig = IntifacePaths.deviceConfigFile.readAsStringSync();
      var jsonConfig = IntifacePaths.userDeviceConfigFile.readAsStringSync();
      cubit._configs = (await api.getUserDeviceConfigs(deviceConfigJson: jsonDeviceConfig, userConfigJson: jsonConfig))
          .map((e) => ExposedWritableUserDeviceConfig.fromRust(e))
          .toList();
    }
    return cubit;
  }

  Future<void> updateDeviceAllow(UserConfigDeviceIdentifier deviceIdentifier, bool allow) async {
    // See if device already exists in config
    for (var config in _configs) {
      if (_compareIdentifiers(config.identifier, deviceIdentifier)) {
        config.allow = allow;
        await _saveConfigFile();
        return;
      }
    }
    ExposedWritableUserDeviceConfig newConfig =
        ExposedWritableUserDeviceConfig(deviceIdentifier, "", null, null, allow, null);
    await _updateConfig(deviceIdentifier, newConfig);
  }

  Future<void> updateDeviceDeny(UserConfigDeviceIdentifier deviceIdentifier, bool deny) async {
    // See if device already exists in config
    for (var config in _configs) {
      if (_compareIdentifiers(config.identifier, deviceIdentifier)) {
        config.deny = deny;
        await _saveConfigFile();
        return;
      }
    }
    ExposedWritableUserDeviceConfig newConfig =
        ExposedWritableUserDeviceConfig(deviceIdentifier, "", null, null, null, deny);
    await _updateConfig(deviceIdentifier, newConfig);
  }

  Future<void> updateDeviceIndex(UserConfigDeviceIdentifier deviceIdentifier, int reservedIndex) async {
    // See if device already exists in config
    for (var config in _configs) {
      if (_compareIdentifiers(config.identifier, deviceIdentifier)) {
        config.reservedIndex = reservedIndex;
        await _saveConfigFile();
        return;
      }
    }
    ExposedWritableUserDeviceConfig newConfig =
        ExposedWritableUserDeviceConfig(deviceIdentifier, "", reservedIndex, null, null, null);
    await _updateConfig(deviceIdentifier, newConfig);
  }

  Future<void> updateDisplayName(UserConfigDeviceIdentifier deviceIdentifier, String displayName) async {
    // See if device already exists in config
    for (var config in _configs) {
      if (_compareIdentifiers(config.identifier, deviceIdentifier)) {
        config.displayName = displayName;
        await _saveConfigFile();
        return;
      }
    }
    ExposedWritableUserDeviceConfig newConfig =
        ExposedWritableUserDeviceConfig(deviceIdentifier, displayName, null, null, null, null);
    await _updateConfig(deviceIdentifier, newConfig);
  }

  // This is me being lazy about not wanting to implement equatable's immutable requirements.
  bool _compareIdentifiers(UserConfigDeviceIdentifier ident1, UserConfigDeviceIdentifier ident2) {
    return ident1.address == ident2.address &&
        ident1.protocol == ident2.protocol &&
        ident1.identifier == ident2.identifier;
  }

  Future<void> _updateConfig(
      UserConfigDeviceIdentifier deviceIdentifier, ExposedWritableUserDeviceConfig newConfig) async {
    _configs.removeWhere((element) =>
        element.identifier.address == deviceIdentifier.address &&
        element.identifier.protocol == deviceIdentifier.protocol &&
        element.identifier.identifier == deviceIdentifier.identifier);
    _configs.add(newConfig);
    await _saveConfigFile();
  }

  Future<void> _saveConfigFile() async {
    var jsonString = await api.generateUserDeviceConfigFile(userConfig: _configs.map((e) => e.toRust()).toList());
    await IntifacePaths.userDeviceConfigFile.writeAsString(jsonString);
    emit(UserDeviceConfigurationStateUpdated());
  }
}
