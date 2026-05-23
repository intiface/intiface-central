import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_environment.dart';
import '../helpers/pump_until.dart';
import '../helpers/rust_lib_lifecycle.dart';
import '../helpers/sim_device_setup.dart';
import '../test_app.dart';

void main() {
  group('engine lifecycle', () {
    final env = TestAppEnvironment();

    setUp(() async => await env.setUp());
    tearDown(() async {
      await clearTestDevices();
      await resetRustLibForIntegrationTest();
      await env.tearDown();
    });

    testWidgets('engine starts and stops', (tester) async {
      await tester.pumpWidget(await createTestApp());
      await pumpUntilFound(tester, find.byTooltip('Start Server'));

      await tester.tap(find.byTooltip('Start Server'));
      await pumpUntilFound(tester, find.byTooltip('Stop Server'));

      expect(find.byTooltip('Stop Server'), findsOneWidget);

      await tester.tap(find.byTooltip('Stop Server'));
      await pumpUntilFound(tester, find.byTooltip('Start Server'));

      expect(find.byTooltip('Start Server'), findsOneWidget);
    });
  });
}
