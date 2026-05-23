import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_environment.dart';
import '../helpers/pump_until.dart';
import '../helpers/rust_lib_lifecycle.dart';
import '../helpers/sim_device_setup.dart';
import '../test_app.dart';

void main() {
  group('device connect', () {
    final env = TestAppEnvironment();

    setUp(() async => await env.setUp());
    tearDown(() async {
      await clearTestDevices();
      await resetRustLibForIntegrationTest();
      await env.tearDown();
    });

    testWidgets('connect and control simulated vibrator', (tester) async {
      await tester.pumpWidget(
        await createTestApp(
          afterUserDeviceConfigurationInit: (userConfigCubit) async {
            await addTestDevice(
              identifier: 'simulated-1vibe',
              displayName: 'Test Domi',
            );
            await userConfigCubit.update();
          },
        ),
      );
      await pumpUntilFound(tester, find.byTooltip('Start Server'));
      await tester.tap(find.text('Devices').first);
      await pumpUntilFound(tester, find.text('Start Scanning'));

      // Start engine (useSimulatedDevices=true is set by TestAppEnvironment)
      await tester.tap(find.byTooltip('Start Server'));
      await pumpUntilFound(tester, find.byTooltip('Stop Server'));
      await tester.tap(find.text('Start Scanning'));
      await pumpUntilFound(tester, find.text('Stop Scanning'));
      await pumpUntilFound(tester, find.text('Test Domi'));

      // Device should auto-connect and appear in list
      expect(find.text('Test Domi'), findsOneWidget);
      await tester.tap(find.text('Stop Scanning'));
      await pumpUntilFound(tester, find.text('Start Scanning'));

      await tester.tap(find.text('Test Domi'));
      await pumpUntilFound(tester, find.text('Device Controls'));

      final slider = tester.widget<Slider>(find.byType(Slider).first);
      slider.onChanged!(50);
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        tester.widget<Slider>(find.byType(Slider).first).value,
        greaterThan(0),
      );

      await pumpUntil(
        tester,
        () => (_latestObservationValue(tester) ?? 0.0) > 0.05,
        timeout: const Duration(seconds: 5),
        reason: 'Timed out waiting for simulated device output observation',
      );
      expect(_latestObservationValue(tester), greaterThan(0.05));
    });
  });
}

double? _latestObservationValue(WidgetTester tester) {
  final widgets = tester.widgetList<Semantics>(
    find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          (widget.properties.label ?? '').startsWith(
            'Device output observation ',
          ),
    ),
  );

  for (final widget in widgets) {
    final value = double.tryParse(widget.properties.value ?? '');
    if (value != null) return value;
  }

  return null;
}
