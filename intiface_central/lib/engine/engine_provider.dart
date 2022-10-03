// Engine providers will take raw messages from the providers and turn them into stream objects to hand up to the bloc.
// This means our providers ONLY handle start/stop/basic stream comms with our provider types, and the repository
// operates as a stream transformer.

import 'package:intiface_central/configuration/intiface_configuration_repository.dart';

abstract class EngineProcessMessage {}

abstract class EngineProvider {
  Future<void> start({required IntifaceConfigurationRepository configRepo});
  Future<void> stop();
  void send(String msg);
  Stream<String> get engineRawMessageStream;
}

class EngineProviderStartException implements Exception {
  const EngineProviderStartException([this.message]);

  final String? message;

  @override
  String toString() {
    return 'Exception while starting Intiface Engine: $message';
  }
}
