import 'package:bloc/bloc.dart';
import 'package:intiface_central/engine/engine_messages.dart';
import 'package:intiface_central/engine/engine_repository.dart';

abstract class EngineControlState {}

class EngineStartedState extends EngineControlState {}

class EngineStoppedState extends EngineControlState {}

class ClientConnectedState extends EngineControlState {
  final String clientName;
  ClientConnectedState(this.clientName);
}

class ClientDisconnectedState extends EngineControlState {}

class DeviceConnectedState extends EngineControlState {
  final String name;
  final String displayName;
  final String address;
  final String protocol;
  final int index;

  DeviceConnectedState(this.name, this.displayName, this.index, this.address, this.protocol);
}

class DeviceDisconnectedState extends EngineControlState {
  final int index;
  DeviceDisconnectedState(this.index);
}

class EngineError extends EngineControlState {}

class EngineControlEvent {}

class EngineControlEventStart extends EngineControlEvent {}

class EngineControlEventStop extends EngineControlEvent {}

class EngineControlBloc extends Bloc<EngineControlEvent, EngineControlState> {
  final EngineRepository _repo;

  EngineControlBloc(this._repo) : super(EngineStoppedState()) {
    on<EngineControlEventStart>((event, emit) async {
      var stream = _repo.messageStream;
      emit(EngineStartedState());
      await _repo.start();
      emit(ClientDisconnectedState());
      return emit.forEach(stream, onData: (EngineMessage message) {
        if (message.clientConnected != null) {
          return ClientConnectedState(message.clientConnected!.clientName);
        }
        if (message.clientDisconnected != null) {
          return ClientDisconnectedState();
        }
        if (message.deviceConnected != null) {
          return DeviceConnectedState(message.deviceConnected!.name, message.deviceConnected!.displayName!,
              message.deviceConnected!.index, message.deviceConnected!.address, "lovense");
        }
        if (message.deviceDisconnected != null) {
          return DeviceDisconnectedState(message.deviceConnected!.index);
        }
        return state;
      });
    });
    on<EngineControlEventStop>((event, emit) async {
      await _repo.stop();
      emit(EngineStoppedState());
    });
  }

  // TODO How to we detect/emit if the external process crashed on desktop?
}
