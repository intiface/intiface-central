import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

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

  @JsonKey(ignore: true)
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
class DeviceConnected {
  final String name;
  final int index;
  final String address;
  @JsonKey(name: "display_name", defaultValue: null)
  final String? displayName;
  factory DeviceConnected.fromJson(Map<String, dynamic> json) => _$DeviceConnectedFromJson(json);
  DeviceConnected({required this.name, required this.index, required this.address, this.displayName});
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

@JsonSerializable(fieldRename: FieldRename.pascal)
class EngineMessage {
  EngineVersion? messageVersion;
  EngineLog? engineLog;
  EngineStarted? engineStarted;
  EngineError? engineError;
  EngineStopped? engineStopped;
  ClientConnected? clientConnected;
  ClientDisconnected? clientDisconnected;
  DeviceConnected? deviceConnected;
  DeviceDisconnected? deviceDisconnected;
  ClientRejected? clientRejected;

  factory EngineMessage.fromJson(Map<String, dynamic> json) => _$EngineMessageFromJson(json);

  Map<String, dynamic> toJson() => _$EngineMessageToJson(this);

  EngineMessage();
}
