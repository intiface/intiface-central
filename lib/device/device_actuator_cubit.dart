import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart';
import 'package:loggy/loggy.dart';
import 'package:easy_debounce/easy_debounce.dart';

class DeviceActuatorState {}

class DeviceActuatorStateInitial extends DeviceActuatorState {}

class DeviceActuatorStateUpdate extends DeviceActuatorState {
  double value;

  DeviceActuatorStateUpdate(this.value);
}

class DeviceActuatorCubit extends Cubit<DeviceActuatorState> {
  final ButtplugClientDevice _device;
  final String descriptor;
  final ActuatorType? actuatorType;
  final int _index;
  final int stepCount;
  double _currentValue = 0;

  DeviceActuatorCubit(this._device, this.descriptor, this.stepCount, this._index, this.actuatorType)
      : super(DeviceActuatorStateInitial());

  void vibrate(double value) {
    var cmd = VibrateCommand.setMap({_index: VibrateComponent(value / stepCount.toDouble())});
    _currentValue = value;
    emit(DeviceActuatorStateUpdate(_currentValue));
    EasyDebounce.debounce("actuator-vibrate-${_device.index}-$_index", const Duration(milliseconds: 100), () async {
      await _device.vibrate(cmd);
    });
  }

  void scalar(double value) {
    var cmd = ScalarCommand.setMap({_index: ScalarComponent(value / stepCount.toDouble(), actuatorType!)});
    _currentValue = value;
    emit(DeviceActuatorStateUpdate(_currentValue));
    EasyDebounce.debounce("actuator-scalar-${_device.index}-$_index", const Duration(milliseconds: 100), () async {
      await _device.scalar(cmd);
    });
  }

  void rotate(double value) {
    var cmd = RotateCommand.setMap({_index: RotateComponent((value / stepCount.toDouble()).abs(), value < 0)});
    _currentValue = value;
    emit(DeviceActuatorStateUpdate(_currentValue));
    EasyDebounce.debounce("actuator-scalar-${_device.index}-$_index", const Duration(milliseconds: 100), () async {
      await _device.rotate(cmd);
    });
  }

  Future<void> _linear(int value, int duration) async {}

  double get currentValue => _currentValue;
}
