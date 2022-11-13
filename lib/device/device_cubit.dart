import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart';
import 'package:intiface_central/device/device_actuator_cubit.dart';

class DeviceState {}

class DeviceStateInitial extends DeviceState {}

class DeviceEvent {}

class DeviceStateOnline extends DeviceState {}

class DeviceStateOffline extends DeviceState {}

class DeviceCubit extends Cubit<DeviceState> {
  ButtplugClientDevice? _clientDevice;
  List<DeviceActuatorCubit> _actuators = [];
  // DeviceConfiguration _deviceConfiguration;

  DeviceCubit(this._clientDevice) : super(DeviceStateInitial()) {
    setOnline(_clientDevice!);
  }

  void setOnline(ButtplugClientDevice device) {
    _clientDevice = device;
    if (_clientDevice!.messageAttributes.scalarCmd != null) {
      int i = 0;
      for (var attr in _clientDevice!.messageAttributes.scalarCmd!) {
        _actuators
            .add(DeviceActuatorCubit(_clientDevice!, attr.featureDescriptor, attr.stepCount, i, attr.actuatorType));
        ++i;
      }
    }
    emit(DeviceStateOnline());
  }

  void setOffline() {
    _clientDevice = null;
    _actuators = [];
    emit(DeviceStateOffline());
  }

  ButtplugClientDevice? get device => _clientDevice;
  List<DeviceActuatorCubit> get actuators => _actuators;
}
