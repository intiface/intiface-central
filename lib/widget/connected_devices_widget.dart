import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/widget/device_config_widget.dart';
import 'package:intiface_central/widget/device_control_widget.dart';
import 'package:intiface_central/widget/expandable_card_widget.dart';

class ConnectedDevicesWidget extends StatelessWidget {
  final List<int> connectedIndexes;

  const ConnectedDevicesWidget({super.key, required this.connectedIndexes});

  @override
  Widget build(BuildContext context) {
    var deviceBloc = BlocProvider.of<DeviceManagerBloc>(context);
    var userDeviceConfigCubit = BlocProvider.of<UserDeviceConfigurationCubit>(
      context,
    );
    var devices = deviceBloc.devices;
    devices.sort((a, b) => a.device!.index.compareTo(b.device!.index));

    List<Widget> widgets = [];
    for (var deviceCubit in devices) {
      var device = deviceCubit.device!;
      connectedIndexes.add(device.index);
      try {
        var deviceEntry = userDeviceConfigCubit.configs.entries.firstWhere(
          (element) => element.value.index == device.index,
        );
        widgets.add(
          ExpandableCardWidget(
            expansionName: "device-connected-${device.index}",
            defaultExpanded: true,
            title: Text(
              device.displayName ?? device.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Index: ${device.index} - Base Name: ${device.name}",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            body: Container(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: [
                  DeviceControlWidget(deviceCubit: deviceCubit),
                  DeviceConfigWidget(identifier: deviceEntry.key),
                ],
              ),
            ),
          ),
        );
      } catch (e) {
        continue;
      }
    }
    return Column(children: widgets);
  }
}
