import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart';
import 'package:intiface_central/bloc/device/device_output_cubit.dart';
import 'package:intiface_central/bloc/device/device_input_cubit.dart';
import 'package:intiface_central/bloc/device/observation_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_messages.dart';

class DeviceState {}

class DeviceStateInitial extends DeviceState {}

class DeviceStateOnline extends DeviceState {}

class DeviceStateOffline extends DeviceState {}

class DeviceCubit extends Cubit<DeviceState> {
  ButtplugClientDevice? _clientDevice;
  List<DeviceOutputCubit> _outputs = [];
  Map<int, ObservationCubit> _observations = {};
  final List<DeviceInputBloc> _inputs = [];
  final Stream<DeviceOutputObservation> _observationStream;

  DeviceCubit(this._clientDevice, this._observationStream)
      : super(DeviceStateInitial()) {
    setOnline(_clientDevice!);
  }

  void setOnline(ButtplugClientDevice device) {
    _clientDevice = device;
    for (var feature in _clientDevice!.features.values) {
      if (feature.feature.output != null) {
        int? maxSteps;
        for (var output in feature.feature.output!.entries) {
          if (output.key == OutputType.hwPositionWithDuration) {
            _outputs.add(PositionWithDurationOutputCubit(feature));
          } else {
            _outputs.add(ValueOutputCubit(feature, output.key));
          }
          final steps = output.value.value![1];
          if (maxSteps == null || steps > maxSteps) {
            maxSteps = steps;
          }
        }
        _observations[feature.feature.featureIndex] = ObservationCubit(
          deviceIndex: _clientDevice!.index,
          featureIndex: feature.feature.featureIndex,
          maxSteps: maxSteps!,
          observationStream: _observationStream,
        );
      }
      if (feature.feature.input != null) {
        for (var input in feature.feature.input!.entries) {
          _inputs.add(
            InputReadBloc(
              device,
              feature.feature.featureDescription,
              input.value.value,
              input.key,
            ),
          );
        }
      }
    }
    emit(DeviceStateOnline());
  }

  void setOffline() {
    _clientDevice = null;
    for (var obs in _observations.values) {
      obs.close();
    }
    _observations = {};
    _outputs = [];
    emit(DeviceStateOffline());
  }

  ButtplugClientDevice? get device => _clientDevice;
  List<DeviceOutputCubit> get outputs => _outputs;
  List<DeviceInputBloc> get inputs => _inputs;
  Map<int, ObservationCubit> get observations => _observations;
}
