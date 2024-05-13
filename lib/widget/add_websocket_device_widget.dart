import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/widget/stateful_dropdown_button.dart';

class AddWebsocketDeviceWidget extends StatelessWidget {
  const AddWebsocketDeviceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(builder: (context, state) {
      var userDeviceConfigCubit = BlocProvider.of<UserDeviceConfigurationCubit>(context);

      var engineIsRunning = BlocProvider.of<EngineControlBloc>(context).isRunning;
      List<DataRow> rows = [];
      for (var (protocol, websocketSpecifier) in userDeviceConfigCubit.specifiers) {
        rows.add(DataRow(cells: [
          DataCell(Text(protocol)),
          DataCell(Text(websocketSpecifier.name)),
          DataCell(TextButton(
            onPressed: engineIsRunning
                ? null
                : () => userDeviceConfigCubit.removeWebsocketDeviceName(protocol, websocketSpecifier.name),
            child: const Text("Delete"),
          ))
        ]));
      }

      // For now, we'll build these locally. This means we lose data on repaint but that's not actually an issue
      // with this entry.
      TextEditingController controller = TextEditingController();
      var sortedNames = userDeviceConfigCubit.protocols;
      sortedNames.sort();
      var valueNotifier = ValueNotifier("");
      var protocolDropdown = StatefulDropdownButton(
        label: "Protocol Type",
        values: sortedNames,
        valueNotifier: valueNotifier,
        enabled: !engineIsRunning,
      );
      return FractionallySizedBox(
          widthFactor: 0.8,
          child: Column(
            children: [
              Visibility(
                  visible: rows.isNotEmpty,
                  child: DataTable(columns: const <DataColumn>[
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'Protocol',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'Device Name',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'Delete',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    )
                  ], rows: rows)),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: Column(children: [
                  const Text("Add Websocket Device",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      )),
                  protocolDropdown,
                  SizedBox(
                    width: 150,
                    child: TextField(
                      enabled: !engineIsRunning,
                      controller: controller,
                      decoration: const InputDecoration(hintText: "Name"),
                    ),
                  ),
                  TextButton(
                      onPressed: engineIsRunning
                          ? null
                          : () {
                              var name = controller.text;
                              var protocol = protocolDropdown.valueNotifier.value;
                              protocolDropdown.valueNotifier.value = "";
                              userDeviceConfigCubit.addWebsocketDeviceName(protocol, name);
                            },
                      child: const Text("Add Websocket Device"))
                ]),
              )
            ],
          ));
    });
  }
}
