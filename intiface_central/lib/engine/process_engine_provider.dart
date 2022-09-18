import 'dart:math';

import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_provider.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';
import 'dart:async';

class ProcessEngineProvider implements EngineProvider {
  Process? _serverProcess;
  WebSocketChannel? _ipcChannel;
  final StreamController<String> _processMessageStream = StreamController();

  List<String> _buildCLIArgs(IntifaceConfigurationRepository options, int frontendPort) {
    List<String> arguments = [];

    arguments.addAll(["--server_name", options.serverName]);
    arguments.addAll(["--frontend_websocket_port", frontendPort.toString()]);
    if (IntifacePaths.deviceConfigFile.existsSync()) {
      arguments.addAll(["--device_config_file", IntifacePaths.deviceConfigFile.path]);
    }
    if (IntifacePaths.userDeviceConfigFile.existsSync()) {
      arguments.addAll(["--user_device_config_file", IntifacePaths.userDeviceConfigFile.path]);
    }
    if (options.websocketServerAllInterfaces) {
      arguments.add("--websocket_use_all_interfaces");
    }
    arguments.addAll(["--websocket_port", options.websocketServerPort.toString()]);
    arguments.addAll(["--log", "debug"]);
    if (options.serverMaxPingTime > 0) {
      arguments.addAll(["--max_ping_time", options.serverMaxPingTime.toString()]);
    }

    if (options.crashReporting) {
      arguments.add("--crash_reporting");
    }
    if (options.allowRawMessages) {
      arguments.add("--allow_raw");
    }
    if (options.useBluetoothLE) {
      arguments.add("--use-bluetooth-le");
    }
    if (options.useDeviceWebsocketServer) {
      arguments.add("--use-device-websocket-server");
    }
    if (options.useHID) {
      arguments.add("--use-hid");
    }
    if (options.useLovenseHIDDongle) {
      arguments.add("--use-lovense-dongle-hid");
    }
    if (options.useLovenseSerialDongle) {
      arguments.add("--use-lovense-dongle-serial");
    }
    if (options.useSerialPort) {
      arguments.add("--use-serial");
    }
    if (options.useXInput) {
      arguments.add("--use-xinput");
    }
    if (options.useLovenseConnectService) {
      arguments.add("--use-lovense-connect");
    }
    return arguments;
  }

  @override
  Future<void> start({String? processPath, required IntifaceConfigurationRepository configRepo}) async {
    // If the process is already up, return success.
    if (_ipcChannel != null || _serverProcess != null) {
      return;
    }
    if (processPath == null || processPath!.isEmpty) {
      throw const EngineProviderStartException("Process path cannot be null/empty for ProcessEngineProvider");
    }
    var rng = Random();
    // Just make port randomly between 10000-60000;
    var frontendPort = rng.nextInt(50000) + 10000;
    var engineArguments = _buildCLIArgs(configRepo, frontendPort);

    logInfo("Starting $engineArguments");
    //_serverProcess = await Process.start(parameters.processPath!, parameters.engineArguments);
    _serverProcess =
        await Process.start("C:\\Users\\qdot\\code\\intiface-cli-rs\\target\\debug\\intiface-cli.exe", engineArguments);
    // Wait for the process to bring up its server before trying to connect.
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
  Future<void> stop() async {
    if (_serverProcess != null && _ipcChannel != null) {
      _ipcChannel!.sink.close();
      await _serverProcess!.exitCode;
      _ipcChannel = null;
      _serverProcess = null;
    }
  }

  @override
  Stream<String> get engineRawMessageStream => _processMessageStream.stream;
}
