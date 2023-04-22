import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/device/device_manager_bloc.dart';
import 'package:intiface_central/device_configuration/user_device_configuration_cubit.dart';
import 'package:settings_ui/settings_ui.dart';

class DeviceConfigWidget extends StatelessWidget {
  const DeviceConfigWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(builder: (context, engineState) {
      var userDeviceConfigCubit = BlocProvider.of<UserDeviceConfigurationCubit>(context);
      return BlocBuilder<DeviceManagerBloc, DeviceManagerState>(builder: (context, state) {
        List<Widget> knownDeviceWidgets = [const ListTile(title: Text("Known Devices"))];
        List<AbstractSettingsSection> tiles = [];

        for (var config in userDeviceConfigCubit.configs) {
          tiles.add(SettingsSection(title: Text(config.name), tiles: [
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
                onToggle: (value) {}, //=> config.allow = value,
                title: const Text("Do Not Connect to this Device")),
            SettingsTile.switchTile(
                initialValue: config.allow,
                onToggle: (value) {}, // => cubit.useLovenseSerialDongle = value,
                title: const Text("Only Connect to this Device")),
          ]));
        }

        return Expanded(
            child: SettingsList(
          sections: tiles,
          platform: DevicePlatform.windows,
        ));
      });
    });
  }
}
