import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/update/github_update_provider.dart';
import 'package:intiface_central/bloc/util/app_reset_cubit.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/bloc/util/navigation_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:intiface_central/bloc/update/update_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Unused dynamic array for storing repaint trigger logic.
    final _ = [context.watch<EngineControlBloc>().state, context.watch<IntifaceConfigurationCubit>().state];
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
              onPressed: !engineIsRunning ? () => BlocProvider.of<UpdateBloc>(context).add(RunUpdate()) : null,
              child: isDesktop()
                  ? const Text("Check For App and Config Updates")
                  : const Text("Check for Config Updates"))),
      SettingsTile(title: const Text("App Version"), value: Text(cubit.currentAppVersion)),
    ];
    if (isDesktop() && canShowUpdate() && cubit.currentAppVersion != cubit.latestAppVersion) {
      if (Platform.isWindows) {
        versionTiles.add(SettingsTile.navigation(
            onPressed: (context) async {
              showDialog<void>(
                context: context,
                barrierDismissible: false, // user must tap button!
                builder: (BuildContext context) {
                  var updater = IntifaceCentralDesktopUpdater();
                  // This will fire the task into background execution.
                  updater.downloadUpdate();
                  return AlertDialog(
                    title: const Text('Downloading Update'),
                    content: const SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          SpinKitFadingCircle(
                            color: Colors.black,
                            size: 50.0,
                          ),
                          Text(
                              'Downloading update. Intiface Central will close and installer will run after download. Hit cancel to stop download.'),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          updater.stopExit();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            title: Text(
              "Intiface Central Desktop version ${cubit.latestAppVersion} is available, click here to update now.",
              style: const TextStyle(color: Colors.green),
            )));
        versionTiles.add(SettingsTile.navigation(
            onPressed: (context) async {
              const url = "https://github.com/intiface/intiface-central/releases";
              if (await canLaunchUrlString(url)) {
                await launchUrlString(url);
              }
            },
            title: const Text(
              "If autoupdate doesn't work, or you want to install manually, click here to visit downloads site.",
              style: const TextStyle(color: Colors.green),
            )));
      } else {
        versionTiles.add(SettingsTile.navigation(
            onPressed: (context) async {
              const url = "https://github.com/intiface/intiface-central/releases";
              if (await canLaunchUrlString(url)) {
                await launchUrlString(url);
              }
            },
            title: Text(
              "Intiface Central Desktop version ${cubit.latestAppVersion} is available, click here to visit releases site.",
              style: const TextStyle(color: Colors.green),
            )));
      }
    }
    versionTiles.addAll([
      SettingsTile(title: const Text("Device Config Version"), value: Text(cubit.currentDeviceConfigVersion)),
    ]);

    var appSettingsTiles = [
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
          initialValue: cubit.showRepeaterMode,
          onToggle: (value) => cubit.showRepeaterMode = value,
          title: const Text("Show Repeater Mode (EXPERIMENTAL)")),
      SettingsTile.switchTile(
          initialValue: cubit.crashReporting,
          onToggle: cubit.canUseCrashReporting ? ((value) => cubit.crashReporting = value) : null,
          title: const Text("Crash Reporting")),
      SettingsTile.navigation(
          title: const Text("Send Logs to Developers"),
          onPressed:
              cubit.canUseCrashReporting ? ((context) => BlocProvider.of<NavigationCubit>(context).goSendLogs()) : null)
    ];

    if (isDesktop()) {
      appSettingsTiles.insert(
          2,
          SettingsTile.switchTile(
              initialValue: cubit.restoreWindowLocation,
              onToggle: (value) => cubit.restoreWindowLocation = value,
              title: const Text("Restore Window Location on Start")));

      appSettingsTiles.insert(
          3,
          SettingsTile.switchTile(
              initialValue: cubit.useDiscordRichPresence,
              onToggle: (value) => cubit.useDiscordRichPresence = value,
              title: const Text("Enable Discord Rich Presence")));
    }

    tiles.addAll([
      SettingsSection(title: const Text("Versions and Updates"), tiles: versionTiles),
      SettingsSection(title: const Text("App Settings"), tiles: appSettingsTiles)
    ]);

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
      tiles.add(SettingsSection(title: const Text("Advanced Mobile Settings"), tiles: mobileSettings));
    }

    List<Widget> widgets = [
      Expanded(
          child: SettingsList(
        sections: tiles,
        shrinkWrap: true,
      ))
    ];

    if (engineIsRunning) {
      widgets.add(const Text("Some settings may be unavailable while server is running.",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
    }

    // SettingsList apparently handles its own scrolling, so do not try wrapping this in scroll views or
    // list views. It will work on desktop and break on mobile.
    return Expanded(child: Column(children: widgets));
  }
}
