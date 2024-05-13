import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';
import 'package:intiface_central/widget/actuator_feature_config_widget.dart';
import 'package:intiface_central/widget/add_serial_device_widget.dart';
import 'package:intiface_central/widget/add_websocket_device_widget.dart';
import 'package:intiface_central/widget/device_config_widget.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/widget/device_control_widget.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';

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
                  var deviceEntry;
                  try {
                    deviceEntry = userDeviceConfigCubit.configs.entries
                        .firstWhere((element) => element.value.userConfig.index == device.index);
                  } catch (e) {
                    continue;
                  }
                  var expansionName = "device-settings-${device.index}";
                  deviceWidgets.add(Card(
                      child: ListView(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, children: [
                    ListTile(
                      title: Text(device.displayName ?? device.name),
                      subtitle: Text("Index: ${device.index} - Base Name: ${device.name}"),
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
                                        DeviceConfigWidget(identifier: deviceEntry.key),
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
              for (var deviceEntry in userDeviceConfigCubit.configs.entries) {
                if (connectedIndexes.contains(deviceEntry.value.userConfig.index)) {
                  continue;
                }
                var expansionName = "device-settings-${deviceEntry.value.userConfig.index}";
                var identifierString =
                    "${deviceEntry.key.protocol}-${deviceEntry.key.identifier}-${deviceEntry.key.address}";
                deviceWidgets.add(BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
                    buildWhen: (previous, current) =>
                        current is GuiSettingStateUpdate && current.valueName == expansionName,
                    builder: (context, state) {
                      var listWidgets = [
                        DeviceConfigWidget(identifier: deviceEntry.key),
                        ActuatorFeatureConfigWidget(
                            deviceIdentifier: deviceEntry.key, deviceDefinition: deviceEntry.value)
                      ];

                      return ExpansionPanelList(
                          children: [
                            ExpansionPanel(
                                headerBuilder: (BuildContext context, bool isExpanded) {
                                  return ListTile(
                                    title: Text(deviceEntry.value.userConfig.displayName != null
                                        ? "${deviceEntry.value.userConfig.displayName} (${deviceEntry.value.name})"
                                        : deviceEntry.value.name),
                                    subtitle: Text(identifierString),
                                  );
                                },
                                body: ListView(
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    children: listWidgets),
                                isExpanded: guiSettingsCubit.getExpansionValue(expansionName) ?? true)
                          ],
                          expansionCallback: (panelIndex, isExpanded) =>
                              guiSettingsCubit.setExpansionValue(expansionName, isExpanded));
                    }));
              }

              var expansionName = "device-settings-advanceddeviceconfig";

              deviceWidgets.add(const ListTile(title: Text("Advanced Device Config")));
              if (configCubit.useDeviceWebsocketServer || configCubit.useSerialPort) {
                deviceWidgets.add(BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(
                    builder: (context, state) => BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
                        buildWhen: (previous, current) =>
                            current is GuiSettingStateUpdate && current.valueName == expansionName,
                        builder: (context, state) {
                          var configWidgetList = <ExpansionPanel>[];
                          if (configCubit.useDeviceWebsocketServer) {
                            configWidgetList.add(
                              ExpansionPanel(
                                  isExpanded: guiSettingsCubit.getExpansionValue(expansionName) ?? false,
                                  headerBuilder: (BuildContext context, bool isExpanded) =>
                                      const ListTile(title: Text("Websocket Devices (Advanced)")),
                                  body: const AddWebsocketDeviceWidget()),
                            );
                          }
                          if (configCubit.useSerialPort) {
                            configWidgetList.add(ExpansionPanel(
                                isExpanded: guiSettingsCubit.getExpansionValue(expansionName) ?? false,
                                headerBuilder: (BuildContext context, bool isExpanded) =>
                                    const ListTile(title: Text("Serial Devices (Advanced)")),
                                body: const AddSerialDeviceWidget()));
                          }
                          return ExpansionPanelList(
                              expansionCallback: (panelIndex, isExpanded) =>
                                  guiSettingsCubit.setExpansionValue(expansionName, isExpanded),
                              children: configWidgetList);
                        })));
              } else {
                deviceWidgets.add(const FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Text(
                      "Advanced device managers (Websocket, Serial Port, etc...) can be turned on in Advanced Settings section of the App Modes panel.",
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
