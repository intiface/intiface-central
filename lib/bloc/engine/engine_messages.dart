import 'dart:convert';

import 'package:intiface_central/bridge_generated.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'engine_messages.g.dart';

@JsonSerializable()
class RequestEngineVersion {
  @JsonKey(name: "expected_version")
  int expectedVersion = 1;
  Map<String, dynamic> toJson() => _$RequestEngineVersionToJson(this);
  factory RequestEngineVersion.fromJson(Map<String, dynamic> json) => _$RequestEngineVersionFromJson(json);
  RequestEngineVersion();
}

@JsonSerializable()
class Stop {
  Map<String, dynamic> toJson() => _$StopToJson(this);
  factory Stop.fromJson(Map<String, dynamic> json) => _$StopFromJson(json);
  Stop();
}

@JsonSerializable(fieldRename: FieldRename.pascal, includeIfNull: false, explicitToJson: true)
class IntifaceMessage {
  RequestEngineVersion? requestEngineVersion;
  Stop? stop;

  factory IntifaceMessage.fromJson(Map<String, dynamic> json) => _$IntifaceMessageFromJson(json);

  Map<String, dynamic> toJson() => _$IntifaceMessageToJson(this);

  IntifaceMessage();
}

@JsonSerializable()
class EngineVersion {
  String version = "";
  factory EngineVersion.fromJson(Map<String, dynamic> json) => _$EngineVersionFromJson(json);
  EngineVersion();
}

@JsonSerializable()
class EngineLogMessageSpan {
  String? name;
  factory EngineLogMessageSpan.fromJson(Map<String, dynamic> json) => _$EngineLogMessageSpanFromJson(json);
  EngineLogMessageSpan();
}

@JsonSerializable()
class EngineLogMessageFields {
  String message = "";
  String target = "";
  EngineLogMessageSpan? span;
  List<EngineLogMessageSpan>? spans;
  factory EngineLogMessageFields.fromJson(Map<String, dynamic> json) => _$EngineLogMessageFieldsFromJson(json);
  EngineLogMessageFields();
}

@JsonSerializable()
class EngineLogMessage {
  String timestamp = "";
  String level = "";
  Map<String, dynamic> fields = {};
  String target = "";
  factory EngineLogMessage.fromJson(Map<String, dynamic> json) => _$EngineLogMessageFromJson(json);
  EngineLogMessage();
}

@JsonSerializable(checked: true, disallowUnrecognizedKeys: true) //)
class EngineLog {
  @JsonKey(name: "message")
  String? rawMessage;

  @JsonKey(includeFromJson: false, includeToJson: false)
  EngineLogMessage? message;

  factory EngineLog.fromJson(Map<String, dynamic> json) {
    EngineLog log = _$EngineLogFromJson(json);
    log.message = EngineLogMessage.fromJson(jsonDecode(log.rawMessage!));
    return log;
  }

  EngineLog();
}

@JsonSerializable()
class EngineStarted {
  factory EngineStarted.fromJson(Map<String, dynamic> json) => _$EngineStartedFromJson(json);
  EngineStarted();
}

@JsonSerializable()
class EngineServerCreated {
  factory EngineServerCreated.fromJson(Map<String, dynamic> json) => _$EngineServerCreatedFromJson(json);
  EngineServerCreated();
}

@JsonSerializable()
class EngineError {
  String error = "";
  factory EngineError.fromJson(Map<String, dynamic> json) => _$EngineErrorFromJson(json);
  EngineError();
}

@JsonSerializable()
class EngineStopped {
  factory EngineStopped.fromJson(Map<String, dynamic> json) => _$EngineStoppedFromJson(json);
  EngineStopped();
}

@JsonSerializable()
class ClientConnected {
  @JsonKey(name: "client_name")
  String clientName = "";
  factory ClientConnected.fromJson(Map<String, dynamic> json) => _$ClientConnectedFromJson(json);
  ClientConnected();
}

@JsonSerializable()
class ClientDisconnected {
  factory ClientDisconnected.fromJson(Map<String, dynamic> json) => _$ClientDisconnectedFromJson(json);
  ClientDisconnected();
}

@JsonSerializable()
class SerializableUserConfigDeviceIdentifier extends Equatable {
  final String address;
  final String protocol;
  @JsonKey(includeIfNull: false)
  final String? identifier;

  @override
  List<dynamic> get props => [address, protocol, identifier];

  Map<String, dynamic> toJson() => _$SerializableUserConfigDeviceIdentifierToJson(this);
  factory SerializableUserConfigDeviceIdentifier.fromJson(Map<String, dynamic> json) =>
      _$SerializableUserConfigDeviceIdentifierFromJson(json);
  const SerializableUserConfigDeviceIdentifier(this.address, this.protocol, this.identifier);

  ExposedUserDeviceIdentifier toExposedUserDeviceIdentifier() {
    return ExposedUserDeviceIdentifier(address: address, protocol: protocol, identifier: identifier);
  }
}

@JsonSerializable()
class DeviceConnected {
  final String name;
  final int index;
  final SerializableUserConfigDeviceIdentifier identifier;
  @JsonKey(name: "display_name", defaultValue: null)
  final String? displayName;
  factory DeviceConnected.fromJson(Map<String, dynamic> json) => _$DeviceConnectedFromJson(json);
  DeviceConnected({required this.name, required this.index, required this.identifier, this.displayName});
}

@JsonSerializable()
class DeviceDisconnected {
  int index = -1;
  factory DeviceDisconnected.fromJson(Map<String, dynamic> json) => _$DeviceDisconnectedFromJson(json);
  DeviceDisconnected();
}

@JsonSerializable()
class ClientRejected {
  String reason = "";
  factory ClientRejected.fromJson(Map<String, dynamic> json) => _$ClientRejectedFromJson(json);
  ClientRejected();
}

@JsonSerializable()
class EngineProviderLog {
  String timestamp = "";
  String level = "";
  String message = "";
  // Unlike all the other engine messages, this actually needs to encode too since we're using this internally.
  Map<String, dynamic> toJson() => _$EngineProviderLogToJson(this);
  factory EngineProviderLog.fromJson(Map<String, dynamic> json) => _$EngineProviderLogFromJson(json);
  EngineProviderLog();
}

@JsonSerializable(fieldRename: FieldRename.pascal)
class EngineMessage {
  EngineVersion? messageVersion;
  EngineLog? engineLog;
  EngineStarted? engineStarted;
  EngineServerCreated? engineServerCreated;
  EngineError? engineError;
  EngineStopped? engineStopped;
  ClientConnected? clientConnected;
  ClientDisconnected? clientDisconnected;
  DeviceConnected? deviceConnected;
  DeviceDisconnected? deviceDisconnected;
  ClientRejected? clientRejected;
  EngineProviderLog? engineProviderLog;

  factory EngineMessage.fromJson(Map<String, dynamic> json) => _$EngineMessageFromJson(json);

  Map<String, dynamic> toJson() => _$EngineMessageToJson(this);

  EngineMessage();
}
