import 'package:bloc/bloc.dart';

class NavigationState {}

class NavigationStateSettings extends NavigationState {}

class NavigationStateDevices extends NavigationState {}

class NavigationStateLogs extends NavigationState {}

class NavigationStateNews extends NavigationState {}

class NavigationStateAbout extends NavigationState {}

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationStateNews());

  void goSettings() {
    emit(NavigationStateSettings());
  }

  void goNews() {
    emit(NavigationStateNews());
  }

  void goDevices() {
    emit(NavigationStateDevices());
  }

  void goLogs() {
    emit(NavigationStateLogs());
  }

  void goAbout() {
    emit(NavigationStateAbout());
  }
}
