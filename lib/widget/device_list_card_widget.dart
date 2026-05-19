import 'package:flutter/material.dart';
import 'package:intiface_central/bloc/device/device_cubit.dart';
import 'package:intiface_central/bloc/device/device_output_cubit.dart';
import 'package:intiface_central/src/rust/api/device_config.dart';
import 'package:intiface_central/widget/compact_observation_widget.dart';

class DeviceListCard extends StatelessWidget {
  final ExposedUserDeviceIdentifier identifier;
  final ExposedServerDeviceDefinition definition;
  final bool isConnected;
  final DeviceCubit? deviceCubit;
  final VoidCallback onTap;

  const DeviceListCard({
    super.key,
    required this.identifier,
    required this.definition,
    required this.isConnected,
    this.deviceCubit,
    required this.onTap,
  });

  static const Map<String, IconData> _outputTypeIcons = {
    'vibrate': Icons.vibration,
    'rotate': Icons.rotate_right,
    'oscillate': Icons.swap_vert,
    'constrict': Icons.compress,
    'temperature': Icons.thermostat,
    'led': Icons.light,
    'spray': Icons.water_drop,
    'position': Icons.straighten,
    'positionWithDuration': Icons.timer,
  };

  static const IconData _inputIcon = Icons.sensors;

  List<IconData> _featureIcons() {
    final icons = <IconData>{};
    for (var feature in definition.features) {
      if (feature.output != null) {
        final output = feature.output!;
        if (output.vibrate != null) icons.add(_outputTypeIcons['vibrate']!);
        if (output.rotate != null) icons.add(_outputTypeIcons['rotate']!);
        if (output.oscillate != null) icons.add(_outputTypeIcons['oscillate']!);
        if (output.constrict != null) icons.add(_outputTypeIcons['constrict']!);
        if (output.temperature != null) {
          icons.add(_outputTypeIcons['temperature']!);
        }
        if (output.led != null) icons.add(_outputTypeIcons['led']!);
        if (output.spray != null) icons.add(_outputTypeIcons['spray']!);
        if (output.position != null) icons.add(_outputTypeIcons['position']!);
        if (output.positionWithDuration != null) {
          icons.add(_outputTypeIcons['positionWithDuration']!);
        }
      }
      if (feature.input != null) {
        icons.add(_inputIcon);
      }
    }
    return icons.toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = definition.displayName ?? definition.name;
    final icons = _featureIcons();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: isConnected
                    ? Colors.green
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (definition.allow) ...[
                          const SizedBox(width: 8),
                          _buildBadge(context, 'ALLOW', Colors.green),
                        ],
                        if (definition.deny) ...[
                          const SizedBox(width: 8),
                          _buildBadge(context, 'DENY', Colors.red),
                        ],
                      ],
                    ),
                    if (icons.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: icons
                            .map(
                              (icon) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  icon,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (isConnected &&
                        deviceCubit != null &&
                        deviceCubit!.observations.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      for (var i = 0;
                          i < deviceCubit!.observations.length;
                          i++)
                        CompactObservationWidget(
                          label: i < deviceCubit!.outputs.length
                              ? _shortLabel(deviceCubit!.outputs[i])
                              : '',
                          observation: deviceCubit!.observations[i],
                        ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  static String _shortLabel(DeviceOutputCubit output) {
    return switch (output.type.name) {
      'vibrate' => 'Vib',
      'rotate' => 'Rot',
      'oscillate' => 'Osc',
      'constrict' => 'Con',
      'temperature' => 'Tmp',
      'led' => 'LED',
      'spray' => 'Spr',
      'position' => 'Pos',
      'hwPositionWithDuration' => 'Lin',
      _ => output.type.name.substring(0, 3),
    };
  }

  Widget _buildBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
