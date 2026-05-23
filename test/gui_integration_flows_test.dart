import 'package:flutter_test/flutter_test.dart';

import '../integration_test/flows/device_connect_test.dart' as device_connect;
import '../integration_test/flows/engine_lifecycle_test.dart'
    as engine_lifecycle;

void main() {
  final binding = LiveTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  engine_lifecycle.main();
  device_connect.main();
}
