import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart';
import 'package:intiface_central/device/backdoor_connector.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:loggy/loggy.dart';

class DeviceManagerEvent {}

class DeviceManagerEngineStartedEvent extends DeviceManagerEvent {}

class DeviceManagerEngineStoppedEvent extends DeviceManagerEvent {}

class DeviceManagerDeviceAddedEvent extends DeviceManagerEvent {
  final ButtplugClientDevice device;

  DeviceManagerDeviceAddedEvent(this.device);
}

class DeviceManagerStartScanningEvent extends DeviceManagerEvent {}

class DeviceManagerStopScanningEvent extends DeviceManagerEvent {}

class DeviceManagerState {}

class DeviceManagerInitialState extends DeviceManagerState {}

class DeviceManagerDeviceOnlineState extends DeviceManagerState {
  final ButtplugClientDevice device;

  DeviceManagerDeviceOnlineState(this.device);
}

class DeviceManagerDeviceOfflineState extends DeviceManagerState {}

class DeviceManagerBloc extends Bloc<DeviceManagerEvent, DeviceManagerState> {
  ButtplugClient? _internalClient;
  final List<ButtplugClientDevice> _onlineDevices = [];
  final List<dynamic> _offlineDevices = [];
  final Stream<EngineControlState> _outputStream;
  final SendFunc _sendFunc;

  DeviceManagerBloc(this._outputStream, this._sendFunc) : super(DeviceManagerInitialState()) {
    on<DeviceManagerEngineStartedEvent>((event, emit) async {
      // Start our internal buttplug client.
      var connector = ButtplugBackdoorClientConnector(_outputStream, _sendFunc);
      var client = ButtplugClient("Backdoor Client");
      // This is infallible due to our connector.
      await client.connect(connector);
      // Hook up our event listeners so we register new online devices as we get device added messages.
      client.eventStream.listen((event) {
        if (event is DeviceAddedEvent) {
          logInfo("Device connected: ${event.device.deviceName}");
          _onlineDevices.add(event.device);
          add(DeviceManagerDeviceAddedEvent(event.device));
        }
      });
      _internalClient = client;
    });

    on<DeviceManagerDeviceAddedEvent>(((event, emit) => emit(DeviceManagerDeviceOnlineState(event.device))));

    on<DeviceManagerEngineStoppedEvent>((event, emit) {
      // Stop our internal buttplug client.
      if (_internalClient != null) {
        _internalClient!.disconnect();
        _internalClient = null;
      }
      // Move all devices to offline.
    });

    on<DeviceManagerStartScanningEvent>(((event, emit) async {
      if (_internalClient == null) {
        return;
      }
      await _internalClient!.startScanning();
    }));

    on<DeviceManagerStopScanningEvent>(((event, emit) async {
      if (_internalClient == null) {
        return;
      }
      await _internalClient!.stopScanning();
    }));
  }

  List<ButtplugClientDevice> get onlineDevices => _onlineDevices;
  List<dynamic> get offlineDevices => _offlineDevices;
}
