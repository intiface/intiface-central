import 'dart:async';
import "../../ffi.dart";
import 'package:intiface_central/bloc/engine/engine_provider.dart';
import 'package:loggy/loggy.dart';

class LibraryEngineProvider implements EngineProvider {
  StreamController<String> _processMessageStream = StreamController();
  Stream<String>? _stream;

  @override
  Future<void> start({required EngineOptionsExternal options}) async {
    logInfo("Starting library internal engine with the following arguments: $options");
    try {
      _stream = api!.runEngine(args: options);
    } catch (e) {
      logError("Engine start failed!");
      stop();
      return;
    }
    logInfo("Engine started");
    _stream!.listen((element) {
      try {
        _processMessageStream.add(element);
      } catch (e) {
        logError("Error adding message to stream: $e");
        stop();
      }
    }).onError((e) => logError(e.anyhow));
  }

  @override
  Future<bool> runtimeStarted() async {
    return await api!.runtimeStarted();
  }

  @override
  void cycleStream() {
    _processMessageStream.close();
    _processMessageStream = StreamController();
  }

  @override
  Future<void> stop() async {
    api!.stopEngine();
    logInfo("Engine stopped");
  }

  @override
  void send(String msg) {
    api!.send(msgJson: msg);
  }

  @override
  void sendBackdoorMessage(String msg) {
    //logInfo("Outgoing: $msg");
    api!.sendBackendServerMessage(msg: msg);
  }

  @override
  void onEngineStart() {}

  @override
  void onEngineStop() {}

  @override
  Stream<String> get engineRawMessageStream => _processMessageStream.stream;
}
