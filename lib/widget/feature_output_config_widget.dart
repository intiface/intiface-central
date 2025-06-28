import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_multi_slider/flutter_multi_slider.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/src/rust/api/device_config.dart';
import 'package:intiface_central/src/rust/api/enums.dart';
import 'package:intiface_central/util/debouncer.dart';
import 'package:loggy/loggy.dart';

class FeatureOutputConfigWidget extends StatelessWidget {
  final ExposedUserDeviceIdentifier _deviceIdentifier;
  final ExposedDeviceDefinition _deviceDefinition;

  const FeatureOutputConfigWidget({super.key, required deviceIdentifier, required deviceDefinition})
    : _deviceDefinition = deviceDefinition,
      _deviceIdentifier = deviceIdentifier;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineControlBloc, EngineControlState>(
      buildWhen: (EngineControlState previous, EngineControlState current) =>
          current is EngineStartingState ||
          current is EngineStartedState ||
          current is EngineStoppedState ||
          current is ClientConnectedState ||
          current is ClientDisconnectedState,
      builder: (context, EngineControlState state) {
        var engineIsRunning = BlocProvider.of<EngineControlBloc>(context).isRunning;
        List<Widget> outputList = [];
        for (var output in _deviceDefinition.outputs()) {
          var userConfigCubit = BlocProvider.of<UserDeviceConfigurationCubit>(context);
          if (output.outputType != OutputType.positionWithDuration) {
            Debouncer d = Debouncer(delay: const Duration(milliseconds: 30));
            outputList.addAll([
              ListTile(
                title: Text(
                  "Feature: ${output.description.isEmpty ? output.featureType.name : "${output.description} - ${output.featureType.name}"}",
                ),
                subtitle: Text(
                  "Step Range - Min: ${output.stepRange.$1} Max: ${output.stepRange.$2} Step Limit - Min: ${output.stepLimit.$1} Max: ${output.stepLimit.$2}",
                ),
              ),
              BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(
                builder: (context, state) => MultiSlider(
                  max: output.stepRange.$2.toDouble(),
                  values: [output.stepLimit.$1.floorToDouble(), output.stepLimit.$2.floorToDouble()],
                  divisions: output.stepRange.$2,
                  onChanged: engineIsRunning
                      ? null
                      : ((value) async {
                          if (value[0].toInt() == value[1].toInt()) {
                            return;
                          }
                          output.setStepLimit(limit: (value[0].toInt(), value[1].toInt()));
                          d.run(() async {
                            _deviceDefinition.updateOutput(userOutput: output);
                            await userConfigCubit.updateDefinition(_deviceIdentifier, _deviceDefinition);
                          });
                        }),
                ),
              ),
            ]);
          }
          if (output.outputType == OutputType.positionWithDuration) {
            outputList.addAll([
              ListTile(
                title: Text(
                  "Feature: ${output.description.isEmpty ? output.featureType.name : "${output.description} - ${output.featureType.name}"}",
                ),
                subtitle: Text("Position Limit - Min: ${output.stepLimit.$1} Max: ${output.stepLimit.$2}"),
              ),
              BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(
                builder: (context, state) => MultiSlider(
                  max: output.stepRange.$2.toDouble(),
                  values: [output.stepLimit.$1.floorToDouble(), output.stepLimit.$2.floorToDouble()],
                  divisions: output.stepRange.$2,
                  onChanged: engineIsRunning
                      ? null
                      : ((value) async {
                          if (value[0].toInt() == value[1].toInt()) {
                            return;
                          }
                          output.setStepLimit(limit: (value[0].toInt(), value[1].toInt()));
                          _deviceDefinition.updateOutput(userOutput: output);
                          await userConfigCubit.updateDefinition(_deviceIdentifier, _deviceDefinition);
                        }),
                ),
              ),
            ]);
          }
        }
        return ListView(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, children: outputList);
      },
    );
  }
}
