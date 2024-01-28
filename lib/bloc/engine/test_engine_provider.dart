import 'package:intiface_central/bridge_generated.dart';
import 'package:intiface_central/bloc/engine/engine_provider.dart';

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
  Future<bool> runtimeStarted() async {
    throw "Unimplemented";
  }

  @override
  void cycleStream() {}

  @override
  void send(String msg) {}

  @override
  void sendBackdoorMessage(String msg) {}

  @override
  void onEngineStart() {}

  @override
  void onEngineStop() {}

  @override
  Stream<String> get engineRawMessageStream => throw "Unimplemented";
}
