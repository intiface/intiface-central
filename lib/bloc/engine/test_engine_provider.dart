import 'package:intiface_central/bloc/engine/engine_provider.dart';
import 'package:intiface_central/src/rust/api/simple.dart';

class TestEngineProvider implements EngineProvider {
  @override
  Future<void> start({required EngineOptionsExternal options}) async {
    throw "Unimplemented";
  }

  @override
  Future<void> stop() async {
    throw "Unimplemented";
  }

  @override
  Future<bool> rustRuntimeStarted() async {
    throw "Unimplemented";
  }

  @override
  void cycleStream() {}

  @override
  void sendToRust(String msg) {}

  @override
  void sendBackdoorMessage(String msg) {}

  @override
  void onEngineStart() {}

  @override
  void onEngineStop() {}

  @override
  Stream<String> get engineRawMessageStream => throw "Unimplemented";
}
