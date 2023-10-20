import 'package:bloc/bloc.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:intiface_central/ffi.dart';
import 'package:loggy/loggy.dart';

class UserDeviceConfigurationState {}

class UserDeviceConfigurationStateInitial extends UserDeviceConfigurationState {}

class UserDeviceConfigurationStateUpdated extends UserDeviceConfigurationState {}

class ExposedWritableUserDeviceSpecifier {
  List<String>? websocketNames;

  ExposedWritableUserDeviceSpecifier(this.websocketNames);

  void addWebsocketDeviceName(String name) {
    if (websocketNames != null) {
      if (!websocketNames!.contains(name)) {
        websocketNames!.add(name);
      }
    } else {
      websocketNames = [name].toList();
    }
  }

  void removeWebsocketDeviceName(String name) {
    if (websocketNames != null) {
      websocketNames!.remove(name);
    }
  }

  static ExposedWritableUserDeviceSpecifier? fromRust(ExposedUserDeviceSpecifiers config) {
    return ExposedWritableUserDeviceSpecifier(config.websocket!.names.toList());
  }

  ExposedUserDeviceSpecifiers? toRust() {
    // For now, assume we'll only use websockets here. This will change once we can also set up serial ports.
    if (websocketNames == null) {
      return null;
    }
    var websocketSpecifier = ExposedWebsocketSpecifier(names: websocketNames!);
    return ExposedUserDeviceSpecifiers(websocket: websocketSpecifier);
  }
}

class ExposedWritableUserDeviceConfig {
  UserConfigDeviceIdentifier identifier;
  String name;
  String? displayName;
  bool? allow;
  bool? deny;
  int? reservedIndex;

  static ExposedWritableUserDeviceConfig createDefault(index) {
    return ExposedWritableUserDeviceConfig(
        const UserConfigDeviceIdentifier(address: "", protocol: ""), "", index, "", false, false);
  }

  ExposedWritableUserDeviceConfig(
      this.identifier, this.name, this.reservedIndex, this.displayName, this.allow, this.deny);

  String get identifierString {
    return "${identifier.protocol}:${identifier.identifier}:${identifier.address}:$reservedIndex";
  }

  bool matches(UserConfigDeviceIdentifier other) {
    return identifier.address == other.address &&
        identifier.protocol == other.protocol &&
        identifier.identifier == other.identifier;
  }

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
  List<ExposedWritableUserDeviceConfig> _configs = List.empty(growable: true);
  List<String> _protocols = List.empty(growable: true);
  final Map<String, ExposedWritableUserDeviceSpecifier> _specifiers = {};

  UserDeviceConfigurationCubit._() : super(UserDeviceConfigurationStateInitial());

  List<ExposedWritableUserDeviceConfig> get configs => _configs;
  Map<String, ExposedWritableUserDeviceSpecifier> get specifiers => _specifiers;
  List<String> get protocols => _protocols;

  static Future<UserDeviceConfigurationCubit> create() async {
    var cubit = UserDeviceConfigurationCubit._();
    try {
      if (!IntifacePaths.userDeviceConfigFile.existsSync()) {
        await cubit._saveConfigFile();
      }
      if (IntifacePaths.deviceConfigFile.existsSync() && IntifacePaths.userDeviceConfigFile.existsSync()) {
        var jsonDeviceConfig = IntifacePaths.deviceConfigFile.readAsStringSync();
        var jsonConfig = IntifacePaths.userDeviceConfigFile.readAsStringSync();
        var config = (await api.getUserDeviceConfigs(deviceConfigJson: jsonDeviceConfig, userConfigJson: jsonConfig));
        cubit._configs = config.configurations.map((e) => ExposedWritableUserDeviceConfig.fromRust(e)).toList();
        for (var k in config.specifiers) {
          var protocol = k.$1;
          var specifier = k.$2;
          var dartSpecifier = ExposedWritableUserDeviceSpecifier.fromRust(specifier);
          if (dartSpecifier == null) {
            continue;
          }
          cubit._specifiers[protocol] = dartSpecifier;
        }
        //.map((k, v) => ExposedWritableUserDeviceSpecifier())
      }
      cubit._protocols = await api.getProtocolNames();
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
      await cubit._saveConfigFile();
    }
    return cubit;
  }

  Future<void> addWebsocketDeviceName(String protocol, String name) async {
    if (!_specifiers.containsKey(protocol)) {
      _specifiers[protocol] = ExposedWritableUserDeviceSpecifier([name]);
    } else {
      _specifiers[protocol]!.addWebsocketDeviceName(name);
    }
    await _saveConfigFile();
  }

  Future<void> removeWebsocketDeviceName(String protocol, String name) async {
    if (_specifiers.containsKey(protocol)) {
      _specifiers[protocol]!.removeWebsocketDeviceName(name);
      await _saveConfigFile();
    }
  }

  Future<void> updateDeviceAllow(UserConfigDeviceIdentifier deviceIdentifier, bool allow) async {
    // See if device already exists in config
    for (var config in _configs) {
      if (config.matches(deviceIdentifier)) {
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
      if (config.matches(deviceIdentifier)) {
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
      if (config.matches(deviceIdentifier)) {
        config.reservedIndex = reservedIndex;
        await _saveConfigFile();
        return;
      }
    }
    ExposedWritableUserDeviceConfig newConfig =
        ExposedWritableUserDeviceConfig(deviceIdentifier, "", reservedIndex, null, null, null);
    await _updateConfig(deviceIdentifier, newConfig);
  }

  Future<void> updateName(UserConfigDeviceIdentifier deviceIdentifier, String name) async {
    var updatedName = name.trim();

    // See if device already exists in config
    for (var config in _configs) {
      if (config.matches(deviceIdentifier)) {
        config.name = updatedName.isEmpty ? "" : updatedName;
        await _saveConfigFile();
        return;
      }
    }
    ExposedWritableUserDeviceConfig newConfig =
        ExposedWritableUserDeviceConfig(deviceIdentifier, updatedName, null, null, null, null);
    await _updateConfig(deviceIdentifier, newConfig);
  }

  Future<void> updateDisplayName(UserConfigDeviceIdentifier deviceIdentifier, String displayName) async {
    var updatedDisplayName = displayName.trim();

    // See if device already exists in config
    for (var config in _configs) {
      if (config.matches(deviceIdentifier)) {
        config.displayName = updatedDisplayName.isEmpty ? null : updatedDisplayName;
        await _saveConfigFile();
        return;
      }
    }
    ExposedWritableUserDeviceConfig newConfig =
        ExposedWritableUserDeviceConfig(deviceIdentifier, displayName, null, null, null, null);
    await _updateConfig(deviceIdentifier, newConfig);
  }

  Future<void> removeDeviceConfig(UserConfigDeviceIdentifier deviceIdentifier) async {
    _configs.removeWhere((element) => element.matches(deviceIdentifier));
    await _saveConfigFile();
  }

  Future<void> _updateConfig(
      UserConfigDeviceIdentifier deviceIdentifier, ExposedWritableUserDeviceConfig newConfig) async {
    _configs.removeWhere((element) => element.matches(deviceIdentifier));
    _configs.add(newConfig);
    await _saveConfigFile();
  }

  Future<void> _saveConfigFile() async {
    List<(String, ExposedUserDeviceSpecifiers)> specifierList = [];
    logInfo(_specifiers);
    for (var entry in _specifiers.entries) {
      if (entry.value.toRust() != null) {
        logInfo(entry.key);
        specifierList.add((entry.key, entry.value.toRust()!));
      }
    }
    logInfo(specifierList);
    var jsonString = await api.generateUserDeviceConfigFile(
        userConfig:
            ExposedUserConfig(configurations: _configs.map((e) => e.toRust()).toList(), specifiers: specifierList));
    await IntifacePaths.userDeviceConfigFile.writeAsString(jsonString);
    emit(UserDeviceConfigurationStateUpdated());
  }
}
