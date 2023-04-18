// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_messages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestEngineVersion _$RequestEngineVersionFromJson(
        Map<String, dynamic> json) =>
    RequestEngineVersion()..expectedVersion = json['expected_version'] as int;

Map<String, dynamic> _$RequestEngineVersionToJson(
        RequestEngineVersion instance) =>
    <String, dynamic>{
      'expected_version': instance.expectedVersion,
    };

Stop _$StopFromJson(Map<String, dynamic> json) => Stop();

Map<String, dynamic> _$StopToJson(Stop instance) => <String, dynamic>{};

IntifaceMessage _$IntifaceMessageFromJson(Map<String, dynamic> json) =>
    IntifaceMessage()
      ..requestEngineVersion = json['RequestEngineVersion'] == null
          ? null
          : RequestEngineVersion.fromJson(
              json['RequestEngineVersion'] as Map<String, dynamic>)
      ..stop = json['Stop'] == null
          ? null
          : Stop.fromJson(json['Stop'] as Map<String, dynamic>);

Map<String, dynamic> _$IntifaceMessageToJson(IntifaceMessage instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('RequestEngineVersion', instance.requestEngineVersion?.toJson());
  writeNotNull('Stop', instance.stop?.toJson());
  return val;
}

EngineVersion _$EngineVersionFromJson(Map<String, dynamic> json) =>
    EngineVersion()..version = json['version'] as String;

Map<String, dynamic> _$EngineVersionToJson(EngineVersion instance) =>
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

EngineLog _$EngineLogFromJson(Map<String, dynamic> json) => $checkedCreate(
      'EngineLog',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['message'],
        );
        final val = EngineLog();
        $checkedConvert('message', (v) => val.rawMessage = v as String?);
        return val;
      },
      fieldKeyMap: const {'rawMessage': 'message'},
    );

Map<String, dynamic> _$EngineLogToJson(EngineLog instance) => <String, dynamic>{
      'message': instance.rawMessage,
    };

EngineStarted _$EngineStartedFromJson(Map<String, dynamic> json) =>
    EngineStarted();

Map<String, dynamic> _$EngineStartedToJson(EngineStarted instance) =>
    <String, dynamic>{};

EngineServerCreated _$EngineServerCreatedFromJson(Map<String, dynamic> json) =>
    EngineServerCreated();

Map<String, dynamic> _$EngineServerCreatedToJson(
        EngineServerCreated instance) =>
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

SerializableUserConfigDeviceIdentifier
    _$SerializableUserConfigDeviceIdentifierFromJson(
            Map<String, dynamic> json) =>
        SerializableUserConfigDeviceIdentifier(
          json['address'] as String,
          json['protocol'] as String,
          json['identifier'] as String?,
        );

Map<String, dynamic> _$SerializableUserConfigDeviceIdentifierToJson(
    SerializableUserConfigDeviceIdentifier instance) {
  final val = <String, dynamic>{
    'address': instance.address,
    'protocol': instance.protocol,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('identifier', instance.identifier);
  return val;
}

DeviceConnected _$DeviceConnectedFromJson(Map<String, dynamic> json) =>
    DeviceConnected(
      name: json['name'] as String,
      index: json['index'] as int,
      identifier: SerializableUserConfigDeviceIdentifier.fromJson(
          json['identifier'] as Map<String, dynamic>),
      displayName: json['display_name'] as String?,
    );

Map<String, dynamic> _$DeviceConnectedToJson(DeviceConnected instance) =>
    <String, dynamic>{
      'name': instance.name,
      'index': instance.index,
      'identifier': instance.identifier,
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

EngineProviderLog _$EngineProviderLogFromJson(Map<String, dynamic> json) =>
    EngineProviderLog()
      ..timestamp = json['timestamp'] as String
      ..level = json['level'] as String
      ..message = json['message'] as String;

Map<String, dynamic> _$EngineProviderLogToJson(EngineProviderLog instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'level': instance.level,
      'message': instance.message,
    };

EngineMessage _$EngineMessageFromJson(Map<String, dynamic> json) =>
    EngineMessage()
      ..messageVersion = json['MessageVersion'] == null
          ? null
          : EngineVersion.fromJson(
              json['MessageVersion'] as Map<String, dynamic>)
      ..engineLog = json['EngineLog'] == null
          ? null
          : EngineLog.fromJson(json['EngineLog'] as Map<String, dynamic>)
      ..engineStarted = json['EngineStarted'] == null
          ? null
          : EngineStarted.fromJson(
              json['EngineStarted'] as Map<String, dynamic>)
      ..engineServerCreated = json['EngineServerCreated'] == null
          ? null
          : EngineServerCreated.fromJson(
              json['EngineServerCreated'] as Map<String, dynamic>)
      ..engineError = json['EngineError'] == null
          ? null
          : EngineError.fromJson(json['EngineError'] as Map<String, dynamic>)
      ..engineStopped = json['EngineStopped'] == null
          ? null
          : EngineStopped.fromJson(
              json['EngineStopped'] as Map<String, dynamic>)
      ..clientConnected = json['ClientConnected'] == null
          ? null
          : ClientConnected.fromJson(
              json['ClientConnected'] as Map<String, dynamic>)
      ..clientDisconnected = json['ClientDisconnected'] == null
          ? null
          : ClientDisconnected.fromJson(
              json['ClientDisconnected'] as Map<String, dynamic>)
      ..deviceConnected = json['DeviceConnected'] == null
          ? null
          : DeviceConnected.fromJson(
              json['DeviceConnected'] as Map<String, dynamic>)
      ..deviceDisconnected = json['DeviceDisconnected'] == null
          ? null
          : DeviceDisconnected.fromJson(
              json['DeviceDisconnected'] as Map<String, dynamic>)
      ..clientRejected = json['ClientRejected'] == null
          ? null
          : ClientRejected.fromJson(
              json['ClientRejected'] as Map<String, dynamic>)
      ..engineProviderLog = json['EngineProviderLog'] == null
          ? null
          : EngineProviderLog.fromJson(
              json['EngineProviderLog'] as Map<String, dynamic>);

Map<String, dynamic> _$EngineMessageToJson(EngineMessage instance) =>
    <String, dynamic>{
      'MessageVersion': instance.messageVersion,
      'EngineLog': instance.engineLog,
      'EngineStarted': instance.engineStarted,
      'EngineServerCreated': instance.engineServerCreated,
      'EngineError': instance.engineError,
      'EngineStopped': instance.engineStopped,
      'ClientConnected': instance.clientConnected,
      'ClientDisconnected': instance.clientDisconnected,
      'DeviceConnected': instance.deviceConnected,
      'DeviceDisconnected': instance.deviceDisconnected,
      'ClientRejected': instance.clientRejected,
      'EngineProviderLog': instance.engineProviderLog,
    };
