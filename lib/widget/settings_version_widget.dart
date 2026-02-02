import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/update/github_update_provider.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:intiface_central/bloc/update/update_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SettingsVersionWidget extends AbstractSettingsSection {
  final IntifaceConfigurationCubit cubit;
  final bool engineIsRunning;

  const SettingsVersionWidget({
    super.key,
    required this.cubit,
    required this.engineIsRunning,
  });

  @override
  Widget build(BuildContext context) {
    List<AbstractSettingsTile> versionTiles = [
      SettingsTile(
        title: TextButton(
          onPressed: !engineIsRunning
              ? () => BlocProvider.of<UpdateBloc>(context).add(RunUpdate())
              : null,
          child: isDesktop()
              ? const Text("Check For App and Config Updates")
              : const Text("Check for Config Updates"),
        ),
      ),
      SettingsTile(
        title: const Text("App Version"),
        value: Text(cubit.currentAppVersion),
      ),
    ];
    if (isDesktop() &&
        canShowUpdate() &&
        cubit.currentAppVersion != cubit.latestAppVersion) {
      if (Platform.isWindows) {
        versionTiles.add(
          SettingsTile.navigation(
            onPressed: (context) async {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  var updater = IntifaceCentralDesktopUpdater();
                  updater.downloadUpdate();
                  return AlertDialog(
                    title: const Text('Downloading Update'),
                    content: const SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          SpinKitFadingCircle(color: Colors.black, size: 50.0),
                          Text(
                            'Downloading update. Intiface Central will close and installer will run after download. Hit cancel to stop download.',
                          ),
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
            ),
          ),
        );
        versionTiles.add(
          SettingsTile.navigation(
            onPressed: (context) async {
              const url =
                  "https://github.com/intiface/intiface-central/releases";
              if (await canLaunchUrlString(url)) {
                await launchUrlString(url);
              }
            },
            title: const Text(
              "If autoupdate doesn't work, or you want to install manually, click here to visit downloads site.",
              style: TextStyle(color: Colors.green),
            ),
          ),
        );
      } else {
        versionTiles.add(
          SettingsTile.navigation(
            onPressed: (context) async {
              const url =
                  "https://github.com/intiface/intiface-central/releases";
              if (await canLaunchUrlString(url)) {
                await launchUrlString(url);
              }
            },
            title: Text(
              "Intiface Central Desktop version ${cubit.latestAppVersion} is available, click here to visit releases site.",
              style: const TextStyle(color: Colors.green),
            ),
          ),
        );
      }
    }
    versionTiles.addAll([
      SettingsTile(
        title: const Text("Device Config Version"),
        value: Text(cubit.currentDeviceConfigVersion),
      ),
    ]);
    if (isDesktop()) {
      versionTiles.addAll([
        SettingsTile.switchTile(
          initialValue: cubit.usePrereleaseVersion,
          onToggle: (value) => cubit.usePrereleaseVersion = value,
          title: const Text("Use Prerelease (Beta) Version"),
        ),
      ]);
    }

    return SettingsSection(
      title: const Text("Versions and Updates"),
      tiles: versionTiles,
    );
  }
}
