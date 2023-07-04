import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/app_reset_cubit.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:intiface_central/navigation_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:intiface_central/update/update_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingWidget extends StatelessWidget {
  const SettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineControlBloc, EngineControlState>(
        buildWhen: ((previous, current) => current is EngineStartedState || current is EngineStoppedState),
        builder: (context, engineState) =>
            BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(builder: (context, state) {
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

              var versionTiles = [
                CustomSettingsTile(
                    child: TextButton(
                        onPressed:
                            !engineIsRunning ? () => BlocProvider.of<UpdateBloc>(context).add(RunUpdate()) : null,
                        child: const Text("Check For Updates"))),
                CustomSettingsTile(child: Text("App Version: ${cubit.currentAppVersion}")),
              ];
              if (isDesktop() && cubit.currentAppVersion != cubit.latestAppVersion) {
                versionTiles.add(CustomSettingsTile(
                    child: TextButton(
                        onPressed: () async {
                          const url = "https://github.com/intiface/intiface-central/releases";
                          if (await canLaunchUrlString(url)) {
                            await launchUrlString(url);
                          }
                        },
                        child: Text(
                            "New Intiface Central Desktop version ${cubit.latestAppVersion} is available, click here to go to releases site."))));
              }
              versionTiles.addAll([
                CustomSettingsTile(child: Text("Device Config Version: ${cubit.currentDeviceConfigVersion}")),
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
                      title: const Text("Listen on all network interfaces.")),
                ])
              ]);

              var deviceSettings = [
                SettingsTile.switchTile(
                    enabled: !engineIsRunning,
                    initialValue: cubit.useBluetoothLE,
                    onToggle: (value) => cubit.useBluetoothLE = value,
                    title: const Text("Bluetooth LE")),
                SettingsTile.switchTile(
                    enabled: !engineIsRunning,
                    initialValue: cubit.useDeviceWebsocketServer,
                    onToggle: (value) => cubit.useDeviceWebsocketServer = value,
                    title: const Text("Device Websocket Server"))
              ];
              if (isDesktop()) {
                deviceSettings.addAll([
                  SettingsTile.switchTile(
                      enabled: !engineIsRunning,
                      initialValue: cubit.useXInput,
                      onToggle: (value) => cubit.useXInput = value,
                      title: const Text("XInput (Windows Only)")),
                  SettingsTile.switchTile(
                      enabled: !engineIsRunning,
                      initialValue: cubit.useLovenseConnectService,
                      onToggle: (value) => cubit.useLovenseConnectService = value,
                      title: const Text("Lovense Connect Service")),
                  SettingsTile.switchTile(
                      enabled: !engineIsRunning,
                      initialValue: cubit.useLovenseHIDDongle,
                      onToggle: (value) => cubit.useLovenseHIDDongle = value,
                      title: const Text("Lovense HID Dongle")),
                  SettingsTile.switchTile(
                      enabled: !engineIsRunning,
                      initialValue: cubit.useLovenseSerialDongle,
                      onToggle: (value) => cubit.useLovenseSerialDongle = value,
                      title: const Text("Lovense Serial Dongle")),
                  SettingsTile.switchTile(
                      enabled: !engineIsRunning,
                      initialValue: cubit.useSerialPort,
                      onToggle: (value) => cubit.useSerialPort = value,
                      title: const Text("Serial Port")),
                ]);
              }

              tiles.add(SettingsSection(title: const Text("Device Managers"), tiles: deviceSettings));

              if (Platform.isAndroid) {
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
                tiles.add(SettingsSection(title: const Text("Mobile Settings"), tiles: mobileSettings));
              }

              tiles.add(SettingsSection(title: const Text("Reset Application"), tiles: [
                CustomSettingsTile(
                    child: TextButton(
                  onPressed: !engineIsRunning
                      ? () {
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
                  child: const Text("Reset User Device Configuration"),
                )),
                CustomSettingsTile(
                    child: TextButton(
                  onPressed: !engineIsRunning
                      ? () {
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
                  child: const Text("Reset Application Configuration"),
                ))
              ]));
              List<Widget> widgets = [Expanded(child: SettingsList(sections: tiles))];
              if (engineIsRunning) {
                widgets.add(const Text("Some settings may be unavailable while server is running.",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
              }

              return Expanded(child: Column(children: widgets));
            }));
  }
}
