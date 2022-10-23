import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_provider.dart';

class TestEngineProvider implements EngineProvider {
  @override
  Future<void> start({required IntifaceConfigurationRepository configRepo}) async {
    throw "Unimplemented";
  }

  @override
  Future<void> stop() async {
    throw "Unimplemented";
  }

  @override
  void send(String msg) {}

  @override
  Stream<String> get engineRawMessageStream => throw "Unimplemented";
}
