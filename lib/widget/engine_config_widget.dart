import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:settings_ui/settings_ui.dart';

class EngineConfigWidget extends StatelessWidget {
  const EngineConfigWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Unused dynamic array for storing repaint trigger logic.
    final _ = [
      context.select<EngineControlBloc, EngineControlState?>(
          (bloc) => bloc.state is EngineStartedState || bloc.state is EngineStoppedState ? bloc.state : null),
      context.watch<IntifaceConfigurationCubit>().state,
      context.watch<GuiSettingsCubit>().state,
    ];

    var cubit = BlocProvider.of<IntifaceConfigurationCubit>(context);

    var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    var portController = TextEditingController();
    portController.text = configCubit.repeaterLocalPort.toString();

    var serverNameController = TextEditingController(text: cubit.serverName);
    var websocketPortController = TextEditingController(text: cubit.websocketServerPort.toString());

    var engineIsRunning = BlocProvider.of<EngineControlBloc>(context).isRunning;
    List<AbstractSettingsSection> tiles = [];

    tiles.addAll([
      SettingsSection(title: const Text("Server Settings"), tiles: [
        // Turn this off until we know the server is mostly stable, or have a way to handle crash on startup
        // gracefully.
        SettingsTile.switchTile(
            enabled: !engineIsRunning,
            initialValue: cubit.startServerOnStartup,
            onToggle: (value) => cubit.startServerOnStartup = value,
            title: const Text("Start Server when Intiface Central Launches")),
        SettingsTile.navigation(
            enabled: !engineIsRunning,
            title: const Text("Server Name"),
            value: Text(cubit.serverName),
            onPressed: (context) {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text('Server Name'),
                        content: TextField(
                          controller: serverNameController,
                          onSubmitted: (value) {
                            cubit.serverName = value;
                            Navigator.pop(context);
                          },
                          decoration: const InputDecoration(hintText: "Server Name Entry"),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              cubit.serverName = serverNameController.text;
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ));
            }),
        SettingsTile.navigation(
            enabled: !engineIsRunning,
            title: const Text("Server Port"),
            value: Text(cubit.websocketServerPort.toString()),
            onPressed: (context) {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text('Server Port'),
                        content: TextField(
                          keyboardType: TextInputType.number,
                          controller: websocketPortController,
                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                          onSubmitted: (value) {
                            var newPort = int.tryParse(value);
                            if (newPort != null && newPort > 1024 && newPort < 65536) {
                              cubit.websocketServerPort = newPort;
                            }
                            Navigator.pop(context);
                          },
                          decoration: const InputDecoration(hintText: "Server Port Entry"),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              var newPort = int.tryParse(websocketPortController.text);
                              if (newPort != null && newPort > 1024 && newPort < 65536) {
                                cubit.websocketServerPort = newPort;
                              }
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ));
            }),
        SettingsTile.switchTile(
            enabled: !engineIsRunning,
            initialValue: cubit.websocketServerAllInterfaces,
            onToggle: (value) => cubit.websocketServerAllInterfaces = value,
            title: const Text("Listen on all network interfaces")),
      ])
    ]);

    List<AbstractSettingsTile> deviceSettings = [
      SettingsTile.switchTile(
          enabled: !engineIsRunning,
          initialValue: cubit.useBluetoothLE,
          onToggle: (value) => cubit.useBluetoothLE = value,
          title: const Text("Bluetooth LE")),
    ];
    if (isDesktop()) {
      if (Platform.isWindows) {
        deviceSettings.addAll([
          SettingsTile.switchTile(
              enabled: !engineIsRunning,
              initialValue: cubit.useXInput,
              onToggle: (value) => cubit.useXInput = value,
              title: const Text("XBox Compatible Gamepads (XInput)")),
        ]);
      }

      deviceSettings.addAll([
        SettingsTile.switchTile(
            enabled: !engineIsRunning,
            initialValue: cubit.useHID,
            onToggle: (value) => cubit.useHID = value,
            title: const Text("HID Devices (Joycon, etc...)")),
        SettingsTile.switchTile(
            enabled: !engineIsRunning,
            initialValue: cubit.useLovenseConnectService,
            onToggle: (value) => cubit.useLovenseConnectService = value,
            title: const Text("Lovense Connect Service")),
        SettingsTile.switchTile(
            enabled: !engineIsRunning,
            initialValue: cubit.useLovenseHIDDongle,
            onToggle: (value) => cubit.useLovenseHIDDongle = value,
            title: const Text("Lovense USB Dongle (HID/White Circuit Board)")),
      ]);
    }

    deviceSettings.add(SettingsTile(
      title: const Text(
        "Other Device Managers are in Advanced Settings Below",
        textAlign: TextAlign.center,
      ),
    ));

    tiles.add(SettingsSection(title: const Text("Device Managers"), tiles: deviceSettings));

    var expansionName = "advanced-settings";
    var guiSettingsCubit = BlocProvider.of<GuiSettingsCubit>(context);
    var advancedSettingsTiles = [
      SettingsTile.switchTile(
          enabled: true,
          initialValue: guiSettingsCubit.getExpansionValue(expansionName),
          onToggle: (value) => guiSettingsCubit.setExpansionValue(expansionName, value),
          title: const Text("Show Advanced/Experimental Settings")),
    ];

    if (guiSettingsCubit.getExpansionValue(expansionName) ?? false) {
      advancedSettingsTiles.add(SettingsTile.switchTile(
          enabled: !engineIsRunning,
          initialValue: cubit.allowRawMessages,
          onToggle: (value) => cubit.allowRawMessages = value,
          title: const Text("Allow Raw Messages")));
      advancedSettingsTiles.add(SettingsTile.switchTile(
          enabled: !engineIsRunning,
          initialValue: cubit.broadcastServerMdns,
          onToggle: (value) => cubit.broadcastServerMdns = value,
          title: const Text("Broadcast Server Info via mDNS")));
      advancedSettingsTiles.add(SettingsTile.navigation(
          enabled: !engineIsRunning,
          title: const Text("mDNS Identifier Suffix (Optional)"),
          value: Text(cubit.mdnsSuffix),
          onPressed: (context) {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: const Text('mDNS Suffix'),
                      content: TextField(
                        controller: TextEditingController(text: cubit.mdnsSuffix),
                        onSubmitted: (value) {
                          cubit.mdnsSuffix = value;
                          Navigator.pop(context);
                        },
                        decoration: const InputDecoration(hintText: "mDNS Suffix Entry"),
                      ),
                    ));
          }));
    }

    var advancedSettings =
        SettingsSection(title: const Text("Advanced/Experimental Settings"), tiles: advancedSettingsTiles);

    // Add the advanced settings tiles first, then the extra advanced sections after.
    tiles.addAll([advancedSettings]);

    var advancedManagers = [
      SettingsTile.switchTile(
          enabled: !engineIsRunning,
          initialValue: cubit.useDeviceWebsocketServer,
          onToggle: (value) => cubit.useDeviceWebsocketServer = value,
          title: const Text("Device Websocket Server")),
    ];

    if (!isMobile()) {
      advancedManagers.addAll([
        SettingsTile.switchTile(
            enabled: !engineIsRunning,
            initialValue: cubit.useLovenseSerialDongle,
            onToggle: (value) => cubit.useLovenseSerialDongle = value,
            title: const Text("Lovense USB Dongle (Serial/Black Circuit Board)")),
        SettingsTile.switchTile(
            enabled: !engineIsRunning,
            initialValue: cubit.useSerialPort,
            onToggle: (value) => cubit.useSerialPort = value,
            title: const Text("Serial Port")),
      ]);
    }

    if (guiSettingsCubit.getExpansionValue(expansionName) ?? false) {
      tiles.add(SettingsSection(title: const Text("Advanced Device Managers"), tiles: advancedManagers));
    }

    List<Widget> widgets = [Expanded(child: SettingsList(shrinkWrap: true, sections: tiles))];

    if (engineIsRunning) {
      widgets.add(const Text("Some settings may be unavailable while server is running.",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
    }

    // SettingsList apparently handles its own scrolling, so do not try wrapping this in scroll views or
    // list views. It will work on desktop and break on mobile.
    return Expanded(child: Column(children: widgets));
  }
}
