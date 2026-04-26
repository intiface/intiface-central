import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/widget/stateful_dropdown_button.dart';

class AddSerialDevicePage extends StatefulWidget {
  const AddSerialDevicePage({super.key});

  @override
  State<AddSerialDevicePage> createState() => _AddSerialDevicePageState();
}

class _AddSerialDevicePageState extends State<AddSerialDevicePage> {
  late TextEditingController _portController;
  late TextEditingController _baudController;
  late ValueNotifier<String> _protocolNotifier;
  late ValueNotifier<int> _dataBitsNotifier;
  late ValueNotifier<String> _parityNotifier;
  late ValueNotifier<int> _stopBitsNotifier;

  @override
  void initState() {
    super.initState();
    _portController = TextEditingController();
    _baudController = TextEditingController();
    _protocolNotifier = ValueNotifier('');
    _dataBitsNotifier = ValueNotifier(8);
    _parityNotifier = ValueNotifier('N');
    _stopBitsNotifier = ValueNotifier(1);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Serial Device')),
      body: BlocBuilder<UserDeviceConfigurationCubit, UserDeviceConfigurationState>(
        builder: (context, state) {
          final cubit = BlocProvider.of<UserDeviceConfigurationCubit>(context);
          final sortedProtocols = cubit.protocols.toList()..sort();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cubit.serialSpecifiers.isNotEmpty) ...[
                  Text(
                    'Existing Serial Devices',
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
                        DataColumn(label: Text('Port')),
                        DataColumn(label: Text('Info')),
                        DataColumn(label: Text('Delete')),
                      ],
                      rows: cubit.serialSpecifiers.map((entry) {
                        final (protocol, spec) = entry;
                        return DataRow(
                          cells: [
                            DataCell(Text(protocol)),
                            DataCell(Text(spec.port)),
                            DataCell(
                              Text(
                                '${spec.baudRate}/${spec.dataBits}/${spec.parity}/${spec.stopBits}',
                              ),
                            ),
                            DataCell(
                              TextButton(
                                onPressed: () =>
                                    cubit.removeSerialPort(protocol, spec.port),
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
                  'Add New Serial Device',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                StatefulDropdownButton<String>(
                  label: 'Protocol Type',
                  values: sortedProtocols,
                  valueNotifier: _protocolNotifier,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      hintText: 'Port Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _baudController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Baud Rate',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                StatefulDropdownButton<int>(
                  label: 'Data Bits',
                  values: const [8, 7, 6, 5, 4, 3, 2, 1],
                  valueNotifier: _dataBitsNotifier,
                ),
                const SizedBox(height: 8),
                StatefulDropdownButton<String>(
                  label: 'Parity',
                  values: const ['N', 'E', 'O', 'S', 'M'],
                  valueNotifier: _parityNotifier,
                ),
                const SizedBox(height: 8),
                StatefulDropdownButton<int>(
                  label: 'Stop Bits',
                  values: const [1, 0],
                  valueNotifier: _stopBitsNotifier,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    final protocol = _protocolNotifier.value;
                    final port = _portController.text;
                    final baudText = _baudController.text;
                    if (protocol.isEmpty || port.isEmpty || baudText.isEmpty) {
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
                    _portController.clear();
                    _baudController.clear();
                    _protocolNotifier.value = '';
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Serial Device'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
