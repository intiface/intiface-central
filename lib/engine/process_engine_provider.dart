import 'package:intiface_central/engine/engine_messages.dart';
import 'package:intiface_central/engine/engine_provider.dart';
import 'package:loggy/loggy.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

class ProcessEngineProvider implements EngineProvider {
  Process? _serverProcess;
  WebSocketChannel? _ipcChannel;
  final StreamController<String> _processMessageStream = StreamController();

  @override
  Future<void> start(EngineProviderStartParameters parameters) async {
    // If the process is already up, return success.
    if (_ipcChannel != null || _serverProcess != null) {
      return;
    }
    if (parameters.processPath == null || parameters.processPath!.isEmpty) {
      throw const EngineProviderStartException("Process path cannot be null/empty for ProcessEngineProvider");
    }
    print("Starting ${parameters.engineArguments}");
    //_serverProcess = await Process.start(parameters.processPath!, parameters.engineArguments);
    _serverProcess = await Process.start(
        "C:\\Users\\qdot\\code\\intiface-cli-rs\\target\\debug\\intiface-cli.exe", parameters.engineArguments);
    // Wait for the process to bring up its server before trying to connect.
    // TODO We should get the websocket port as an argument here.
    _ipcChannel = WebSocketChannel.connect(
      Uri.parse('ws://127.0.0.1:12346'),
    );
    _ipcChannel!.stream.forEach((element) {
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
