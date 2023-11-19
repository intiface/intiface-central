import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart';
import 'package:loggy/loggy.dart';

abstract class DeviceSensorState {}

class DeviceSensorStateInitial extends DeviceSensorState {}

class DeviceSensorStateUpdate extends DeviceSensorState {
  List<int> value;

  DeviceSensorStateUpdate(this.value);
}

abstract class DeviceReadSensorEvent {}

class DeviceReadSensorEventRead extends DeviceReadSensorEvent {}

class DeviceSubscribeSensorEvent {}

class DeviceSubscribeSensorEventSubscribe extends DeviceSubscribeSensorEvent {}

class DeviceSubscribeSensorEventUnsubscribe extends DeviceSubscribeSensorEvent {}

abstract class DeviceSensorBloc<T> extends Bloc<T, DeviceSensorState> {
  final ButtplugClientDevice _device;
  final String descriptor;
  final int _index;
  final List<List<int>> sensorRange;
  final SensorType sensorType;
  List<int> _currentData = [0];

  DeviceSensorBloc(this._device, this.descriptor, this.sensorRange, this._index, this.sensorType)
      : super(DeviceSensorStateInitial());

  List<int> get currentData => _currentData;
}

class SensorReadBloc extends DeviceSensorBloc<DeviceReadSensorEvent> {
  SensorReadBloc(super.device, super.descriptor, super.sensorRange, super.index, super.sensorType) {
    on<DeviceReadSensorEventRead>(((event, emit) async {
      var newData = await _device.sensorRead(_index);
      logInfo("Sensor data: $newData");
      if (_currentData != newData) {
        logInfo("Updating");
        _currentData = newData;
        return emit(DeviceSensorStateUpdate(_currentData));
      }
    }));
  }
}
