import 'package:json_annotation/json_annotation.dart';

part 'engine_messages.g.dart';

@JsonSerializable()
class MessageVersion {
  int version = -1;
  factory MessageVersion.fromJson(Map<String, dynamic> json) => _$MessageVersionFromJson(json);
  Map<String, dynamic> toJson() => _$MessageVersionToJson(this);
  MessageVersion();
}

@JsonSerializable()
class EngineLogMessageSpan {
  String? name;
  factory EngineLogMessageSpan.fromJson(Map<String, dynamic> json) => _$EngineLogMessageSpanFromJson(json);
  Map<String, dynamic> toJson() => _$EngineLogMessageSpanToJson(this);
  EngineLogMessageSpan();
}

@JsonSerializable()
class EngineLogMessageFields {
  String message = "";
  String target = "";
  EngineLogMessageSpan? span;
  List<EngineLogMessageSpan>? spans;
  factory EngineLogMessageFields.fromJson(Map<String, dynamic> json) => _$EngineLogMessageFieldsFromJson(json);
  Map<String, dynamic> toJson() => _$EngineLogMessageFieldsToJson(this);
  EngineLogMessageFields();
}

@JsonSerializable()
class EngineLogMessage {
  String timestamp = "";
  String level = "";
  Map<String, dynamic> fields = new Map();
  String target = "";
  factory EngineLogMessage.fromJson(Map<String, dynamic> json) => _$EngineLogMessageFromJson(json);
  Map<String, dynamic> toJson() => _$EngineLogMessageToJson(this);
  EngineLogMessage();
}

@JsonSerializable() //)
class EngineLog {
  EngineLogMessage? message = null;
  factory EngineLog.fromJson(Map<String, dynamic> json) => _$EngineLogFromJson(json);
  Map<String, dynamic> toJson() => _$EngineLogToJson(this);
  EngineLog();
}

@JsonSerializable()
class EngineStarted {
  factory EngineStarted.fromJson(Map<String, dynamic> json) => _$EngineStartedFromJson(json);
  Map<String, dynamic> toJson() => _$EngineStartedToJson(this);
  EngineStarted();
}

@JsonSerializable()
class EngineError {
  String error = "";
  factory EngineError.fromJson(Map<String, dynamic> json) => _$EngineErrorFromJson(json);
  Map<String, dynamic> toJson() => _$EngineErrorToJson(this);
  EngineError();
}

@JsonSerializable()
class EngineStopped {
  factory EngineStopped.fromJson(Map<String, dynamic> json) => _$EngineStoppedFromJson(json);
  Map<String, dynamic> toJson() => _$EngineStoppedToJson(this);
  EngineStopped();
}

@JsonSerializable()
class ClientConnected {
  @JsonKey(name: "client_name")
  String clientName = "";
  factory ClientConnected.fromJson(Map<String, dynamic> json) => _$ClientConnectedFromJson(json);
  Map<String, dynamic> toJson() => _$ClientConnectedToJson(this);
  ClientConnected();
}

@JsonSerializable()
class ClientDisconnected {
  factory ClientDisconnected.fromJson(Map<String, dynamic> json) => _$ClientDisconnectedFromJson(json);
  Map<String, dynamic> toJson() => _$ClientDisconnectedToJson(this);
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
  Map<String, dynamic> toJson() => _$DeviceConnectedToJson(this);
  DeviceConnected({required this.name, required this.index, required this.address, this.displayName});
}

@JsonSerializable()
class DeviceDisconnected {
  int index = -1;
  factory DeviceDisconnected.fromJson(Map<String, dynamic> json) => _$DeviceDisconnectedFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceDisconnectedToJson(this);
  DeviceDisconnected();
}

@JsonSerializable()
class ClientRejected {
  String reason = "";
  factory ClientRejected.fromJson(Map<String, dynamic> json) => _$ClientRejectedFromJson(json);
  Map<String, dynamic> toJson() => _$ClientRejectedToJson(this);
  ClientRejected();
}

@JsonSerializable()
class EngineMessage {
  MessageVersion? messageVersion = null;
  EngineLog? engineLog = null;
  EngineStarted? engineStarted = null;
  EngineError? engineError = null;
  EngineStopped? engineStopped = null;
  ClientConnected? clientConnected = null;
  ClientDisconnected? clientDisconnected = null;
  DeviceConnected? deviceConnected = null;
  DeviceDisconnected? deviceDisconnected = null;
  ClientRejected? clientRejected = null;

  factory EngineMessage.fromJson(Map<String, dynamic> json) => _$EngineMessageFromJson(json);

  Map<String, dynamic> toJson() => _$EngineMessageToJson(this);

  EngineMessage();
}
