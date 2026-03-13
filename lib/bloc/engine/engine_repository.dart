// Repository will select whether we're going through test, external process, or internal library. There won't be a
// point where we have to split between these so this basically works as a dependency injection point for running tests.

import 'dart:async';
import 'dart:convert';

import 'package:buttplug/buttplug.dart';
import 'package:buttplug/messages/messages.dart';
import 'package:intiface_central/src/rust/api/runtime.dart';
import 'package:intiface_central/bloc/engine/engine_messages.dart';
import 'package:intiface_central/bloc/engine/engine_provider.dart';
import 'package:loggy/loggy.dart';

class EngineOutput {
  final EngineMessage? engineMessage;
  final ButtplugServerMessage? buttplugServerMessage;

  EngineOutput(this.engineMessage, this.buttplugServerMessage);
}

class EngineRepository {
  final EngineProvider _provider;
  StreamController<EngineOutput> _engineMessageStream = StreamController();

  EngineRepository(this._provider);

  Future<void> start({required EngineOptionsExternal options}) async {
    _engineMessageStream.close();
    _engineMessageStream = StreamController();
    // Start the provider first so it creates a fresh engineRawMessageStream,
    // then attach the listener. Non-broadcast StreamControllers buffer events
    // until listened, so no messages are lost.
    await _provider.start(options: options);
    _provider.engineRawMessageStream.listen((element) {
      dynamic jsonElement;
      try {
        jsonElement = jsonDecode(element);
      } catch (e) {
        logError("Error decoding json for engine message $element: $e");
        return;
      }
      try {
        var message = EngineMessage.fromJson(jsonElement);
        if (!_engineMessageStream.isClosed) {
          _engineMessageStream.add(EngineOutput(message, null));
        }
        if (message.engineStopped != null) {
          _engineMessageStream.close();
        }
        return;
      } catch (_) {}
      try {
        var buttplugMessage = ButtplugServerMessage.fromJson(jsonElement[0]);
        if (!_engineMessageStream.isClosed) {
          _engineMessageStream.add(EngineOutput(null, buttplugMessage));
        }
        return;
      } catch (_) {}
      logError("Error deserializing engine message $element");
    });
  }

  Future<void> stop() async {
    final streamToClose = _engineMessageStream;
    await _provider.stop();
    if (!streamToClose.isClosed) {
      await streamToClose.close();
    }
  }

  Future<bool> runtimeStarted() async {
    return await _provider.runtimeStarted();
  }

  void send(String msg) {
    _provider.send(msg);
  }

  void sendBackdoorMessage(String msg) {
    _provider.sendBackdoorMessage(msg);
  }

  Stream<EngineOutput> get messageStream => _engineMessageStream.stream;
}
