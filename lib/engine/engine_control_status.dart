part of 'engine_control_bloc.dart';

enum EngineControlStatus {
  stopped,
  starting,
  clientDisconnected,
  clientConnected,
  error;

  bool get isStopped => this == EngineControlStatus.stopped;
  bool get isStarting => this == EngineControlStatus.starting;
  bool get isRunning => this == EngineControlStatus.clientConnected || this == EngineControlStatus.clientDisconnected;
  bool get isClientConnected => this == EngineControlStatus.clientConnected;
  bool get isClientDisconnected => this == EngineControlStatus.clientDisconnected;
  bool get isError => this == EngineControlStatus.error;
}

class EngineControlState extends Equatable {
  const EngineControlState({
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

  @override
  List<Object?> get props => [status];
}
