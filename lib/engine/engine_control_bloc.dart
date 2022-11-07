import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:intiface_central/engine/engine_messages.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:loggy/loggy.dart';

abstract class EngineControlState {}

class EngineStartedState extends EngineControlState {}

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


class ServerLogMessageState extends EngineControlState {
  final EngineLog message;
  ServerLogMessageState(this.message);
}

class EngineError extends EngineControlState {}

class EngineControlEvent {}

class EngineControlEventStart extends EngineControlEvent {}

class EngineControlEventStop extends EngineControlEvent {}

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
      var stream = _repo.messageStream;
      emit(EngineStartedState());
      await _repo.start();
      emit(ClientDisconnectedState());
      return emit.forEach(stream, onData: (EngineMessage message) {
        if (message.engineStarted != null) {
          // Query for message version.
          logDebug("Got engine started, ending message version request");
          var msg = IntifaceMessage();
          msg.requestEngineVersion = RequestEngineVersion();
          _repo.send(jsonEncode(msg));
        }
        if (message.messageVersion != null) {
          logDebug("Got message version return");
        }
        if (message.clientConnected != null) {
          return ClientConnectedState(message.clientConnected!.clientName);
        }
        if (message.clientDisconnected != null) {
          return ClientDisconnectedState();
        }
        if (message.deviceConnected != null) {
          var deviceInfo = message.deviceConnected!;
          _devices[deviceInfo.index] = EngineDevice(deviceInfo.index, deviceInfo.name, deviceInfo.address);
          return DeviceConnectedState(
              deviceInfo.name, deviceInfo.displayName, deviceInfo.index, deviceInfo.address, "lovense");
        }
        if (message.deviceDisconnected != null) {
          _devices.remove(message.deviceDisconnected!.index);
          return DeviceDisconnectedState(message.deviceDisconnected!.index);
        }
        if (message.engineStopped != null) {
          return EngineStoppedState();
        }
        return state;
      });
    });
    on<EngineControlEventStop>((event, emit) async {
      await _repo.stop();
      return emit(EngineStoppedState());
    });
  }

  List<EngineDevice> get devices => _devices.values.toList();

  // TODO How to we detect/emit if the external process crashed on desktop?
}
