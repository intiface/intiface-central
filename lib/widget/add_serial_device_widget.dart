import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/widget/stateful_dropdown_button.dart';

class AddSerialDeviceWidget extends StatelessWidget {
  const AddSerialDeviceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(builder: (context, state) {
      var userDeviceConfigCubit = BlocProvider.of<UserDeviceConfigurationCubit>(context);

      var engineIsRunning = BlocProvider.of<EngineControlBloc>(context).isRunning;
      List<DataRow> rows = [];
      for (var (protocol, serialSpecifier) in userDeviceConfigCubit.serialSpecifiers) {
        rows.add(DataRow(cells: [
          DataCell(Text(protocol)),
          DataCell(Text(serialSpecifier.port)),
          DataCell(Text(
              "${serialSpecifier.baudRate.toString()}/${serialSpecifier.dataBits}/${serialSpecifier.parity}/${serialSpecifier.stopBits}")),
          DataCell(TextButton(
            onPressed:
                engineIsRunning ? null : () => userDeviceConfigCubit.removeSerialPort(protocol, serialSpecifier.port),
            child: const Text("Delete"),
          ))
        ]));
      }

      // For now, we'll build these locally. This means we lose data on repaint but that's not actually an issue
      // with this entry.
      TextEditingController portController = TextEditingController();
      TextEditingController baudController = TextEditingController();
      var sortedNames = userDeviceConfigCubit.protocols;
      sortedNames.sort();
      var valueNotifier = ValueNotifier("");
      var protocolDropdown = StatefulDropdownButton<String>(
        label: "Protocol Type",
        values: sortedNames,
        valueNotifier: valueNotifier,
        enabled: !engineIsRunning,
      );

      var dataBitsValueNotifier = ValueNotifier(8);
      var dataBitsDropdown = StatefulDropdownButton<int>(
        label: "Data Bits",
        values: const [8, 7, 6, 5, 4, 3, 2, 1],
        valueNotifier: dataBitsValueNotifier,
        enabled: !engineIsRunning,
      );

      var parityValueNotifier = ValueNotifier("N");
      var parityDropdown = StatefulDropdownButton(
        label: "Parity",
        values: const ["N", "E", "O", "S", "M"],
        valueNotifier: parityValueNotifier,
        enabled: !engineIsRunning,
      );

      var stopBitsValueNotifier = ValueNotifier(1);
      var stopBitsDropdown = StatefulDropdownButton(
        label: "StopBits",
        values: const [1, 0],
        valueNotifier: stopBitsValueNotifier,
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
                          'Port',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'Info',
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
                  const Text("Add Serial Device",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      )),
                  protocolDropdown,
                  SizedBox(
                    width: 150,
                    child: TextField(
                      enabled: !engineIsRunning,
                      controller: portController,
                      decoration: const InputDecoration(hintText: "Port Name"),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      enabled: !engineIsRunning,
                      controller: baudController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(hintText: "Baud"),
                    ),
                  ),
                  dataBitsDropdown,
                  parityDropdown,
                  stopBitsDropdown,
                  TextButton(
                      onPressed: engineIsRunning
                          ? null
                          : () {
                              var name = portController.text;
                              var protocol = protocolDropdown.valueNotifier.value;
                              protocolDropdown.valueNotifier.value = "";
                              userDeviceConfigCubit.addSerialPort(
                                protocol,
                                name,
                                int.parse(baudController.text),
                                dataBitsDropdown.valueNotifier.value,
                                stopBitsDropdown.valueNotifier.value,
                                parityDropdown.valueNotifier.value,
                              );
                            },
                      child: const Text("Add Serial Device"))
                ]),
              )
            ],
          ));
    });
  }
}
