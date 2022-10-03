// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceConfigFileVersion _$DeviceConfigFileVersionFromJson(
        Map<String, dynamic> json) =>
    DeviceConfigFileVersion()
      ..major = json['major'] as int
      ..minor = json['minor'] as int;

Map<String, dynamic> _$DeviceConfigFileVersionToJson(
        DeviceConfigFileVersion instance) =>
    <String, dynamic>{
      'major': instance.major,
      'minor': instance.minor,
    };

DeviceConfigFile _$DeviceConfigFileFromJson(Map<String, dynamic> json) =>
    DeviceConfigFile()
      ..version = json['version'] == null
          ? null
          : DeviceConfigFileVersion.fromJson(
              json['version'] as Map<String, dynamic>);

Map<String, dynamic> _$DeviceConfigFileToJson(DeviceConfigFile instance) =>
    <String, dynamic>{
      'version': instance.version,
    };
