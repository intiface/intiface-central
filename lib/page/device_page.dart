import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device/device_cubit.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/page/device_detail_page.dart';
import 'package:intiface_central/widget/device_list_card_widget.dart';

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

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
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          itemCount: sortedEntries.length + 1,
                          itemBuilder: (context, index) {
                            if (index == sortedEntries.length) {
                              return _AddDeviceButton(
                                enabled: !engineRunning,
                                onTap: () {
                                  // TODO: Phase 5 — Navigator.push AddDeviceTypePage
                                },
                              );
                            }
                            final entry = sortedEntries[index];
                            final isConnected = connectedIndexes.contains(
                              entry.value.index,
                            );
                            DeviceCubit? deviceCubit;
                            if (isConnected) {
                              try {
                                deviceCubit = connectedDevices.firstWhere(
                                  (d) => d.device!.index == entry.value.index,
                                );
                              } catch (_) {}
                            }
                            return DeviceListCard(
                              identifier: entry.key,
                              definition: entry.value,
                              isConnected: isConnected,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DeviceDetailPage(
                                      identifier: entry.key,
                                      deviceCubit: deviceCubit,
                                    ),
                                  ),
                                );
                              },
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
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.add),
        label: const Text('Add New Device'),
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
