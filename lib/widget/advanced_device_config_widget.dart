import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/widget/add_serial_device_widget.dart';
import 'package:intiface_central/widget/add_websocket_device_widget.dart';
import 'package:intiface_central/widget/expandable_card_widget.dart';

class AdvancedDeviceConfigWidget extends StatelessWidget {
  const AdvancedDeviceConfigWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);

    if (!configCubit.useDeviceWebsocketServer && !configCubit.useSerialPort) {
      return const FractionallySizedBox(
        widthFactor: 0.8,
        child: Text(
          "Advanced device managers (Websocket, Serial Port, etc...) can be turned on in Advanced Settings section of the App Modes panel.",
          textAlign: TextAlign.center,
        ),
      );
    }

    List<Widget> widgets = [];
    if (configCubit.useDeviceWebsocketServer) {
      widgets.add(
        ExpandableCardWidget(
          expansionName: "device-settings-advanced-websocket",
          title: Text(
            "Websocket Devices",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          body: const AddWebsocketDeviceWidget(),
        ),
      );
    }
    if (configCubit.useSerialPort) {
      widgets.add(
        ExpandableCardWidget(
          expansionName: "device-settings-advanced-serial",
          title: Text(
            "Serial Devices",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          body: const AddSerialDeviceWidget(),
        ),
      );
    }
    return Column(children: widgets);
  }
}
