import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intiface_central/engine/engine_provider.dart';
import 'package:json_annotation/json_annotation.dart';

part 'engine_control_cubit.g.dart';
part 'engine_control_status.dart';

class EngineControlCubit extends Cubit<EngineControlState> {
  final EngineProvider _provider;

  EngineControlCubit(this._provider) : super(EngineControlState());

  Future<void> start(EngineProviderStartParameters parameters) async {
    emit(state.copyWith(status: EngineControlStatus.starting));
    await _provider.start(parameters);
    emit(state.copyWith(status: EngineControlStatus.running));
  }

  Future<void> stop() async {
    await _provider.stop();
    emit(state.copyWith(status: EngineControlStatus.stopped));
  }

  // TODO How to we detect/emit if the external process crashed on desktop?
}
