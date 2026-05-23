import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show BaseEntrypoint;
import 'package:intiface_central/src/rust/frb_generated.dart';
import 'mocks.dart';

void setUpRustLibMock([RustLibApi? api]) {
  tearDownRustLibMock();
  RustLib.initMock(api: api ?? MockRustLibApi());
}

void tearDownRustLibMock() {
  // resetState() sets __state = null, which is what initMockImpl checks.
  // dispose() only cleans up resources but doesn't clear the state reference.
  (RustLib.instance as BaseEntrypoint).resetState();
}
