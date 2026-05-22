import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/src/rust/api/simulated_devices.dart'
    as simulated_api;

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
          _DetailHeader(title: 'Add Simulated Device', onBack: widget.onBack),
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

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cubit.simulatedDevices.isNotEmpty) ...[
                            Text(
                              'Existing Simulated Devices',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Device')),
                                  DataColumn(label: Text('Display Name')),
                                  DataColumn(label: Text('Address')),
                                  DataColumn(label: Text('Delete')),
                                ],
                                rows: cubit.simulatedDevices.map((device) {
                                  final archetype =
                                      archetypesByIdentifier[device.identifier];
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          archetype?.displayName ??
                                              device.identifier,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          device.displayName?.isNotEmpty == true
                                              ? device.displayName!
                                              : archetype?.displayName ??
                                                    device.identifier,
                                        ),
                                      ),
                                      DataCell(Text(device.address)),
                                      DataCell(
                                        TextButton(
                                          onPressed: () =>
                                              cubit.removeSimulatedDevice(
                                                device.address,
                                              ),
                                          child: const Text('Delete'),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          Text(
                            'Add New Simulated Device',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 300,
                            child: DropdownButtonFormField<String>(
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
                          SizedBox(
                            width: 300,
                            child: TextField(
                              controller: _displayNameController,
                              decoration: const InputDecoration(
                                hintText: 'Display Name (Optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: archetypeIdentifiers.isEmpty
                                ? null
                                : () {
                                    final identifier = _selectedIdentifier;
                                    final displayName = _displayNameController
                                        .text
                                        .trim();
                                    if (identifier == null) return;
                                    cubit.addSimulatedDevice(
                                      identifier,
                                      displayName.isEmpty ? null : displayName,
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

class _DetailHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _DetailHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
