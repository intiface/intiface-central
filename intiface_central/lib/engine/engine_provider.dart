// Engine providers will take raw messages from the providers and turn them into stream objects to hand up to the bloc.
// This means our providers ONLY handle start/stop/basic stream comms with our provider types, and the repository
// operates as a stream transformer.

abstract class EngineProcessMessage {}

abstract class EngineProvider {
  Future<void> start(EngineProviderStartParameters parameters);
  Future<void> stop();
  Stream<String> get engineRawMessageStream;
}

class EngineProviderStartParameters {
  final String? _processPath;
  final List<String> _engineArguments;

  EngineProviderStartParameters(this._processPath, this._engineArguments);

  String? get processPath => _processPath;
  List<String> get engineArguments => _engineArguments;
}

class EngineProviderStartException implements Exception {
  const EngineProviderStartException([this.message]);

  final String? message;

  @override
  String toString() {
    return 'Exception while starting Intiface Engine: $message';
  }
}
