import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bridge_generated.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:loggy/loggy.dart';
import 'package:settings_ui/settings_ui.dart';

class DeviceConfigWidget extends StatelessWidget {
  final UserConfigDeviceIdentifier identifier;

  const DeviceConfigWidget({super.key, required this.identifier});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineControlBloc, EngineControlState>(
        buildWhen: ((previous, current) => current is EngineStartedState || current is EngineStoppedState),
        builder: (context, state) {
          return BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(
              builder: (context, userConfigState) {
            var userDeviceConfigCubit = BlocProvider.of<UserDeviceConfigurationCubit>(context);
            return BlocBuilder<DeviceManagerBloc, DeviceManagerState>(builder: (context, state) {
              List<AbstractSettingsSection> tiles = [];
              var engineIsRunning = BlocProvider.of<EngineControlBloc>(context).isRunning;
              ExposedWritableUserDeviceConfig config;
              try {
                config = userDeviceConfigCubit.configs.firstWhere((element) => element.matches(identifier));
              } catch (e) {
                // If we can't find the corresponding device, return nothing.
                logWarning("Cannot find identifier to render user config");
                return const SizedBox.shrink();
              }

              tiles.add(SettingsSection(tiles: [
                SettingsTile.navigation(
                    enabled: !engineIsRunning,
                    title: const Text("Display Name"),
                    value: Text(config.displayName ?? ""),
                    onPressed: (context) {
                      final TextEditingController nameController =
                          TextEditingController(text: config.displayName ?? "");
                      var nameField = TextField(
                        controller: nameController,
                        onSubmitted: (value) async {
                          Navigator.pop(context);
                          await userDeviceConfigCubit.updateDisplayName(config.identifier, value);
                        },
                        decoration: const InputDecoration(hintText: "Display Name Entry"),
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
                                      await userDeviceConfigCubit.updateDisplayName(
                                          config.identifier, nameController.text);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ));
                    }),
                SettingsTile.switchTile(
                    enabled: !engineIsRunning,
                    initialValue: !(config.deny ?? false),
                    onToggle: (value) async {
                      await userDeviceConfigCubit.updateDeviceDeny(config.identifier, !value);
                    },
                    title: const Text("Connect to this device")),
                CustomSettingsTile(
                    child: TextButton(
                  onPressed: engineIsRunning
                      ? null
                      : () async {
                          await userDeviceConfigCubit.removeDeviceConfig(config.identifier);
                        },
                  child: const Text('Forget Device'),
                ))
              ]));

              return SettingsList(
                sections: tiles,
                shrinkWrap: true,
              );
            });
          });
        });
  }
}
