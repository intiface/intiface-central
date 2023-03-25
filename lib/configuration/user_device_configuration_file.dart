// Device Utility Classes
import 'dart:developer';

import 'package:buttplug/buttplug.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:tuple/tuple.dart';

part 'user_device_configuration_file.g.dart';

@JsonSerializable()
class UserDeviceConfigurationFileVersion {
  int major = 0;
  int minor = 0;
  Map<String, dynamic> toJson() => _$UserDeviceConfigurationFileVersionToJson(this);
  factory UserDeviceConfigurationFileVersion.fromJson(Map<String, dynamic> json) =>
      _$UserDeviceConfigurationFileVersionFromJson(json);
  UserDeviceConfigurationFileVersion();
}

@JsonSerializable()
class UserDeviceConfigurationFile {
  UserDeviceConfigurationFileVersion version = UserDeviceConfigurationFileVersion();
  @JsonKey(name: "user-configs")
  UserDeviceConfigurationFileContent userConfigs = UserDeviceConfigurationFileContent();
  Map<String, dynamic> toJson() => _$UserDeviceConfigurationFileToJson(this);
  factory UserDeviceConfigurationFile.fromJson(Map<String, dynamic> json) =>
      _$UserDeviceConfigurationFileFromJson(json);
  UserDeviceConfigurationFile();
}

class UserConfigDevice extends Tuple2<ServerDeviceIdentifier, UserConfig> {
  const UserConfigDevice(ServerDeviceIdentifier item1, UserConfig item2) : super(item1, item2);
  ServerDeviceIdentifier get identifier => item1;
  UserConfig get config => item2;
}

class UserConfigDeviceConverter implements JsonConverter<UserConfigDevice, List<dynamic>> {
  static const instance = UserConfigDeviceConverter();

  const UserConfigDeviceConverter();

  @override
  UserConfigDevice fromJson(dynamic json) {
    final identifier = ServerDeviceIdentifier.fromJson(json[0]);
    final config = UserConfig.fromJson(json[1]);

    return UserConfigDevice(identifier, config);
  }

  @override
  List<dynamic> toJson(UserConfigDevice entry) {
    return [entry.identifier, entry.config];
  }
}

@JsonSerializable()
@UserConfigDeviceConverter.instance
class UserDeviceConfigurationFileContent {
  // Protocol to definition mapping
  Map<String, UserProtocolDefinition> specifiers = {};
  //@JsonKey(name: "devices")
  List<UserConfigDevice> devices = [];
  Map<ServerDeviceIdentifier, UserConfig>? _deviceMap;
  Map<ServerDeviceIdentifier, UserConfig> get deviceMap {
    if (_deviceMap == null) {
      _deviceMap = {};
      for (var config in devices) {
        _deviceMap![config.identifier] = config.config;
      }
    }
    return _deviceMap!;
  }

  Map<String, dynamic> toJson() => _$UserDeviceConfigurationFileContentToJson(this);
  factory UserDeviceConfigurationFileContent.fromJson(Map<String, dynamic> json) =>
      _$UserDeviceConfigurationFileContentFromJson(json);
  UserDeviceConfigurationFileContent();
}

@JsonSerializable()
class WebsocketProtocolDefinition {
  List<String> names = [];
  Map<String, dynamic> toJson() => _$WebsocketProtocolDefinitionToJson(this);
  factory WebsocketProtocolDefinition.fromJson(Map<String, dynamic> json) =>
      _$WebsocketProtocolDefinitionFromJson(json);
  WebsocketProtocolDefinition();
}

@JsonSerializable()
class UserProtocolDefinition {
  WebsocketProtocolDefinition websocket = WebsocketProtocolDefinition();
  Map<String, dynamic> toJson() => _$UserProtocolDefinitionToJson(this);
  factory UserProtocolDefinition.fromJson(Map<String, dynamic> json) => _$UserProtocolDefinitionFromJson(json);
  UserProtocolDefinition();
}

@JsonSerializable()
class ServerDeviceIdentifier extends Equatable {
  final String address;
  final String protocol;
  final String identifier;

  @override
  List<Object> get props => [address, protocol, identifier];

  Map<String, dynamic> toJson() => _$ServerDeviceIdentifierToJson(this);
  factory ServerDeviceIdentifier.fromJson(Map<String, dynamic> json) => _$ServerDeviceIdentifierFromJson(json);
  const ServerDeviceIdentifier(this.address, this.protocol, this.identifier);
}

@JsonSerializable()
class UserConfig {
  String? displayName;
  bool? allow;
  bool? deny;
  int? index;
  ServerGenericDeviceMessageAttributes? messageAttributes;
  Map<String, dynamic> toJson() => _$UserConfigToJson(this);
  factory UserConfig.fromJson(Map<String, dynamic> json) => _$UserConfigFromJson(json);
  UserConfig();
}

@JsonSerializable(fieldRename: FieldRename.pascal)
class ServerGenericDeviceMessageAttributes {
  String featureDescriptor = "";
  ActuatorType actuatorType = ActuatorType.Vibrate;
  List<int> stepCount = [0, 0];

  Map<String, dynamic> toJson() => _$ServerGenericDeviceMessageAttributesToJson(this);
  factory ServerGenericDeviceMessageAttributes.fromJson(Map<String, dynamic> json) =>
      _$ServerGenericDeviceMessageAttributesFromJson(json);
  ServerGenericDeviceMessageAttributes();
}

@JsonSerializable(fieldRename: FieldRename.pascal)
class SensorDeviceMessageAttributes {
  String featureDescriptor = "";
  SensorType sensorType = SensorType.Pressure;
  List<List<int>> sensorRange = [];

  Map<String, dynamic> toJson() => _$SensorDeviceMessageAttributesToJson(this);
  factory SensorDeviceMessageAttributes.fromJson(Map<String, dynamic> json) =>
      _$SensorDeviceMessageAttributesFromJson(json);
  SensorDeviceMessageAttributes();
}

@JsonSerializable(fieldRename: FieldRename.pascal)
class NullDeviceMessageAttributes {
  Map<String, dynamic> toJson() => _$NullDeviceMessageAttributesToJson(this);
  factory NullDeviceMessageAttributes.fromJson(Map<String, dynamic> json) =>
      _$NullDeviceMessageAttributesFromJson(json);
  NullDeviceMessageAttributes();
}

@JsonSerializable(fieldRename: FieldRename.pascal)
class RawDeviceMessageAttributes {
  List<Endpoint> endpoints = [];

  Map<String, dynamic> toJson() => _$RawDeviceMessageAttributesToJson(this);
  factory RawDeviceMessageAttributes.fromJson(Map<String, dynamic> json) => _$RawDeviceMessageAttributesFromJson(json);
  RawDeviceMessageAttributes();
}

@JsonSerializable(fieldRename: FieldRename.pascal, includeIfNull: false)
class ServerDeviceMessageAttributes {
  List<ServerGenericDeviceMessageAttributes>? scalarCmd;
  List<ServerGenericDeviceMessageAttributes>? rotateCmd;
  List<ServerGenericDeviceMessageAttributes>? linearCmd;
  List<SensorDeviceMessageAttributes>? sensorReadCmd;
  List<SensorDeviceMessageAttributes>? sensorSubscribeCmd;
  // This is the only message that should always exist, so don't mark it nullable. If it's null, our parser should throw.
  NullDeviceMessageAttributes stopDeviceCmd = NullDeviceMessageAttributes();
  List<RawDeviceMessageAttributes>? rawReadCmd;
  List<RawDeviceMessageAttributes>? rawWriteCmd;
  List<RawDeviceMessageAttributes>? rawSubscribeCmd;

  Map<String, dynamic> toJson() => _$ServerDeviceMessageAttributesToJson(this);
  factory ServerDeviceMessageAttributes.fromJson(Map<String, dynamic> json) =>
      _$ServerDeviceMessageAttributesFromJson(json);
  ServerDeviceMessageAttributes();
}
