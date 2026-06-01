import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intiface_central/page/device_page.dart';

import '../helpers/device_fixtures.dart';
import '../helpers/fake_blocs.dart';
import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

void main() {
  group('DevicePage', () {
    testWidgets('shows an empty state when no devices are configured', (
      tester,
    ) async {
      await pumpApp(
        tester,
        child: const Scaffold(body: Column(children: [DevicePage()])),
      );

      expect(find.text('No devices available'), findsOneWidget);
      expect(
        find.text('Start the engine and connect a device to get started.'),
        findsOneWidget,
      );
    });

    testWidgets('hides the empty state when devices are configured', (
      tester,
    ) async {
      final userConfigCubit = MockUserDeviceConfigurationCubit();
      final device = singleVibrator();
      stubUserDeviceConfigurationCubit(
        userConfigCubit,
        configs: {device.identifier: device.definition},
      );

      await pumpApp(
        tester,
        child: const Scaffold(body: Column(children: [DevicePage()])),
        userConfigCubit: userConfigCubit,
      );

      expect(find.text('No devices available'), findsNothing);
      expect(find.text('Test Vibrator'), findsOneWidget);
    });
  });
}
