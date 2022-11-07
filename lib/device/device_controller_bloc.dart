import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart';
import 'package:intiface_central/device/backdoor_connector.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:loggy/loggy.dart';

class DeviceControllerEvent {}

class DeviceControllerEngineStartedEvent extends DeviceControllerEvent {}

class DeviceControllerEngineStoppedEvent extends DeviceControllerEvent {}

class DeviceControllerDeviceAddedEvent extends DeviceControllerEvent {
  final ButtplugClientDevice device;

  DeviceControllerDeviceAddedEvent(this.device);
}

class DeviceControllerStartScanningEvent extends DeviceControllerEvent {}

class DeviceControllerStopScanningEvent extends DeviceControllerEvent {}

class DeviceControllerState {}

class DeviceControllerInitialState extends DeviceControllerState {}

class DeviceControllerDeviceOnlineState extends DeviceControllerState {
  final ButtplugClientDevice device;

  DeviceControllerDeviceOnlineState(this.device);
}

class DeviceControllerDeviceOfflineState extends DeviceControllerState {}

class DeviceControllerBloc extends Bloc<DeviceControllerEvent, DeviceControllerState> {
  ButtplugClient? _internalClient;
  final List<ButtplugClientDevice> _onlineDevices = [];
  final List<dynamic> _offlineDevices = [];
  final Stream<EngineControlState> _outputStream;
  final SendFunc _sendFunc;

  DeviceControllerBloc(this._outputStream, this._sendFunc) : super(DeviceControllerInitialState()) {
    on<DeviceControllerEngineStartedEvent>((event, emit) async {
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
          add(DeviceControllerDeviceAddedEvent(event.device));
        }
      });
      _internalClient = client;
    });

    on<DeviceControllerDeviceAddedEvent>(((event, emit) => emit(DeviceControllerDeviceOnlineState(event.device))));

    on<DeviceControllerEngineStoppedEvent>((event, emit) {
      // Stop our internal buttplug client.
      if (_internalClient != null) {
        _internalClient!.disconnect();
        _internalClient = null;
      }
      // Move all devices to offline.
    });

    on<DeviceControllerStartScanningEvent>(((event, emit) async {
      if (_internalClient == null) {
        return;
      }
      await _internalClient!.startScanning();
    }));

    on<DeviceControllerStopScanningEvent>(((event, emit) async {
      if (_internalClient == null) {
        return;
      }
      await _internalClient!.stopScanning();
    }));
  }

  List<ButtplugClientDevice> get onlineDevices => _onlineDevices;
  List<dynamic> get offlineDevices => _offlineDevices;
}
