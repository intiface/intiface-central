import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:intiface_central/src/rust/api/device_config.dart';

class DeviceConfigWidget extends StatelessWidget {
  final ExposedUserDeviceIdentifier identifier;

  const DeviceConfigWidget({super.key, required this.identifier});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineControlBloc, EngineControlState>(
      buildWhen: ((previous, current) =>
          current is EngineStartedState || current is EngineStoppedState),
      builder: (context, state) {
        return BlocBuilder<
          UserDeviceConfigurationCubit,
          UserDeviceConfigurationState
        >(
          builder: (context, userConfigState) {
            var userDeviceConfigCubit =
                BlocProvider.of<UserDeviceConfigurationCubit>(context);
            return BlocBuilder<DeviceManagerBloc, DeviceManagerState>(
              builder: (context, state) {
                List<AbstractSettingsSection> tiles = [];
                var engineIsRunning = BlocProvider.of<EngineControlBloc>(
                  context,
                ).isRunning;
                ExposedServerDeviceDefinition config;
                try {
                  config = userDeviceConfigCubit.configs[identifier]!;
                } catch (e) {
                  // If we can't find the corresponding device, return nothing.
                  logWarning("Cannot find identifier to render user config");
                  return const SizedBox.shrink();
                }

                tiles.add(
                  SettingsSection(
                    tiles: [
                      SettingsTile.navigation(
                        enabled: !engineIsRunning,
                        title: const Text("Display Name"),
                        value: Text(config.displayName ?? ""),
                        onPressed: (context) {
                          final TextEditingController nameController =
                              TextEditingController(
                                text: config.displayName ?? "",
                              );
                          var nameField = TextField(
                            controller: nameController,
                            onSubmitted: (value) async {
                              Navigator.pop(context);
                              await userDeviceConfigCubit.updateDisplayName(
                                identifier,
                                config,
                                value,
                              );
                            },
                            decoration: const InputDecoration(
                              hintText: "Display Name Entry",
                            ),
                          );
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Display Name'),
                              content: nameField,
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Ok'),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await userDeviceConfigCubit
                                        .updateDisplayName(
                                          identifier,
                                          config,
                                          nameController.text,
                                        );
                                  },
                                ),
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SettingsTile.navigation(
                        enabled: !engineIsRunning,
                        title: const Text("Message Gap (ms)"),
                        value: Text(
                          config.messageGapMs?.toString() ?? "Default",
                        ),
                        onPressed: (context) {
                          final TextEditingController gapController =
                              TextEditingController(
                                text: config.messageGapMs?.toString() ?? "",
                              );
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Message Gap (ms)'),
                              content: TextField(
                                controller: gapController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  hintText: "Leave empty for default",
                                ),
                                onSubmitted: (value) async {
                                  Navigator.pop(context);
                                  final parsed = int.tryParse(value);
                                  await userDeviceConfigCubit
                                      .updateMessageGapMs(
                                        identifier,
                                        config,
                                        parsed,
                                      );
                                },
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Ok'),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    final parsed =
                                        int.tryParse(gapController.text);
                                    await userDeviceConfigCubit
                                        .updateMessageGapMs(
                                          identifier,
                                          config,
                                          parsed,
                                        );
                                  },
                                ),
                                TextButton(
                                  child: const Text('Clear'),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await userDeviceConfigCubit
                                        .updateMessageGapMs(
                                          identifier,
                                          config,
                                          null,
                                        );
                                  },
                                ),
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SettingsTile.switchTile(
                        enabled: !engineIsRunning,
                        initialValue: !config.deny,
                        onToggle: (value) async {
                          await userDeviceConfigCubit.updateDeviceDeny(
                            identifier,
                            config,
                            !value,
                          );
                        },
                        title: const Text("Connect to this device"),
                      ),
                      CustomSettingsTile(
                        child: TextButton(
                          onPressed: engineIsRunning
                              ? null
                              : () async {
                                  await userDeviceConfigCubit
                                      .removeDeviceConfig(identifier);
                                },
                          child: const Text('Forget Device'),
                        ),
                      ),
                    ],
                  ),
                );
                final brightness = Theme.of(context).brightness;
                final transparentBg = SettingsThemeData(
                  settingsListBackground: Colors.transparent,
                );
                return SettingsList(
                  sections: tiles,
                  shrinkWrap: true,
                  lightTheme: brightness == Brightness.light
                      ? transparentBg
                      : null,
                  darkTheme: brightness == Brightness.dark
                      ? transparentBg
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }
}
