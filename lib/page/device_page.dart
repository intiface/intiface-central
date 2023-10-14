import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';
import 'package:intiface_central/widget/device_config_widget.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/widget/device_control_widget.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';

class ProtocolDropdownButton extends StatefulWidget {
  final List<String> protocols;
  final ValueNotifier<String> protocol;
  final bool enabled;
  ProtocolDropdownButton({super.key, required this.protocols, required this.protocol, this.enabled = true}) {
    protocols.sort();
  }

  @override
  State<ProtocolDropdownButton> createState() => _ProtocolDropdownButtonState();
}

class _ProtocolDropdownButtonState extends State<ProtocolDropdownButton> {
  String? dropdownValue;

  _ProtocolDropdownButtonState();

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: dropdownValue,
      hint: const Text("Protocol Type"),
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: widget.enabled
          ? (String? value) {
              // This is called when the user selects an item.
              setState(() {
                dropdownValue = value!;
              });
              widget.protocol.value = value!;
            }
          : null,
      items: widget.protocols.map<DropdownMenuItem<String>>((String value) {
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
          var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
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
                  var deviceConfig = userDeviceConfigCubit.configs.firstWhere(
                      (element) => element.reservedIndex == device.index,
                      orElse: () => ExposedWritableUserDeviceConfig.createDefault(device.index));
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
                                guiSettingsCubit.setExpansionValue(expansionName, isExpanded),
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
                              guiSettingsCubit.setExpansionValue(expansionName, isExpanded));
                    }));
              }

              var engineIsRunning = BlocProvider.of<EngineControlBloc>(context).isRunning;
              List<DataRow> rows = [];
              for (var websocketConfig in userDeviceConfigCubit.specifiers.entries) {
                if (websocketConfig.value.websocketNames != null) {
                  for (var name in websocketConfig.value.websocketNames!) {
                    rows.add(DataRow(cells: [
                      DataCell(Text(websocketConfig.key)),
                      DataCell(Text(name)),
                      DataCell(TextButton(
                        onPressed: engineIsRunning
                            ? null
                            : () => userDeviceConfigCubit.removeWebsocketDeviceName(websocketConfig.key, name),
                        child: const Text("Delete"),
                      ))
                    ]));
                  }
                }
              }

              // For now, we'll build these locally. This means we lose data on repaint but that's not actually an issue
              // with this entry.
              TextEditingController controller = TextEditingController();
              var sortedNames = userDeviceConfigCubit.protocols;
              sortedNames.sort();
              var valueNotifier = ValueNotifier("");
              var protocolDropdown = ProtocolDropdownButton(
                protocols: sortedNames,
                protocol: valueNotifier,
                enabled: !engineIsRunning,
              );
              var expansionName = "device-settings-websocketdevices";
              deviceWidgets.add(const ListTile(title: Text("Advanced Device Config")));
              if (configCubit.useDeviceWebsocketServer) {
                deviceWidgets.add(BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
                    buildWhen: (previous, current) =>
                        current is GuiSettingStateUpdate && current.valueName == expansionName,
                    builder: (context, state) {
                      return ExpansionPanelList(
                          expansionCallback: (panelIndex, isExpanded) =>
                              guiSettingsCubit.setExpansionValue(expansionName, isExpanded),
                          children: [
                            ExpansionPanel(
                                isExpanded: guiSettingsCubit.getExpansionValue(expansionName) ?? false,
                                headerBuilder: (BuildContext context, bool isExpanded) =>
                                    const ListTile(title: Text("Websocket Devices (Advanced)")),
                                body: FractionallySizedBox(
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
                                                        var protocol = protocolDropdown.protocol.value;
                                                        userDeviceConfigCubit.addWebsocketDeviceName(protocol, name);
                                                      },
                                                child: const Text("Add Websocket Device"))
                                          ]),
                                        )
                                      ],
                                    )))
                          ]);
                    }));
              } else {
                deviceWidgets.add(const FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Text(
                      "Advanced device managers (Websocket, Serial Port, etc...) can be turned on in Advanced Settings section of the settings panel.",
                      textAlign: TextAlign.center,
                    )));
              }

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
