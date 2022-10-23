import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';

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
        return ExpansionPanelList(
          children: BlocProvider.of<EngineControlBloc>(context).devices.map((element) {
            return ExpansionPanel(
              headerBuilder: ((context, isExpanded) => ListTile(
                    title: Text(element.name),
                  )),
              body: const ListTile(title: Text("Device")),
              canTapOnHeader: true,
              isExpanded: false,
            );
          }).toList(),
        );
      }),
    );
  }
}
