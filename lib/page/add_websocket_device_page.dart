import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/widget/stateful_dropdown_button.dart';

class AddWebsocketDevicePage extends StatefulWidget {
  const AddWebsocketDevicePage({super.key});

  @override
  State<AddWebsocketDevicePage> createState() => _AddWebsocketDevicePageState();
}

class _AddWebsocketDevicePageState extends State<AddWebsocketDevicePage> {
  late TextEditingController _nameController;
  late ValueNotifier<String> _protocolNotifier;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _protocolNotifier = ValueNotifier('');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _protocolNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Websocket Device')),
      body:
          BlocBuilder<
            UserDeviceConfigurationCubit,
            UserDeviceConfigurationState
          >(
            builder: (context, state) {
              final cubit = BlocProvider.of<UserDeviceConfigurationCubit>(
                context,
              );
              final sortedProtocols = cubit.protocols.toList()..sort();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cubit.specifiers.isNotEmpty) ...[
                      Text(
                        'Existing Websocket Devices',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Protocol')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Delete')),
                        ],
                        rows: cubit.specifiers.map((entry) {
                          final (protocol, spec) = entry;
                          return DataRow(
                            cells: [
                              DataCell(Text(protocol)),
                              DataCell(Text(spec.name)),
                              DataCell(
                                TextButton(
                                  onPressed: () =>
                                      cubit.removeWebsocketDeviceName(
                                        protocol,
                                        spec.name,
                                      ),
                                  child: const Text('Delete'),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      'Add New Websocket Device',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StatefulDropdownButton(
                      label: 'Protocol Type',
                      values: sortedProtocols,
                      valueNotifier: _protocolNotifier,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Device Address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        final protocol = _protocolNotifier.value;
                        final name = _nameController.text;
                        if (protocol.isEmpty || name.isEmpty) return;
                        cubit.addWebsocketDeviceName(protocol, name);
                        _nameController.clear();
                        _protocolNotifier.value = '';
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Websocket Device'),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
