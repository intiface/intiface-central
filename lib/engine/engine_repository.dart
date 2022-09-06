// Repository will select whether we're going through test, external process, or internal library. There won't be a
// point where we have to split between these so this basically works as a dependency injection point for running tests.

import 'dart:async';
import 'dart:convert';

import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_messages.dart';
import 'package:intiface_central/engine/engine_provider.dart';
import 'package:intiface_central/util/intiface_util.dart';

class EngineRepository {
  final EngineProvider _provider;
  final IntifaceConfigurationRepository _configRepo;
  final StreamController<EngineMessage> _engineMessageStream = StreamController();

  EngineRepository(this._provider, this._configRepo) {
    _provider.engineRawMessageStream.forEach((element) {
      var message = EngineMessage.fromJson(jsonDecode(element));
      _engineMessageStream.add(message);
    });
  }

  List<String> _buildArguments() {
    List<String> arguments = [];

    arguments.addAll(["--servername", _configRepo.serverName]);
    arguments.add("--stayopen");
    if (isDesktop()) {
      // TODO This is now a websocket, should take a port.
      arguments.addAll(["--frontendpipe", "NotAPipe"]);
    }
    if (IntifacePaths.deviceConfigFile.existsSync()) {
      arguments.addAll(["--deviceconfig", IntifacePaths.deviceConfigFile.path]);
    }
    if (IntifacePaths.userDeviceConfigFile.existsSync()) {
      arguments.addAll(["--userdeviceconfig", IntifacePaths.userDeviceConfigFile.path]);
    }
    if (_configRepo.websocketServerAllInterfaces) {
      arguments.add("--wsallinterfaces");
    }
    arguments.addAll(["--wsinsecureport", _configRepo.websocketServerPort.toString()]);
    arguments.addAll(["--log", "debug"]);
    if (_configRepo.serverMaxPingTime > 0) {
      arguments.addAll(["--pingtime", _configRepo.serverMaxPingTime.toString()]);
    }
    if (_configRepo.withDeviceWebsocketServer) {
      arguments.add("--with-device-websocket-server");
    }
    if (_configRepo.crashReporting) {
      arguments.add("--crash-reporting");
    }
    if (_configRepo.allowRawMessages) {
      arguments.add("--allowraw");
    }
    if (!_configRepo.withBluetoothLE) {
      arguments.add("--without-bluetooth-le");
    }

    // All options below only exist on desktop, we can't run these device communication managers on mobile.
    if (isDesktop() && !_configRepo.withHID) {
      arguments.add("--without-hid");
    }
    if (isDesktop() && !_configRepo.withLovenseHIDDongle) {
      arguments.add("--without-lovense-dongle-hid");
    }
    if (isDesktop() && !_configRepo.withLovenseSerialDongle) {
      arguments.add("--without-lovense-dongle-serial");
    }
    if (isDesktop() && !_configRepo.withSerialPort) {
      arguments.add("--without-serial");
    }
    if (isDesktop() && !_configRepo.withXInput) {
      arguments.add("--without-xinput");
    }
    if (isDesktop() && _configRepo.withLovenseConnectService) {
      arguments.add("--with-lovense-connect");
    }

    return arguments;
  }

  Future<void> start() async {
    var params = EngineProviderStartParameters(IntifacePaths.engineFile.toString(), _buildArguments());
    return await _provider.start(params);
  }

  Future<void> stop() async {
    return await _provider.stop();
  }

  Stream<EngineMessage> get messageStream => _engineMessageStream.stream;
}
