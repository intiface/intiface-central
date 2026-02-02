import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/widget/stateful_dropdown_button.dart';

class AddSerialDeviceWidget extends StatefulWidget {
  const AddSerialDeviceWidget({super.key});

  @override
  State<AddSerialDeviceWidget> createState() => _AddSerialDeviceWidgetState();
}

class _AddSerialDeviceWidgetState extends State<AddSerialDeviceWidget> {
  late TextEditingController _portController;
  late TextEditingController _baudController;
  late ValueNotifier<String> _protocolNotifier;
  late ValueNotifier<int> _dataBitsNotifier;
  late ValueNotifier<String> _parityNotifier;
  late ValueNotifier<int> _stopBitsNotifier;

  @override
  void initState() {
    super.initState();
    _portController = TextEditingController();
    _baudController = TextEditingController();
    _protocolNotifier = ValueNotifier("");
    _dataBitsNotifier = ValueNotifier(8);
    _parityNotifier = ValueNotifier("N");
    _stopBitsNotifier = ValueNotifier(1);
  }

  @override
  void dispose() {
    _portController.dispose();
    _baudController.dispose();
    _protocolNotifier.dispose();
    _dataBitsNotifier.dispose();
    _parityNotifier.dispose();
    _stopBitsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      UserDeviceConfigurationCubit,
      UserDeviceConfigurationState
    >(
      builder: (context, state) {
        var userDeviceConfigCubit =
            BlocProvider.of<UserDeviceConfigurationCubit>(context);

        var engineIsRunning = BlocProvider.of<EngineControlBloc>(
          context,
        ).isRunning;
        List<DataRow> rows = [];
        for (var (protocol, serialSpecifier)
            in userDeviceConfigCubit.serialSpecifiers) {
          rows.add(
            DataRow(
              cells: [
                DataCell(Text(protocol)),
                DataCell(Text(serialSpecifier.port)),
                DataCell(
                  Text(
                    "${serialSpecifier.baudRate.toString()}/${serialSpecifier.dataBits}/${serialSpecifier.parity}/${serialSpecifier.stopBits}",
                  ),
                ),
                DataCell(
                  TextButton(
                    onPressed: engineIsRunning
                        ? null
                        : () => userDeviceConfigCubit.removeSerialPort(
                            protocol,
                            serialSpecifier.port,
                          ),
                    child: const Text("Delete"),
                  ),
                ),
              ],
            ),
          );
        }

        var sortedNames = userDeviceConfigCubit.protocols;
        sortedNames.sort();
        var protocolDropdown = StatefulDropdownButton<String>(
          label: "Protocol Type",
          values: sortedNames,
          valueNotifier: _protocolNotifier,
          enabled: !engineIsRunning,
        );

        var dataBitsDropdown = StatefulDropdownButton<int>(
          label: "Data Bits",
          values: const [8, 7, 6, 5, 4, 3, 2, 1],
          valueNotifier: _dataBitsNotifier,
          enabled: !engineIsRunning,
        );

        var parityDropdown = StatefulDropdownButton(
          label: "Parity",
          values: const ["N", "E", "O", "S", "M"],
          valueNotifier: _parityNotifier,
          enabled: !engineIsRunning,
        );

        var stopBitsDropdown = StatefulDropdownButton(
          label: "StopBits",
          values: const [1, 0],
          valueNotifier: _stopBitsNotifier,
          enabled: !engineIsRunning,
        );
        return FractionallySizedBox(
          widthFactor: 0.8,
          child: Column(
            children: [
              Visibility(
                visible: rows.isNotEmpty,
                child: DataTable(
                  columns: const <DataColumn>[
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
                    ),
                  ],
                  rows: rows,
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: Column(
                  children: [
                    const Text(
                      "Add Serial Device",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    protocolDropdown,
                    SizedBox(
                      width: 150,
                      child: TextField(
                        enabled: !engineIsRunning,
                        controller: _portController,
                        decoration: const InputDecoration(
                          hintText: "Port Name",
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        enabled: !engineIsRunning,
                        controller: _baudController,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
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
                              var name = _portController.text;
                              var protocol =
                                  protocolDropdown.valueNotifier.value;
                              protocolDropdown.valueNotifier.value = "";
                              userDeviceConfigCubit.addSerialPort(
                                protocol,
                                name,
                                int.parse(_baudController.text),
                                dataBitsDropdown.valueNotifier.value,
                                stopBitsDropdown.valueNotifier.value,
                                parityDropdown.valueNotifier.value,
                              );
                            },
                      child: const Text("Add Serial Device"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
