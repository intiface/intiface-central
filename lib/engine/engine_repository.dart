// Repository will select whether we're going through test, external process, or internal library. There won't be a
// point where we have to split between these so this basically works as a dependency injection point for running tests.

import 'dart:async';
import 'dart:convert';

import 'package:intiface_central/engine/engine_messages.dart';
import 'package:intiface_central/engine/engine_provider.dart';

class EngineRepository {
  EngineProvider _provider;
  StreamController<EngineMessage> _engineMessageStream = StreamController();

  EngineRepository(this._provider) {
    _provider.engineRawMessageStream.forEach((element) {
      var message = EngineMessage.fromJson(jsonDecode(element));
      _engineMessageStream.add(message);
    });
  }

  Stream<EngineMessage> get messageStream => _engineMessageStream.stream;

  // Expose provider so we can call start/stop on it.
  EngineProvider get provider => _provider;
}
