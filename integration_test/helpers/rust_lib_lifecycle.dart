import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show BaseEntrypoint;
import 'package:intiface_central/src/rust/api/runtime.dart';
import 'package:intiface_central/src/rust/frb_generated.dart';

Future<void> resetRustLibForIntegrationTest() async {
  if (!await _waitForRuntimeStopped()) {
    try {
      await stopEngine();
      await _waitForRuntimeStopped();
    } catch (_) {}
  }

  try {
    RustLib.dispose();
  } catch (_) {}
  // resetState() clears the init guard that dispose() leaves behind.
  // ignore: invalid_use_of_internal_member
  (RustLib.instance as BaseEntrypoint).resetState();
}

Future<bool> _waitForRuntimeStopped({
  Duration timeout = const Duration(seconds: 3),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    try {
      if (!await rustRuntimeStarted()) return true;
    } catch (_) {
      return true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return false;
}
