import 'package:intiface_central/engine/engine_provider.dart';

class TestEngineProvider implements EngineProvider {
  @override
  Future<void> start(EngineProviderStartParameters parameters) async {
    throw "Unimplemented";
  }

  @override
  Future<void> stop() async {
    throw "Unimplemented";
  }

  @override
  Stream<String> get engineRawMessageStream => throw "Unimplemented";
}
