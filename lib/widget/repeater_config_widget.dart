import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:settings_ui/settings_ui.dart';

class RepeaterConfigWidget extends StatelessWidget {
  const RepeaterConfigWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    var portController = TextEditingController();
    portController.text = configCubit.repeaterLocalPort.toString();
    var remoteAddressController = TextEditingController();
    remoteAddressController.text = configCubit.repeaterRemoteAddress;
    return Expanded(
        child: BlocBuilder<EngineControlBloc, EngineControlState>(
            buildWhen: ((previous, current) => current is EngineStartedState || current is EngineStoppedState),
            builder: (context, engineState) {
              return BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
                  buildWhen: (previousState, currentState) =>
                      currentState is RepeaterLocalPortState || currentState is RepeaterRemoteAddressState,
                  builder: (context, state) {
                    var cubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
                    var engineIsRunning = BlocProvider.of<EngineControlBloc>(context).isRunning;
                    List<AbstractSettingsSection> tiles = [
                      SettingsSection(title: const Text("Repeater Settings"), tiles: [
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
                                          controller: TextEditingController(text: cubit.repeaterLocalPort.toString()),
                                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                          onSubmitted: (value) {
                                            var newPort = int.tryParse(value);
                                            if (newPort != null && newPort > 1024 && newPort < 65536) {
                                              cubit.repeaterLocalPort = newPort;
                                            }
                                            Navigator.pop(context);
                                          },
                                          decoration: const InputDecoration(hintText: "Local Port"),
                                        ),
                                      ));
                            }),
                        SettingsTile.navigation(
                            enabled: !engineIsRunning,
                            title: const Text("Remote Address"),
                            value: Text(cubit.repeaterRemoteAddress),
                            onPressed: (context) {
                              showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        title: const Text('Remote Address'),
                                        content: TextField(
                                          //keyboardType: TextInputType.number,
                                          controller: TextEditingController(text: cubit.repeaterRemoteAddress),
                                          //inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                          onSubmitted: (value) {
                                            configCubit.repeaterRemoteAddress = value;
                                            Navigator.pop(context);
                                          },
                                          decoration: const InputDecoration(hintText: "Remote Address"),
                                        ),
                                      ));
                            }),
                      ])
                    ];
                    return SettingsList(sections: tiles);
                    // Expanded(child: Column(children: [Expanded(child: SettingsList(sections: tiles))]));
                  });
            }));
  }
}
