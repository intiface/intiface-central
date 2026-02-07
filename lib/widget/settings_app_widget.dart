import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/util/navigation_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class SettingsAppWidget extends AbstractSettingsSection {
  final IntifaceConfigurationCubit cubit;

  const SettingsAppWidget({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    const themeModeLabels = {
      "system": "System",
      "light": "Light",
      "dark": "Dark",
    };
    var appSettingsTiles = <AbstractSettingsTile>[
      SettingsTile.navigation(
        title: const Text("Theme"),
        value: Text(themeModeLabels[cubit.themeModeSetting] ?? "System"),
        onPressed: (context) {
          showDialog<String>(
            context: context,
            builder: (context) => SimpleDialog(
              title: const Text("Theme"),
              children: [
                RadioGroup<String>(
                  groupValue: cubit.themeModeSetting,
                  onChanged: (value) {
                    if (value != null) {
                      cubit.themeModeSetting = value;
                    }
                    Navigator.pop(context);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: themeModeLabels.entries
                        .map(
                          (e) => RadioListTile<String>(
                            title: Text(e.value),
                            value: e.key,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      SettingsTile.switchTile(
        initialValue: cubit.useSideNavigationBar,
        onToggle: (value) => cubit.useSideNavigationBar = value,
        title: const Text("Side Navigation Bar"),
      ),
      SettingsTile.switchTile(
        initialValue: cubit.checkForUpdateOnStart,
        onToggle: (value) => cubit.checkForUpdateOnStart = value,
        title: const Text("Check For Updates when Intiface Central Launches"),
      ),
      SettingsTile.switchTile(
        initialValue: cubit.crashReporting,
        onToggle: cubit.canUseCrashReporting
            ? ((value) => cubit.crashReporting = value)
            : null,
        title: const Text("Crash Reporting"),
      ),
      SettingsTile.navigation(
        title: const Text("Send Logs to Developers"),
        onPressed: (context) =>
            BlocProvider.of<NavigationCubit>(context).goSendLogs(),
      ),
    ];

    if (isDesktop()) {
      appSettingsTiles.insert(
        2,
        SettingsTile.switchTile(
          initialValue: cubit.restoreWindowLocation,
          onToggle: (value) => cubit.restoreWindowLocation = value,
          title: const Text("Restore Window Location on Start"),
        ),
      );

      appSettingsTiles.insert(
        3,
        SettingsTile.switchTile(
          initialValue: cubit.useDiscordRichPresence,
          onToggle: (value) => cubit.useDiscordRichPresence = value,
          title: const Text("Enable Discord Rich Presence"),
        ),
      );
    }

    return SettingsSection(
      title: const Text("App Settings"),
      tiles: appSettingsTiles,
    );
  }
}
