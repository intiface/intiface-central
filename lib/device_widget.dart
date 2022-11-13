import 'package:buttplug/buttplug.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/device/device_actuator_cubit.dart';
import 'package:intiface_central/device/device_manager_bloc.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:loggy/loggy.dart';

class DeviceWidget extends StatelessWidget {
  const DeviceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineControlBloc, EngineControlState>(
        buildWhen: (previous, current) =>
            current is DeviceConnectedState ||
            current is DeviceDisconnectedState ||
            current is ClientDisconnectedState ||
            current is EngineStoppedState,
        builder: (context, state) {
          var deviceBloc = BlocProvider.of<DeviceManagerBloc>(context);
          return Expanded(
              child: Column(children: [
            Row(
              children: [
                TextButton(
                    onPressed: state is! EngineStoppedState
                        ? () {
                            deviceBloc.add(DeviceManagerStartScanningEvent());
                          }
                        : null,
                    child: const Text("Start Scanning")),
                TextButton(
                    onPressed: state is! EngineStoppedState
                        ? () {
                            deviceBloc.add(DeviceManagerStopScanningEvent());
                          }
                        : null,
                    child: const Text("Stop Scanning"))
              ],
            ),
            Expanded(
                child: BlocBuilder<DeviceManagerBloc, DeviceManagerState>(
                    buildWhen: (previous, DeviceManagerState current) =>
                        current is DeviceManagerDeviceOnlineState || current is DeviceManagerDeviceOfflineState,
                    builder: (context, state) {
                      return Column(children: [
                        ExpansionPanelList(expandedHeaderPadding: EdgeInsets.all(1), children: [
                          ExpansionPanel(
                            headerBuilder: ((context, isExpanded) => const ListTile(
                                  title: Text("Online Devices"),
                                )),
                            body: ExpansionPanelList(
                                expandedHeaderPadding: EdgeInsets.all(1),
                                children: deviceBloc.devices.map((element) {
                                  // Since the device is still online, we know we can get the ClientDevice out of it.
                                  var device = element.device!;
                                  return ExpansionPanel(
                                    headerBuilder: ((context, isExpanded) => ListTile(
                                          title: Text(device.name),
                                        )),
                                    body: ListView(
                                        shrinkWrap: true,
                                        children: element.actuators.map((actuator) {
                                          /*                                          if (actuator.actuatorType == ActuatorType.Vibrate) {
                                            return ListView(shrinkWrap: true, children: [
                                              ListTile(title: Text("Vibrator: ${actuator.descriptor}")),
                                              BlocBuilder<DeviceActuatorCubit, DeviceActuatorState>(
                                                  bloc: actuator,
                                                  buildWhen: (previous, current) =>
                                                      current is DeviceActuatorStateUpdate,
                                                  builder: (context, state) => Slider(
                                                        max: actuator.stepCount.toDouble(),
                                                        value: actuator.currentValue.floorToDouble(),
                                                        divisions: actuator.stepCount,
                                                        onChanged: ((value) async {
                                                          actuator.vibrate(value);
                                                        }),
                                                      ))
                                            ]);
                                          } else */
                                          if (actuator.actuatorType != null) {
                                            return ListView(shrinkWrap: true, children: [
                                              ListTile(
                                                title: Text("${actuator.actuatorType}"),
                                                subtitle: Text(
                                                    "Description: ${actuator.descriptor} - Step Count: ${actuator.stepCount}"),
                                              ),
                                              BlocBuilder<DeviceActuatorCubit, DeviceActuatorState>(
                                                  bloc: actuator,
                                                  buildWhen: (previous, current) =>
                                                      current is DeviceActuatorStateUpdate,
                                                  builder: (context, state) => Slider(
                                                        max: actuator.stepCount.toDouble(),
                                                        value: actuator.currentValue.floorToDouble(),
                                                        divisions: actuator.stepCount,
                                                        onChanged: ((value) async {
                                                          actuator.scalar(value);
                                                        }),
                                                      ))
                                            ]);
                                          }
                                          return ListTile(title: Text("Unknown"));
                                        }).toList()),
                                    canTapOnHeader: true,
                                    isExpanded: true,
                                  );
                                }).toList()),
                            canTapOnHeader: true,
                            isExpanded: true,
                          )
                        ]),
                        ExpansionPanelList(expandedHeaderPadding: EdgeInsets.all(1), children: [
                          ExpansionPanel(
                            headerBuilder: ((context, isExpanded) => const ListTile(
                                  title: Text("Offline Devices"),
                                )),
                            body: const ExpansionPanelList(children: []),
                            canTapOnHeader: true,
                            isExpanded: true,
                          )
                        ])
                      ]);
                    }))
          ]));
        });
  }
}
