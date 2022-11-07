// Repository will select whether we're going through test, external process, or internal library. There won't be a
// point where we have to split between these so this basically works as a dependency injection point for running tests.

import 'dart:async';
import 'dart:convert';

import 'package:buttplug/buttplug.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_messages.dart';
import 'package:intiface_central/engine/engine_provider.dart';
import 'package:loggy/loggy.dart';

class EngineOutput {
  final EngineMessage? engineMessage;
  final ButtplugServerMessage? buttplugServerMessage;

  EngineOutput(this.engineMessage, this.buttplugServerMessage);
}

class EngineRepository {
  final EngineProvider _provider;
  final IntifaceConfigurationRepository _configRepo;
  StreamController<EngineOutput> _engineMessageStream = StreamController.broadcast();

  EngineRepository(this._provider, this._configRepo) {}

  Future<void> start() async {
    _engineMessageStream.close();
    _engineMessageStream = StreamController.broadcast();
    _provider.cycleStream();
    _provider.engineRawMessageStream.forEach((element) {
      dynamic jsonElement;
      try {
        // Try parsing the JSON first to make sure it's even valid JSON.
        jsonElement = jsonDecode(element);
      } catch (e) {
        logError("Error decoding engine message $element: $e");
      }
      try {
        // If we've got valid JSON, see if it's an engine message or a server message.
        var message = EngineMessage.fromJson(jsonElement);
        _engineMessageStream.add(EngineOutput(message, null));
      } catch (e) {
        try {
          var buttplugMessage = ButtplugServerMessage.fromJson(jsonElement[0]);
          _engineMessageStream.add(EngineOutput(null, buttplugMessage));
        } catch (e) {
          logError("Error deserializing engine message $element: $e");
        }
      }
    });
    await _provider.start(configRepo: _configRepo);
  }

  Future<void> stop() async {
    await _provider.stop();
  }

  void send(String msg) {
    _provider.send(msg);
  }

  void sendBackdoorMessage(String msg) {
    _provider.sendBackdoorMessage(msg);
  }

  Stream<EngineOutput> get messageStream => _engineMessageStream.stream;
}
