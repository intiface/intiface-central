import 'package:bloc/bloc.dart';

class NavigationState {}

class NavigationStateSettings extends NavigationState {}

class NavigationStateDeviceConfig extends NavigationState {}

class NavigationStateDeviceControl extends NavigationState {}

class NavigationStateLogs extends NavigationState {}

class NavigationStateNews extends NavigationState {}

class NavigationStateAbout extends NavigationState {}

class NavigationStateHelp extends NavigationState {}

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationStateNews());

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

  void goHelp() {
    emit(NavigationStateHelp());
  }
}
