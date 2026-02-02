import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/bloc/util/navigation_cubit.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:intiface_central/widget/settings_version_widget.dart';
import 'package:intiface_central/widget/settings_app_widget.dart';
import 'package:intiface_central/widget/settings_reset_widget.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    var cubit = context.watch<IntifaceConfigurationCubit>();
    var engineIsRunning = context.watch<EngineControlBloc>().isRunning;
    List<AbstractSettingsSection> tiles = [];

    if (!cubit.useSideNavigationBar) {
      tiles.add(
        SettingsSection(
          tiles: [
            SettingsTile.navigation(
              title: const Text("Help / About"),
              onPressed: (context) {
                BlocProvider.of<NavigationCubit>(context).goAbout();
              },
            ),
          ],
        ),
      );
    }

    tiles.addAll([
      SettingsVersionWidget(cubit: cubit, engineIsRunning: engineIsRunning),
      SettingsAppWidget(cubit: cubit),
      SettingsSection(
        title: const Text("Experimental Features"),
        tiles: [
          SettingsTile.switchTile(
            initialValue: cubit.allowExperimentalRestServer,
            onToggle: (value) => cubit.allowExperimentalRestServer = value,
            title: const Text("REST Server"),
          ),
        ],
      ),
      SettingsResetWidget(cubit: cubit, engineIsRunning: engineIsRunning),
    ]);

    if (Platform.isAndroid || Platform.isIOS) {
      tiles.add(
        SettingsSection(
          title: const Text("Advanced Mobile Settings"),
          tiles: [
            SettingsTile.switchTile(
              enabled: !engineIsRunning,
              initialValue: cubit.useForegroundProcess,
              onToggle: (value) {
                cubit.useForegroundProcess = value;
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('App needs restart'),
                      content: const SingleChildScrollView(
                        child: ListBody(
                          children: <Widget>[
                            Text(
                              'Changing to/from foregrounding requires an app restart. Please close and reopen the application to use foregrounding.',
                            ),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Ok'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    );
                  },
                );
              },
              title: const Text("Use Foreground Process"),
            ),
          ],
        ),
      );
    }

    List<Widget> widgets = [
      Expanded(child: SettingsList(sections: tiles, shrinkWrap: true)),
    ];

    if (engineIsRunning) {
      widgets.add(
        const Text(
          "Some settings may be unavailable while server is running.",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }

    // SettingsList apparently handles its own scrolling, so do not try wrapping this in scroll views or
    // list views. It will work on desktop and break on mobile.
    return Expanded(child: Column(children: widgets));
  }
}
