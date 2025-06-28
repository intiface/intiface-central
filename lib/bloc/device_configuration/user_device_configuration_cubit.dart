import 'package:bloc/bloc.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:intiface_central/src/rust/api/device_config.dart';
import 'package:intiface_central/src/rust/api/specifiers.dart';
import 'package:loggy/loggy.dart';

class UserDeviceConfigurationState {}

class UserDeviceConfigurationStateInitial extends UserDeviceConfigurationState {}

class UserDeviceConfigurationStateUpdated extends UserDeviceConfigurationState {}

class UserDeviceConfigurationCubit extends Cubit<UserDeviceConfigurationState> {
  UserDeviceConfigurationCubit._() : super(UserDeviceConfigurationStateInitial());
  /*
  static Future<UserDeviceConfigurationCubit> create() async {
    var cubit = UserDeviceConfigurationCubit._();
    return cubit;
  }
*/

  Map<ExposedUserDeviceIdentifier, ExposedDeviceDefinition> _configs = {};
  Map<ExposedUserDeviceIdentifier, ExposedDeviceDefinition> get configs => _configs;

  List<String> _protocols = List.empty(growable: true);
  List<(String, ExposedWebsocketSpecifier)> _specifiers = [];
  List<(String, ExposedSerialSpecifier)> _serialSpecifiers = [];
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
      String? deviceConfig;
      String? userConfig;
      if (IntifacePaths.deviceConfigFile.existsSync()) {
        deviceConfig = IntifacePaths.deviceConfigFile.readAsStringSync();
      }
      if (IntifacePaths.userDeviceConfigFile.existsSync()) {
        userConfig = IntifacePaths.userDeviceConfigFile.readAsStringSync();
      }
      await setupDeviceConfigurationManager(baseConfig: deviceConfig, userConfig: userConfig);
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
      await setupDeviceConfigurationManager(baseConfig: null, userConfig: null);
    }
    await update();
  }

  Future<void> update() async {
    _protocols = await getProtocolNames();
    _specifiers = await getUserWebsocketCommunicationSpecifiers();
    _serialSpecifiers = await getUserSerialCommunicationSpecifiers();
    _configs = await getUserDeviceDefinitions();
    emit(UserDeviceConfigurationStateUpdated());
  }

  Future<void> addWebsocketDeviceName(String protocol, String name) async {
    await addWebsocketSpecifier(protocol: protocol, name: name);
    await _saveConfigFile();
  }

  Future<void> removeWebsocketDeviceName(String protocol, String name) async {
    await removeWebsocketSpecifier(protocol: protocol, name: name);
    await _saveConfigFile();
  }

  Future<void> addSerialPort(
    String protocol,
    String port,
    int baudRate,
    int dataBits,
    int stopBits,
    String parity,
  ) async {
    await addSerialSpecifier(
      protocol: protocol,
      port: port,
      baudRate: baudRate,
      dataBits: dataBits,
      stopBits: stopBits,
      parity: parity,
    );
    await _saveConfigFile();
  }

  Future<void> removeSerialPort(String protocol, String port) async {
    await removeSerialSpecifier(protocol: protocol, port: port);
    await _saveConfigFile();
  }

  Future<void> updateDeviceAllow(
    ExposedUserDeviceIdentifier deviceIdentifier,
    ExposedDeviceDefinition def,
    bool allow,
  ) async {
    var newUserConfig = ExposedUserDeviceCustomization(
      allow: allow,
      deny: def.userConfig.deny,
      index: def.userConfig.index,
      displayName: def.userConfig.displayName,
    );
    def.setUserConfig(config: newUserConfig);
    await updateDefinition(deviceIdentifier, def);
  }

  Future<void> updateDeviceDeny(
    ExposedUserDeviceIdentifier deviceIdentifier,
    ExposedDeviceDefinition def,
    bool deny,
  ) async {
    var newUserConfig = ExposedUserDeviceCustomization(
      allow: def.userConfig.allow,
      deny: deny,
      index: def.userConfig.index,
      displayName: def.userConfig.displayName,
    );
    def.setUserConfig(config: newUserConfig);
    await updateDefinition(deviceIdentifier, def);
  }

  Future<void> updateDisplayName(
    ExposedUserDeviceIdentifier deviceIdentifier,
    ExposedDeviceDefinition def,
    String displayName,
  ) async {
    var newUserConfig = ExposedUserDeviceCustomization(
      allow: def.userConfig.allow,
      deny: def.userConfig.deny,
      index: def.userConfig.index,
      displayName: displayName,
    );
    def.setUserConfig(config: newUserConfig);
    await updateDefinition(deviceIdentifier, def);
  }

  /*
  Future<void> updateFeature(
    ExposedUserDeviceIdentifier deviceIdentifier,
    ExposedDeviceDefinition def,
    int index,
    ExposedDeviceFeature feature,
  ) async {
    var newFeatureArray = def.features;
    newFeatureArray[index] = feature;
    var newDeviceDefinition = ExposedDeviceDefinition(
      name: def.name,
      id: def.id,
      baseId: def.baseId,
      features: newFeatureArray,
      userConfig: def.userConfig,
    );
    await updateDefinition(deviceIdentifier, newDeviceDefinition);
  }
  */

  Future<void> updateDefinition(ExposedUserDeviceIdentifier deviceIdentifier, ExposedDeviceDefinition def) async {
    await updateUserConfig(identifier: deviceIdentifier, config: def);
    await _saveConfigFile();
  }

  Future<void> removeDeviceConfig(ExposedUserDeviceIdentifier deviceIdentifier) async {
    await removeUserConfig(identifier: deviceIdentifier);
    await _saveConfigFile();
  }

  Future<void> _saveConfigFile() async {
    var configStr = await getUserConfigStr();
    await IntifacePaths.userDeviceConfigFile.writeAsString(configStr);
    await update();
  }
}
