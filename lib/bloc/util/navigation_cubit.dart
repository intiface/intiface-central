import 'package:bloc/bloc.dart';

class NavigationState {}

class NavigationStateAppControl extends NavigationState {}

class NavigationStateSettings extends NavigationState {}

class NavigationStateDeviceConfig extends NavigationState {}

class NavigationStateDeviceControl extends NavigationState {}

class NavigationStateLogs extends NavigationState {}

class NavigationStateNews extends NavigationState {}

class NavigationStateAbout extends NavigationState {}

class NavigationStateHelp extends NavigationState {}

class NavigationStateSendLogs extends NavigationState {}

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationStateNews());

  void goAppControl() {
    emit(NavigationStateAppControl());
  }

  void goSettings() {
    emit(NavigationStateSettings());
  }

  void goNews() {
    emit(NavigationStateNews());
  }

  void goDeviceControl() {
    emit(NavigationStateDeviceControl());
  }

  void goDeviceConfig() {
    emit(NavigationStateDeviceConfig());
  }

  void goLogs() {
    emit(NavigationStateLogs());
  }

  void goAbout() {
    emit(NavigationStateAbout());
  }

  void goSendLogs() {
    emit(NavigationStateSendLogs());
  }
}
