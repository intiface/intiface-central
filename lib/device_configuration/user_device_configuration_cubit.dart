import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:intiface_central/device_configuration/user_device_configuration_file.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';

class UserDeviceConfigurationState {}

class UserDeviceConfigurationStateInitial extends UserDeviceConfigurationState {}

class UserDeviceConfigurationCubit extends Cubit<UserDeviceConfigurationState> {
  late UserDeviceConfigurationFile _configFile;

  UserDeviceConfigurationCubit(File filePath) : super(UserDeviceConfigurationStateInitial()) {
    // This is only ever run on program start so we're fine to check it synchronously.
    try {
      var jsonConfig = IntifacePaths.userDeviceConfigFile.readAsStringSync();
      _configFile = UserDeviceConfigurationFile.fromJson(jsonDecode(jsonConfig));
      logInfo("User device config ${filePath.path} loaded from disk.");
    } catch (e) {
      if (IntifacePaths.userDeviceConfigFile.existsSync()) {
        logError("Error loading user config file: ${e.toString()}. Removing and rebuilding.");
      } else {
        logInfo("User config file not found, assuming first run, rebuilding default.");
      }
      _configFile = UserDeviceConfigurationFile();
      _configFile.version.major = 2;
      _configFile.version.minor = 0;
      IntifacePaths.userDeviceConfigFile.createSync(recursive: true);
      _saveConfigFile();
    }
  }

  void updateDeviceIndex(UserConfigDeviceIdentifier deviceIdentifier, int index) {
    // See if device already exists in config
    if (_configFile.userConfigs.deviceMap.containsKey(deviceIdentifier)) {
      logInfo("Device key exists");
    } else {
      logInfo("Device key ${jsonEncode(deviceIdentifier.toJson())} does not exist, adding");
      // If not, add it.
      var config = UserConfig();
      config.index = index;
      _configFile.userConfigs.devices.add(UserConfigPair(deviceIdentifier, config));
      logInfo("New file ${jsonEncode(_configFile.toJson())}");
      _saveConfigFile();
    }
  }

  void _saveConfigFile() {
    logInfo("SAVING CONFIG FILE");
    IntifacePaths.userDeviceConfigFile.writeAsStringSync(jsonEncode(_configFile.toJson()));
  }
}
