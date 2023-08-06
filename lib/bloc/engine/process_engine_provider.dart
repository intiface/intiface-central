import 'dart:convert';
import 'dart:math';

import 'package:intiface_central/bridge_generated.dart';
import 'package:intiface_central/bloc/engine/engine_messages.dart';
import 'package:intiface_central/bloc/engine/engine_provider.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';
import 'dart:async';

class ProcessEngineProvider implements EngineProvider {
  Process? _serverProcess;
  WebSocketChannel? _ipcChannel;
  final StreamController<String> _processMessageStream = StreamController();

  List<String> _buildCLIArgs(EngineOptionsExternal options, int frontendPort) {
    List<String> arguments = [];

    arguments.addAll(["--server-name", options.serverName]);
    arguments.addAll(["--frontend-websocket-port", frontendPort.toString()]);
    if (IntifacePaths.deviceConfigFile.existsSync()) {
      arguments.addAll(["--device-config-file", IntifacePaths.deviceConfigFile.path]);
    }
    if (IntifacePaths.userDeviceConfigFile.existsSync()) {
      arguments.addAll(["--user-device-config-file", IntifacePaths.userDeviceConfigFile.path]);
    }
    if (options.websocketUseAllInterfaces) {
      arguments.add("--websocket-use-all-interfaces");
    }
    arguments.addAll(["--websocket-port", options.websocketPort.toString()]);
    arguments.addAll(["--log", "debug"]);
    if (options.maxPingTime > 0) {
      arguments.addAll(["--max-ping-time", options.maxPingTime.toString()]);
    }

    if (options.crashReporting) {
      arguments.add("--crash-reporting");
    }
    if (options.allowRawMessages) {
      arguments.add("--allow-raw");
    }
    if (options.useBluetoothLe) {
      arguments.add("--use-bluetooth-le");
    }
    if (options.useDeviceWebsocketServer) {
      arguments.add("--use-device-websocket-server");
    }
    if (options.useHid) {
      arguments.add("--use-hid");
    }
    if (options.useLovenseDongleHid) {
      arguments.add("--use-lovense-dongle-hid");
    }
    if (options.useLovenseDongleSerial) {
      arguments.add("--use-lovense-dongle-serial");
    }
    if (options.useSerialPort) {
      arguments.add("--use-serial");
    }
    if (options.useXinput) {
      arguments.add("--use-xinput");
    }
    if (options.useLovenseConnect) {
      arguments.add("--use-lovense-connect");
    }
    return arguments;
  }

  @override
  Future<void> start({required EngineOptionsExternal options}) async {
    // If the process is already up, return success.
    if (_ipcChannel != null || _serverProcess != null) {
      return;
    }
    var processFile = IntifacePaths.engineFile;
    if (!await processFile.exists()) {
      var path = processFile.path;
      logError("Cannot find engine file at $path");
      throw EngineProviderStartException("Process cannot be started, engine file not found at $path");
    }

    var rng = Random();
    // Just make port randomly between 10000-60000;
    var frontendPort = rng.nextInt(50000) + 10000;
    //var frontendPort = 51865;

    var engineArguments = _buildCLIArgs(options, frontendPort);

    logInfo("Starting $engineArguments");

    _serverProcess = await Process.start(processFile.path, engineArguments);
    //_serverProcess = await Process.start(
    //    "C:\\Users\\qdot\\code\\intiface-engine\\target\\debug\\intiface_engine.exe", engineArguments);
    // Wait for the process to bring up its server before trying to connect.
    // TODO This is assuming our server is local, which may not be the case?
    _ipcChannel = WebSocketChannel.connect(
      Uri.parse('ws://127.0.0.1:$frontendPort'),
    );
    _ipcChannel!.stream.forEach((element) {
      try {
        _processMessageStream.add(element);
      } catch (e) {
        logError("Error adding message to stream: $e");
        stop();
      }
    });
  }

  @override
  void cycleStream() {}

  @override
  void send(String msg) {
    _ipcChannel!.sink.add(msg);
  }

  @override
  void sendBackdoorMessage(String msg) {}

  @override
  Future<void> stop() async {
    if (_serverProcess != null && _ipcChannel != null) {
      var msg = IntifaceMessage();
      msg.stop = Stop();
      send(jsonEncode(msg));
      await _serverProcess!.exitCode;
      _ipcChannel = null;
      _serverProcess = null;
    }
  }

  @override
  void onEngineStart() {}

  @override
  void onEngineStop() {}

  @override
  Stream<String> get engineRawMessageStream => _processMessageStream.stream;
}
