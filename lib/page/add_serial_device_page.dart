import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/src/rust/api/serial_ports.dart';
import 'package:intiface_central/util/docs_screenshot_keys.dart';
import 'package:intiface_central/widget/config_entry_card.dart';
import 'package:intiface_central/widget/detail_header_widget.dart';
import 'package:intiface_central/widget/form_panel_widget.dart';
import 'package:intiface_central/widget/stateful_dropdown_button.dart';

class AddSerialDevicePage extends StatefulWidget {
  final VoidCallback onBack;

  const AddSerialDevicePage({super.key, required this.onBack});

  @override
  State<AddSerialDevicePage> createState() => _AddSerialDevicePageState();
}

class _AddSerialDevicePageState extends State<AddSerialDevicePage> {
  static const _defaultProtocol = 'tcode-v03';
  static const _defaultBaudRate = '115200';
  static const _manualEntrySentinel = '__manual_port_entry__';

  late TextEditingController _portController;
  late TextEditingController _baudController;
  late ValueNotifier<String> _protocolNotifier;
  late ValueNotifier<int> _dataBitsNotifier;
  late ValueNotifier<String> _parityNotifier;
  late ValueNotifier<int> _stopBitsNotifier;

  List<ExposedSerialPortInfo> _ports = [];
  bool _manualPortEntry = false;
  bool _protocolSeeded = false;

  @override
  void initState() {
    super.initState();
    _portController = TextEditingController();
    _baudController = TextEditingController(text: _defaultBaudRate);
    _protocolNotifier = ValueNotifier('');
    _dataBitsNotifier = ValueNotifier(8);
    _parityNotifier = ValueNotifier('N');
    _stopBitsNotifier = ValueNotifier(1);
    _refreshPorts();
  }

  @override
  void dispose() {
    _portController.dispose();
    _baudController.dispose();
    _protocolNotifier.dispose();
    _dataBitsNotifier.dispose();
    _parityNotifier.dispose();
    _stopBitsNotifier.dispose();
    super.dispose();
  }

  Future<void> _refreshPorts() async {
    final ports = await listSerialPorts();
    if (!mounted) return;
    setState(() {
      _ports = _preferCalloutPorts(ports);
    });
  }

  // macOS exposes each port twice, as a /dev/cu.* callout device and a
  // /dev/tty.* dial-in device. The dial-in half blocks on carrier detect and is
  // never what we want here. Linux names (/dev/ttyUSB0) have no dot and are
  // left alone.
  List<ExposedSerialPortInfo> _preferCalloutPorts(
    List<ExposedSerialPortInfo> ports,
  ) {
    final calloutNames = ports
        .map((port) => port.portName)
        .where((name) => name.startsWith('/dev/cu.'))
        .toSet();
    return ports
        .where(
          (port) =>
              !port.portName.startsWith('/dev/tty.') ||
              !calloutNames.contains(
                port.portName.replaceFirst('/dev/tty.', '/dev/cu.'),
              ),
        )
        .toList();
  }

  Widget _buildPortDropdown() {
    final currentValue =
        _ports.any((port) => port.portName == _portController.text)
        ? _portController.text
        : null;
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Serial Port',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          hint: const Text('Port'),
          isExpanded: true,
          isDense: true,
          items: [
            for (final port in _ports)
              DropdownMenuItem(
                value: port.portName,
                child: Text(
                  port.product == null && port.manufacturer == null
                      ? port.portName
                      : '${port.portName} — ${port.product ?? port.manufacturer}',
                ),
              ),
            const DropdownMenuItem(
              value: _manualEntrySentinel,
              child: Text('Enter port manually…'),
            ),
          ],
          onChanged: (value) {
            if (value == _manualEntrySentinel) {
              setState(() {
                _manualPortEntry = true;
              });
            } else if (value != null) {
              setState(() {
                _portController.text = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildPortTextField() {
    return TextField(
      controller: _portController,
      decoration: const InputDecoration(
        labelText: 'Port Name',
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          DetailHeader(title: 'Manage Serial Devices', onBack: widget.onBack),
          Expanded(
            child: BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(
              builder: (context, state) {
                final cubit = BlocProvider.of<UserDeviceConfigurationCubit>(
                  context,
                );
                final sortedProtocols = cubit.protocols.toList()..sort();

                if (!_protocolSeeded && sortedProtocols.isNotEmpty) {
                  _protocolSeeded = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _protocolNotifier.value =
                        sortedProtocols.contains(_defaultProtocol)
                        ? _defaultProtocol
                        : '';
                  });
                }

                final showPortDropdown = _ports.isNotEmpty && !_manualPortEntry;

                return FormPanel(
                  children: [
                    if (cubit.serialSpecifiers.isNotEmpty) ...[
                      KeyedSubtree(
                        key: DocsScreenshotKeys.advancedDeviceExistingDevices,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Existing Serial Devices',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            ...cubit.serialSpecifiers.map((entry) {
                              final (protocol, spec) = entry;
                              return ConfigEntryCard(
                                title: spec.port,
                                subtitle:
                                    '$protocol · ${spec.baudRate}/${spec.dataBits}/${spec.parity}/${spec.stopBits}',
                                onDelete: () =>
                                    cubit.removeSerialPort(protocol, spec.port),
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
                            'Add New Serial Device',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          StatefulDropdownButton<String>(
                            label: 'Protocol Type',
                            values: sortedProtocols,
                            valueNotifier: _protocolNotifier,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: showPortDropdown
                                    ? _buildPortDropdown()
                                    : _buildPortTextField(),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Refresh Ports',
                                onPressed: _refreshPorts,
                              ),
                            ],
                          ),
                          if (_ports.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'No serial ports detected. On Linux, check that your user is in the dialout group.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                          if (!showPortDropdown && _ports.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _manualPortEntry = false;
                                });
                              },
                              child: const Text('Use detected port'),
                            ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _baudController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Baud Rate',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            shape: const Border(),
                            collapsedShape: const Border(),
                            title: const Text('Advanced Line Settings'),
                            initiallyExpanded: false,
                            subtitle: AnimatedBuilder(
                              animation: Listenable.merge([
                                _dataBitsNotifier,
                                _parityNotifier,
                                _stopBitsNotifier,
                              ]),
                              builder: (context, _) => Text(
                                '${_dataBitsNotifier.value} / ${_parityNotifier.value} / ${_stopBitsNotifier.value}',
                              ),
                            ),
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: StatefulDropdownButton<int>(
                                      label: 'Data Bits',
                                      values: const [8, 7, 6, 5, 4, 3, 2, 1],
                                      valueNotifier: _dataBitsNotifier,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: StatefulDropdownButton<String>(
                                      label: 'Parity',
                                      values: const ['N', 'E', 'O', 'S', 'M'],
                                      valueNotifier: _parityNotifier,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: StatefulDropdownButton<int>(
                                      label: 'Stop Bits',
                                      values: const [1, 0],
                                      valueNotifier: _stopBitsNotifier,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            onPressed: () {
                              final protocol = _protocolNotifier.value;
                              final port = _portController.text;
                              final baudText = _baudController.text;
                              if (protocol.isEmpty ||
                                  port.isEmpty ||
                                  baudText.isEmpty) {
                                return;
                              }
                              cubit.addSerialPort(
                                protocol,
                                port,
                                int.parse(baudText),
                                _dataBitsNotifier.value,
                                _stopBitsNotifier.value,
                                _parityNotifier.value,
                              );
                              setState(() {
                                _portController.clear();
                                _manualPortEntry = false;
                                _baudController.text = _defaultBaudRate;
                              });
                              _protocolNotifier.value = _defaultProtocol;
                              _refreshPorts();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Serial Device'),
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
