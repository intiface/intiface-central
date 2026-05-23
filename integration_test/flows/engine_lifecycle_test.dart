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

  testWidgets('engine starts and stops', (tester) async {
    await tester.pumpWidget(await createTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Start Server'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byTooltip('Stop Server'), findsOneWidget);

    await tester.tap(find.byTooltip('Stop Server'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byTooltip('Start Server'), findsOneWidget);
  });
}
