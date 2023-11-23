import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/util/error_notifier_cubit.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';
import 'package:intiface_central/widget/log/widgets/loggy_stream_widget.dart';
import 'package:loggy/loggy.dart';

class LogPage extends StatelessWidget {
  static final DateTime appStartTime = DateTime.now();

  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<ErrorNotifierCubit>(context).clearError();
    var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    var guiSettingsCubit = BlocProvider.of<GuiSettingsCubit>(context);
    var expansionName = "gui_log_settings";
    final List<DropdownMenuEntry<LogLevel>> logLevelEntries = <DropdownMenuEntry<LogLevel>>[];
    for (final LogLevel level in LogLevel.values) {
      logLevelEntries.add(DropdownMenuEntry<LogLevel>(value: level, label: level.name));
    }
    return Expanded(
        child: Column(children: [
      BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
          buildWhen: (previous, current) => current is GuiSettingStateUpdate && current.valueName == expansionName,
          builder: (context, state) => ExpansionPanelList(
              elevation: 0,
              children: [
                ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return const ListTile(
                        title: Text("Log Options"),
                      );
                    },
                    body: ListView(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, children: [
                      DropdownMenu(
                          label: const Text("Log Level"),
                          dropdownMenuEntries: logLevelEntries,
                          onSelected: (value) => configCubit.displayLogLevel = value!.name),
                    ]),
                    isExpanded: guiSettingsCubit.getExpansionValue(expansionName) ?? false)
              ],
              expansionCallback: (panelIndex, isExpanded) {
                guiSettingsCubit.setExpansionValue(expansionName, isExpanded);
              })),
      Expanded(
          child: BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
              buildWhen: (previous, current) => current is DisplayLogLevelState,
              builder: (context, state) {
                var level = LogLevel.values
                    .firstWhere((element) => element.name == configCubit.displayLogLevel, orElse: () => LogLevel.info);
                return LoggyStreamWidget(logLevel: level);
              }))
    ]));
  }
}
