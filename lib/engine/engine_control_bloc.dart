import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart';
import 'package:intiface_central/engine/engine_messages.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:loggy/loggy.dart';

abstract class EngineControlState {}

class EngineStartedState extends EngineControlState {}

class EngineServerCreatedState extends EngineControlState {}

class EngineStoppedState extends EngineControlState {}

class ClientConnectedState extends EngineControlState {
  final String clientName;
  ClientConnectedState(this.clientName);
}

class ClientDisconnectedState extends EngineControlState {}

class DeviceConnectedState extends EngineControlState {
  final String name;
  final String? displayName;
  final String address;
  final String protocol;
  final int index;

  DeviceConnectedState(this.name, this.displayName, this.index, this.address, this.protocol);
}

class DeviceDisconnectedState extends EngineControlState {
  final int index;
  DeviceDisconnectedState(this.index);
}

class ButtplugServerMessageState extends EngineControlState {
  final ButtplugServerMessage message;
  ButtplugServerMessageState(this.message);
}

class ServerLogMessageState extends EngineControlState {
  final EngineLog message;
  ServerLogMessageState(this.message);
}

class EngineError extends EngineControlState {}

class EngineControlEvent {}

class EngineControlEventStart extends EngineControlEvent {}

class EngineControlEventStop extends EngineControlEvent {}

class EngineControlEventBackdoorMessage extends EngineControlEvent {
  final String message;
  EngineControlEventBackdoorMessage(this.message);
}

class EngineDevice {
  final int index;
  final String name;
  final String address;

  const EngineDevice(this.index, this.name, this.address);
}

class EngineControlBloc extends Bloc<EngineControlEvent, EngineControlState> {
  final EngineRepository _repo;
  final Map<int, EngineDevice> _devices = {};

  EngineControlBloc(this._repo) : super(EngineStoppedState()) {
    on<EngineControlEventStart>((event, emit) async {
      logInfo("Trying to start engine...");
      await _repo.start();
      emit(EngineStartedState());
      emit(ClientDisconnectedState());
      return emit.forEach(_repo.messageStream, onData: (EngineOutput message) {
        if (message.engineMessage != null) {
          var engineMessage = message.engineMessage!;
          if (engineMessage.engineStarted != null) {
            // Query for message version.
            logDebug("Got engine started, ending message version request");
            var msg = IntifaceMessage();
            msg.requestEngineVersion = RequestEngineVersion();
            _repo.send(jsonEncode(msg));
            return state;
          }
          if (engineMessage.engineServerCreated != null) {
            return EngineServerCreatedState();
          }
          if (engineMessage.engineLog != null) {
            return ServerLogMessageState(engineMessage.engineLog!);
          }
          if (engineMessage.messageVersion != null) {
            logDebug("Got message version return");
            return state;
          }
          if (engineMessage.clientConnected != null) {
            return ClientConnectedState(engineMessage.clientConnected!.clientName);
          }
          if (engineMessage.clientDisconnected != null) {
            return ClientDisconnectedState();
          }
          if (engineMessage.deviceConnected != null) {
            var deviceInfo = engineMessage.deviceConnected!;
            _devices[deviceInfo.index] = EngineDevice(deviceInfo.index, deviceInfo.name, deviceInfo.address);
            return DeviceConnectedState(
                deviceInfo.name, deviceInfo.displayName, deviceInfo.index, deviceInfo.address, "lovense");
          }
          if (engineMessage.deviceDisconnected != null) {
            _devices.remove(engineMessage.deviceDisconnected!.index);
            return DeviceDisconnectedState(engineMessage.deviceDisconnected!.index);
          }
          if (engineMessage.engineStopped != null) {
            logInfo("Received EngineStopped message");
            return EngineStoppedState();
          }
        } else if (message.buttplugServerMessage != null) {
          return ButtplugServerMessageState(message.buttplugServerMessage!);
        }
        return state;
      });
    });
    on<EngineControlEventBackdoorMessage>((event, emit) async {
      _repo.sendBackdoorMessage(event.message);
    });
    on<EngineControlEventStop>((event, emit) async {
      await _repo.stop();
      return emit(EngineStoppedState());
    });
  }

  List<EngineDevice> get devices => _devices.values.toList();
}
