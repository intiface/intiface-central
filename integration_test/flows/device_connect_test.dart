import 'package:flutter_test/flutter_test.dart';
import 'package:intiface_central/src/rust/frb_generated.dart';

import '../helpers/app_environment.dart';
import '../helpers/sim_device_setup.dart';
import '../test_app.dart';

void main() {
  final env = TestAppEnvironment();

  setUp(() async => await env.setUp());
  tearDown(() async {
    await clearTestDevices();
    try {
      RustLib.dispose();
    } catch (_) {}
    await env.tearDown();
  });

  testWidgets('connect and control simulated vibrator', (tester) async {
    await tester.pumpWidget(await createTestApp(
      afterUserDeviceConfigurationInit: (userConfigCubit) async {
        await addTestDevice(
          identifier: 'lovense-domi',
          displayName: 'Test Domi',
        );
        await userConfigCubit.update();
      },
    ));
    await tester.pumpAndSettle();

    // Start engine (useSimulatedDevices=true is set by TestAppEnvironment)
    await tester.tap(find.byTooltip('Start Server'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Device should auto-connect and appear in list
    expect(find.text('Test Domi'), findsOneWidget);
  });
}
