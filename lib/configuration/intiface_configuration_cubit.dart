import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';

class IntifaceConfigurationState {}

class IntifaceConfigurationStateNone extends IntifaceConfigurationState {}

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

class IntifaceConfigurationCubit extends Cubit<IntifaceConfigurationState> {
  final IntifaceConfigurationRepository _repo;
  IntifaceConfigurationCubit(this._repo) : super(IntifaceConfigurationStateNone());

  set startServerOnStartup(bool value) {
    _repo.startServerOnStartup = value;
    emit(StartServerOnStartupState(value));
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
    _repo.withBluetoothLE = value;
    emit(UseBluetoothLE(value));
  }

  bool get useBluetoothLE {
    return _repo.withBluetoothLE;
  }

  set useXInput(bool value) {
    _repo.withXInput = value;
    emit(UseXInput(value));
  }

  bool get useXInput {
    return _repo.withXInput;
  }

  set useLovenseConnectService(bool value) {
    _repo.withLovenseConnectService = value;
    emit(UseLovenseConnectService(value));
  }

  bool get useLovenseConnectService {
    return _repo.withLovenseConnectService;
  }

  set useDeviceWebsocketServer(bool value) {
    _repo.withDeviceWebsocketServer = value;
    emit(UseDeviceWebsocketServer(value));
  }

  bool get useDeviceWebsocketServer {
    return _repo.withDeviceWebsocketServer;
  }

  set useSerialPort(bool value) {
    _repo.withSerialPort = value;
    emit(UseSerialPort(value));
  }

  bool get useSerialPort {
    return _repo.withSerialPort;
  }

  set useHID(bool value) {
    _repo.withHID = value;
    emit(UseHID(value));
  }

  bool get useHID {
    return _repo.withHID;
  }

  set useLovenseHIDDongle(bool value) {
    _repo.withLovenseHIDDongle = value;
    emit(UseLovenseHIDDongle(value));
  }

  bool get useLovenseHIDDongle {
    return _repo.withLovenseHIDDongle;
  }

  set useLovenseSerialDongle(bool value) {
    _repo.withLovenseSerialDongle = value;
    emit(UseLovenseSerialDongle(value));
  }

  bool get useLovenseSerialDongle {
    return _repo.withLovenseSerialDongle;
  }
}

/*
enum IntifaceConfigurationStatus {
  none,
  serverName,
  serverMaxPingTime,
  websocketServerAllInterfaces,
  websocketServerPort,
  serverLogLevel,
  usePrereleaseEngine,
  checkForUpdateOnStart,
  startServerOnStartup,
  crashReporting,
  showNotifications,
  hasRunFirstUse,
  showExtendedUI,
  allowRawMessages,
  unreadNews,
  withBluetoothLE,
  withXInput,
  withLovenseConnectService,
  withDeviceWebsocketServer,
  withSerialPort,
  withHID,
  withLovenseHIDDongle,
  withLovenseSerialDongle,
  ;
}

class IntifaceConfigurationState extends Equatable {
  const IntifaceConfigurationState({
    this.status = IntifaceConfigurationStatus.none,
  });

  final IntifaceConfigurationStatus status;

  IntifaceConfigurationState copyWith({
    IntifaceConfigurationStatus? status,
  }) {
    return IntifaceConfigurationState(
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [status];
}
*/
