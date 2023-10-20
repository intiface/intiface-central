import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/util/app_reset_cubit.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';
import 'package:intiface_central/bloc/util/navigation_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:intiface_central/bloc/update/update_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    var expansionName = "advanced-settings";
    return BlocBuilder<EngineControlBloc, EngineControlState>(
        buildWhen: ((previous, current) => current is EngineStartedState || current is EngineStoppedState),
        builder: (context, engineState) =>
            BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(builder: (context, state) {
              return BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
                  buildWhen: (previous, current) =>
                      current is GuiSettingStateUpdate && current.valueName == expansionName,
                  builder: (context, state) {
                    var cubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
                    var engineIsRunning = BlocProvider.of<EngineControlBloc>(context).isRunning;
                    List<AbstractSettingsSection> tiles = [];

                    if (!cubit.useSideNavigationBar) {
                      tiles.add(SettingsSection(tiles: [
                        SettingsTile.navigation(
                            title: const Text("Help / About"),
                            onPressed: (context) {
                              BlocProvider.of<NavigationCubit>(context).goAbout();
                            }),
                      ]));
                    }

                    List<AbstractSettingsTile> versionTiles = [
                      SettingsTile(
                          title: TextButton(
                              onPressed:
                                  !engineIsRunning ? () => BlocProvider.of<UpdateBloc>(context).add(RunUpdate()) : null,
                              child: const Text("Check For Updates"))),
                      SettingsTile(title: const Text("App Version"), value: Text(cubit.currentAppVersion)),
                    ];
                    if (isDesktop() && canShowUpdate() && cubit.currentAppVersion != cubit.latestAppVersion) {
                      versionTiles.add(SettingsTile.navigation(
                          onPressed: (context) async {
                            const url = "https://github.com/intiface/intiface-central/releases";
                            if (await canLaunchUrlString(url)) {
                              await launchUrlString(url);
                            }
                          },
                          title: Text(
                            "Intiface Central Desktop version ${cubit.latestAppVersion} is available, click to visit releases site.",
                            style: const TextStyle(color: Colors.green),
                          )));
                    }
                    versionTiles.addAll([
                      SettingsTile(
                          title: const Text("Device Config Version"), value: Text(cubit.currentDeviceConfigVersion)),
                    ]);

                    tiles.addAll([
                      SettingsSection(title: const Text("Versions and Updates"), tiles: versionTiles),
                      SettingsSection(title: const Text("App Settings"), tiles: [
                        SettingsTile.switchTile(
                            initialValue: cubit.useLightTheme,
                            onToggle: (value) => cubit.useLightTheme = value,
                            title: const Text("Light Theme")),
                        SettingsTile.switchTile(
                            initialValue: cubit.useSideNavigationBar,
                            onToggle: (value) => cubit.useSideNavigationBar = value,
                            title: const Text("Side Navigation Bar")),
                        SettingsTile.switchTile(
                            initialValue: cubit.checkForUpdateOnStart,
                            onToggle: (value) => cubit.checkForUpdateOnStart = value,
                            title: const Text("Check For Updates when Intiface Central Launches")),
                        SettingsTile.switchTile(
                            initialValue: cubit.crashReporting,
                            onToggle: cubit.canUseCrashReporting ? ((value) => cubit.crashReporting = value) : null,
                            title: const Text("Crash Reporting")),
                        SettingsTile.navigation(
                            title: const Text("Send Logs to Developers"),
                            onPressed: cubit.canUseCrashReporting
                                ? ((context) => BlocProvider.of<NavigationCubit>(context).goSendLogs())
                                : null)
                      ]),
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
                                          controller: TextEditingController(text: cubit.serverName),
                                          onSubmitted: (value) {
                                            cubit.serverName = value;
                                            Navigator.pop(context);
                                          },
                                          decoration: const InputDecoration(hintText: "Server Name Entry"),
                                        ),
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
                                          controller: TextEditingController(text: cubit.websocketServerPort.toString()),
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
                      deviceSettings.addAll([
                        SettingsTile.switchTile(
                            enabled: !engineIsRunning,
                            initialValue: cubit.useXInput,
                            onToggle: (value) => cubit.useXInput = value,
                            title: const Text("XBox Compatible Gamepads (XInput)")),
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

                    tiles.add(SettingsSection(title: const Text("Reset Application"), tiles: [
                      SettingsTile.navigation(
                        onPressed: !engineIsRunning
                            ? (context) {
                                showDialog<void>(
                                  context: context,
                                  barrierDismissible: false, // user must tap button!
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Reset User Device Configuration'),
                                      content: const SingleChildScrollView(
                                        child: ListBody(
                                          children: <Widget>[
                                            Text(
                                                'This will erase the user device configuration, which stores per-device info. It is recommended to stop and restart the application after this step.'),
                                            Text('Would you like to continue?'),
                                          ],
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('Ok'),
                                          onPressed: () async {
                                            logWarning("Running user device configuration reset");
                                            // This is gross and a bug, but until we can check context mounting across asyncs in Flutter
                                            // 3.4+, we're stuck.
                                            var navigator = Navigator.of(context);
                                            var resetCubit = BlocProvider.of<AppResetCubit>(context);
                                            // Delete all file assets
                                            if (await IntifacePaths.userDeviceConfigFile.exists()) {
                                              await IntifacePaths.userDeviceConfigFile.delete();
                                            }
                                            logWarning("User device configuration reset finished");
                                            navigator.pop();
                                            resetCubit.reset();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            : null,
                        title: const Text("Reset User Device Configuration"),
                      ),
                      SettingsTile.navigation(
                        onPressed: !engineIsRunning
                            ? (context) {
                                showDialog<void>(
                                  context: context,
                                  barrierDismissible: false, // user must tap button!
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Reset Application to Defaults'),
                                      content: const SingleChildScrollView(
                                        child: ListBody(
                                          children: <Widget>[
                                            Text(
                                                'This will erase all configuration and downloaded engine/config files. It is recommended to stop and restart the application after this step.'),
                                            Text('Would you like to continue?'),
                                          ],
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('Ok'),
                                          onPressed: () async {
                                            logWarning("Running configuration reset");
                                            // This is gross and a bug, but until we can check context mounting across asyncs in Flutter
                                            // 3.4+, we're stuck.
                                            var navigator = Navigator.of(context);
                                            var resetCubit = BlocProvider.of<AppResetCubit>(context);
                                            // Delete all file assets
                                            if (await IntifacePaths.deviceConfigFile.exists()) {
                                              await IntifacePaths.deviceConfigFile.delete();
                                            }
                                            if (await IntifacePaths.newsFile.exists()) {
                                              await IntifacePaths.newsFile.delete();
                                            }
                                            if (await IntifacePaths.userDeviceConfigFile.exists()) {
                                              await IntifacePaths.userDeviceConfigFile.delete();
                                            }
                                            // Reset our configuration
                                            await cubit.reset();
                                            logWarning("Configuration reset finished");
                                            navigator.pop();
                                            resetCubit.reset();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            : null,
                        title: const Text("Reset Application Configuration"),
                      )
                    ]));

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

                    var advancedSettings = SettingsSection(
                        title: const Text("Advanced/Experimental Settings"), tiles: advancedSettingsTiles);

                    // Add the advanced settings tiles first, then the extra advanced sections after.
                    tiles.addAll([advancedSettings]);

                    var advancedManagers = [
                      SettingsTile.switchTile(
                          enabled: !engineIsRunning,
                          initialValue: cubit.useDeviceWebsocketServer,
                          onToggle: (value) => cubit.useDeviceWebsocketServer = value,
                          title: const Text("Device Websocket Server")),
                    ];

                    if (!Platform.isIOS && !Platform.isAndroid) {
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
                      tiles
                          .add(SettingsSection(title: const Text("Advanced Device Managers"), tiles: advancedManagers));
                    }

                    if (Platform.isAndroid || Platform.isIOS) {
                      var mobileSettings = [
                        SettingsTile.switchTile(
                            enabled: !engineIsRunning,
                            initialValue: cubit.useForegroundProcess,
                            onToggle: (value) {
                              cubit.useForegroundProcess = value;
                              showDialog<void>(
                                context: context,
                                barrierDismissible: false, // user must tap button!
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('App needs restart'),
                                    content: const SingleChildScrollView(
                                      child: ListBody(
                                        children: <Widget>[
                                          Text(
                                              'Changing to/from foregrounding requires an app restart. Please close and reopen the application to use foregrounding.'),
                                        ],
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Ok'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            title: const Text("Use Foreground Process"))
                      ];
                      // Only show when showing advanced settings, this shouldn't really be turned off now.
                      if (guiSettingsCubit.getExpansionValue(expansionName) ?? false) {
                        tiles
                            .add(SettingsSection(title: const Text("Advanced Mobile Settings"), tiles: mobileSettings));
                      }
                    }

                    List<Widget> widgets = [SettingsList(shrinkWrap: true, sections: tiles)];

                    if (engineIsRunning) {
                      widgets.add(const Text("Some settings may be unavailable while server is running.",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
                    }

                    // SettingsList apparently handles its own scrolling, so do not try wrapping this in scroll views or
                    // list views. It will work on desktop and break on mobile.
                    return Expanded(child: Column(children: [Expanded(child: SettingsList(sections: tiles))]));
                  });
            }));
  }
}
