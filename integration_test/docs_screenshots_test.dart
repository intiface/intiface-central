import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_environment.dart';
import 'helpers/pump_until.dart';
import 'helpers/rust_lib_lifecycle.dart';
import 'helpers/sim_device_setup.dart';
import 'test_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  group('docs screenshots', () {
    final env = TestAppEnvironment();

    setUp(() async => await env.setUp());
    tearDown(() async {
      await clearTestDevices();
      await resetRustLibForIntegrationTest();
      await env.tearDown();
    });

    testWidgets('captures connected simulated device list', (tester) async {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await binding.convertFlutterSurfaceToImage();
      }

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

      await tester.tap(find.byTooltip('Start Server'));
      await pumpUntilFound(tester, find.byTooltip('Stop Server'));
      await tester.tap(find.text('Start Scanning'));
      await pumpUntilFound(tester, find.text('Test Domi'));

      await tester.tap(find.text('Stop Scanning'));
      await pumpUntilFound(tester, find.text('Start Scanning'));
      await tester.pump(const Duration(milliseconds: 250));

      await binding.takeScreenshot('device-list-connected-integration');
    });
  });
}
