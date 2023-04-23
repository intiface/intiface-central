import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bridge_generated.dart';
import 'package:intiface_central/device/device_manager_bloc.dart';
import 'package:intiface_central/device_configuration/user_device_configuration_cubit.dart';
import 'package:loggy/loggy.dart';
import 'package:settings_ui/settings_ui.dart';

class DeviceConfigWidget extends StatelessWidget {
  final UserConfigDeviceIdentifier identifier;

  const DeviceConfigWidget({Key? key, required this.identifier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(builder: (context, engineState) {
      var userDeviceConfigCubit = BlocProvider.of<UserDeviceConfigurationCubit>(context);
      return BlocBuilder<DeviceManagerBloc, DeviceManagerState>(builder: (context, state) {
        List<AbstractSettingsSection> tiles = [];

        ExposedWritableUserDeviceConfig config;
        try {
          config = userDeviceConfigCubit.configs.firstWhere((element) => element.matches(identifier));
        } catch (e) {
          // If we can't find the corresponding device, return nothing.
          logWarning("Cannot find identifier to render user config");
          return const SizedBox.shrink();
        }

        tiles.add(SettingsSection(tiles: [
          SettingsTile(
            title: const Text("Protocol"),
            value: Text(config.identifier.protocol),
          ),
          SettingsTile(
            title: const Text("Identifier"),
            value: Text(config.identifier.identifier ?? "default"),
          ),
          SettingsTile(
            title: const Text("Address"),
            value: Text(config.identifier.address),
          ),
          SettingsTile(
            title: const Text("Reserved Index"),
            value: Text("${config.reservedIndex}"),
          ),
          SettingsTile.navigation(
              title: const Text("Display Name"),
              value: Text(config.displayName ?? ""),
              onPressed: (context) {
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: const Text('Display Name'),
                          content: TextField(
                            controller: TextEditingController(text: config.displayName ?? ""),
                            onSubmitted: (value) async {
                              Navigator.pop(context);
                              await userDeviceConfigCubit.updateDisplayName(config.identifier, value);
                            },
                            decoration: const InputDecoration(hintText: "Display Name Entry"),
                          ),
                        ));
              }),
          SettingsTile.switchTile(
              initialValue: config.deny,
              onToggle: (value) async {
                await userDeviceConfigCubit.updateDeviceDeny(config.identifier, value);
              },
              title: const Text("Do Not Connect to this Device")),
          SettingsTile.switchTile(
              initialValue: config.allow,
              onToggle: (value) async {
                await userDeviceConfigCubit.updateDeviceAllow(config.identifier, value);
              },
              title: const Text("Only Connect to this Device")),
          CustomSettingsTile(
              child: TextButton(
            child: const Text('Remove Device Configuration'),
            onPressed: () async {
              await userDeviceConfigCubit.removeDeviceConfig(config.identifier);
            },
          ))
        ]));

        return SettingsList(
          sections: tiles,
          shrinkWrap: true,
        );
      });
    });
  }
}
