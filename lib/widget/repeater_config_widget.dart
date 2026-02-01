import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class RepeaterConfigWidget extends StatelessWidget {
  const RepeaterConfigWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    var portController = TextEditingController();
    portController.text = configCubit.repeaterLocalPort.toString();

    var repeaterAddressController = TextEditingController(
      text: configCubit.repeaterRemoteAddress,
    );
    var repeaterPortController = TextEditingController(
      text: configCubit.repeaterLocalPort.toString(),
    );
    return Expanded(
      child: BlocBuilder<EngineControlBloc, EngineControlState>(
        buildWhen: ((previous, current) =>
            current is EngineStartedState || current is EngineStoppedState),
        builder: (context, engineState) {
          return BlocBuilder<
            IntifaceConfigurationCubit,
            IntifaceConfigurationState
          >(
            buildWhen: (previousState, currentState) =>
                currentState is RepeaterLocalPortState ||
                currentState is RepeaterRemoteAddressState,
            builder: (context, state) {
              var cubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
              var engineIsRunning = BlocProvider.of<EngineControlBloc>(
                context,
              ).isRunning;
              List<AbstractSettingsSection> tiles = [
                SettingsSection(
                  title: const Text("Repeater Settings"),
                  tiles: [
                    SettingsTile.navigation(
                      enabled: !engineIsRunning,
                      title: const Text("Repeater Port"),
                      value: Text(cubit.repeaterLocalPort.toString()),
                      onPressed: (context) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Local Port'),
                            content: TextField(
                              keyboardType: TextInputType.number,
                              controller: repeaterPortController,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onSubmitted: (value) {
                                var newPort = int.tryParse(value);
                                if (newPort != null &&
                                    newPort > 1024 &&
                                    newPort < 65536) {
                                  cubit.repeaterLocalPort = newPort;
                                }
                                Navigator.pop(context);
                              },
                              decoration: const InputDecoration(
                                hintText: "Local Port",
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'Cancel'),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  var newPort = int.tryParse(
                                    repeaterPortController.text,
                                  );
                                  if (newPort != null &&
                                      newPort > 1024 &&
                                      newPort < 65536) {
                                    cubit.repeaterLocalPort = newPort;
                                  }
                                  Navigator.pop(context);
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SettingsTile.navigation(
                      enabled: !engineIsRunning,
                      title: const Text("Remote Server Address"),
                      value: Text(cubit.repeaterRemoteAddress),
                      onPressed: (context) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remote Server Address'),
                            content: TextField(
                              //keyboardType: TextInputType.number,
                              controller: repeaterAddressController,
                              //inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                              onSubmitted: (value) {
                                configCubit.repeaterRemoteAddress = value;
                                Navigator.pop(context);
                              },
                              decoration: const InputDecoration(
                                hintText: "Remote Server Address",
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'Cancel'),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  configCubit.repeaterRemoteAddress =
                                      repeaterAddressController.text;
                                  Navigator.pop(context);
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ];
              return SettingsList(sections: tiles);
              // Expanded(child: Column(children: [Expanded(child: SettingsList(sections: tiles))]));
            },
          );
        },
      ),
    );
  }
}
