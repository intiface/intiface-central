import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/widget/engine_config_widget.dart';
import 'package:intiface_central/widget/repeater_config_widget.dart';
import 'package:intl/intl.dart';
import 'package:loggy/loggy.dart';

class AppControlPage extends StatelessWidget {
  const AppControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    var modes = [AppMode.engine];
    if (configCubit.showRepeaterMode) {
      modes.add(AppMode.repeater);
    }
    return BlocBuilder<EngineControlBloc, EngineControlState>(
        buildWhen: ((previous, current) => current is EngineStartedState || current is EngineStoppedState),
        builder: (context, engineState) => BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
            buildWhen: ((previous, current) => current is AppModeState),
            builder: (context, settingsState) => Expanded(
                    child: Column(
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: Colors.deepPurpleAccent, //background color of dropdown button
                                border: Border.all(color: Colors.black38, width: 3), //border of dropdown button
                                borderRadius: BorderRadius.circular(50), //border raiuds of dropdown button
                                boxShadow: const <BoxShadow>[
                                  //apply shadow on Dropdown button
                                  BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.57), //shadow for button
                                      blurRadius: 5) //blur radius of shadow
                                ]),
                            child: Padding(
                                padding: const EdgeInsets.only(left: 30, right: 30),
                                child: DropdownButton<String>(
                                  value: configCubit.appMode.name,
                                  elevation: 16,
                                  onChanged: engineState is EngineStoppedState
                                      ? (String? value) {
                                          configCubit.appMode = AppMode.values.firstWhere((element) {
                                            return element.name == value;
                                          }, orElse: () => AppMode.engine);
                                          logDebug("Set appMode to ${configCubit.appMode.name}");
                                        }
                                      : null,
                                  items: modes.map((e) => e.name).map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text("App Mode: ${toBeginningOfSentenceCase(value)!}"),
                                    );
                                  }).toList(),
                                  icon: const Padding(
                                      //Icon at tail, arrow bottom is default icon
                                      padding: EdgeInsets.only(left: 20),
                                      child: Icon(Icons.arrow_circle_down_sharp)),
                                  iconEnabledColor: Colors.white, //Icon color
                                  style: const TextStyle(
                                      //te
                                      color: Colors.white, //Font color
                                      fontSize: 20 //font size on dropdown button
                                      ),
                                  dropdownColor: Colors.deepPurpleAccent, //dropdown background color
                                  underline: Container(), //remove underline
                                )))),
                    configCubit.appMode == AppMode.repeater ? const RepeaterConfigWidget() : const EngineConfigWidget()
                  ],
                ))));
  }
}
