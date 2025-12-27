import 'dart:async';
import 'dart:convert';

import 'package:buttplug/connectors/connector.dart';
import 'package:buttplug/messages/messages.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';

typedef SendFunc = void Function(EngineControlEvent msg);

class ButtplugBackdoorClientConnector implements ButtplugClientConnector {
  final _internalServerMessageStream = StreamController<ButtplugServerMessage>.broadcast();
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
  void send(List<ButtplugClientMessageUnion> message) {
    var msgJson = jsonEncode(message.map((x) => x.toJson()).toList());
    var msgEvent = EngineControlEventBackdoorMessage(msgJson);
    _sendFunc(msgEvent);
  }

  @override
  Stream<ButtplugServerMessage> get messageStream {
    return _internalServerMessageStream.stream;
  }
}
