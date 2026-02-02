import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';
import 'package:intiface_central/widget/connected_devices_widget.dart';
import 'package:intiface_central/widget/disconnected_devices_widget.dart';
import 'package:intiface_central/widget/advanced_device_config_widget.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';

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
                List<int> connectedIndexes = [];
                List<Widget> deviceWidgets = [];

                if (engineState is! EngineStoppedState) {
                  deviceWidgets.add(
                    _sectionHeader(context, "Connected Devices"),
                  );
                  deviceWidgets.add(
                    ConnectedDevicesWidget(connectedIndexes: connectedIndexes),
                  );
                }

                deviceWidgets.add(
                  _sectionHeader(
                    context,
                    "Disconnected Devices",
                    addTopSpacing: engineState is! EngineStoppedState,
                  ),
                );
                deviceWidgets.add(
                  DisconnectedDevicesWidget(connectedIndexes: connectedIndexes),
                );

                deviceWidgets.add(
                  _sectionHeader(
                    context,
                    "Advanced Device Config",
                    addTopSpacing: true,
                  ),
                );
                deviceWidgets.add(const AdvancedDeviceConfigWidget());

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
