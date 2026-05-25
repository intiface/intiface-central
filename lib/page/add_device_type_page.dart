import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/util/docs_screenshot_keys.dart';

class AddDeviceTypePage extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onWebsocket;
  final VoidCallback onSerial;
  final VoidCallback onSimulated;

  const AddDeviceTypePage({
    super.key,
    required this.onBack,
    required this.onWebsocket,
    required this.onSerial,
    required this.onSimulated,
  });

  @override
  Widget build(BuildContext context) {
    final configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    final websocketEnabled = configCubit.useDeviceWebsocketServer;
    final serialEnabled = isDesktop && configCubit.useSerialPort;
    final simulatedEnabled = configCubit.useSimulatedDevices;

    return Expanded(
      child: Column(
        children: [
          _DetailHeader(title: 'Manage Advanced Devices', onBack: onBack),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose device type',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!websocketEnabled && !serialEnabled && !simulatedEnabled)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                      child: Text(
                        'Advanced device managers can '
                        'be turned on in the Advanced Settings section of the '
                        'App Modes panel.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (simulatedEnabled)
                    _DeviceTypeCard(
                      key: DocsScreenshotKeys.advancedDeviceTypeSimulated,
                      icon: Icons.memory,
                      title: 'Simulated Devices',
                      subtitle: 'Add/Manage a fake test device defined from built-in templates',
                      onTap: onSimulated,
                    ),
                  if (websocketEnabled)
                    _DeviceTypeCard(
                      key: DocsScreenshotKeys.advancedDeviceTypeWebsocket,
                      icon: Icons.language,
                      title: 'Websocket Devices',
                      subtitle: 'Add/Manage a device over WebSocket protocol',
                      onTap: onWebsocket,
                    ),
                  if (serialEnabled)
                    _DeviceTypeCard(
                      key: DocsScreenshotKeys.advancedDeviceTypeSerial,
                      icon: Icons.usb,
                      title: 'Serial Port Devices',
                      subtitle: 'Add/Manage a serial port device',
                      onTap: onSerial,
                    ),
                ],
              ),
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
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack, tooltip: 'Back to device list'),
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

class _DeviceTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DeviceTypeCard({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
