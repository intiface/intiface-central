import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:intiface_central/util/intiface_util.dart';

class ControlWidget extends StatelessWidget {
  const ControlWidget({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var clientName = "No Client Connected"; //_clientName ?? "No Client Connected";

    var engineControlCubit = BlocProvider.of<EngineControlBloc>(context);

    var infoColumn = BlocBuilder(
        bloc: engineControlCubit,
        builder: (context, EngineControlState state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Text("Network Address: $_wifiIP"),
              Text("Client Status: ${state.status.isClientConnected ? "Client Connected" : "No Client Connected"}"),
              Text("Device Status:"),
            ],
          );
        });
    var statusColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Tooltip(message: "No new errors", child: Icon(Icons.warning)),
        Tooltip(message: "No new software updates", child: Icon(Icons.update_disabled)),
        Tooltip(message: "No new news", child: Icon(Icons.newspaper))
      ],
    );

    var statusIcon = /*_processManager.running()
        ? (_clientName != null
            ? const Tooltip(message: "Client connected", child: Icon(Icons.phone_in_talk, size: 70))
            : const Tooltip(
                message: "Server running, no client connected", child: Icon(Icons.phone_disabled, size: 70)))
        : */
        const Tooltip(message: "Server not running", child: Icon(Icons.block, size: 70));

    return Row(children: [
      BlocBuilder(
          bloc: engineControlCubit,
          builder: (context, EngineControlState state) {
            print(state);
            return IconButton(
                iconSize: 90,
                onPressed: state.status.isStarting ? null : () => engineControlCubit.add(EngineControlEventStart()),
                tooltip: state.status.isStopped ? "Start Server" : "Stop Server",
                icon: Icon(state.status.isStopped ? Icons.play_arrow : Icons.stop));
          }),
      Expanded(child: infoColumn),
      statusIcon,
      statusColumn,
    ]);
  }
}
