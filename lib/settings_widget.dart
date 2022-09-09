import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingWidget extends StatelessWidget {
  const SettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var repo = RepositoryProvider.of<IntifaceConfigurationRepository>(context);
    var cubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    return BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
        builder: (context, state) => Expanded(
                child: SettingsList(platform: DevicePlatform.windows, sections: [
              //const SettingsSection(title: Text("Updates"), tiles: []),
              SettingsSection(title: const Text("Server Settings"), tiles: [
                SettingsTile.switchTile(
                    initialValue: repo.startServerOnStartup,
                    onToggle: (value) => cubit.startServerOnStartup = value,
                    title: const Text("Start Server when Intiface Central Launches")),
                SettingsTile.navigation(
                    title: const Text("Start Name"),
                    value: Text(repo.serverName),
                    onPressed: (context) {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: Text('TextField in Dialog'),
                                content: TextField(
                                  onChanged: (value) {
                                    cubit.serverName(value);
                                  },
                                  decoration: InputDecoration(hintText: "Text Field in Dialog"),
                                ),
                              ));
                    })
              ])
            ])));
  }
}
