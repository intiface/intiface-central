import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/util/docs_screenshot_keys.dart';
import 'package:intiface_central/widget/config_entry_card.dart';
import 'package:intiface_central/widget/detail_header_widget.dart';
import 'package:intiface_central/widget/form_panel_widget.dart';
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
          DetailHeader(
            title: 'Manage Websocket Devices',
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
                    final sortedProtocols = cubit.protocols.toList()..sort();

                    return FormPanel(
                      children: [
                        if (cubit.specifiers.isNotEmpty) ...[
                          KeyedSubtree(
                            key: DocsScreenshotKeys
                                .advancedDeviceExistingDevices,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Existing Websocket Devices',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                ...cubit.specifiers.map((entry) {
                                  final (protocol, spec) = entry;
                                  return ConfigEntryCard(
                                    title: spec.name,
                                    subtitle: protocol,
                                    onDelete: () =>
                                        cubit.removeWebsocketDeviceName(
                                          protocol,
                                          spec.name,
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
                                'Add New Websocket Device',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              StatefulDropdownButton(
                                label: 'Protocol Type',
                                values: sortedProtocols,
                                valueNotifier: _protocolNotifier,
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Device Address',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                                onPressed: () {
                                  final protocol = _protocolNotifier.value;
                                  final name = _nameController.text;
                                  if (protocol.isEmpty || name.isEmpty) {
                                    return;
                                  }
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
