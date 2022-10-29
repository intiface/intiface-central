import 'package:bloc/bloc.dart';
import 'package:loggy/loggy.dart';

class ErrorNotifierState {}

class ErrorNotifierInitialState extends ErrorNotifierState {}

class ErrorNotifierTriggerState extends ErrorNotifierState {
  final LogRecord _record;
  ErrorNotifierTriggerState(this._record) : super();
  get record => _record;
}

class ErrorNotifierClearState extends ErrorNotifierState {}

class ErrorNotifierCubit extends Cubit<ErrorNotifierState> {
  ErrorNotifierCubit() : super(ErrorNotifierInitialState());

  void emitError(LogRecord record) {
    emit(ErrorNotifierTriggerState(record));
  }

  void clearError() {
    emit(ErrorNotifierClearState());
  }
}
