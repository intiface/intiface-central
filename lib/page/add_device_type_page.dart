import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/page/add_serial_device_page.dart';
import 'package:intiface_central/page/add_websocket_device_page.dart';

class AddDeviceTypePage extends StatelessWidget {
  const AddDeviceTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    final configCubit = BlocProvider.of<IntifaceConfigurationCubit>(context);
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    final websocketEnabled = configCubit.useDeviceWebsocketServer;
    final serialEnabled = isDesktop && configCubit.useSerialPort;

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Device')),
      body: Padding(
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
            if (!websocketEnabled && !serialEnabled)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Text(
                  'Advanced device managers (Websocket, Serial Port) can be '
                  'turned on in the Advanced Settings section of the App '
                  'Modes panel.',
                  textAlign: TextAlign.center,
                ),
              ),
            if (websocketEnabled)
              _DeviceTypeCard(
                icon: Icons.language,
                title: 'Websocket Device',
                subtitle: 'Connect to a device over WebSocket protocol',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddWebsocketDevicePage(),
                    ),
                  );
                },
              ),
            if (serialEnabled)
              _DeviceTypeCard(
                icon: Icons.usb,
                title: 'Serial Port Device',
                subtitle: 'Connect to a device via serial port',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddSerialDevicePage(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DeviceTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

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
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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
