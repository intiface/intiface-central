import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/gui_settings_cubit.dart';
import 'package:intiface_central/widget/device_config_widget.dart';
import 'package:intiface_central/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/widget/device_control_widget.dart';
import 'package:intiface_central/device/device_manager_bloc.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:loggy/loggy.dart';

class ProtocolDropdownButton extends StatefulWidget {
  final List<String> protocols;
  ProtocolDropdownButton({super.key, required this.protocols}) {
    protocols.sort();
  }

  @override
  State<ProtocolDropdownButton> createState() => _ProtocolDropdownButtonState();
}

class _ProtocolDropdownButtonState extends State<ProtocolDropdownButton> {
  late String? dropdownValue = "lovense";

  _ProtocolDropdownButtonState();

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: dropdownValue,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (String? value) {
        // This is called when the user selects an item.
        setState(() {
          dropdownValue = value!;
        });
      },
      items: widget.protocols.map<DropdownMenuItem<String>>((String value) {
        logInfo(value);
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineControlBloc, EngineControlState>(
        buildWhen: (previous, current) =>
            current is DeviceConnectedState ||
            current is DeviceDisconnectedState ||
            current is ClientDisconnectedState ||
            current is EngineStoppedState,
        builder: (context, engineState) {
          var deviceBloc = BlocProvider.of<DeviceManagerBloc>(context);
          var guiSettingsCubit = BlocProvider.of<GuiSettingsCubit>(context);
          return BlocBuilder<DeviceManagerBloc, DeviceManagerState>(builder: (context, state) {
            return BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(
                builder: (context, userConfigState) {
              List<Widget> deviceWidgets = [];
              List<int> connectedIndexes = [];
              var userDeviceConfigCubit = BlocProvider.of<UserDeviceConfigurationCubit>(context);

              if (engineState is! EngineStoppedState) {
                deviceWidgets.add(const ListTile(title: Text("Connected Devices")));
                for (var deviceCubit in deviceBloc.devices) {
                  var device = deviceCubit.device!;
                  connectedIndexes.add(device.index);
                  var deviceConfig =
                      userDeviceConfigCubit.configs.firstWhere((element) => element.reservedIndex == device.index);
                  var expansionName = "device-settings-${device.index}";
                  deviceWidgets.add(Card(
                      child: ListView(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, children: [
                    ListTile(
                      title: Text(device.displayName ?? device.name),
                      subtitle:
                          Text("Index: ${device.index} - Base Name: ${device.name}\n${deviceConfig.identifierString}"),
                    ),
                    DeviceControlWidget(deviceCubit: deviceCubit),
                    BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
                        buildWhen: (previous, current) =>
                            current is GuiSettingStateUpdate && current.valueName == expansionName,
                        builder: (context, state) {
                          return ExpansionPanelList(
                            children: [
                              ExpansionPanel(
                                  headerBuilder: (BuildContext context, bool isExpanded) {
                                    return const ListTile(
                                      title: Text("Settings"),
                                    );
                                  },
                                  body: ListView(
                                      physics: const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      children: [
                                        DeviceConfigWidget(identifier: deviceConfig.identifier),
                                      ]),
                                  isExpanded: guiSettingsCubit.getExpansionValue(expansionName) ?? false)
                            ],
                            expansionCallback: (panelIndex, isExpanded) =>
                                guiSettingsCubit.setExpansionValue(expansionName, !isExpanded),
                          );
                        })
                  ])));
                }
              }

              deviceWidgets.add(const ListTile(title: Text("Disconnected Devices")));
              for (var deviceConfig in userDeviceConfigCubit.configs) {
                if (connectedIndexes.contains(deviceConfig.reservedIndex)) {
                  continue;
                }
                var expansionName = "device-settings-${deviceConfig.reservedIndex}";
                deviceWidgets.add(BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
                    buildWhen: (previous, current) =>
                        current is GuiSettingStateUpdate && current.valueName == expansionName,
                    builder: (context, state) {
                      return ExpansionPanelList(
                          children: [
                            ExpansionPanel(
                                headerBuilder: (BuildContext context, bool isExpanded) {
                                  return ListTile(
                                    title: Text(deviceConfig.displayName != null
                                        ? "${deviceConfig.displayName} (${deviceConfig.name})"
                                        : deviceConfig.name),
                                    subtitle: Text(deviceConfig.identifierString),
                                  );
                                },
                                body: ListView(
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    children: [
                                      DeviceConfigWidget(identifier: deviceConfig.identifier),
                                    ]),
                                isExpanded: guiSettingsCubit.getExpansionValue(expansionName) ?? true)
                          ],
                          expansionCallback: (panelIndex, isExpanded) =>
                              guiSettingsCubit.setExpansionValue(expansionName, !isExpanded));
                    }));
              }

              deviceWidgets.add(const ListTile(title: Text("Websocket Devices")));
              List<DataRow> rows = [];
              for (var websocketConfig in userDeviceConfigCubit.specifiers.entries) {
                if (websocketConfig.value.websocketNames != null) {
                  for (var name in websocketConfig.value.websocketNames!) {
                    rows.add(DataRow(cells: [
                      DataCell(Text(websocketConfig.key)),
                      DataCell(Text(name)),
                      DataCell(TextButton(
                        child: const Text("Delete"),
                        onPressed: () => userDeviceConfigCubit.removeWebsocketDeviceName(websocketConfig.key, name),
                      ))
                    ]));
                  }
                }
              }

              deviceWidgets.add(DataTable(columns: const <DataColumn>[
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
              ], rows: rows));

              deviceWidgets.add(ProtocolDropdownButton(protocols: userDeviceConfigCubit.protocols));
              return Expanded(
                  child: Column(children: [
                Row(
                  children: [
                    !deviceBloc.scanning
                        ? TextButton(
                            onPressed: engineState is! EngineStoppedState
                                ? () {
                                    deviceBloc.add(DeviceManagerStartScanningEvent());
                                  }
                                : null,
                            child: const Text("Start Scanning"))
                        : TextButton(
                            onPressed: engineState is! EngineStoppedState
                                ? () {
                                    deviceBloc.add(DeviceManagerStopScanningEvent());
                                  }
                                : null,
                            child: const Text("Stop Scanning"))
                  ],
                ),
                Expanded(
                    child: SingleChildScrollView(
                        child: ListView(
                            physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, children: deviceWidgets)))
              ]));
            });
          });
        });
  }
}
