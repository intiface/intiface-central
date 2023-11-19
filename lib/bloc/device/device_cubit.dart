import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart';
import 'package:intiface_central/bloc/device/device_actuator_cubit.dart';
import 'package:intiface_central/bloc/device/device_sensor_cubit.dart';

class DeviceState {}

class DeviceStateInitial extends DeviceState {}

class DeviceStateOnline extends DeviceState {}

class DeviceStateOffline extends DeviceState {}

class DeviceCubit extends Cubit<DeviceState> {
  ButtplugClientDevice? _clientDevice;
  List<DeviceActuatorCubit> _actuators = [];
  final List<DeviceSensorBloc> _sensors = [];
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
            .add(ScalarActuatorCubit(_clientDevice!, attr.featureDescriptor, attr.stepCount, i, attr.actuatorType));
        ++i;
      }
    }
    if (_clientDevice!.messageAttributes.rotateCmd != null) {
      int i = 0;
      for (var attr in _clientDevice!.messageAttributes.rotateCmd!) {
        _actuators.add(RotateActuatorCubit(_clientDevice!, attr.featureDescriptor, attr.stepCount, i));
        ++i;
      }
    }
    if (_clientDevice!.messageAttributes.linearCmd != null) {
      var i = 0;
      for (var attr in _clientDevice!.messageAttributes.linearCmd!) {
        _actuators.add(LinearActuatorCubit(_clientDevice!, attr.featureDescriptor, attr.stepCount, i));
        ++i;
      }
    }
    if (_clientDevice!.messageAttributes.sensorReadCmd != null) {
      var i = 0;
      for (var attr in _clientDevice!.messageAttributes.sensorReadCmd!) {
        _sensors.add(SensorReadBloc(_clientDevice!, attr.featureDescriptor, attr.sensorRange, i, attr.sensorType));
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
  List<DeviceSensorBloc> get sensors => _sensors;
}
