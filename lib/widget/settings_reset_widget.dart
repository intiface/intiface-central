import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/util/app_reset_cubit.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class SettingsResetWidget extends AbstractSettingsSection with UiLoggy {
  final IntifaceConfigurationCubit cubit;
  final bool engineIsRunning;

  SettingsResetWidget({
    super.key,
    required this.cubit,
    required this.engineIsRunning,
  });

  void _showResetDialog(
    BuildContext context, {
    required String title,
    required String description,
    required Future<void> Function(
      NavigatorState navigator,
      AppResetCubit resetCubit,
    )
    onConfirm,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(description),
                const Text('Would you like to continue?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () async {
                var navigator = Navigator.of(context);
                var resetCubit = BlocProvider.of<AppResetCubit>(context);
                await onConfirm(navigator, resetCubit);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: const Text("Reset Application"),
      tiles: [
        SettingsTile.navigation(
          onPressed: !engineIsRunning
              ? (context) {
                  _showResetDialog(
                    context,
                    title: 'Reset User Device Configuration',
                    description:
                        'This will erase the user device configuration, which stores per-device info. It is recommended to stop and restart the application after this step.',
                    onConfirm: (navigator, resetCubit) async {
                      logWarning("Running user device configuration reset");
                      if (await IntifacePaths.userDeviceConfigFile.exists()) {
                        await IntifacePaths.userDeviceConfigFile.delete();
                      }
                      logWarning("User device configuration reset finished");
                      navigator.pop();
                      resetCubit.reset();
                    },
                  );
                }
              : null,
          title: const Text("Reset User Device Configuration"),
        ),
        SettingsTile.navigation(
          onPressed: !engineIsRunning
              ? (context) {
                  _showResetDialog(
                    context,
                    title: 'Reset Application to Defaults',
                    description:
                        'This will erase all configuration and downloaded engine/config files. It is recommended to stop and restart the application after this step.',
                    onConfirm: (navigator, resetCubit) async {
                      logWarning("Running configuration reset");
                      if (await IntifacePaths.deviceConfigFile.exists()) {
                        await IntifacePaths.deviceConfigFile.delete();
                      }
                      if (await IntifacePaths.newsFile.exists()) {
                        await IntifacePaths.newsFile.delete();
                      }
                      if (await IntifacePaths.userDeviceConfigFile.exists()) {
                        await IntifacePaths.userDeviceConfigFile.delete();
                      }
                      await cubit.reset();
                      logWarning("Configuration reset finished");
                      navigator.pop();
                      resetCubit.reset();
                    },
                  );
                }
              : null,
          title: const Text("Reset Application Configuration"),
        ),
      ],
    );
  }
}
