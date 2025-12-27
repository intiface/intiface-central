import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart' as buttplug_dart;
import 'package:buttplug/client/client_device_feature.dart';
import 'package:buttplug/messages/messages.dart';
import 'package:easy_debounce/easy_debounce.dart';

class DeviceOutputState {}

class DeviceOutputStateInitial extends DeviceOutputState {}

class DeviceOutputStateUpdate extends DeviceOutputState {
  int value;

  DeviceOutputStateUpdate(this.value);
}

abstract class DeviceOutputCubit extends Cubit<DeviceOutputState> {
  final buttplug_dart.ButtplugClientDeviceFeature feature;
  final OutputType type;
  int _currentValue = 0;

  DeviceOutputCubit(this.feature, this.type) : super(DeviceOutputStateInitial());

  int get currentValue => _currentValue;
}

class ValueOutputCubit extends DeviceOutputCubit {
  ValueOutputCubit(super._feature, super._type);

  void setValue(int value) {
    _currentValue = value;
    emit(DeviceOutputStateUpdate(_currentValue));
    EasyDebounce.debounce(
      "actuator-output-${feature.feature.featureIndex}-$type",
      const Duration(milliseconds: 100),
      () async {
        await feature.runOutput(buttplug_dart.DeviceOutputValueConstructor(type).steps(value));
      },
    );
  }
}

class PositionOutputCubit extends DeviceOutputCubit {
  PositionOutputCubit(buttplug_dart.ButtplugClientDeviceFeature feature)
    : super(feature, buttplug_dart.OutputType.position);

  void setValue(int value) {
    _currentValue = value;
    emit(DeviceOutputStateUpdate(_currentValue));
    EasyDebounce.debounce(
      "actuator-output-${feature.deviceIndex}-${feature.feature.featureIndex}-$type",
      const Duration(milliseconds: 100),
      () async {
        await feature.runOutput(buttplug_dart.DeviceOutputPositionConstructor().steps(value));
      },
    );
  }
}

class PositionWithDurationOutputCubit extends DeviceOutputCubit {
  double _currentMin = 0;
  late double _currentMax;
  double _currentDuration = 3000;
  bool _running = false;

  PositionWithDurationOutputCubit(ButtplugClientDeviceFeature feature)
    : super(feature, buttplug_dart.OutputType.positionWithDuration) {
    _currentMax = feature.feature.output![buttplug_dart.OutputType.positionWithDuration]!.position![1].toDouble();
  }

  void position(double min, double max) {
    _currentMin = min;
    _currentMax = max;
    emit(DeviceOutputStateUpdate(_currentValue));
    EasyDebounce.debounce(
      "actuator-linear-${feature.deviceIndex}-${feature.feature.featureIndex}-$type",
      const Duration(milliseconds: 100),
      () async {
        await feature.runOutput(
          buttplug_dart.DeviceOutputPositionWithDurationConstructor().steps(_currentValue, _currentDuration.toInt()),
        );
      },
    );
  }

  void duration(double duration) {
    _currentDuration = duration;
    emit(DeviceOutputStateUpdate(_currentValue));
    EasyDebounce.debounce(
      "actuator-linear-${feature.deviceIndex}-${feature.feature.featureIndex}-$type",
      const Duration(milliseconds: 100),
      () async {
        await feature.runOutput(
          buttplug_dart.DeviceOutputPositionWithDurationConstructor().steps(_currentValue, _currentDuration.toInt()),
        );
      },
    );
  }

  Future<void> runOscillation() async {
    bool toMin = false;
    while (_running) {
      if (toMin) {
        await feature.runOutput(
          buttplug_dart.DeviceOutputPositionWithDurationConstructor().steps(
            _currentMin.toInt(),
            _currentDuration.toInt(),
          ),
        );
        toMin = false;
      } else {
        await feature.runOutput(
          buttplug_dart.DeviceOutputPositionWithDurationConstructor().steps(
            _currentMax.toInt(),
            _currentDuration.toInt(),
          ),
        );
        toMin = true;
      }
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
