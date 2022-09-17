import 'dart:async';

import 'package:intiface_central/engine/engine_provider.dart';
import 'package:intiface_engine_flutter/intiface_engine_flutter.dart';
import 'dart:io';
import 'package:loggy/loggy.dart';

class LibraryEngineProvider implements EngineProvider {
  final StreamController<String> _processMessageStream = StreamController();
  Stream<String>? _sink;

  @override
  Future<void> start(EngineProviderStartParameters parameters) async {
    var args = EngineOptionsExternal(
        serverName: "Flutter Server",
        crashReporting: false,
        websocketUseAllInterfaces: true,
        websocketPort: 12345,
        frontendInProcessChannel: false,
        maxPingTime: 0,
        allowRawMessages: false,
        logLevel: "DEBUG".toString(),
        useBluetoothLe: true,
        useSerialPort: false,
        useHid: false,
        useLovenseDongleSerial: false,
        useLovenseDongleHid: false,
        useXinput: false,
        useLovenseConnect: false,
        useDeviceWebsocketServer: false,
        crashMainThread: false,
        crashTaskThread: false);
    _sink = api.runEngine(args: args);
    _sink!.forEach((element) {
      try {
        _processMessageStream.add(element);
      } catch (e, stacktrace) {
        logError("Error adding message to stream: $e");
        stop();
      }
    });
  }

  @override
  Future<void> stop() async {
    throw "Unimplemented";
  }

  @override
  Stream<String> get engineRawMessageStream => _processMessageStream.stream;
}
