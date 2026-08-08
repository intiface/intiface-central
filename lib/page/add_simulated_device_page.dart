import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/src/rust/api/simulated_devices.dart'
    as simulated_api;
import 'package:intiface_central/util/docs_screenshot_keys.dart';
import 'package:intiface_central/widget/config_entry_card.dart';
import 'package:intiface_central/widget/detail_header_widget.dart';
import 'package:intiface_central/widget/form_panel_widget.dart';

class AddSimulatedDevicePage extends StatefulWidget {
  final VoidCallback onBack;

  const AddSimulatedDevicePage({super.key, required this.onBack});

  @override
  State<AddSimulatedDevicePage> createState() => _AddSimulatedDevicePageState();
}

class _AddSimulatedDevicePageState extends State<AddSimulatedDevicePage> {
  late TextEditingController _displayNameController;
  String? _selectedIdentifier;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          DetailHeader(
            title: 'Manage Simulated Devices',
            onBack: widget.onBack,
          ),
          Expanded(
            child:
                BlocBuilder<
                  UserDeviceConfigurationCubit,
                  UserDeviceConfigurationState
                >(
                  builder: (context, state) {
                    final cubit = BlocProvider.of<UserDeviceConfigurationCubit>(
                      context,
                    );
                    final archetypes = cubit.simulatedArchetypes.toList()
                      ..sort((a, b) => a.displayName.compareTo(b.displayName));
                    final archetypeIdentifiers = archetypes
                        .map((archetype) => archetype.identifier)
                        .toList();
                    final archetypesByIdentifier = {
                      for (final archetype in archetypes)
                        archetype.identifier: archetype,
                    };

                    return FormPanel(
                      children: [
                        if (cubit.simulatedDevices.isNotEmpty) ...[
                          KeyedSubtree(
                            key: DocsScreenshotKeys
                                .advancedDeviceExistingDevices,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Existing Simulated Devices',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                ...cubit.simulatedDevices.map((device) {
                                  final archetypeName =
                                      archetypesByIdentifier[device.identifier]
                                          ?.displayName ??
                                      device.identifier;
                                  final customName =
                                      device.displayName?.isNotEmpty == true;
                                  return ConfigEntryCard(
                                    title: customName
                                        ? device.displayName!
                                        : archetypeName,
                                    subtitle: customName
                                        ? '$archetypeName · ${device.address}'
                                        : device.address,
                                    onDelete: () => cubit.removeSimulatedDevice(
                                      device.address,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                        ],
                        KeyedSubtree(
                          key: DocsScreenshotKeys.advancedDeviceAddDevice,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add New Simulated Device',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedIdentifier,
                                decoration: const InputDecoration(
                                  labelText: 'Device Type',
                                  border: OutlineInputBorder(),
                                ),
                                items: archetypes
                                    .map(
                                      (archetype) => DropdownMenuItem<String>(
                                        value: archetype.identifier,
                                        child: Text(archetype.displayName),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedIdentifier = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              if (_selectedIdentifier != null &&
                                  archetypesByIdentifier[_selectedIdentifier] !=
                                      null)
                                _ArchetypeSummary(
                                  archetype:
                                      archetypesByIdentifier[_selectedIdentifier]!,
                                ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _displayNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Display Name (Optional)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                                onPressed: archetypeIdentifiers.isEmpty
                                    ? null
                                    : () {
                                        final identifier = _selectedIdentifier;
                                        final displayName =
                                            _displayNameController.text.trim();
                                        if (identifier == null) return;
                                        cubit.addSimulatedDevice(
                                          identifier,
                                          displayName.isEmpty
                                              ? null
                                              : displayName,
                                        );
                                        _displayNameController.clear();
                                        setState(() {
                                          _selectedIdentifier = null;
                                        });
                                      },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Simulated Device'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _ArchetypeSummary extends StatelessWidget {
  final simulated_api.ExposedSimulatedDeviceArchetype archetype;

  const _ArchetypeSummary({required this.archetype});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final features = archetype.outputFeatures
        .map(
          (feature) =>
              '${feature.description}: ${feature.outputType} ${feature.index}',
        )
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        features,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
