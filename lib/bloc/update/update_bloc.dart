import 'package:bloc/bloc.dart';
import 'package:intiface_central/bloc/update/update_repository.dart';

abstract class UpdateState {}

class UpdaterInitialized extends UpdateState {}

class UpdateRunning extends UpdateState {}

class UpdateFinished extends UpdateState {}

class NewsUpdateRetrieved extends UpdateState {
  final String _version;

  NewsUpdateRetrieved(this._version);

  String get version => _version;
}

class DeviceConfigUpdateRetrieved extends UpdateState {
  final String _version;

  DeviceConfigUpdateRetrieved(this._version);

  String get version => _version;
}

class IncompatibleIntifaceEngineUpdate extends UpdateState {
  final String _version;

  IncompatibleIntifaceEngineUpdate(this._version);

  String get version => _version;
}

class IntifaceEngineUpdateRetrieved extends UpdateState {
  final String _version;

  IntifaceEngineUpdateRetrieved(this._version);

  String get version => _version;
}

class IntifaceCentralUpdateAvailable extends UpdateState {
  final String _version;

  IntifaceCentralUpdateAvailable(this._version);

  String get version => _version;
}

abstract class UpdateEvent {}

class RunUpdate extends UpdateEvent {}

class UpdateBloc extends Bloc<UpdateEvent, UpdateState> {
  final UpdateRepository _repo;

  UpdateBloc(this._repo) : super(UpdaterInitialized()) {
    on<RunUpdate>(((event, emit) async {
      emit(UpdateRunning());
      var events = await _repo.update();
      events.forEach(emit.call);
      emit(UpdateFinished());
    }));
  }
}
