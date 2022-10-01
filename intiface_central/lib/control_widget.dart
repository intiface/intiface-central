import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:intiface_central/navigation_cubit.dart';
import 'package:intiface_central/network_info_cubit.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ControlWidget extends StatelessWidget {
  const ControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var engineControlBloc = BlocProvider.of<EngineControlBloc>(context);
    var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    var navCubit = BlocProvider.of<NavigationCubit>(context);

    return BlocBuilder(
        bloc: engineControlBloc,
        builder: (context, EngineControlState state) {
          var statusMessage = "Unknown Status";
          var statusIcon = Icons.question_mark;
          var networkCubit = BlocProvider.of<NetworkInfoCubit>(context);
          var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
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
          return Row(children: [
            IconButton(
                iconSize: 90,
                onPressed: buttonAction,
                tooltip: state is EngineStoppedState ? "Start Server" : "Stop Server",
                icon: Icon(state is EngineStoppedState ? Icons.play_arrow : Icons.stop)),
            Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(state is ClientConnectedState ? "${state.clientName} Connected" : "No Client Connected"),
              BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
                  bloc: configCubit,
                  buildWhen: (previous, current) => current is WebsocketServerAllInterfaces,
                  builder: (context, state) => Text(
                      "Server Address: ${configCubit.websocketServerAllInterfaces ? networkCubit.ip : "localhost"}:12345")),
            ])),
            Tooltip(message: statusMessage, child: Icon(statusIcon, size: 70)),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    iconSize: 25,
                    onPressed: () => navCubit.goLogs(),
                    icon: const Icon(Icons.warning),
                    tooltip: "No new errors",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
                IconButton(
                    iconSize: 25,
                    onPressed: () => navCubit.goSettings(),
                    icon: const Icon(Icons.update),
                    tooltip: "No new updates",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
                IconButton(
                    iconSize: 25,
                    onPressed: () => navCubit.goNews(),
                    icon: const Icon(Icons.newspaper),
                    tooltip: "No new news",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
              ],
            )
          ]);
        });
  }
}
