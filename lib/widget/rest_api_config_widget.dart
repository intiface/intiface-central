import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class RestApiConfigWidget extends StatefulWidget {
  const RestApiConfigWidget({super.key});

  @override
  State<RestApiConfigWidget> createState() => _RestApiConfigWidgetState();
}

class _RestApiConfigWidgetState extends State<RestApiConfigWidget> {
  late TextEditingController _restPortController;

  @override
  void initState() {
    super.initState();
    _restPortController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    _restPortController.text = configCubit.restLocalPort.toString();
  }

  @override
  void dispose() {
    _restPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                currentState is RestLocalPortState,
            builder: (context, state) {
              var cubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
              var engineIsRunning = BlocProvider.of<EngineControlBloc>(
                context,
              ).isRunning;
              List<AbstractSettingsSection> tiles = [
                SettingsSection(
                  title: const Text("Rest API Settings"),
                  tiles: [
                    SettingsTile.navigation(
                      enabled: !engineIsRunning,
                      title: const Text("Rest API Port"),
                      value: Text(cubit.restLocalPort.toString()),
                      onPressed: (context) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Local Port'),
                            content: TextField(
                              keyboardType: TextInputType.number,
                              controller: _restPortController,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onSubmitted: (value) {
                                var newPort = int.tryParse(value);
                                if (newPort != null &&
                                    newPort > 1024 &&
                                    newPort < 65536) {
                                  cubit.restLocalPort = newPort;
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
                                    _restPortController.text,
                                  );
                                  if (newPort != null &&
                                      newPort > 1024 &&
                                      newPort < 65536) {
                                    cubit.restLocalPort = newPort;
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
                  ],
                ),
              ];
              return SettingsList(sections: tiles);
            },
          );
        },
      ),
    );
  }
}
