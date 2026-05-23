import 'package:flutter_test/flutter_test.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
  Duration step = const Duration(milliseconds: 100),
  String? reason,
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (condition()) return;
    await tester.pump(step);
  }

  if (condition()) return;
  fail(reason ?? 'Timed out waiting for test condition');
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
  Duration step = const Duration(milliseconds: 100),
}) async {
  await pumpUntil(
    tester,
    () => finder.evaluate().isNotEmpty,
    timeout: timeout,
    step: step,
    reason: 'Timed out waiting for $finder',
  );
}
