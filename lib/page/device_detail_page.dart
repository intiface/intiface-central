import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:intiface_central/bloc/device/device_cubit.dart';
import 'package:intiface_central/bloc/device/device_input_cubit.dart';
import 'package:intiface_central/bloc/device/device_output_cubit.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/src/rust/api/device_config.dart';
import 'package:intiface_central/src/rust/api/enums.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class DeviceDetailPage extends StatelessWidget {
  final ExposedUserDeviceIdentifier identifier;
  final DeviceCubit? deviceCubit;

  const DeviceDetailPage({
    super.key,
    required this.identifier,
    this.deviceCubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineControlBloc, EngineControlState>(
      buildWhen: (previous, current) =>
          current is EngineStartedState ||
          current is EngineStoppedState ||
          current is DeviceConnectedState ||
          current is DeviceDisconnectedState,
      builder: (context, engineState) {
        return BlocBuilder<
          UserDeviceConfigurationCubit,
          UserDeviceConfigurationState
        >(
          builder: (context, userConfigState) {
            final userDeviceConfigCubit =
                BlocProvider.of<UserDeviceConfigurationCubit>(context);
            final config = userDeviceConfigCubit.configs[identifier];
            if (config == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) Navigator.of(context).pop();
              });
              return const SizedBox.shrink();
            }

            final engineRunning = BlocProvider.of<EngineControlBloc>(
              context,
            ).isRunning;
            final displayName = config.displayName ?? config.name;

            return Scaffold(
              appBar: AppBar(title: Text(displayName)),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DeviceInfoSection(config: config, identifier: identifier),
                    const Divider(),
                    _DeviceConfigSection(
                      identifier: identifier,
                      config: config,
                      engineRunning: engineRunning,
                      userDeviceConfigCubit: userDeviceConfigCubit,
                    ),
                    const Divider(),
                    if (deviceCubit != null &&
                        deviceCubit!.state is DeviceStateOnline)
                      _DeviceControlsSection(deviceCubit: deviceCubit!),
                    // TODO: Phase 4 — Feature output config section
                    _ForgetDeviceButton(
                      enabled: !engineRunning,
                      onPressed: () async {
                        await userDeviceConfigCubit.removeDeviceConfig(
                          identifier,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DeviceInfoSection extends StatelessWidget {
  final ExposedServerDeviceDefinition config;
  final ExposedUserDeviceIdentifier identifier;

  const _DeviceInfoSection({required this.config, required this.identifier});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Info',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(context, 'Hardware Name', config.name),
          if (config.displayName != null)
            _infoRow(context, 'Display Name', config.displayName!),
          _infoRow(context, 'Protocol', identifier.protocol),
          _infoRow(context, 'Address', identifier.address),
          _infoRow(context, 'Index', config.index.toString()),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _DeviceConfigSection extends StatelessWidget {
  final ExposedUserDeviceIdentifier identifier;
  final ExposedServerDeviceDefinition config;
  final bool engineRunning;
  final UserDeviceConfigurationCubit userDeviceConfigCubit;

  const _DeviceConfigSection({
    required this.identifier,
    required this.config,
    required this.engineRunning,
    required this.userDeviceConfigCubit,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final transparentBg = SettingsThemeData(
      settingsListBackground: Colors.transparent,
    );

    return SettingsList(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      lightTheme: brightness == Brightness.light ? transparentBg : null,
      darkTheme: brightness == Brightness.dark ? transparentBg : null,
      sections: [
        SettingsSection(
          title: const Text('Configuration'),
          tiles: [
            SettingsTile.navigation(
              enabled: !engineRunning,
              title: const Text('Display Name'),
              value: Text(config.displayName ?? ''),
              onPressed: (context) => _showDisplayNameDialog(context),
            ),
            SettingsTile.navigation(
              enabled: !engineRunning,
              title: const Text('Message Gap (ms)'),
              value: Text(config.messageGapMs?.toString() ?? 'Default'),
              onPressed: (context) => _showMessageGapDialog(context),
            ),
            SettingsTile.switchTile(
              enabled: !engineRunning,
              initialValue: !config.deny,
              onToggle: (value) async {
                await userDeviceConfigCubit.updateDeviceDeny(
                  identifier,
                  config,
                  !value,
                );
              },
              title: const Text('Connect to this device'),
            ),
            SettingsTile.switchTile(
              enabled: !engineRunning,
              initialValue: config.allow,
              onToggle: (value) async {
                await userDeviceConfigCubit.updateDeviceAllow(
                  identifier,
                  config,
                  value,
                );
              },
              title: const Text('Only connect to this device'),
              description: const Text(
                'When enabled, only devices with this flag will connect',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDisplayNameDialog(BuildContext context) {
    final controller = TextEditingController(text: config.displayName ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Display Name Entry'),
          onSubmitted: (value) async {
            Navigator.pop(dialogContext);
            await userDeviceConfigCubit.updateDisplayName(
              identifier,
              config,
              value,
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await userDeviceConfigCubit.updateDisplayName(
                identifier,
                config,
                controller.text,
              );
            },
            child: const Text('Ok'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMessageGapDialog(BuildContext context) {
    final controller = TextEditingController(
      text: config.messageGapMs?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Message Gap (ms)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: 'Leave empty for default',
          ),
          onSubmitted: (value) async {
            Navigator.pop(dialogContext);
            await userDeviceConfigCubit.updateMessageGapMs(
              identifier,
              config,
              int.tryParse(value),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await userDeviceConfigCubit.updateMessageGapMs(
                identifier,
                config,
                int.tryParse(controller.text),
              );
            },
            child: const Text('Ok'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await userDeviceConfigCubit.updateMessageGapMs(
                identifier,
                config,
                null,
              );
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _DeviceControlsSection extends StatelessWidget {
  final DeviceCubit deviceCubit;

  const _DeviceControlsSection({required this.deviceCubit});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<Widget> controls = [];

    for (var output in deviceCubit.outputs) {
      if (output is ValueOutputCubit) {
        var range = output.feature.feature.output![output.type]!.value!;
        controls.addAll([
          ListTile(
            title: Text(output.type.name),
            subtitle: Text(
              'Description: ${output.feature.feature.featureDescription} - '
              'Step Count: $range',
            ),
          ),
          BlocBuilder<DeviceOutputCubit, DeviceOutputState>(
            bloc: output,
            buildWhen: (previous, current) =>
                current is DeviceOutputStateUpdate,
            builder: (context, state) => Slider(
              min: range[0].toDouble(),
              max: range[1].toDouble(),
              value: output.currentValue.floorToDouble(),
              divisions: (range[0].abs() + range[1].abs()),
              onChanged: (value) async {
                output.setValue(value.ceil());
              },
            ),
          ),
        ]);
      } else if (output is PositionWithDurationOutputCubit) {
        var range = output.feature.feature.output![output.type]!.value!;
        controls.addAll([
          ListTile(
            title: const Text('Linear'),
            subtitle: Text(
              'Description: ${output.feature.feature.featureDescription} - '
              'Step Count: $range',
            ),
          ),
          BlocBuilder<DeviceOutputCubit, DeviceOutputState>(
            bloc: output,
            buildWhen: (previous, current) =>
                current is DeviceOutputStateUpdate,
            builder: (context, state) {
              return Column(
                children: [
                  RangeSlider(
                    max: range[1].toDouble(),
                    values: RangeValues(output.currentMin, output.currentMax),
                    divisions: range[1],
                    onChanged: (values) async {
                      output.setPosition(values.start, values.end);
                    },
                  ),
                  Slider(
                    max: 3000,
                    value: output.currentDuration.floorToDouble(),
                    onChanged: (value) async {
                      output.duration(value);
                    },
                  ),
                  TextButton(
                    child: const Text('Toggle Oscillation'),
                    onPressed: () => output.toggleRunning(),
                  ),
                ],
              );
            },
          ),
        ]);
      }
    }

    for (var input in deviceCubit.inputs) {
      if (input is InputReadBloc) {
        controls.addAll([
          ListTile(
            title: Text(input.inputType.name),
            subtitle: Text(
              'Description: ${input.descriptor} - '
              'Sensor Range: ${input.sensorRange}',
            ),
          ),
          BlocBuilder<DeviceInputBloc, DeviceInputState>(
            bloc: input,
            buildWhen: (previous, current) => current is DeviceInputStateUpdate,
            builder: (context, state) {
              if (input.inputType.name == InputType.battery.name) {
                double percentage = input.currentData / 100.0;
                return LinearPercentIndicator(
                  percent: percentage,
                  animation: true,
                  lineHeight: 20.0,
                  animationDuration: 1000,
                  backgroundColor: Colors.grey,
                  progressColor: Colors.blue,
                  center: Text('${(percentage * 100).toInt()}%'),
                );
              }
              return Text('${input.currentData}');
            },
          ),
          TextButton(
            child: const Text('Read Sensor'),
            onPressed: () => input.add(DeviceInputReadEvent()),
          ),
        ]);
      }
    }

    if (controls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Controls',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...controls,
          const Divider(),
        ],
      ),
    );
  }
}

class _ForgetDeviceButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _ForgetDeviceButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: enabled
            ? () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Forget Device'),
                    content: const Text(
                      'This will remove all configuration for this device. '
                      'Are you sure?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          onPressed();
                        },
                        child: const Text('Forget'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );
              }
            : null,
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: const Text('Forget Device'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
