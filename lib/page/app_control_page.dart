import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/widget/repeater_config_widget.dart';
import 'package:loggy/loggy.dart';

class AppControlPage extends StatelessWidget {
  const AppControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    return BlocBuilder<EngineControlBloc, EngineControlState>(
        buildWhen: ((previous, current) => current is EngineStartedState || current is EngineStoppedState),
        builder: (context, engineState) => BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
            buildWhen: ((previous, current) => current is AppModeState),
            builder: (context, settingsState) => Expanded(
                    child: Column(
                  children: [
                    DropdownButton<String>(
                      value: configCubit.appMode.name,
                      icon: const Icon(Icons.arrow_downward),
                      elevation: 16,
                      style: const TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 2,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: engineState is EngineStoppedState
                          ? (String? value) {
                              configCubit.appMode = AppMode.values.firstWhere((element) {
                                logInfo("${element.name} $value ${element.name == value}");
                                return element.name == value;
                              }, orElse: () => AppMode.engine);
                              logInfo("Set appMode to ${configCubit.appMode.name}");
                            }
                          : null,
                      items: AppMode.values.map((e) => e.name).map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const RepeaterConfigWidget()
                  ],
                ))));
  }
}
