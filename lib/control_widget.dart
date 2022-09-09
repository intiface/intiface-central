import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:intiface_central/navigation_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';

class ControlWidget extends StatelessWidget {
  const ControlWidget({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var clientName = "No Client Connected"; //_clientName ?? "No Client Connected";

    var engineControlBloc = BlocProvider.of<EngineControlBloc>(context);

    return BlocBuilder(
        bloc: engineControlBloc,
        builder: (context, EngineControlState state) {
          var statusMessage = "Unknown Status";
          var statusIcon = Icons.question_mark;
          void Function()? buttonAction = () => engineControlBloc.add(EngineControlEventStop());
          if (state.status.isClientConnected) {
            statusMessage = "Client Connected";
            statusIcon = Icons.phone_in_talk;
          } else if (state.status.isClientDisconnected) {
            statusMessage = "Server running, no client connected";
            statusIcon = Icons.phone_disabled;
          } else if (state.status.isStarting) {
            statusMessage = "Server starting up";
            statusIcon = Icons.block;
            // In the case of starting up,
            buttonAction = null;
          } else if (state.status.isStopped) {
            statusMessage = "Server not running";
            statusIcon = Icons.block;
            buttonAction = () => engineControlBloc.add(EngineControlEventStart());
          }
          return Row(children: [
            IconButton(
                iconSize: 90,
                onPressed: buttonAction,
                tooltip: state.status.isStopped ? "Start Server" : "Stop Server",
                icon: Icon(state.status.isStopped ? Icons.play_arrow : Icons.stop)),
            Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              //Text("Network Address: $_wifiIP"),
              Text("Client Status: ${state.status.isClientConnected ? "Client Connected" : "No Client Connected"}"),
              Text("Device Status:"),
            ])),
            Tooltip(message: statusMessage, child: Icon(statusIcon, size: 70)),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    iconSize: 25,
                    onPressed: () => BlocProvider.of<NavigationCubit>(context).goLogs(),
                    icon: const Icon(Icons.warning),
                    tooltip: "No new errors",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
                IconButton(
                    iconSize: 25,
                    onPressed: () => BlocProvider.of<NavigationCubit>(context).goSettings(),
                    icon: const Icon(Icons.update),
                    tooltip: "No new updates",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
                IconButton(
                    iconSize: 25,
                    onPressed: () => BlocProvider.of<NavigationCubit>(context).goNews(),
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
