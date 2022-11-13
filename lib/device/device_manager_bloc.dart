import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart';
import 'package:intiface_central/device/backdoor_connector.dart';
import 'package:intiface_central/device/device_cubit.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:loggy/loggy.dart';

class DeviceManagerEvent {}

class DeviceManagerEngineStartedEvent extends DeviceManagerEvent {}

class DeviceManagerEngineStoppedEvent extends DeviceManagerEvent {}

class DeviceManagerDeviceAddedEvent extends DeviceManagerEvent {
  final ButtplugClientDevice device;

  DeviceManagerDeviceAddedEvent(this.device);
}

class DeviceManagerDeviceRemovedEvent extends DeviceManagerEvent {
  final int index;

  DeviceManagerDeviceRemovedEvent(this.index);
}

class DeviceManagerStartScanningEvent extends DeviceManagerEvent {}

class DeviceManagerStopScanningEvent extends DeviceManagerEvent {}

class DeviceManagerState {}

class DeviceManagerInitialState extends DeviceManagerState {}

class DeviceManagerDeviceOnlineState extends DeviceManagerState {
  final DeviceCubit device;

  DeviceManagerDeviceOnlineState(this.device);
}

class DeviceManagerDeviceOfflineState extends DeviceManagerState {
  final DeviceCubit device;

  DeviceManagerDeviceOfflineState(this.device);
}

class DeviceManagerBloc extends Bloc<DeviceManagerEvent, DeviceManagerState> {
  ButtplugClient? _internalClient;
  final List<DeviceCubit> _devices = [];
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
          logInfo("Device connected: ${event.device.name}");
          _devices.add(DeviceCubit(event.device));
          add(DeviceManagerDeviceAddedEvent(event.device));
        }
      });
      _internalClient = client;
    });

    on<DeviceManagerDeviceAddedEvent>((event, emit) {
      var deviceBloc = DeviceCubit(event.device);
      _devices.remove(deviceBloc);
      emit(DeviceManagerDeviceOnlineState(deviceBloc));
    });

    on<DeviceManagerDeviceRemovedEvent>(((event, emit) {
      try {
        // This will throw if it doesn't find anything.
        var deviceBloc = _devices.firstWhere((deviceBloc) => deviceBloc.device?.index == event.index);
        _devices.remove(deviceBloc);
        emit(DeviceManagerDeviceOfflineState(deviceBloc));
      } catch (e) {
        logError("Got device removal event for a device we don't have.");
      }
    }));

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

  List<DeviceCubit> get devices => _devices;
}
