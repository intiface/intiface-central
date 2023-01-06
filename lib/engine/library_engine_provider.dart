import 'dart:async';
import 'dart:io';
import "../ffi.dart";

import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_provider.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';

class LibraryEngineProvider implements EngineProvider {
  StreamController<String> _processMessageStream = StreamController();
  Stream<String>? _stream;

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
    logInfo("Starting library internal engine with the following arguments: $engineOptions");
    _stream = api.runEngine(args: engineOptions);
    logInfo("Engine started");
    _stream!.forEach((element) {
      try {
        _processMessageStream.add(element);
      } catch (e) {
        logError("Error adding message to stream: $e");
        stop();
      }
    });
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

  @override
  Stream<String> get engineRawMessageStream => _processMessageStream.stream;
}
