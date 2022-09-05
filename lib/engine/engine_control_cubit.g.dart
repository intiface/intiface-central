// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_control_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EngineControlState _$EngineControlStateFromJson(Map<String, dynamic> json) =>
    EngineControlState(
      status:
          $enumDecodeNullable(_$EngineControlStatusEnumMap, json['status']) ??
              EngineControlStatus.stopped,
    );

Map<String, dynamic> _$EngineControlStateToJson(EngineControlState instance) =>
    <String, dynamic>{
      'status': _$EngineControlStatusEnumMap[instance.status]!,
    };

const _$EngineControlStatusEnumMap = {
  EngineControlStatus.stopped: 'stopped',
  EngineControlStatus.starting: 'starting',
  EngineControlStatus.running: 'running',
  EngineControlStatus.error: 'error',
};
