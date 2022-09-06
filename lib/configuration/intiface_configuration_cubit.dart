import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intiface_central/configuration/intiface_configuration_provider.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';

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

class IntifaceConfigurationCubit extends Cubit<IntifaceConfigurationState> {
  final IntifaceConfigurationRepository _repo;
  IntifaceConfigurationCubit(this._repo) : super(const IntifaceConfigurationState());

  void serverName(String value) {
    _repo.serverName = value;
    emit(state.copyWith(status: IntifaceConfigurationStatus.serverName));
  }
}
