import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device/device_output_cubit.dart';
import 'package:intiface_central/bloc/device/device_cubit.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/device/device_input_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/src/rust/api/enums.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class DeviceControlWidget extends StatelessWidget {
  final DeviceCubit _deviceCubit;

  const DeviceControlWidget({super.key, required deviceCubit})
    : _deviceCubit = deviceCubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineControlBloc, EngineControlState>(
      buildWhen: (previous, current) =>
          current is DeviceConnectedState ||
          current is DeviceDisconnectedState ||
          current is ClientDisconnectedState ||
          current is EngineStoppedState,
      builder: (context, engineState) {
        return BlocBuilder<DeviceManagerBloc, DeviceManagerState>(
          builder: (context, state) {
            List<Widget> outputList = [];
            for (var output in _deviceCubit.outputs) {
              if (output is ValueOutputCubit) {
                var range = output.feature.feature.output![output.type]!.value!;
                outputList.addAll([
                  ListTile(
                    title: Text(output.type.name),
                    subtitle: Text(
                      "Description: ${output.feature.feature.featureDescription} - Step Count: $range",
                    ),
                  ),
                  BlocBuilder<DeviceOutputCubit, DeviceOutputState>(
                    bloc: output,
                    buildWhen: (previous, current) =>
                        current is DeviceOutputStateUpdate,
                    builder: (context, state) => Slider(
                      min: range[0].toDouble(),
                      max: range[1].toDouble(),
                      value: output.currentValue.floorToDouble(),
                      divisions: (range[0].abs() + range[1].abs()),
                      onChanged: ((value) async {
                        output.setValue(value.ceil());
                      }),
                    ),
                  ),
                ]);
              } else if (output is PositionWithDurationOutputCubit) {
                var range = output.feature.feature.output![output.type]!.value!;
                outputList.addAll([
                  ListTile(
                    title: const Text("Linear"),
                    subtitle: Text(
                      "Description: ${output.feature.feature.featureDescription} - Step Count: $range",
                    ),
                  ),
                  BlocBuilder<DeviceOutputCubit, DeviceOutputState>(
                    bloc: output,
                    buildWhen: (previous, current) =>
                        current is DeviceOutputStateUpdate,
                    builder: (context, state) {
                      return ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          RangeSlider(
                            max: range[1].toDouble(),
                            values: RangeValues(
                              output.currentMin,
                              output.currentMax,
                            ),
                            divisions: range[1],
                            onChanged: ((values) async {
                              output.setPosition(values.start, values.end);
                            }),
                          ),
                          Slider(
                            max: 3000,
                            value: output.currentDuration.floorToDouble(),
                            onChanged: ((value) async {
                              output.duration(value);
                            }),
                          ),
                          TextButton(
                            child: const Text("Toggle Oscillation"),
                            onPressed: () => output.toggleRunning(),
                          ),
                        ],
                      );
                    },
                  ),
                ]);
              } else {
                outputList.add(const ListTile(title: Text("Unknown")));
              }
            }
            for (var input in _deviceCubit.inputs) {
              if (input is InputReadBloc) {
                outputList.addAll([
                  ListTile(
                    title: Text(input.inputType.name),
                    subtitle: Text(
                      "Description: ${input.descriptor} - Sensor Range: ${input.sensorRange}",
                    ),
                  ),
                  BlocBuilder<DeviceInputBloc, DeviceInputState>(
                    bloc: input,
                    buildWhen:
                        (DeviceInputState previous, DeviceInputState current) =>
                            current is DeviceInputStateUpdate,
                    builder: (context, state) {
                      if (input.inputType.name == InputType.battery.name) {
                        double percentage = input.currentData / 100.0;
                        return LinearPercentIndicator(
                          percent: percentage,
                          animation: true,
                          lineHeight: 20.0,
                          animationDuration: 1000,
                          backgroundColor: Colors.grey,
                          progressColor: Colors.blue,
                          center: Text("${(percentage * 100).toInt()}%"),
                        );
                      }
                      return Text("${input.currentData}");
                    },
                  ),
                  TextButton(
                    child: const Text("Read Sensor"),
                    onPressed: () => input.add(DeviceInputReadEvent()),
                  ),
                ]);
              }
            }
            return ListView(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: outputList,
            );
          },
        );
      },
    );
  }
}
