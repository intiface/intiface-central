import 'package:bloc/bloc.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';

class IntifaceConfigurationState {}

class IntifaceConfigurationStateNone extends IntifaceConfigurationState {}

class UseLightThemeState extends IntifaceConfigurationState {
  final bool value;
  UseLightThemeState(this.value);
}

class UseSideNavigationBar extends IntifaceConfigurationState {
  final bool value;
  UseSideNavigationBar(this.value);
}

class StartServerOnStartupState extends IntifaceConfigurationState {
  final bool value;
  StartServerOnStartupState(this.value);
}

class ServerNameState extends IntifaceConfigurationState {
  final String value;
  ServerNameState(this.value);
}

class UseBluetoothLE extends IntifaceConfigurationState {
  final bool value;
  UseBluetoothLE(this.value);
}

class UseXInput extends IntifaceConfigurationState {
  final bool value;
  UseXInput(this.value);
}

class UseLovenseConnectService extends IntifaceConfigurationState {
  final bool value;
  UseLovenseConnectService(this.value);
}

class UseDeviceWebsocketServer extends IntifaceConfigurationState {
  final bool value;
  UseDeviceWebsocketServer(this.value);
}

class UseSerialPort extends IntifaceConfigurationState {
  final bool value;
  UseSerialPort(this.value);
}

class UseHID extends IntifaceConfigurationState {
  final bool value;
  UseHID(this.value);
}

class UseLovenseHIDDongle extends IntifaceConfigurationState {
  final bool value;
  UseLovenseHIDDongle(this.value);
}

class UseLovenseSerialDongle extends IntifaceConfigurationState {
  final bool value;
  UseLovenseSerialDongle(this.value);
}

class WebsocketServerAllInterfaces extends IntifaceConfigurationState {
  final bool value;
  WebsocketServerAllInterfaces(this.value);
}

class WebsocketServerPort extends IntifaceConfigurationState {
  final int value;
  WebsocketServerPort(this.value);
}

class UseCompactDisplay extends IntifaceConfigurationState {
  final bool value;
  UseCompactDisplay(this.value);
}

class CurrentNewsEtag extends IntifaceConfigurationState {
  final String value;
  CurrentNewsEtag(this.value);
}

class CurrentDeviceConfigEtag extends IntifaceConfigurationState {
  final String value;
  CurrentDeviceConfigEtag(this.value);
}

class CurrentDeviceConfigVersion extends IntifaceConfigurationState {
  final String value;
  CurrentDeviceConfigVersion(this.value);
}

class LatestAppVersion extends IntifaceConfigurationState {
  final String version;
  LatestAppVersion(this.version);
}

class CheckForUpdateOnStart extends IntifaceConfigurationState {
  final bool value;
  CheckForUpdateOnStart(this.value);
}

class UseProcessEngine extends IntifaceConfigurationState {
  final bool value;
  UseProcessEngine(this.value);
}

class ConfigurationReset extends IntifaceConfigurationState {}

class IntifaceConfigurationCubit extends Cubit<IntifaceConfigurationState> {
  final IntifaceConfigurationRepository _repo;
  IntifaceConfigurationCubit(this._repo) : super(IntifaceConfigurationStateNone());

  set startServerOnStartup(bool value) {
    _repo.startServerOnStartup = value;
    emit(StartServerOnStartupState(value));
  }

  bool get useSideNavigationBar {
    return _repo.useSideNavigationBar;
  }

  set useSideNavigationBar(value) {
    _repo.useSideNavigationBar = value;
    emit(UseSideNavigationBar(value));
  }

  bool get useLightTheme {
    return _repo.useLightTheme;
  }

  set useLightTheme(value) {
    _repo.useLightTheme = value;
    emit(UseLightThemeState(value));
  }

  bool get startServerOnStartup {
    return _repo.startServerOnStartup;
  }

  set serverName(String value) {
    _repo.serverName = value;
    emit(ServerNameState(value));
  }

  String get serverName {
    return _repo.serverName;
  }

  set useBluetoothLE(bool value) {
    _repo.useBluetoothLE = value;
    emit(UseBluetoothLE(value));
  }

  bool get useBluetoothLE {
    return _repo.useBluetoothLE;
  }

  set useXInput(bool value) {
    _repo.useXInput = value;
    emit(UseXInput(value));
  }

  bool get useXInput {
    return _repo.useXInput;
  }

  set useLovenseConnectService(bool value) {
    _repo.useLovenseConnectService = value;
    emit(UseLovenseConnectService(value));
  }

  bool get useLovenseConnectService {
    return _repo.useLovenseConnectService;
  }

  set useDeviceWebsocketServer(bool value) {
    _repo.useDeviceWebsocketServer = value;
    emit(UseDeviceWebsocketServer(value));
  }

  bool get useDeviceWebsocketServer {
    return _repo.useDeviceWebsocketServer;
  }

  set useSerialPort(bool value) {
    _repo.useSerialPort = value;
    emit(UseSerialPort(value));
  }

  bool get useSerialPort {
    return _repo.useSerialPort;
  }

  set useHID(bool value) {
    _repo.useHID = value;
    emit(UseHID(value));
  }

  bool get useHID {
    return _repo.useHID;
  }

  set useLovenseHIDDongle(bool value) {
    _repo.useLovenseHIDDongle = value;
    emit(UseLovenseHIDDongle(value));
  }

  bool get useLovenseHIDDongle {
    return _repo.useLovenseHIDDongle;
  }

  set useLovenseSerialDongle(bool value) {
    _repo.useLovenseSerialDongle = value;
    emit(UseLovenseSerialDongle(value));
  }

  bool get useLovenseSerialDongle {
    return _repo.useLovenseSerialDongle;
  }

  set websocketServerAllInterfaces(bool value) {
    _repo.websocketServerAllInterfaces = value;
    emit(WebsocketServerAllInterfaces(value));
  }

  bool get websocketServerAllInterfaces {
    return _repo.websocketServerAllInterfaces;
  }

  set websocketServerPort(int value) {
    _repo.websocketServerPort = value;
    emit(WebsocketServerPort(value));
  }

  int get websocketServerPort {
    return _repo.websocketServerPort;
  }

  set useCompactDisplay(bool value) {
    _repo.useCompactDisplay = value;
    emit(UseCompactDisplay(value));
  }

  bool get useCompactDisplay {
    return _repo.useCompactDisplay;
  }

  set currentNewsEtag(String value) {
    _repo.currentNewsEtag = value;
    emit(CurrentNewsEtag(value));
  }

  String get currentNewsEtag {
    return _repo.currentNewsEtag;
  }

  set currentDeviceConfigEtag(String value) {
    _repo.currentDeviceConfigEtag = value;
    emit(CurrentDeviceConfigEtag(value));
  }

  String get currentDeviceConfigEtag {
    return _repo.currentDeviceConfigEtag;
  }

  set currentAppVersion(String value) {
    _repo.currentAppVersion = value;
    // Nothing to emit here, this will never change *while* we're running.
  }

  String get currentAppVersion {
    return _repo.currentAppVersion;
  }

  set latestAppVersion(String value) {
    _repo.latestAppVersion = value;
    emit(LatestAppVersion(value));
  }

  String get latestAppVersion {
    return _repo.latestAppVersion;
  }

  set currentDeviceConfigVersion(String value) {
    _repo.currentDeviceConfigVersion = value;
    emit(CurrentDeviceConfigVersion(value));
  }

  String get currentDeviceConfigVersion {
    return _repo.currentDeviceConfigVersion;
  }

  Future<bool> reset() async {
    var result = await _repo.reset();
    emit(ConfigurationReset());
    return result;
  }

  set checkForUpdateOnStart(bool value) {
    _repo.checkForUpdateOnStart = value;
    emit(CheckForUpdateOnStart(value));
  }

  bool get checkForUpdateOnStart {
    return _repo.checkForUpdateOnStart;
  }

  set useProcessEngine(bool value) {
    _repo.useProcessEngine = value;
    emit(UseProcessEngine(value));
  }

  bool get useProcessEngine {
    return _repo.useProcessEngine;
  }
}
