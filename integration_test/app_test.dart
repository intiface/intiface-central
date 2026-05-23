import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'flows/engine_lifecycle_test.dart' as engine_lifecycle;
import 'flows/device_connect_test.dart' as device_connect;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  engine_lifecycle.main();
  device_connect.main();
}
