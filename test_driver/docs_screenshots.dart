import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() {
  return integrationDriver(
    onScreenshot: (screenshotName, screenshotBytes, [args]) async {
      final output = File(
        'docs/assets/screenshots/generated/$screenshotName.png',
      );
      await output.parent.create(recursive: true);
      await output.writeAsBytes(screenshotBytes);
      return true;
    },
  );
}
