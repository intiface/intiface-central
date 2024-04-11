import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart';
import 'package:easy_debounce/easy_debounce.dart';

class DeviceActuatorState {}

class DeviceActuatorStateInitial extends DeviceActuatorState {}

class DeviceActuatorStateUpdate extends DeviceActuatorState {
  double value;

  DeviceActuatorStateUpdate(this.value);
}

abstract class DeviceActuatorCubit extends Cubit<DeviceActuatorState> {
  final ButtplugClientDevice _device;
  final String descriptor;
  final int _index;
  final int stepCount;
  double _currentValue = 0;

  DeviceActuatorCubit(
      this._device, this.descriptor, this.stepCount, this._index)
      : super(DeviceActuatorStateInitial());

  double get currentValue => _currentValue;
}

class ScalarActuatorCubit extends DeviceActuatorCubit {
  final ActuatorType actuatorType;

  ScalarActuatorCubit(super.device, super.descriptor, super.stepCount,
      super.index, this.actuatorType);

  void scalar(double value) {
    var cmd = ScalarCommand.setMap(
        {_index: ScalarComponent(value / stepCount.toDouble(), actuatorType)});
    _currentValue = value;
    emit(DeviceActuatorStateUpdate(_currentValue));
    EasyDebounce.debounce("actuator-scalar-${_device.index}-$_index",
        const Duration(milliseconds: 100), () async {
      await _device.scalar(cmd);
    });
  }
}

class RotateActuatorCubit extends DeviceActuatorCubit {
  RotateActuatorCubit(
      super.device, super.descriptor, super.stepCount, super.index);

  void rotate(double value) {
    var cmd = RotateCommand.setMap({
      _index: RotateComponent((value / stepCount.toDouble()).abs(), value < 0)
    });
    _currentValue = value;
    emit(DeviceActuatorStateUpdate(_currentValue));
    EasyDebounce.debounce("actuator-rotate-${_device.index}-$_index",
        const Duration(milliseconds: 100), () async {
      await _device.rotate(cmd);
    });
  }
}

class LinearActuatorCubit extends DeviceActuatorCubit {
  double _currentMin = 0;
  late double _currentMax;
  double _currentDuration = 3000;
  bool _running = false;

  LinearActuatorCubit(
      ButtplugClientDevice device, String descriptor, int stepCount, int index)
      : super(device, descriptor, stepCount, index) {
    _currentMax = stepCount.toDouble();
  }

  void position(double min, double max) {
    //var cmd = LinearCommand.setMap({_index: LinearComponent((position / stepCount.toDouble()), duration.toInt())});
    _currentMin = min;
    _currentMax = max;
    emit(DeviceActuatorStateUpdate(_currentValue));
    /*
    EasyDebounce.debounce("actuator-linear-${_device.index}-$_index", const Duration(milliseconds: 100), () async {
      await _device.linear(cmd);
    });
    */
  }

  void duration(double duration) {
    //var cmd = LinearCommand.setMap({_index: LinearComponent((position / stepCount.toDouble()), duration.toInt())});
    _currentDuration = duration;
    emit(DeviceActuatorStateUpdate(_currentValue));
    /*
    EasyDebounce.debounce("actuator-linear-${_device.index}-$_index", const Duration(milliseconds: 100), () async {
      await _device.linear(cmd);
    });
    */
  }

  Future<void> runOscillation() async {
    bool toMin = false;
    while (_running) {
      ButtplugDeviceCommand<LinearComponent> cmd;
      if (toMin) {
        cmd = LinearCommand.setMap({
          _index: LinearComponent(
              currentMin / stepCount.toDouble(), _currentDuration.toInt())
        });
        toMin = false;
      } else {
        cmd = LinearCommand.setMap({
          _index: LinearComponent(
              currentMax / stepCount.toDouble(), _currentDuration.toInt())
        });
        toMin = true;
      }
      await _device.linear(cmd);
      await Future.delayed(Duration(milliseconds: _currentDuration.toInt()));
    }
  }

  void toggleRunning() {
    if (_running) {
      _running = false;
    } else {
      _running = true;
      runOscillation();
    }
  }

  bool get running => _running;
  double get currentMin => _currentMin;
  double get currentMax => _currentMax;
  double get currentDuration => _currentDuration;
}
