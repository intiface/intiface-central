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
        title: _settingsText("Theme"),
        value: _settingsText(
          themeModeLabels[cubit.themeModeSetting] ?? "System",
        ),
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
        title: _settingsText("Side Navigation Bar"),
      ),
      SettingsTile.switchTile(
        initialValue: cubit.checkForUpdateOnStart,
        onToggle: (value) => cubit.checkForUpdateOnStart = value,
        title: _settingsText(
          "Check For Updates when Intiface Central Launches",
        ),
      ),
      SettingsTile.switchTile(
        initialValue: cubit.crashReporting,
        onToggle: cubit.canUseCrashReporting
            ? ((value) => cubit.crashReporting = value)
            : null,
        title: _settingsText("Crash Reporting"),
      ),
      SettingsTile.navigation(
        title: _settingsText("Send Logs to Developers"),
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
          title: _settingsText("Restore Window Location on Start"),
        ),
      );

      appSettingsTiles.insert(
        3,
        SettingsTile.switchTile(
          initialValue: cubit.useDiscordRichPresence,
          onToggle: (value) => cubit.useDiscordRichPresence = value,
          title: _settingsText("Enable Discord Rich Presence"),
        ),
      );
    }

    if (supportsTray()) {
      const trayIconModeLabels = {
        "none": "No Tray Icon",
        "both": "Tray + Taskbar",
        "tray_only": "Tray Only",
      };

      appSettingsTiles.insert(
        isDesktop() ? 4 : 2,
        SettingsTile.navigation(
          title: _settingsText("System Tray Icon"),
          value: _settingsText(
            trayIconModeLabels[cubit.trayIconMode] ?? "Tray + Taskbar",
          ),
          onPressed: (context) {
            showDialog<String>(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text("System Tray Icon"),
                children: [
                  RadioGroup<String>(
                    groupValue: cubit.trayIconMode,
                    onChanged: (value) {
                      if (value != null) {
                        cubit.trayIconMode = value;
                      }
                      Navigator.pop(context);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: trayIconModeLabels.entries
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
      );
    }

    return SettingsSection(
      title: _settingsText("App Settings"),
      tiles: appSettingsTiles,
    );
  }
}

const _settingsTextStyle = TextStyle(fontFamily: 'Roboto');

Text _settingsText(String text) {
  return Text(text, style: _settingsTextStyle);
}
