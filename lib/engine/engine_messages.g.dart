// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_messages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageVersion _$MessageVersionFromJson(Map<String, dynamic> json) =>
    MessageVersion()..version = json['version'] as int;

Map<String, dynamic> _$MessageVersionToJson(MessageVersion instance) =>
    <String, dynamic>{
      'version': instance.version,
    };

EngineLogMessageSpan _$EngineLogMessageSpanFromJson(
        Map<String, dynamic> json) =>
    EngineLogMessageSpan()..name = json['name'] as String?;

Map<String, dynamic> _$EngineLogMessageSpanToJson(
        EngineLogMessageSpan instance) =>
    <String, dynamic>{
      'name': instance.name,
    };

EngineLogMessageFields _$EngineLogMessageFieldsFromJson(
        Map<String, dynamic> json) =>
    EngineLogMessageFields()
      ..message = json['message'] as String
      ..target = json['target'] as String
      ..span = json['span'] == null
          ? null
          : EngineLogMessageSpan.fromJson(json['span'] as Map<String, dynamic>)
      ..spans = (json['spans'] as List<dynamic>?)
          ?.map((e) => EngineLogMessageSpan.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$EngineLogMessageFieldsToJson(
        EngineLogMessageFields instance) =>
    <String, dynamic>{
      'message': instance.message,
      'target': instance.target,
      'span': instance.span,
      'spans': instance.spans,
    };

EngineLogMessage _$EngineLogMessageFromJson(Map<String, dynamic> json) =>
    EngineLogMessage()
      ..timestamp = json['timestamp'] as String
      ..level = json['level'] as String
      ..fields = json['fields'] as Map<String, dynamic>
      ..target = json['target'] as String;

Map<String, dynamic> _$EngineLogMessageToJson(EngineLogMessage instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'level': instance.level,
      'fields': instance.fields,
      'target': instance.target,
    };

EngineLog _$EngineLogFromJson(Map<String, dynamic> json) => EngineLog()
  ..message = json['message'] == null
      ? null
      : EngineLogMessage.fromJson(json['message'] as Map<String, dynamic>);

Map<String, dynamic> _$EngineLogToJson(EngineLog instance) => <String, dynamic>{
      'message': instance.message,
    };

EngineStarted _$EngineStartedFromJson(Map<String, dynamic> json) =>
    EngineStarted();

Map<String, dynamic> _$EngineStartedToJson(EngineStarted instance) =>
    <String, dynamic>{};

EngineError _$EngineErrorFromJson(Map<String, dynamic> json) =>
    EngineError()..error = json['error'] as String;

Map<String, dynamic> _$EngineErrorToJson(EngineError instance) =>
    <String, dynamic>{
      'error': instance.error,
    };

EngineStopped _$EngineStoppedFromJson(Map<String, dynamic> json) =>
    EngineStopped();

Map<String, dynamic> _$EngineStoppedToJson(EngineStopped instance) =>
    <String, dynamic>{};

ClientConnected _$ClientConnectedFromJson(Map<String, dynamic> json) =>
    ClientConnected()..clientName = json['client_name'] as String;

Map<String, dynamic> _$ClientConnectedToJson(ClientConnected instance) =>
    <String, dynamic>{
      'client_name': instance.clientName,
    };

ClientDisconnected _$ClientDisconnectedFromJson(Map<String, dynamic> json) =>
    ClientDisconnected();

Map<String, dynamic> _$ClientDisconnectedToJson(ClientDisconnected instance) =>
    <String, dynamic>{};

DeviceConnected _$DeviceConnectedFromJson(Map<String, dynamic> json) =>
    DeviceConnected(
      name: json['name'] as String,
      index: json['index'] as int,
      address: json['address'] as String,
      displayName: json['display_name'] as String?,
    );

Map<String, dynamic> _$DeviceConnectedToJson(DeviceConnected instance) =>
    <String, dynamic>{
      'name': instance.name,
      'index': instance.index,
      'address': instance.address,
      'display_name': instance.displayName,
    };

DeviceDisconnected _$DeviceDisconnectedFromJson(Map<String, dynamic> json) =>
    DeviceDisconnected()..index = json['index'] as int;

Map<String, dynamic> _$DeviceDisconnectedToJson(DeviceDisconnected instance) =>
    <String, dynamic>{
      'index': instance.index,
    };

ClientRejected _$ClientRejectedFromJson(Map<String, dynamic> json) =>
    ClientRejected()..reason = json['reason'] as String;

Map<String, dynamic> _$ClientRejectedToJson(ClientRejected instance) =>
    <String, dynamic>{
      'reason': instance.reason,
    };

EngineMessage _$EngineMessageFromJson(Map<String, dynamic> json) =>
    EngineMessage()
      ..messageVersion = json['messageVersion'] == null
          ? null
          : MessageVersion.fromJson(
              json['messageVersion'] as Map<String, dynamic>)
      ..engineLog = json['engineLog'] == null
          ? null
          : EngineLog.fromJson(json['engineLog'] as Map<String, dynamic>)
      ..engineStarted = json['engineStarted'] == null
          ? null
          : EngineStarted.fromJson(
              json['engineStarted'] as Map<String, dynamic>)
      ..engineError = json['engineError'] == null
          ? null
          : EngineError.fromJson(json['engineError'] as Map<String, dynamic>)
      ..engineStopped = json['engineStopped'] == null
          ? null
          : EngineStopped.fromJson(
              json['engineStopped'] as Map<String, dynamic>)
      ..clientConnected = json['clientConnected'] == null
          ? null
          : ClientConnected.fromJson(
              json['clientConnected'] as Map<String, dynamic>)
      ..clientDisconnected = json['clientDisconnected'] == null
          ? null
          : ClientDisconnected.fromJson(
              json['clientDisconnected'] as Map<String, dynamic>)
      ..deviceConnected = json['deviceConnected'] == null
          ? null
          : DeviceConnected.fromJson(
              json['deviceConnected'] as Map<String, dynamic>)
      ..deviceDisconnected = json['deviceDisconnected'] == null
          ? null
          : DeviceDisconnected.fromJson(
              json['deviceDisconnected'] as Map<String, dynamic>)
      ..clientRejected = json['clientRejected'] == null
          ? null
          : ClientRejected.fromJson(
              json['clientRejected'] as Map<String, dynamic>);

Map<String, dynamic> _$EngineMessageToJson(EngineMessage instance) =>
    <String, dynamic>{
      'messageVersion': instance.messageVersion,
      'engineLog': instance.engineLog,
      'engineStarted': instance.engineStarted,
      'engineError': instance.engineError,
      'engineStopped': instance.engineStopped,
      'clientConnected': instance.clientConnected,
      'clientDisconnected': instance.clientDisconnected,
      'deviceConnected': instance.deviceConnected,
      'deviceDisconnected': instance.deviceDisconnected,
      'clientRejected': instance.clientRejected,
    };
