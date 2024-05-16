import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/bloc/util/error_notifier_cubit.dart';
import 'package:intiface_central/bloc/util/navigation_cubit.dart';
import 'package:intiface_central/bloc/util/network_info_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';

class ControlWidget extends StatelessWidget {
  const ControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Unused dynamic array for storing repaint trigger logic.
    final _ = context.select<IntifaceConfigurationCubit, bool>((bloc) => bloc.state is AppModeState);

    // No easy way to do "only update on certain states" with select, so we still use a BlocBuilder here.
    return BlocBuilder<EngineControlBloc, EngineControlState>(
        buildWhen: (EngineControlState previous, EngineControlState current) =>
            current is EngineStartingState ||
            current is EngineStartedState ||
            current is EngineStoppedState ||
            current is ClientConnectedState ||
            current is ClientDisconnectedState,
        builder: (context, EngineControlState state) {
          var engineControlBloc = BlocProvider.of<EngineControlBloc>(context);
          var navCubit = BlocProvider.of<NavigationCubit>(context);

          var statusMessage = "Unknown Status";
          var statusIcon = Icons.question_mark;
          var networkCubit = BlocProvider.of<NetworkInfoCubit>(context);
          var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
          final ColorScheme colors = Theme.of(context).colorScheme;
          void Function()? buttonAction = () => engineControlBloc.add(EngineControlEventStop());
          if (state is ClientConnectedState) {
            statusMessage = state.clientName;
            statusIcon = Icons.phone_in_talk;
          } else if (state is ClientDisconnectedState || state is EngineServerCreatedState) {
            statusMessage = "Server running, no client connected";
            statusIcon = Icons.phone_disabled;
            // Once we're in this state the engine is started.
            buttonAction = () => engineControlBloc.add(EngineControlEventStop());
          } else if (state is EngineStartedState) {
            statusMessage = "Server started";
            statusIcon = Icons.bedtime;
            buttonAction = () => engineControlBloc.add(EngineControlEventStop());
          } else if (state is EngineStoppedState) {
            statusMessage = "Server not running";
            statusIcon = Icons.bedtime;
            buttonAction = () async => engineControlBloc.add(EngineControlEventStart(
                options: await BlocProvider.of<IntifaceConfigurationCubit>(context, listen: false).getEngineOptions()));
          } else if (state is EngineStartingState) {
            statusIcon = Icons.start;
            statusMessage = "Server starting";
            buttonAction = null;
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

          var engineStatus = "Engine Status Unknown";
          if (configCubit.appMode == AppMode.engine) {
            if (state is ClientConnectedState) {
              engineStatus = "${state.clientName} connected";
            } else if (state is EngineStartedState ||
                state is EngineServerCreatedState ||
                state is ClientDisconnectedState) {
              engineStatus = "Engine running, waiting for client";
            } else if (state is EngineStartingState) {
              engineStatus = "Engine starting...";
            } else if (state is EngineStoppedState) {
              engineStatus = "Engine not running";
            } else {
              logWarning("Engine Status $state unknown");
            }
          } else if (configCubit.appMode == AppMode.repeater) {
            if (state is EngineStartedState || state is EngineServerCreatedState || state is ClientDisconnectedState) {
              engineStatus = "Repeater running";
            } else if (state is EngineStoppedState) {
              engineStatus = "Repeater not running";
            } else if (state is EngineStartingState) {
              engineStatus = "Repeater starting...";
            }
          }

          List<Widget> columnWidgets = [
            const Text("Status:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(engineStatus)
          ];

          if (configCubit.appMode == AppMode.engine) {
            columnWidgets.addAll([
              const Text("Server Address:", style: TextStyle(fontWeight: FontWeight.bold)),
              BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
                  bloc: configCubit,
                  buildWhen: (previous, current) =>
                      current is WebsocketServerAllInterfacesState || current is WebsocketServerPortState,
                  builder: (context, state) => Text(
                      "ws://${configCubit.websocketServerAllInterfaces ? (networkCubit.ip ?? "0.0.0.0") : "localhost"}:${configCubit.websocketServerPort}")),
              BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
                  bloc: configCubit,
                  buildWhen: (previous, current) => current is AllowRawMessagesState,
                  builder: (context, state) => Visibility(
                      visible: configCubit.allowRawMessages,
                      child: const Text("Raw Messages Allowed",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))))
            ]);
          }

          return Row(children: [
            Padding(padding: const EdgeInsets.all(5.0), child: controlButton),
            Expanded(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: columnWidgets)),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BlocBuilder(
                    bloc: BlocProvider.of<ErrorNotifierCubit>(context),
                    builder: (context, ErrorNotifierState state) {
                      return Visibility(
                        visible: state is ErrorNotifierTriggerState ? true : false,
                        child: TextButton.icon(
                            label: const Text("Error"),
                            onPressed: () => navCubit.goLogs(),
                            icon: const Icon(Icons.warning),
                            style: ButtonStyle(foregroundColor: MaterialStateProperty.resolveWith((s) => Colors.red))),
                      );
                    }),
                Visibility(
                  visible:
                      isDesktop() && canShowUpdate() && configCubit.currentAppVersion != configCubit.latestAppVersion,
                  child: TextButton.icon(
                      label: const Text("Update"),
                      onPressed: () => navCubit.goSettings(),
                      icon: const Icon(Icons.update, color: Colors.green),
                      style: ButtonStyle(foregroundColor: MaterialStateProperty.resolveWith((s) => Colors.green))),
                ),
                Visibility(
                  visible: false,
                  child: TextButton.icon(
                      onPressed: () => navCubit.goNews(),
                      icon: const Icon(Icons.newspaper),
                      label: const Text("News"),
                      style: ButtonStyle(foregroundColor: MaterialStateProperty.resolveWith((s) => Colors.blue))),
                )
              ],
            ),
            Tooltip(message: statusMessage, child: Icon(statusIcon, size: 70)),
          ]);
        });
  }
}
