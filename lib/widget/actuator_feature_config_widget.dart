import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_multi_slider/flutter_multi_slider.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/src/rust/api/device_config.dart';

class ActuatorFeatureConfigWidget extends StatelessWidget {
  final ExposedUserDeviceIdentifier _deviceIdentifier;
  //final ExposedUserDeviceDefinition _deviceDefinition;

  const ActuatorFeatureConfigWidget({super.key, required deviceIdentifier, required deviceDefinition})
    : //_deviceDefinition = deviceDefinition,
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
        List<Widget> actuatorList = [];
        /*
        for (var (index, feature) in _deviceDefinition.features.indexed) {
          if (feature.output == null) {
            continue;
          }
          var userConfigCubit = BlocProvider.of<UserDeviceConfigurationCubit>(context);
          for (var output in feature.output!) {
            if (output.outputType != OutputType.PositionWithDuration) {
              var actuator = output.output;
              actuatorList.addAll([
                ListTile(
                  title: Text(
                    "Feature: ${feature.description.isEmpty ? feature.featureType.name : "${feature.description} - ${feature.featureType.name}"}",
                  ),
                  subtitle: Text("Step Limit - Min: ${actuator.stepLimit} Max: ${actuator.stepLimit.$2}"),
                ),
                BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(
                  builder: (context, state) => MultiSlider(
                    max: actuator.stepRange.$2.toDouble(),
                    values: [actuator.stepLimit.$1.floorToDouble(), actuator.stepLimit.$2.floorToDouble()],
                    divisions: actuator.stepRange.$2,
                    onChanged: engineIsRunning
                        ? null
                        : ((value) async {
                            if (value[0].toInt() == value[1].toInt()) {
                              return;
                            }
                            var featureOutput = ExposedDeviceFeatureOutput(
                              stepRange: actuator.stepRange,
                              stepLimit: (value[0].toInt(), value[1].toInt()),
                            );
                            var newOutput = List<ExposedDeviceFeatureOutputPair>.from(feature.output!);
                            newOutput.removeWhere((x) => x.outputType == output.outputType);
                            newOutput.add(
                              ExposedDeviceFeatureOutputPair(outputType: output.outputType, output: featureOutput),
                            );
                            var newFeature = ExposedDeviceFeature(
                              description: feature.description,
                              id: feature.id,
                              featureType: feature.featureType,
                              output: newOutput,
                              input: feature.input,
                            );
                            await userConfigCubit.updateFeature(
                              _deviceIdentifier,
                              _deviceDefinition,
                              index,
                              newFeature,
                            );
                          }),
                  ),
                ),
              ]);
            }
            if (output.outputType == OutputType.PositionWithDuration) {
              var actuator = output.output;
              actuatorList.addAll([
                ListTile(
                  title: Text(
                    "Feature: ${feature.description.isEmpty ? feature.featureType.name : "${feature.description} - ${feature.featureType.name}"}",
                  ),
                  subtitle: Text("Position Limit - Min: ${actuator.stepLimit.$1} Max: ${actuator.stepLimit.$2}"),
                ),
                BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(
                  builder: (context, state) => MultiSlider(
                    max: actuator.stepRange.$2.toDouble(),
                    values: [actuator.stepLimit.$1.floorToDouble(), actuator.stepLimit.$2.floorToDouble()],
                    divisions: actuator.stepRange.$2,
                    onChanged: engineIsRunning
                        ? null
                        : ((value) async {
                            if (value[0].toInt() == value[1].toInt()) {
                              return;
                            }
                            var featureOutput = ExposedDeviceFeatureOutput(
                              stepRange: actuator.stepRange,
                              stepLimit: (value[0].toInt(), value[1].toInt()),
                            );
                            var newOutput = List<ExposedDeviceFeatureOutputPair>.from(feature.output!);
                            newOutput.removeWhere((x) => x.outputType == output.outputType);
                            newOutput.add(
                              ExposedDeviceFeatureOutputPair(outputType: output.outputType, output: featureOutput),
                            );
                            var newFeature = ExposedDeviceFeature(
                              description: feature.description,
                              id: feature.id,
                              featureType: feature.featureType,
                              output: newOutput,
                              input: feature.input,
                            );
                            await userConfigCubit.updateFeature(
                              _deviceIdentifier,
                              _deviceDefinition,
                              index,
                              newFeature,
                            );
                          }),
                  ),
                ),
              ]);
            }
          }
        }
        */
        return ListView(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, children: actuatorList);
      },
    );
  }
}
