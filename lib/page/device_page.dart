import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device/device_cubit.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/page/add_device_type_page.dart';
import 'package:intiface_central/page/add_serial_device_page.dart';
import 'package:intiface_central/page/add_simulated_device_page.dart';
import 'package:intiface_central/page/add_websocket_device_page.dart';
import 'package:intiface_central/page/device_detail_page.dart';
import 'package:intiface_central/src/rust/api/device_config.dart';
import 'package:intiface_central/util/docs_screenshot_keys.dart';
import 'package:intiface_central/widget/device_list_card_widget.dart';

enum _DeviceSubPage {
  list,
  detail,
  addType,
  addWebsocket,
  addSerial,
  addSimulated,
}

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  _DeviceSubPage _currentPage = _DeviceSubPage.list;
  ExposedUserDeviceIdentifier? _selectedIdentifier;

  void _goToDetail(ExposedUserDeviceIdentifier identifier) {
    setState(() {
      _currentPage = _DeviceSubPage.detail;
      _selectedIdentifier = identifier;
    });
  }

  void _goToAddType() {
    setState(() {
      _currentPage = _DeviceSubPage.addType;
    });
  }

  void _goToAddWebsocket() {
    setState(() {
      _currentPage = _DeviceSubPage.addWebsocket;
    });
  }

  void _goToAddSerial() {
    setState(() {
      _currentPage = _DeviceSubPage.addSerial;
    });
  }

  void _goToAddSimulated() {
    setState(() {
      _currentPage = _DeviceSubPage.addSimulated;
    });
  }

  void _goBack() {
    setState(() {
      _currentPage = _DeviceSubPage.list;
      _selectedIdentifier = null;
    });
  }

  void _goBackToAddType() {
    setState(() {
      _currentPage = _DeviceSubPage.addType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_currentPage) {
      _DeviceSubPage.list => _DeviceListView(
        onDeviceTap: _goToDetail,
        onAddDeviceTap: _goToAddType,
      ),
      _DeviceSubPage.detail => DeviceDetailPage(
        identifier: _selectedIdentifier!,
        onBack: _goBack,
      ),
      _DeviceSubPage.addType => AddDeviceTypePage(
        onBack: _goBack,
        onWebsocket: _goToAddWebsocket,
        onSerial: _goToAddSerial,
        onSimulated: _goToAddSimulated,
      ),
      _DeviceSubPage.addWebsocket => AddWebsocketDevicePage(
        onBack: _goBackToAddType,
      ),
      _DeviceSubPage.addSerial => AddSerialDevicePage(onBack: _goBackToAddType),
      _DeviceSubPage.addSimulated => AddSimulatedDevicePage(
        onBack: _goBackToAddType,
      ),
    };
  }
}

class _DeviceListView extends StatelessWidget {
  final void Function(ExposedUserDeviceIdentifier identifier) onDeviceTap;
  final VoidCallback onAddDeviceTap;

  const _DeviceListView({
    required this.onDeviceTap,
    required this.onAddDeviceTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineControlBloc, EngineControlState>(
      buildWhen: (previous, current) =>
          current is DeviceConnectedState ||
          current is DeviceDisconnectedState ||
          current is ClientDisconnectedState ||
          current is EngineStoppedState,
      builder: (context, engineState) {
        final deviceBloc = BlocProvider.of<DeviceManagerBloc>(context);
        final engineRunning = engineState is! EngineStoppedState;

        return BlocBuilder<DeviceManagerBloc, DeviceManagerState>(
          builder: (context, state) {
            return BlocBuilder<
              UserDeviceConfigurationCubit,
              UserDeviceConfigurationState
            >(
              builder: (context, userConfigState) {
                final userDeviceConfigCubit =
                    BlocProvider.of<UserDeviceConfigurationCubit>(context);
                final connectedDevices = deviceBloc.devices;
                final connectedIndexes = connectedDevices
                    .map((d) => d.device!.index)
                    .toSet();
                final anyAllowed = userDeviceConfigCubit.configs.values.any(
                  (def) => def.allow,
                );

                final sortedEntries = userDeviceConfigCubit.configs.entries
                    .toList();
                sortedEntries.sort((a, b) {
                  final aConnected = connectedIndexes.contains(a.value.index);
                  final bConnected = connectedIndexes.contains(b.value.index);
                  if (aConnected != bConnected) {
                    return aConnected ? -1 : 1;
                  }
                  final aName = (a.value.displayName ?? a.value.name)
                      .toLowerCase();
                  final bName = (b.value.displayName ?? b.value.name)
                      .toLowerCase();
                  return aName.compareTo(bName);
                });

                return Expanded(
                  child: Column(
                    children: [
                      if (anyAllowed) _AllowModeBanner(),
                      Row(
                        children: [
                          !deviceBloc.scanning
                              ? TextButton(
                                  onPressed: engineRunning
                                      ? () {
                                          deviceBloc.add(
                                            DeviceManagerStartScanningEvent(),
                                          );
                                        }
                                      : null,
                                  child: const Text("Start Scanning"),
                                )
                              : TextButton(
                                  onPressed: engineRunning
                                      ? () {
                                          deviceBloc.add(
                                            DeviceManagerStopScanningEvent(),
                                          );
                                        }
                                      : null,
                                  child: const Text("Stop Scanning"),
                                ),
                        ],
                      ),
                      Expanded(
                        child: sortedEntries.isEmpty
                            ? _NoDevicesView(
                                engineRunning: engineRunning,
                                onAddDeviceTap: onAddDeviceTap,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                itemCount: sortedEntries.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == sortedEntries.length) {
                                    return _AddDeviceButton(
                                      enabled: !engineRunning,
                                      onTap: onAddDeviceTap,
                                    );
                                  }
                                  final entry = sortedEntries[index];
                                  final isConnected = connectedIndexes.contains(
                                    entry.value.index,
                                  );
                                  DeviceCubit? matchingCubit;
                                  if (isConnected) {
                                    try {
                                      matchingCubit = connectedDevices
                                          .firstWhere(
                                            (d) =>
                                                d.device?.index ==
                                                entry.value.index,
                                          );
                                    } catch (_) {}
                                  }
                                  return DeviceListCard(
                                    identifier: entry.key,
                                    definition: entry.value,
                                    isConnected: isConnected,
                                    deviceCubit: matchingCubit,
                                    onTap: () => onDeviceTap(entry.key),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AllowModeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 18, color: Colors.green[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Allow-mode active: only devices marked "Allow" will connect',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.green[700]),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoDevicesView extends StatelessWidget {
  final bool engineRunning;
  final VoidCallback onAddDeviceTap;

  const _NoDevicesView({
    required this.engineRunning,
    required this.onAddDeviceTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.vibration,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No devices available',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start the engine and connect a device to get started.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _AddDeviceButton(enabled: !engineRunning, onTap: onAddDeviceTap),
        ],
      ),
    );
  }
}

class _AddDeviceButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _AddDeviceButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: OutlinedButton.icon(
        key: DocsScreenshotKeys.manageAdvancedDevicesCard,
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.add),
        label: const Text('Manage Advanced Devices'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          side: BorderSide(
            color: enabled
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}
