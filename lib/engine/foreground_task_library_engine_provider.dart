import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:intiface_central/configuration/intiface_configuration_provider_shared_preferences.dart';
import 'package:intiface_central/engine/engine_messages.dart';

import "../ffi.dart";

import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_provider.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

String _kMainBackdoorPortName = "intifaceCentralBackdoorMain";
String _kMainServerPortName = "intifaceCentralServerMain";

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(IntifaceEngineTaskHandler());
}

Future<EngineOptionsExternal> _buildArguments(IntifaceConfigurationRepository configRepo) async {
  String? deviceConfigFile;
  if (await IntifacePaths.deviceConfigFile.exists()) {
    deviceConfigFile = await File(IntifacePaths.deviceConfigFile.path).readAsString();
  }

  String? userDeviceConfigFile;
  if (await IntifacePaths.userDeviceConfigFile.exists()) {
    userDeviceConfigFile = await File(IntifacePaths.userDeviceConfigFile.path).readAsString();
  }

  return EngineOptionsExternal(
      serverName: configRepo.serverName,
      deviceConfigJson: deviceConfigFile,
      userDeviceConfigJson: userDeviceConfigFile,
      crashReporting: configRepo.crashReporting,
      websocketUseAllInterfaces: configRepo.websocketServerAllInterfaces,
      websocketPort: configRepo.websocketServerPort,
      frontendInProcessChannel: isMobile(),
      maxPingTime: configRepo.serverMaxPingTime,
      allowRawMessages: configRepo.allowRawMessages,
      logLevel: "DEBUG".toString(),
      useBluetoothLe: configRepo.useBluetoothLE,
      useSerialPort: isDesktop() ? configRepo.useSerialPort : false,
      useHid: isDesktop() ? configRepo.useHID : false,
      useLovenseDongleSerial: isDesktop() ? configRepo.useLovenseSerialDongle : false,
      useLovenseDongleHid: isDesktop() ? configRepo.useLovenseHIDDongle : false,
      useXinput: isDesktop() ? configRepo.useXInput : false,
      useLovenseConnect: isDesktop() ? configRepo.useLovenseConnectService : false,
      useDeviceWebsocketServer: configRepo.useDeviceWebsocketServer,
      crashMainThread: false,
      crashTaskThread: false);
}

class IntifaceEngineTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  ReceivePort _serverMessageReceivePort;
  ReceivePort _backdoorMessageReceivePort;
  Stream<String>? _stream;
  final Completer<void> _serverExited = Completer();

  void _sendProviderLog(String level, String outgoingMessage) {
    var message = EngineProviderLog();
    message.timestamp = DateTime.now().toString();
    message.level = level;
    message.message = outgoingMessage;
    var engineMessage = EngineMessage();
    engineMessage.engineProviderLog = message;
    _sendPort!.send(jsonEncode(engineMessage));
  }

  IntifaceEngineTaskHandler()
      : _serverMessageReceivePort = ReceivePort(),
        _backdoorMessageReceivePort = ReceivePort() {
    // Once we've started everything up, register our receive port
    final serverSendPort = _serverMessageReceivePort.sendPort;
    final backdoorSendPort = _backdoorMessageReceivePort.sendPort;
    IsolateNameServer.registerPortWithName(serverSendPort, _kMainServerPortName);
    IsolateNameServer.registerPortWithName(backdoorSendPort, _kMainBackdoorPortName);
  }

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    _sendProviderLog("Info", "Trying to start engine in foreground service.");

    // Due to the way the foregrounding package we're using works, we can't store the options across the foregrounding
    // process boundary. Trying to encode to/decode from JSON also isn't easily possible because EngineOptionsExternal
    // is a FFI generated class. Therefore we just bring up what is considered to be a readonly version of our config
    // repo in order to build the engine options, then we just drop it when done.
    //
    // Under the covers, flutter_foreground_task is just using SharedPreferences for its data commands anyways, so this
    // is basically doing what it does, while not having to deal with shuffling things around.
    _sendProviderLog("INFO", "Creating shared prefs");
    var prefs = await IntifaceConfigurationProviderSharedPreferences.create();
    _sendProviderLog("INFO", "Creating config repo");
    var configRepo = await IntifaceConfigurationRepository.create(prefs);
    _sendProviderLog("INFO", "Building arguments");

    // Since we're on another process we'll have to reinitialize our paths.
    await IntifacePaths.init();

    // Ok, NOW we can build our engine options.
    var engineOptions = await _buildArguments(configRepo);
    _sendProviderLog("INFO", "Starting engine");

    _sendProviderLog("INFO", "Starting library internal engine with the following arguments: $engineOptions");
    _stream = api.runEngine(args: engineOptions);
    _sendProviderLog("INFO", "Engine started");
    _stream!.forEach((element) {
      try {
        // Send first
        _sendPort!.send(element);
        // Then check to see if this is a EngineStopped message.
        // Try parsing the JSON first to make sure it's even valid JSON.
        var jsonElement = jsonDecode(element);
        var message = EngineMessage.fromJson(jsonElement);
        if (message.engineStopped != null) {
          _serverExited.complete();
        }
      } catch (e) {
        _sendProviderLog("ERROR", "Error adding message to stream: $e");
        //stop();
      }
    });
    _serverMessageReceivePort.forEach((element) async {
      await api.send(msgJson: element);
    });
    _backdoorMessageReceivePort.forEach((element) async {
      await api.sendBackendServerMessage(msg: element);
    });
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Send data to the main isolate.
    sendPort?.send(timestamp);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _sendProviderLog("INFO", "Destroying foreground service.");
    await api.stopEngine();
    await _serverExited.future;
    _sendProviderLog("INFO", "Foreground service destroyed.");
    IsolateNameServer.removePortNameMapping(_kMainServerPortName);
    IsolateNameServer.removePortNameMapping(_kMainBackdoorPortName);
  }

  @override
  void onButtonPressed(String id) {
    if (id == "stopServerButton") {
      FlutterForegroundTask.stopService();
    } else {
      // Called when the notification button on the Android platform is pressed.
      _sendProviderLog("ERROR", "Button id $id not recognized");
    }
  }
}

class ForegroundTaskLibraryEngineProvider implements EngineProvider {
  StreamController<String> _processMessageStream = StreamController();
  ReceivePort? _receivePort;
  SendPort? _serverSendPort;
  SendPort? _backdoorSendPort;

  @override
  Future<void> start({required IntifaceConfigurationRepository configRepo}) async {
    await _startForegroundTask();
  }

  @override
  void cycleStream() {
    _processMessageStream.close();
    _processMessageStream = StreamController();
  }

  @override
  void onEngineStart() {
    _serverSendPort = IsolateNameServer.lookupPortByName(_kMainServerPortName);
    _backdoorSendPort = IsolateNameServer.lookupPortByName(_kMainBackdoorPortName);
  }

  @override
  void onEngineStop() {
    _serverSendPort = null;
    _backdoorSendPort = null;
  }

  @override
  Future<void> stop() async {
    //api.stopEngine();
    await FlutterForegroundTask.stopService();
    logInfo("Engine stop request sent");
  }

  @override
  void send(String msg) {
    _serverSendPort!.send(msg);
  }

  @override
  void sendBackdoorMessage(String msg) {
    //logInfo("Outgoing: $msg");
    //api.sendBackendServerMessage(msg: msg);
    _backdoorSendPort!.send(msg);
  }

  Future<bool> _startForegroundTask() async {
    bool reqResult;
    if (await FlutterForegroundTask.isRunningService) {
      reqResult = await FlutterForegroundTask.restartService();
    } else {
      reqResult = await FlutterForegroundTask.startService(
        notificationTitle: 'Intiface Engine is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }

    ReceivePort? receivePort;
    if (reqResult) {
      receivePort = await FlutterForegroundTask.receivePort;
    }

    return _registerReceivePort(receivePort);
  }

  void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }

  bool _registerReceivePort(ReceivePort? receivePort) {
    _closeReceivePort();

    if (receivePort != null) {
      _receivePort = receivePort;
      _receivePort?.listen((message) {
        if (message is DateTime) {
          logInfo('timestamp: ${message.toString()}');
        } else if (message is String) {
          _processMessageStream.add(message);
        }
      });

      return true;
    }

    return false;
  }

  @override
  Stream<String> get engineRawMessageStream => _processMessageStream.stream;
}
