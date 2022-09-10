import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingWidget extends StatelessWidget {
  const SettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var cubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    return BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
        builder: (context, state) => Expanded(
                child: SettingsList(platform: DevicePlatform.windows, sections: [
              SettingsSection(title: const Text("Updates"), tiles: [
                CustomSettingsTile(child: TextButton(onPressed: () => {}, child: const Text("Check For Updates")))
              ]),
              SettingsSection(title: const Text("Server Settings"), tiles: [
                SettingsTile.switchTile(
                    initialValue: cubit.startServerOnStartup,
                    onToggle: (value) => cubit.startServerOnStartup = value,
                    title: const Text("Start Server when Intiface Central Launches")),
                SettingsTile.navigation(
                    title: const Text("Server Name"),
                    value: Text(cubit.serverName),
                    onPressed: (context) {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: const Text('TextField in Dialog'),
                                content: TextField(
                                  controller: TextEditingController(text: cubit.serverName),
                                  onSubmitted: (value) {
                                    cubit.serverName = value;
                                    Navigator.pop(context);
                                  },
                                  decoration: const InputDecoration(hintText: "Text Field in Dialog"),
                                ),
                              ));
                    })
              ]),
              SettingsSection(title: const Text("Device Managers"), tiles: [
                SettingsTile.switchTile(
                    initialValue: cubit.useBluetoothLE,
                    onToggle: (value) => cubit.useBluetoothLE = value,
                    title: const Text("Bluetooth LE")),
                SettingsTile.switchTile(
                    initialValue: cubit.useDeviceWebsocketServer,
                    onToggle: (value) => cubit.useDeviceWebsocketServer = value,
                    title: const Text("Device Websocket Server")),
                SettingsTile.switchTile(
                    initialValue: cubit.useXInput,
                    onToggle: (value) => cubit.useXInput = value,
                    title: const Text("XInput (Windows Only)")),
                SettingsTile.switchTile(
                    initialValue: cubit.useLovenseConnectService,
                    onToggle: (value) => cubit.startServerOnStartup = value,
                    title: const Text("Lovense Connect Service")),
                SettingsTile.switchTile(
                    initialValue: cubit.useLovenseHIDDongle,
                    onToggle: (value) => cubit.useLovenseHIDDongle = value,
                    title: const Text("Lovense HID Dongle")),
                SettingsTile.switchTile(
                    initialValue: cubit.useLovenseSerialDongle,
                    onToggle: (value) => cubit.useLovenseSerialDongle = value,
                    title: const Text("Lovense Serial Dongle")),
                SettingsTile.switchTile(
                    initialValue: cubit.useSerialPort,
                    onToggle: (value) => cubit.useSerialPort = value,
                    title: const Text("Serial Port")),
              ])
            ])));
  }
}
