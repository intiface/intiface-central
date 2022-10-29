import 'package:bloc/bloc.dart';

class AppResetState {}

class AppResetInitialState extends AppResetState {}

class AppResetTriggerState extends AppResetState {}

class AppResetCubit extends Cubit<AppResetState> {
  AppResetCubit() : super(AppResetInitialState());

  void reset() {
    emit(AppResetTriggerState());
  }
}
