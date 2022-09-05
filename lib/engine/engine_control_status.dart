part of 'engine_control_cubit.dart';

enum EngineControlStatus { stopped, starting, running, error }

extension EngineControlStatusX on EngineControlStatus {
  bool get isStopped => this == EngineControlStatus.stopped;
  bool get isStarting => this == EngineControlStatus.starting;
  bool get isRunning => this == EngineControlStatus.running;
  bool get isError => this == EngineControlStatus.error;
}

@JsonSerializable()
class EngineControlState extends Equatable {
  EngineControlState({
    this.status = EngineControlStatus.stopped,
  });

  final EngineControlStatus status;

  EngineControlState copyWith({
    EngineControlStatus? status,
  }) {
    return EngineControlState(
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => _$EngineControlStateToJson(this);

  @override
  List<Object?> get props => [status];
}
