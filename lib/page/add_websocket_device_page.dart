import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/util/docs_screenshot_keys.dart';
import 'package:intiface_central/widget/stateful_dropdown_button.dart';

class AddWebsocketDevicePage extends StatefulWidget {
  final VoidCallback onBack;

  const AddWebsocketDevicePage({super.key, required this.onBack});

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
    return Expanded(
      child: Column(
        children: [
          _DetailHeader(title: 'Manage Websocket Devices', onBack: widget.onBack),
          Expanded(
            child: BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(
              builder: (context, state) {
                final cubit = BlocProvider.of<UserDeviceConfigurationCubit>(context);
                final sortedProtocols = cubit.protocols.toList()..sort();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cubit.specifiers.isNotEmpty) ...[
                        KeyedSubtree(
                          key: DocsScreenshotKeys.advancedDeviceExistingDevices,
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Existing Websocket Devices',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
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
                                              onPressed: () => cubit.removeWebsocketDeviceName(protocol, spec.name),
                                              child: const Text('Delete'),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      KeyedSubtree(
                        key: DocsScreenshotKeys.advancedDeviceAddDevice,
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  decoration: const InputDecoration(hintText: 'Device Address', border: OutlineInputBorder()),
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
                        ),
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
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack, tooltip: 'Back'),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
