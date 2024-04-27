import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart';
import 'package:intiface_central/bridge_generated.dart';
import 'package:intiface_central/bloc/engine/engine_messages.dart';
import 'package:intiface_central/bloc/engine/engine_repository.dart';
import 'package:loggy/loggy.dart';

abstract class EngineControlState {}

class EngineStartingState extends EngineControlState {}

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
  final int index;
  final ExposedUserDeviceIdentifier identifier;

  DeviceConnectedState(this.name, this.displayName, this.index, this.identifier);
}

class DeviceDisconnectedState extends EngineControlState {
  final int index;
  DeviceDisconnectedState(this.index);
}

class ButtplugServerMessageState extends EngineControlState {
  final ButtplugServerMessage message;
  ButtplugServerMessageState(this.message);
}

class ProviderLogMessageState extends EngineControlState {
  final EngineProviderLog message;
  ProviderLogMessageState(this.message);
}

class EngineError extends EngineControlState {}

class EngineControlEvent {}

class EngineControlEventStart extends EngineControlEvent {
  final EngineOptionsExternal options;

  EngineControlEventStart({required this.options});
}

class EngineControlEventStop extends EngineControlEvent {}

class EngineControlEventBackdoorMessage extends EngineControlEvent {
  final String message;
  EngineControlEventBackdoorMessage(this.message);
}

class EngineDevice {
  final int index;
  final String name;
  final ExposedUserDeviceIdentifier identifier;

  const EngineDevice(this.index, this.name, this.identifier);
}

class EngineControlBloc extends Bloc<EngineControlEvent, EngineControlState> {
  final EngineRepository _repo;
  final Map<int, EngineDevice> _devices = {};
  bool _isRunning = false;

  // HACK We have the engine control bloc representing too many things right now, as it handles both the engine control
  // and messages about the engine sessions. This should be divided out into a EngineControlBloc that handles engine
  // started/stopped/etc, and an EngineSessionBloc that handles events while the engine is running. However, that's a
  // good bit of refactoring and I just want to get foregrounding out, so for now we're doing this the gross way.
  bool get isRunning {
    return _isRunning;
  }

  EngineControlBloc(this._repo) : super(EngineStoppedState()) {
    on<EngineControlEventStart>((event, emit) async {
      if (await _repo.runtimeStarted()) {
        logWarning("Runtime already started, ignoring restart request.");
        return;
      }
      logInfo("Trying to start engine...");
      await _repo.start(options: event.options);
      _isRunning = true;
      emit(EngineStartingState());
      return emit.forEach(_repo.messageStream, onData: (EngineOutput message) {
        if (message.engineMessage != null) {
          var engineMessage = message.engineMessage!;
          if (engineMessage.engineStarted != null) {
            // Query for message version.
            logDebug("Got engine started, sending message version request");
            emit(EngineStartedState());
            emit(ClientDisconnectedState());
            var msg = IntifaceMessage();
            msg.requestEngineVersion = RequestEngineVersion();
            _repo.send(jsonEncode(msg));
            return state;
          }
          if (engineMessage.engineServerCreated != null) {
            return EngineServerCreatedState();
          }
          if (engineMessage.engineProviderLog != null) {
            return ProviderLogMessageState(engineMessage.engineProviderLog!);
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
            _devices[deviceInfo.index] =
                EngineDevice(deviceInfo.index, deviceInfo.name, deviceInfo.identifier.toExposedUserDeviceIdentifier());
            return DeviceConnectedState(deviceInfo.name, deviceInfo.displayName, deviceInfo.index,
                deviceInfo.identifier.toExposedUserDeviceIdentifier());
          }
          if (engineMessage.deviceDisconnected != null) {
            _devices.remove(engineMessage.deviceDisconnected!.index);
            return DeviceDisconnectedState(engineMessage.deviceDisconnected!.index);
          }
          if (engineMessage.engineStopped != null) {
            logInfo("Received EngineStopped message");
            _isRunning = false;
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
      //return emit(EngineStoppedState());
    });
  }

  List<EngineDevice> get devices => _devices.values.toList();
}
