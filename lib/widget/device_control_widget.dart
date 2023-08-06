import 'package:buttplug/buttplug.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device/device_actuator_cubit.dart';
import 'package:intiface_central/bloc/device/device_cubit.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/device/device_sensor_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class DeviceControlWidget extends StatelessWidget {
  final DeviceCubit _deviceCubit;

  const DeviceControlWidget({Key? key, required deviceCubit})
      : _deviceCubit = deviceCubit,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineControlBloc, EngineControlState>(
        buildWhen: (previous, current) =>
            current is DeviceConnectedState ||
            current is DeviceDisconnectedState ||
            current is ClientDisconnectedState ||
            current is EngineStoppedState,
        builder: (context, engineState) {
          return BlocBuilder<DeviceManagerBloc, DeviceManagerState>(builder: (context, state) {
            List<Widget> actuatorList = [];
            for (var actuator in _deviceCubit.actuators) {
              if (actuator is ScalarActuatorCubit) {
                actuatorList.addAll([
                  ListTile(
                    title: Text(actuator.actuatorType.name),
                    subtitle: Text("Description: ${actuator.descriptor} - Step Count: ${actuator.stepCount}"),
                  ),
                  BlocBuilder<DeviceActuatorCubit, DeviceActuatorState>(
                      bloc: actuator,
                      buildWhen: (previous, current) => current is DeviceActuatorStateUpdate,
                      builder: (context, state) => Slider(
                            max: actuator.stepCount.toDouble(),
                            value: actuator.currentValue.floorToDouble(),
                            divisions: actuator.stepCount,
                            onChanged: ((value) async {
                              actuator.scalar(value);
                            }),
                          ))
                ]);
              } else if (actuator is RotateActuatorCubit) {
                actuatorList.addAll([
                  ListTile(
                    title: const Text("Rotation"),
                    subtitle: Text("Description: ${actuator.descriptor} - Step Count: ${actuator.stepCount}"),
                  ),
                  BlocBuilder<DeviceActuatorCubit, DeviceActuatorState>(
                      bloc: actuator,
                      buildWhen: (previous, current) => current is DeviceActuatorStateUpdate,
                      builder: (context, state) => Slider(
                            max: actuator.stepCount.toDouble(),
                            value: actuator.currentValue.floorToDouble(),
                            divisions: actuator.stepCount,
                            onChanged: ((value) async {
                              actuator.rotate(value);
                            }),
                          ))
                ]);
              } else if (actuator is LinearActuatorCubit) {
                actuatorList.addAll([
                  ListTile(
                    title: const Text("Linear"),
                    subtitle: Text("Description: ${actuator.descriptor} - Step Count: ${actuator.stepCount}"),
                  ),
                  BlocBuilder<DeviceActuatorCubit, DeviceActuatorState>(
                      bloc: actuator,
                      buildWhen: (previous, current) => current is DeviceActuatorStateUpdate,
                      builder: (context, state) {
                        return ListView(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, children: [
                          RangeSlider(
                            max: actuator.stepCount.toDouble(),
                            values: RangeValues(actuator.currentMin, actuator.currentMax),
                            divisions: actuator.stepCount,
                            onChanged: ((values) async {
                              actuator.position(values.start, values.end);
                            }),
                          ),
                          Slider(
                            max: 3000,
                            value: actuator.currentDuration.floorToDouble(),
                            onChanged: ((value) async {
                              actuator.duration(value);
                            }),
                          ),
                          TextButton(child: const Text("Toggle Oscillation"), onPressed: () => actuator.toggleRunning())
                        ]);
                      })
                ]);
              } else {
                actuatorList.add(const ListTile(title: Text("Unknown")));
              }
            }

            for (var sensor in _deviceCubit.sensors) {
              if (sensor is SensorReadBloc) {
                actuatorList.addAll([
                  ListTile(
                    title: Text(sensor.sensorType.name),
                    subtitle: Text("Description: ${sensor.descriptor} - Sensor Range: ${sensor.sensorRange}"),
                  ),
                  BlocBuilder<DeviceSensorBloc, DeviceSensorState>(
                      bloc: sensor,
                      buildWhen: (DeviceSensorState previous, DeviceSensorState current) =>
                          current is DeviceSensorStateUpdate,
                      builder: (context, state) {
                        if (sensor.sensorType == SensorType.Battery) {
                          double percentage = sensor.currentData[0] / 100.0;
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
                        return Text("${sensor.currentData}");
                      }),
                  TextButton(child: const Text("Read Sensor"), onPressed: () => sensor.add(DeviceReadSensorEventRead()))
                ]);
              }
            }
            return ListView(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, children: actuatorList);
          });
        });
  }
}
