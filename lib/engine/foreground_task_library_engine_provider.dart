import 'dart:async';
import 'dart:io';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';

import "../ffi.dart";

import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_provider.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(IntifaceEngineTaskHandler());
}

class IntifaceEngineTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  Stream<String>? _stream;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    _sendPort!.send("Trying to start engine");
    var engineOptions = EngineOptionsExternal(
        serverName: "ForegroundServer",
        deviceConfigJson: null,
        userDeviceConfigJson: null,
        crashReporting: false,
        websocketUseAllInterfaces: true,
        websocketPort: 12345,
        frontendInProcessChannel: true,
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
    _sendPort!.send("got arguments");
    _sendPort!.send("Starting library internal engine with the following arguments: $engineOptions");
    _stream = api.runEngine(args: engineOptions!);
    _sendPort!.send("Engine started");
    _stream!.forEach((element) {
      try {
        _sendPort!.send(element);
      } catch (e) {
        _sendPort!.send("Error adding message to stream: $e");
        //stop();
      }
    });
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Send data to the main isolate.
    sendPort?.send(timestamp);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // You can use the clearAllData function to clear all the stored data.
    await FlutterForegroundTask.clearAllData();
  }

  @override
  void onButtonPressed(String id) {
    // Called when the notification button on the Android platform is pressed.
    _sendPort!.send('onButtonPressed >> $id');
  }

  @override
  void onNotificationPressed() {
    // Called when the notification itself on the Android platform is pressed.
    //
    // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
    // this function to be called.

    // Note that the app will only route to "/resume-route" when it is exited so
    // it will usually be necessary to send a message through the send port to
    // signal it to restore state when the app is already started.
    FlutterForegroundTask.launchApp("/resume-route");
    _sendPort?.send('onNotificationPressed');
  }
}

class ForegroundTaskLibraryEngineProvider implements EngineProvider {
  StreamController<String> _processMessageStream = StreamController();
  ReceivePort? _receivePort;

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

  @override
  Future<void> start({required IntifaceConfigurationRepository configRepo}) async {
    var engineOptions = await _buildArguments(configRepo);
    await _startForegroundTask(engineOptions);
  }

  @override
  void cycleStream() {
    _processMessageStream.close();
    _processMessageStream = StreamController();
  }

  @override
  Future<void> stop() async {
    api.stopEngine();
    logInfo("Engine stopped");
  }

  @override
  void send(String msg) {
    api.send(msgJson: msg);
  }

  @override
  void sendBackdoorMessage(String msg) {
    //logInfo("Outgoing: $msg");
    api.sendBackendServerMessage(msg: msg);
  }

  Future<bool> _startForegroundTask(EngineOptionsExternal engineOptions) async {
    // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
    // onNotificationPressed function to be called.
    //
    // When the notification is pressed while permission is denied,
    // the onNotificationPressed function is not called and the app opens.
    //
    // If you do not use the onNotificationPressed or launchApp function,
    // you do not need to write this code.
    if (!await FlutterForegroundTask.canDrawOverlays) {
      final isGranted = await FlutterForegroundTask.openSystemAlertWindowSettings();
      if (!isGranted) {
        logError('SYSTEM_ALERT_WINDOW permission denied!');
        return false;
      }
    }

    await FlutterForegroundTask.saveData(key: 'arguments', value: engineOptions);

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
          if (message == 'onNotificationPressed') {
            //Navigator.of(context).pushNamed('/resume-route');
          }
        }
        if (message is String) {
          logError(message);
        }
      });

      return true;
    }

    return false;
  }

  @override
  Stream<String> get engineRawMessageStream => _processMessageStream.stream;
}
