import 'dart:convert';

import 'package:buttplug/buttplug.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/device/device_controller_bloc.dart';
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
      builder: ((context, state) {
        var engineBloc = BlocProvider.of<EngineControlBloc>(context);
        var deviceBloc = BlocProvider.of<DeviceControllerBloc>(context);
        return Expanded(
            child: Column(children: [
          Row(
            children: [
              TextButton(
                  onPressed: () {
                    deviceBloc.add(DeviceControllerStartScanningEvent());
                  },
                  child: const Text("Start Scanning")),
              TextButton(
                  onPressed: () {
                    deviceBloc.add(DeviceControllerStopScanningEvent());
                  },
                  child: const Text("Stop Scanning"))
            ],
          ),
          ExpansionPanelList(
            children: engineBloc.devices.map((element) {
              return ExpansionPanel(
                headerBuilder: ((context, isExpanded) => ListTile(
                      title: Text(element.name),
                    )),
                body: const ListTile(title: Text("Device")),
                canTapOnHeader: true,
                isExpanded: false,
              );
            }).toList(),
          )
        ]));
      }),
    );
  }
}
