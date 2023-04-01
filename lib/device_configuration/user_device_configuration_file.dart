// Device Utility Classes
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

@JsonSerializable()
class UserConfigPair {
  late UserConfigDeviceIdentifier identifier;
  late UserConfig config;
  UserConfigPair(this.identifier, this.config);
  Map<String, dynamic> toJson() => _$UserConfigPairToJson(this);
  factory UserConfigPair.fromJson(Map<String, dynamic> json) => _$UserConfigPairFromJson(json);
}

@JsonSerializable()
class UserDeviceConfigurationFileContent {
  // Protocol to definition mapping
  Map<String, UserProtocolDefinition> specifiers = {};
  //@JsonKey(name: "devices")
  List<UserConfigPair> devices = [];
  Map<UserConfigDeviceIdentifier, UserConfig> get deviceMap {
    Map<UserConfigDeviceIdentifier, UserConfig> deviceMap = {};
    for (var config in devices) {
      deviceMap[config.identifier] = config.config;
    }
    return deviceMap;
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
class UserConfigDeviceIdentifier extends Equatable {
  final String address;
  final String protocol;
  @JsonKey(includeIfNull: false)
  final String? identifier;

  @override
  List<dynamic> get props => [address, protocol, identifier];

  Map<String, dynamic> toJson() => _$UserConfigDeviceIdentifierToJson(this);
  factory UserConfigDeviceIdentifier.fromJson(Map<String, dynamic> json) => _$UserConfigDeviceIdentifierFromJson(json);
  const UserConfigDeviceIdentifier(this.address, this.protocol, this.identifier);
}

@JsonSerializable()
class UserConfig {
  @JsonKey(includeIfNull: false)
  String? displayName;
  @JsonKey(includeIfNull: false)
  bool? allow;
  @JsonKey(includeIfNull: false)
  bool? deny;
  @JsonKey(includeIfNull: false)
  int? index;
  @JsonKey(includeIfNull: false)
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
  @JsonKey(includeIfNull: false)
  List<ServerGenericDeviceMessageAttributes>? scalarCmd;
  @JsonKey(includeIfNull: false)
  List<ServerGenericDeviceMessageAttributes>? rotateCmd;
  @JsonKey(includeIfNull: false)
  List<ServerGenericDeviceMessageAttributes>? linearCmd;
  @JsonKey(includeIfNull: false)
  List<SensorDeviceMessageAttributes>? sensorReadCmd;
  @JsonKey(includeIfNull: false)
  List<SensorDeviceMessageAttributes>? sensorSubscribeCmd;
  // This is the only message that should always exist, so don't mark it nullable. If it's null, our parser should throw.
  NullDeviceMessageAttributes stopDeviceCmd = NullDeviceMessageAttributes();
  @JsonKey(includeIfNull: false)
  List<RawDeviceMessageAttributes>? rawReadCmd;
  @JsonKey(includeIfNull: false)
  List<RawDeviceMessageAttributes>? rawWriteCmd;
  @JsonKey(includeIfNull: false)
  List<RawDeviceMessageAttributes>? rawSubscribeCmd;

  Map<String, dynamic> toJson() => _$ServerDeviceMessageAttributesToJson(this);
  factory ServerDeviceMessageAttributes.fromJson(Map<String, dynamic> json) =>
      _$ServerDeviceMessageAttributesFromJson(json);
  ServerDeviceMessageAttributes();
}
