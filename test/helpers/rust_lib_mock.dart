import 'package:intiface_central/src/rust/frb_generated.dart';
import 'mocks.dart';

void setUpRustLibMock([RustLibApi? api]) {
  try {
    RustLib.dispose();
  } catch (_) {}
  RustLib.initMock(api: api ?? MockRustLibApi());
}

void tearDownRustLibMock() {
  try {
    RustLib.dispose();
  } catch (_) {}
}
