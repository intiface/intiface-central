import 'dart:convert';

import 'package:buttplug/buttplug.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                    onPressed: () {
                      deviceBloc.add(DeviceManagerStartScanningEvent());
                    },
                    child: const Text("Start Scanning")),
                TextButton(
                    onPressed: () {
                      deviceBloc.add(DeviceManagerStopScanningEvent());
                    },
                    child: const Text("Stop Scanning"))
              ],
            ),
            BlocBuilder<DeviceManagerBloc, DeviceManagerState>(
                buildWhen: (previous, DeviceManagerState current) =>
                    current is DeviceManagerDeviceOnlineState || current is DeviceManagerDeviceOfflineState,
                builder: (context, state) => ExpansionPanelList(
                      children: deviceBloc.onlineDevices.map((element) {
                        return ExpansionPanel(
                          headerBuilder: ((context, isExpanded) => ListTile(
                                title: Text(element.deviceName),
                              )),
                          body: Column(children: [
                            const ListTile(title: Text("Device")),
                            Slider(
                              value: 0,
                              divisions: element.messageAttributes.scalarCmd![0].stepCount,
                              onChanged: ((value) {}),
                              onChangeEnd: (value) async {
                                await element.vibrate(ButtplugDeviceCommand.setAll(VibrateComponents(value)));
                              },
                            )
                          ]),
                          canTapOnHeader: true,
                          isExpanded: true,
                        );
                      }).toList(),
                    ))
          ]));
        });
  }
}
