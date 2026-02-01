import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';
import 'package:intiface_central/widget/feature_output_config_widget.dart';
import 'package:intiface_central/widget/add_serial_device_widget.dart';
import 'package:intiface_central/widget/add_websocket_device_widget.dart';
import 'package:intiface_central/widget/device_config_widget.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/widget/device_control_widget.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/src/rust/api/device_config.dart';

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  static Widget _sectionHeader(
    BuildContext context,
    String title, {
    bool addTopSpacing = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        top: addTopSpacing ? 24 : 8,
        bottom: 8,
        left: 4,
        right: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (addTopSpacing) Divider(color: colorScheme.outlineVariant),
          if (addTopSpacing) const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

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

        // When a device connects, force its connected card expanded.
        // When a device disconnects, force its disconnected card collapsed.
        if (engineState is DeviceConnectedState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            guiSettingsCubit.setExpansionValue(
              "device-connected-${engineState.index}",
              true,
            );
          });
        } else if (engineState is DeviceDisconnectedState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            guiSettingsCubit.setExpansionValue(
              "device-settings-${engineState.index}",
              false,
            );
          });
        }

        return BlocBuilder<DeviceManagerBloc, DeviceManagerState>(
          builder: (context, state) {
            return BlocBuilder<
              UserDeviceConfigurationCubit,
              UserDeviceConfigurationState
            >(
              builder: (context, userConfigState) {
                List<Widget> deviceWidgets = [];
                List<int> connectedIndexes = [];
                var userDeviceConfigCubit =
                    BlocProvider.of<UserDeviceConfigurationCubit>(context);
                if (engineState is! EngineStoppedState) {
                  deviceWidgets.add(
                    _sectionHeader(context, "Connected Devices"),
                  );
                  var devices = deviceBloc.devices;
                  devices.sort(
                    (a, b) => a.device!.index.compareTo(b.device!.index),
                  );
                  for (var deviceCubit in devices) {
                    var device = deviceCubit.device!;
                    connectedIndexes.add(device.index);
                    MapEntry<
                      ExposedUserDeviceIdentifier,
                      ExposedServerDeviceDefinition
                    >
                    deviceEntry;
                    try {
                      deviceEntry = userDeviceConfigCubit.configs.entries
                          .firstWhere(
                            (element) => element.value.index == device.index,
                          );
                    } catch (e) {
                      continue;
                    }
                    var expansionName = "device-connected-${device.index}";
                    deviceWidgets.add(
                      BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
                        buildWhen: (previous, current) =>
                            current is GuiSettingStateUpdate &&
                            current.valueName == expansionName,
                        builder: (context, state) {
                          final isExpanded =
                              guiSettingsCubit.getExpansionValue(
                                expansionName,
                              ) ??
                              true;
                          final colorScheme = Theme.of(context).colorScheme;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () =>
                                      guiSettingsCubit.setExpansionValue(
                                        expansionName,
                                        !isExpanded,
                                      ),
                                  child: Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                device.displayName ??
                                                    device.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Index: ${device.index} - Base Name: ${device.name}",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        AnimatedRotation(
                                          turns: isExpanded ? 0.5 : 0.0,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: Icon(
                                            Icons.expand_more,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isExpanded)
                                  Container(
                                    color: colorScheme.surfaceContainerLow,
                                    child: ListView(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      children: [
                                        DeviceControlWidget(
                                          deviceCubit: deviceCubit,
                                        ),
                                        DeviceConfigWidget(
                                          identifier: deviceEntry.key,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }
                }

                deviceWidgets.add(
                  _sectionHeader(
                    context,
                    "Disconnected Devices",
                    addTopSpacing: engineState is! EngineStoppedState,
                  ),
                );
                var userDevices = userDeviceConfigCubit.configs.entries
                    .toList();
                userDevices.sort(
                  (a, b) => a.value.index.compareTo(b.value.index),
                );
                for (var deviceEntry in userDevices) {
                  if (connectedIndexes.contains(deviceEntry.value.index)) {
                    continue;
                  }
                  var expansionName =
                      "device-settings-${deviceEntry.value.index}";
                  var identifierString =
                      "${deviceEntry.key.protocol}-${deviceEntry.key.identifier}-${deviceEntry.key.address}";
                  deviceWidgets.add(
                    BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
                      buildWhen: (previous, current) =>
                          current is GuiSettingStateUpdate &&
                          current.valueName == expansionName,
                      builder: (context, state) {
                        final isExpanded =
                            guiSettingsCubit.getExpansionValue(expansionName) ??
                            false;
                        final colorScheme = Theme.of(context).colorScheme;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => guiSettingsCubit.setExpansionValue(
                                  expansionName,
                                  !isExpanded,
                                ),
                                child: Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              deviceEntry.value.displayName !=
                                                      null
                                                  ? "${deviceEntry.value.displayName} (${deviceEntry.value.name})"
                                                  : deviceEntry.value.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              identifierString,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0.0,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: Icon(
                                          Icons.expand_more,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isExpanded)
                                Container(
                                  color: colorScheme.surfaceContainerLow,
                                  child: ListView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    children: [
                                      DeviceConfigWidget(
                                        identifier: deviceEntry.key,
                                      ),
                                      FeatureOutputConfigWidget(
                                        deviceIdentifier: deviceEntry.key,
                                        deviceDefinition: deviceEntry.value,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }

                deviceWidgets.add(
                  _sectionHeader(
                    context,
                    "Advanced Device Config",
                    addTopSpacing: true,
                  ),
                );
                if (configCubit.useDeviceWebsocketServer ||
                    configCubit.useSerialPort) {
                  if (configCubit.useDeviceWebsocketServer) {
                    const wsExpansion = "device-settings-advanced-websocket";
                    deviceWidgets.add(
                      BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
                        buildWhen: (previous, current) =>
                            current is GuiSettingStateUpdate &&
                            current.valueName == wsExpansion,
                        builder: (context, state) {
                          final isExpanded =
                              guiSettingsCubit.getExpansionValue(wsExpansion) ??
                              false;
                          final colorScheme = Theme.of(context).colorScheme;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () =>
                                      guiSettingsCubit.setExpansionValue(
                                        wsExpansion,
                                        !isExpanded,
                                      ),
                                  child: Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "Websocket Devices",
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        AnimatedRotation(
                                          turns: isExpanded ? 0.5 : 0.0,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: Icon(
                                            Icons.expand_more,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isExpanded)
                                  const AddWebsocketDeviceWidget(),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }
                  if (configCubit.useSerialPort) {
                    const serialExpansion = "device-settings-advanced-serial";
                    deviceWidgets.add(
                      BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
                        buildWhen: (previous, current) =>
                            current is GuiSettingStateUpdate &&
                            current.valueName == serialExpansion,
                        builder: (context, state) {
                          final isExpanded =
                              guiSettingsCubit.getExpansionValue(
                                serialExpansion,
                              ) ??
                              false;
                          final colorScheme = Theme.of(context).colorScheme;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () =>
                                      guiSettingsCubit.setExpansionValue(
                                        serialExpansion,
                                        !isExpanded,
                                      ),
                                  child: Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "Serial Devices",
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        AnimatedRotation(
                                          turns: isExpanded ? 0.5 : 0.0,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: Icon(
                                            Icons.expand_more,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isExpanded) const AddSerialDeviceWidget(),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }
                } else {
                  deviceWidgets.add(
                    const FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Text(
                        "Advanced device managers (Websocket, Serial Port, etc...) can be turned on in Advanced Settings section of the App Modes panel.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          !deviceBloc.scanning
                              ? TextButton(
                                  onPressed: engineState is! EngineStoppedState
                                      ? () {
                                          deviceBloc.add(
                                            DeviceManagerStartScanningEvent(),
                                          );
                                        }
                                      : null,
                                  child: const Text("Start Scanning"),
                                )
                              : TextButton(
                                  onPressed: engineState is! EngineStoppedState
                                      ? () {
                                          deviceBloc.add(
                                            DeviceManagerStopScanningEvent(),
                                          );
                                        }
                                      : null,
                                  child: const Text("Stop Scanning"),
                                ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: ListView(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            children: deviceWidgets,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
