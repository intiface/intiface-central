// Repository will select whether we're going through test, external process, or internal library. There won't be a
// point where we have to split between these so this basically works as a dependency injection point for running tests.

import 'dart:async';
import 'dart:convert';

import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_messages.dart';
import 'package:intiface_central/engine/engine_provider.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';

class EngineRepository {
  final EngineProvider _provider;
  final IntifaceConfigurationRepository _configRepo;
  final StreamController<EngineMessage> _engineMessageStream = StreamController.broadcast();

  EngineRepository(this._provider, this._configRepo) {
    _provider.engineRawMessageStream.forEach((element) {
      try {
        var message = EngineMessage.fromJson(jsonDecode(element));
        _engineMessageStream.add(message);
      } catch (e) {
        logError("Error decoding engine message: $e");
      }
    });
  }

  Future<void> start() async {
    await _provider.start(processPath: IntifacePaths.engineFile.toString(), configRepo: _configRepo);
  }

  Future<void> stop() async {
    await _provider.stop();
  }

  Stream<EngineMessage> get messageStream => _engineMessageStream.stream;
}
