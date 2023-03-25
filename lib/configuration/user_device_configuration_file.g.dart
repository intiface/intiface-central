// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_device_configuration_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDeviceConfigurationFileVersion _$UserDeviceConfigurationFileVersionFromJson(
        Map<String, dynamic> json) =>
    UserDeviceConfigurationFileVersion()
      ..major = json['major'] as int
      ..minor = json['minor'] as int;

Map<String, dynamic> _$UserDeviceConfigurationFileVersionToJson(
        UserDeviceConfigurationFileVersion instance) =>
    <String, dynamic>{
      'major': instance.major,
      'minor': instance.minor,
    };

UserDeviceConfigurationFile _$UserDeviceConfigurationFileFromJson(
        Map<String, dynamic> json) =>
    UserDeviceConfigurationFile()
      ..version = UserDeviceConfigurationFileVersion.fromJson(
          json['version'] as Map<String, dynamic>)
      ..userConfigs = UserDeviceConfigurationFileContent.fromJson(
          json['user-configs'] as Map<String, dynamic>);

Map<String, dynamic> _$UserDeviceConfigurationFileToJson(
        UserDeviceConfigurationFile instance) =>
    <String, dynamic>{
      'version': instance.version,
      'user-configs': instance.userConfigs,
    };

UserDeviceConfigurationFileContent _$UserDeviceConfigurationFileContentFromJson(
        Map<String, dynamic> json) =>
    UserDeviceConfigurationFileContent()
      ..specifiers = (json['specifiers'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, UserProtocolDefinition.fromJson(e as Map<String, dynamic>)),
      )
      ..devices = (json['devices'] as List<dynamic>)
          .map((e) => UserConfigDeviceConverter.instance.fromJson(e as List))
          .toList();

Map<String, dynamic> _$UserDeviceConfigurationFileContentToJson(
        UserDeviceConfigurationFileContent instance) =>
    <String, dynamic>{
      'specifiers': instance.specifiers,
      'devices': instance.devices
          .map(UserConfigDeviceConverter.instance.toJson)
          .toList(),
    };

WebsocketProtocolDefinition _$WebsocketProtocolDefinitionFromJson(
        Map<String, dynamic> json) =>
    WebsocketProtocolDefinition()
      ..names =
          (json['names'] as List<dynamic>).map((e) => e as String).toList();

Map<String, dynamic> _$WebsocketProtocolDefinitionToJson(
        WebsocketProtocolDefinition instance) =>
    <String, dynamic>{
      'names': instance.names,
    };

UserProtocolDefinition _$UserProtocolDefinitionFromJson(
        Map<String, dynamic> json) =>
    UserProtocolDefinition()
      ..websocket = WebsocketProtocolDefinition.fromJson(
          json['websocket'] as Map<String, dynamic>);

Map<String, dynamic> _$UserProtocolDefinitionToJson(
        UserProtocolDefinition instance) =>
    <String, dynamic>{
      'websocket': instance.websocket,
    };

ServerDeviceIdentifier _$ServerDeviceIdentifierFromJson(
        Map<String, dynamic> json) =>
    ServerDeviceIdentifier(
      json['address'] as String,
      json['protocol'] as String,
      json['identifier'] as String,
    );

Map<String, dynamic> _$ServerDeviceIdentifierToJson(
        ServerDeviceIdentifier instance) =>
    <String, dynamic>{
      'address': instance.address,
      'protocol': instance.protocol,
      'identifier': instance.identifier,
    };

UserConfig _$UserConfigFromJson(Map<String, dynamic> json) => UserConfig()
  ..displayName = json['displayName'] as String?
  ..allow = json['allow'] as bool?
  ..deny = json['deny'] as bool?
  ..index = json['index'] as int?
  ..messageAttributes = json['messageAttributes'] == null
      ? null
      : ServerGenericDeviceMessageAttributes.fromJson(
          json['messageAttributes'] as Map<String, dynamic>);

Map<String, dynamic> _$UserConfigToJson(UserConfig instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'allow': instance.allow,
      'deny': instance.deny,
      'index': instance.index,
      'messageAttributes': instance.messageAttributes,
    };

ServerGenericDeviceMessageAttributes
    _$ServerGenericDeviceMessageAttributesFromJson(Map<String, dynamic> json) =>
        ServerGenericDeviceMessageAttributes()
          ..featureDescriptor = json['FeatureDescriptor'] as String
          ..actuatorType =
              $enumDecode(_$ActuatorTypeEnumMap, json['ActuatorType'])
          ..stepCount = (json['StepCount'] as List<dynamic>)
              .map((e) => e as int)
              .toList();

Map<String, dynamic> _$ServerGenericDeviceMessageAttributesToJson(
        ServerGenericDeviceMessageAttributes instance) =>
    <String, dynamic>{
      'FeatureDescriptor': instance.featureDescriptor,
      'ActuatorType': _$ActuatorTypeEnumMap[instance.actuatorType]!,
      'StepCount': instance.stepCount,
    };

const _$ActuatorTypeEnumMap = {
  ActuatorType.Vibrate: 'Vibrate',
  ActuatorType.Rotate: 'Rotate',
  ActuatorType.Oscillate: 'Oscillate',
  ActuatorType.Constrict: 'Constrict',
  ActuatorType.Inflate: 'Inflate',
  ActuatorType.Position: 'Position',
};

SensorDeviceMessageAttributes _$SensorDeviceMessageAttributesFromJson(
        Map<String, dynamic> json) =>
    SensorDeviceMessageAttributes()
      ..featureDescriptor = json['FeatureDescriptor'] as String
      ..sensorType = $enumDecode(_$SensorTypeEnumMap, json['SensorType'])
      ..sensorRange = (json['SensorRange'] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((e) => e as int).toList())
          .toList();

Map<String, dynamic> _$SensorDeviceMessageAttributesToJson(
        SensorDeviceMessageAttributes instance) =>
    <String, dynamic>{
      'FeatureDescriptor': instance.featureDescriptor,
      'SensorType': _$SensorTypeEnumMap[instance.sensorType]!,
      'SensorRange': instance.sensorRange,
    };

const _$SensorTypeEnumMap = {
  SensorType.Battery: 'Battery',
  SensorType.RSSI: 'RSSI',
  SensorType.Button: 'Button',
  SensorType.Pressure: 'Pressure',
  SensorType.Temperature: 'Temperature',
};

NullDeviceMessageAttributes _$NullDeviceMessageAttributesFromJson(
        Map<String, dynamic> json) =>
    NullDeviceMessageAttributes();

Map<String, dynamic> _$NullDeviceMessageAttributesToJson(
        NullDeviceMessageAttributes instance) =>
    <String, dynamic>{};

RawDeviceMessageAttributes _$RawDeviceMessageAttributesFromJson(
        Map<String, dynamic> json) =>
    RawDeviceMessageAttributes()
      ..endpoints = (json['Endpoints'] as List<dynamic>)
          .map((e) => $enumDecode(_$EndpointEnumMap, e))
          .toList();

Map<String, dynamic> _$RawDeviceMessageAttributesToJson(
        RawDeviceMessageAttributes instance) =>
    <String, dynamic>{
      'Endpoints':
          instance.endpoints.map((e) => _$EndpointEnumMap[e]!).toList(),
    };

const _$EndpointEnumMap = {
  Endpoint.Command: 'Command',
  Endpoint.Firmware: 'Firmware',
  Endpoint.Rx: 'Rx',
  Endpoint.RxAccel: 'RxAccel',
  Endpoint.RxBLEBattery: 'RxBLEBattery',
  Endpoint.RxBLEModel: 'RxBLEModel',
  Endpoint.RxPressure: 'RxPressure',
  Endpoint.RxTouch: 'RxTouch',
  Endpoint.Tx: 'Tx',
  Endpoint.TxMode: 'TxMode',
  Endpoint.TxShock: 'TxShock',
  Endpoint.TxVibrate: 'TxVibrate',
  Endpoint.TxVendorControl: 'TxVendorControl',
  Endpoint.Whitelist: 'Whitelist',
  Endpoint.Generic0: 'Generic0',
  Endpoint.Generic1: 'Generic1',
  Endpoint.Generic2: 'Generic2',
  Endpoint.Generic3: 'Generic3',
  Endpoint.Generic4: 'Generic4',
  Endpoint.Generic5: 'Generic5',
  Endpoint.Generic6: 'Generic6',
  Endpoint.Generic7: 'Generic7',
  Endpoint.Generic8: 'Generic8',
  Endpoint.Generic9: 'Generic9',
  Endpoint.Generic10: 'Generic10',
  Endpoint.Generic11: 'Generic11',
  Endpoint.Generic12: 'Generic12',
  Endpoint.Generic13: 'Generic13',
  Endpoint.Generic14: 'Generic14',
  Endpoint.Generic15: 'Generic15',
  Endpoint.Generic16: 'Generic16',
  Endpoint.Generic17: 'Generic17',
  Endpoint.Generic18: 'Generic18',
  Endpoint.Generic19: 'Generic19',
  Endpoint.Generic20: 'Generic20',
  Endpoint.Generic21: 'Generic21',
  Endpoint.Generic22: 'Generic22',
  Endpoint.Generic23: 'Generic23',
  Endpoint.Generic24: 'Generic24',
  Endpoint.Generic25: 'Generic25',
  Endpoint.Generic26: 'Generic26',
  Endpoint.Generic27: 'Generic27',
  Endpoint.Generic28: 'Generic28',
  Endpoint.Generic29: 'Generic29',
  Endpoint.Generic30: 'Generic30',
  Endpoint.Generic31: 'Generic31',
};

ServerDeviceMessageAttributes _$ServerDeviceMessageAttributesFromJson(
        Map<String, dynamic> json) =>
    ServerDeviceMessageAttributes()
      ..scalarCmd = (json['ScalarCmd'] as List<dynamic>?)
          ?.map((e) => ServerGenericDeviceMessageAttributes.fromJson(
              e as Map<String, dynamic>))
          .toList()
      ..rotateCmd = (json['RotateCmd'] as List<dynamic>?)
          ?.map((e) => ServerGenericDeviceMessageAttributes.fromJson(
              e as Map<String, dynamic>))
          .toList()
      ..linearCmd = (json['LinearCmd'] as List<dynamic>?)
          ?.map((e) => ServerGenericDeviceMessageAttributes.fromJson(
              e as Map<String, dynamic>))
          .toList()
      ..sensorReadCmd = (json['SensorReadCmd'] as List<dynamic>?)
          ?.map((e) =>
              SensorDeviceMessageAttributes.fromJson(e as Map<String, dynamic>))
          .toList()
      ..sensorSubscribeCmd = (json['SensorSubscribeCmd'] as List<dynamic>?)
          ?.map((e) =>
              SensorDeviceMessageAttributes.fromJson(e as Map<String, dynamic>))
          .toList()
      ..stopDeviceCmd = NullDeviceMessageAttributes.fromJson(
          json['StopDeviceCmd'] as Map<String, dynamic>)
      ..rawReadCmd = (json['RawReadCmd'] as List<dynamic>?)
          ?.map((e) =>
              RawDeviceMessageAttributes.fromJson(e as Map<String, dynamic>))
          .toList()
      ..rawWriteCmd = (json['RawWriteCmd'] as List<dynamic>?)
          ?.map((e) =>
              RawDeviceMessageAttributes.fromJson(e as Map<String, dynamic>))
          .toList()
      ..rawSubscribeCmd = (json['RawSubscribeCmd'] as List<dynamic>?)
          ?.map((e) =>
              RawDeviceMessageAttributes.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$ServerDeviceMessageAttributesToJson(
    ServerDeviceMessageAttributes instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('ScalarCmd', instance.scalarCmd);
  writeNotNull('RotateCmd', instance.rotateCmd);
  writeNotNull('LinearCmd', instance.linearCmd);
  writeNotNull('SensorReadCmd', instance.sensorReadCmd);
  writeNotNull('SensorSubscribeCmd', instance.sensorSubscribeCmd);
  val['StopDeviceCmd'] = instance.stopDeviceCmd;
  writeNotNull('RawReadCmd', instance.rawReadCmd);
  writeNotNull('RawWriteCmd', instance.rawWriteCmd);
  writeNotNull('RawSubscribeCmd', instance.rawSubscribeCmd);
  return val;
}
