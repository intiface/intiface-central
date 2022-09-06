import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intiface_central/engine/engine_messages.dart';
import 'package:intiface_central/engine/engine_repository.dart';

part 'engine_control_status.dart';

class EngineControlEvent {}

class EngineControlEventStart extends EngineControlEvent {}

class EngineControlEventStop extends EngineControlEvent {}

class EngineControlBloc extends Bloc<EngineControlEvent, EngineControlState> {
  final EngineRepository _repo;

  EngineControlBloc(this._repo) : super(const EngineControlState()) {
    on<EngineControlEventStart>((event, emit) async {
      var stream = _repo.messageStream;
      emit(state.copyWith(status: EngineControlStatus.starting));
      await _repo.start();
      emit(state.copyWith(status: EngineControlStatus.clientDisconnected));
      return emit.forEach(stream, onData: (EngineMessage message) {
        print("$message");
        if (message.clientConnected != null) {
          print("CLIENT CONNECTED");
          return state.copyWith(status: EngineControlStatus.clientConnected);
        }
        return state;
      });
    });
    on<EngineControlEventStop>((event, emit) async {
      emit(state.copyWith(status: EngineControlStatus.starting));
      await _repo.stop();
      emit(state.copyWith(status: EngineControlStatus.clientDisconnected));
    });
  }

  // TODO How to we detect/emit if the external process crashed on desktop?
}
