import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart';
import 'package:intiface_central/bloc/device/device_output_cubit.dart';
import 'package:intiface_central/bloc/device/device_input_cubit.dart';

class DeviceState {}

class DeviceStateInitial extends DeviceState {}

class DeviceStateOnline extends DeviceState {}

class DeviceStateOffline extends DeviceState {}

class DeviceCubit extends Cubit<DeviceState> {
  ButtplugClientDevice? _clientDevice;
  List<DeviceOutputCubit> _outputs = [];
  final List<DeviceInputBloc> _inputs = [];
  // DeviceConfiguration _deviceConfiguration;

  DeviceCubit(this._clientDevice) : super(DeviceStateInitial()) {
    setOnline(_clientDevice!);
  }

  void setOnline(ButtplugClientDevice device) {
    _clientDevice = device;
    for (var feature in _clientDevice!.features.values) {
      if (feature.feature.output != null) {
        for (var output in feature.feature.output!.entries) {
          if (output.key == OutputType.positionWithDuration) {
            _outputs.add(PositionWithDurationOutputCubit(feature));
          } else {
            _outputs.add(ValueOutputCubit(feature, output.key));
          }
        }
      }
      if (feature.feature.input != null) {
        for (var input in feature.feature.input!.entries) {
          _inputs.add(InputReadBloc(device, feature.feature.featureDescription, input.value.value, input.key));
        }
      }
    }
    emit(DeviceStateOnline());
  }

  void setOffline() {
    _clientDevice = null;
    _outputs = [];
    emit(DeviceStateOffline());
  }

  ButtplugClientDevice? get device => _clientDevice;
  List<DeviceOutputCubit> get outputs => _outputs;
  List<DeviceInputBloc> get inputs => _inputs;
}
