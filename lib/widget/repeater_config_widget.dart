import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';

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
        child: Column(
      children: [
        BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
            buildWhen: (previousState, currentState) => currentState is RepeaterLocalPortState,
            builder: (context, state) => TextField(
                  enabled: true,
                  controller: portController,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (value) => configCubit.repeaterLocalPort = int.parse(value),
                  decoration: const InputDecoration(labelText: "Local Port"),
                )),
        BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
            buildWhen: (previousState, currentState) => currentState is RepeaterRemoteAddressState,
            builder: (context, state) => TextField(
                  enabled: true,
                  controller: remoteAddressController,
                  onSubmitted: (value) => configCubit.repeaterRemoteAddress = value,
                  decoration: const InputDecoration(labelText: "Remote Address"),
                )),
      ],
    ));
  }
}
