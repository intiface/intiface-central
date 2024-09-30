import 'dart:async';
import 'dart:convert';

import 'package:buttplug/buttplug.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';

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
    var msgJson = jsonEncode([message.toJson()]);
    var msgEvent = EngineControlEventBackdoorMessage(msgJson);
    _sendFunc(msgEvent);
  }

  @override
  Stream<ButtplugServerMessage> get messageStream {
    return _internalServerMessageStream.stream;
  }
}
