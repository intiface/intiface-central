import 'dart:async';
import 'dart:convert';

import 'package:buttplug/buttplug.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:loggy/loggy.dart';

typedef SendFunc = void Function(EngineControlEvent msg);

class ButtplugBackdoorClientConnector implements ButtplugClientConnector {
  final _internalServerMessageStream = StreamController<ButtplugServerMessage>();
  late final SendFunc _sendFunc;
  late StreamSubscription _outputSubscription;

  // We should only be created
  ButtplugBackdoorClientConnector(Stream<EngineControlState> outputStream, SendFunc sendFunc) {
    _outputSubscription = outputStream.listen((event) {
      if (event is ButtplugServerMessageState) {
        _internalServerMessageStream.add(event.message);
      }
    });
    _sendFunc = sendFunc;
  }

  @override
  Future<void> connect() async {
    // This will just automatically succeed.
  }

  @override
  Future<void> disconnect() async {
    _internalServerMessageStream.close();
    _outputSubscription.cancel();
  }

  @override
  void send(ButtplugClientMessageUnion message) {
    // We'll need to catch handshake messages, because any message we let through will go directly to the DeviceManager,
    // bypassing the Server. So we'll handle server replies ourselves to make the client happy.

    if (message.requestServerInfo != null) {
      logInfo("Got backdoor RSI message, sending internal reply");
      var serverInfo = ServerInfo();
      serverInfo.id = message.id;
      serverInfo.maxPingTime = 0;
      serverInfo.messageVersion = 3;
      serverInfo.serverName = "Backdoor Server";
      var serverMessage = ButtplugServerMessage();
      serverMessage.serverInfo = serverInfo;
      _internalServerMessageStream.add(serverMessage);
      return;
    }

    var msgJson = jsonEncode([message.toJson()]);
    var msgEvent = EngineControlEventBackdoorMessage(msgJson);
    _sendFunc(msgEvent);
  }

  @override
  Stream<ButtplugServerMessage> get messageStream {
    return _internalServerMessageStream.stream;
  }
}
