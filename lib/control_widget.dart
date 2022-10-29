import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:intiface_central/error_notifier_cubit.dart';
import 'package:intiface_central/navigation_cubit.dart';
import 'package:intiface_central/network_info_cubit.dart';
import 'package:intiface_central/update/update_bloc.dart';
import 'package:intiface_central/util/intiface_util.dart';

class ControlWidget extends StatelessWidget {
  const ControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var engineControlBloc = BlocProvider.of<EngineControlBloc>(context);
    var updateBloc = BlocProvider.of<UpdateBloc>(context);
    var navCubit = BlocProvider.of<NavigationCubit>(context);

    return BlocBuilder(
        bloc: updateBloc,
        builder: (context, updateState) {
          return BlocBuilder(
              bloc: engineControlBloc,
              builder: (context, EngineControlState state) {
                var statusMessage = "Unknown Status";
                var statusIcon = Icons.question_mark;
                var networkCubit = BlocProvider.of<NetworkInfoCubit>(context);
                var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
                final ColorScheme colors = Theme.of(context).colorScheme;
                void Function()? buttonAction = () => engineControlBloc.add(EngineControlEventStop());
                if (state is ClientConnectedState) {
                  statusMessage = state.clientName;
                  statusIcon = Icons.phone_in_talk;
                } else if (state is ClientDisconnectedState) {
                  statusMessage = "Server running, no client connected";
                  statusIcon = Icons.phone_disabled;
                  // Once we're in this state the engine is started.
                  buttonAction = () => engineControlBloc.add(EngineControlEventStop());
                } else if (state is EngineStartedState) {
                  statusMessage = "Server starting up";
                  statusIcon = Icons.block;
                  // In the case of starting up,
                  buttonAction = null;
                } else if (state is EngineStoppedState) {
                  statusMessage = "Server not running";
                  statusIcon = Icons.block;
                  buttonAction = () => engineControlBloc.add(EngineControlEventStart());
                }

                IconButton controlButton;

                if (isDesktop() && configCubit.useProcessEngine && !IntifacePaths.engineFile.existsSync()) {
                  controlButton = IconButton(
                      style: IconButton.styleFrom(
                        foregroundColor: colors.onPrimary,
                        backgroundColor: colors.primary,
                        disabledBackgroundColor: colors.onSurface.withOpacity(0.12),
                        hoverColor: colors.onPrimary.withOpacity(0.08),
                        focusColor: colors.onPrimary.withOpacity(0.12),
                        highlightColor: colors.onPrimary.withOpacity(0.12),
                      ),
                      iconSize: 90,
                      onPressed: null,
                      tooltip: "Engine file not found, run Check For Updates",
                      icon: const Icon(Icons.error));
                } else {
                  controlButton = IconButton(
                      style: IconButton.styleFrom(
                        foregroundColor: colors.onPrimary,
                        backgroundColor: colors.primary,
                        disabledBackgroundColor: colors.onSurface.withOpacity(0.12),
                        hoverColor: colors.onPrimary.withOpacity(0.08),
                        focusColor: colors.onPrimary.withOpacity(0.12),
                        highlightColor: colors.onPrimary.withOpacity(0.12),
                      ),
                      iconSize: 90,
                      onPressed: buttonAction,
                      tooltip: state is EngineStoppedState ? "Start Server" : "Stop Server",
                      icon: Icon(state is EngineStoppedState ? Icons.play_arrow : Icons.stop));
                }

                return Row(children: [
                  Padding(padding: const EdgeInsets.all(5.0), child: controlButton),
                  Expanded(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(state is ClientConnectedState ? "${state.clientName} Connected" : "No Client Connected"),
                        BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
                            bloc: configCubit,
                            buildWhen: (previous, current) => current is WebsocketServerAllInterfaces,
                            builder: (context, state) => Text(
                                "Server Address: ${configCubit.websocketServerAllInterfaces ? networkCubit.ip : "localhost"}:12345")),
                      ])),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BlocBuilder(
                          bloc: BlocProvider.of<ErrorNotifierCubit>(context),
                          builder: (context, ErrorNotifierState state) {
                            return Visibility(
                              visible: state is ErrorNotifierTriggerState ? true : false,
                              child: IconButton(
                                iconSize: 25,
                                onPressed: () => navCubit.goLogs(),
                                color: Colors.red,
                                icon: const Icon(Icons.warning),
                                tooltip: "Errors Occured",
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            );
                          }),
                      Visibility(
                          visible: configCubit.currentAppVersion != configCubit.latestAppVersion,
                          child: IconButton(
                              iconSize: 25,
                              onPressed: () => navCubit.goSettings(),
                              icon: const Icon(Icons.update, color: Colors.green),
                              tooltip: "Updates Available",
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints())),
                      Visibility(
                          visible: false,
                          child: IconButton(
                              iconSize: 25,
                              onPressed: () => navCubit.goNews(),
                              icon: const Icon(Icons.newspaper),
                              tooltip: "New News Available",
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints())),
                    ],
                  ),
                  Tooltip(message: statusMessage, child: Icon(statusIcon, size: 70)),
                ]);
              });
        });
  }
}
