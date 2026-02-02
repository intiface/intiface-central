import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/widget/device_config_widget.dart';
import 'package:intiface_central/widget/expandable_card_widget.dart';
import 'package:intiface_central/widget/feature_output_config_widget.dart';

class DisconnectedDevicesWidget extends StatelessWidget {
  final List<int> connectedIndexes;

  const DisconnectedDevicesWidget({super.key, required this.connectedIndexes});

  @override
  Widget build(BuildContext context) {
    var userDeviceConfigCubit = BlocProvider.of<UserDeviceConfigurationCubit>(
      context,
    );
    var userDevices = userDeviceConfigCubit.configs.entries.toList();
    userDevices.sort((a, b) => a.value.index.compareTo(b.value.index));

    List<Widget> widgets = [];
    for (var deviceEntry in userDevices) {
      if (connectedIndexes.contains(deviceEntry.value.index)) {
        continue;
      }
      var identifierString =
          "${deviceEntry.key.protocol}-${deviceEntry.key.identifier}-${deviceEntry.key.address}";
      widgets.add(
        ExpandableCardWidget(
          expansionName: "device-settings-${deviceEntry.value.index}",
          title: Text(
            deviceEntry.value.displayName != null
                ? "${deviceEntry.value.displayName} (${deviceEntry.value.name})"
                : deviceEntry.value.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            identifierString,
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
                DeviceConfigWidget(identifier: deviceEntry.key),
                FeatureOutputConfigWidget(
                  deviceIdentifier: deviceEntry.key,
                  deviceDefinition: deviceEntry.value,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: widgets);
  }
}
