import 'dart:convert';
import 'dart:io';

import 'package:intiface_central/util/intiface_util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:loggy/loggy.dart';
part 'device_configuration.g.dart';

@JsonSerializable()
class DeviceConfigFileVersion {
  int major = 0;
  int minor = 0;
  Map<String, dynamic> toJson() => _$DeviceConfigFileVersionToJson(this);
  factory DeviceConfigFileVersion.fromJson(Map<String, dynamic> json) => _$DeviceConfigFileVersionFromJson(json);
  DeviceConfigFileVersion();
  @override
  String toString() {
    return "$major.$minor";
  }
}

@JsonSerializable()
class DeviceConfigFile {
  @JsonKey(name: "version")
  DeviceConfigFileVersion? version;
  Map<String, dynamic> toJson() => _$DeviceConfigFileToJson(this);
  factory DeviceConfigFile.fromJson(Map<String, dynamic> json) => _$DeviceConfigFileFromJson(json);
  DeviceConfigFile();
}

class DeviceConfiguration {
  static Future<String> _getConfigFileVersion(File configFile) async {
    if (!await configFile.exists()) {
      logInfo("Device configuration ${configFile.path} does not exist, returning 0.0.");
      return "0.0";
    }
    var configFileJson = await configFile.readAsString();
    try {
      DeviceConfigFile config = DeviceConfigFile.fromJson(jsonDecode(configFileJson));
      logInfo("${configFile.path} version: ${config.version}");
      if (config.version!.major != 3) {
        logWarning("${configFile.path} is not v3, removing and letting system pull from repo.");
        return "0.0";
      }
      return config.version.toString();
    } catch (e) {
      logError("Error loading ${configFile.path}! Deleting if exists and letting system pull from repo.");
      return "0.0";
    }
  }

  static Future<String> getBaseConfigFileVersion() async {
    return await DeviceConfiguration._getConfigFileVersion(IntifacePaths.deviceConfigFile);
  }

  static Future<String> getUserConfigFileVersion() async {
    return await DeviceConfiguration._getConfigFileVersion(IntifacePaths.userDeviceConfigFile);
  }
}
