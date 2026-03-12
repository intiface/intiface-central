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
    // Capture the stream for this run. The listener closure uses this reference
    // so that if start() is called again concurrently (replacing _engineMessageStream),
    // the old listener still closes only its own stream and not the new one.
    final capturedStream = _engineMessageStream;
    _provider.cycleStream();
    _provider.engineRawMessageStream.listen((element) {
      dynamic jsonElement;
      try {
        // Try parsing the JSON first to make sure it's even valid JSON.
        jsonElement = jsonDecode(element);
      } catch (e) {
        logError("Error decoding json for engine message $element: $e");
        return;
      }
      try {
        // If we've got valid JSON, see if it's an engine message or a server message.
        var message = EngineMessage.fromJson(jsonElement);
        if (!capturedStream.isClosed) {
          capturedStream.add(EngineOutput(message, null));
        }
        if (message.engineStarted != null) {
          _provider.onEngineStart();
        }
        if (message.engineStopped != null) {
          _provider.onEngineStop();
          // Close the stream after adding engineStopped. Closing here (rather
          // than in stop()) ensures the message is queued before the done event,
          // so emit.forEach always receives engineStopped and clears _isRunning.
          // Closing in stop() races with async stream delivery and can cause
          // _isRunning to be stuck true, silently dropping all future start events.
          capturedStream.close();
        }
        return;
      } catch (_) {}
      try {
        var buttplugMessage = ButtplugServerMessage.fromJson(jsonElement[0]);
        capturedStream.add(EngineOutput(null, buttplugMessage));
        return;
      } catch (_) {}
      logError("Error deserializing engine message $element");
    });
    await _provider.start(options: options);
  }

  Future<void> stop() async {
    // Snapshot the current stream BEFORE awaiting, so we can check later whether
    // a concurrent EngineControlEventStart replaced it while we were waiting.
    final streamToClose = _engineMessageStream;
    await _provider.stop();
    // The stream is normally closed by the engineStopped message handler above.
    // This is a safety-net close for cases where engineStopped never arrives
    // (e.g. Rust panic, service killed). Skip if already closed or replaced.
    if (!streamToClose.isClosed && identical(streamToClose, _engineMessageStream)) {
      await _engineMessageStream.close();
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
