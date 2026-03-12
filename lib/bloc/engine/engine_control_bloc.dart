import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:buttplug/buttplug.dart';
import 'package:buttplug/messages/messages.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intiface_central/bloc/engine/engine_messages.dart';
import 'package:intiface_central/bloc/engine/engine_repository.dart';
import 'package:intiface_central/src/rust/api/device_config.dart';
import 'package:intiface_central/src/rust/api/runtime.dart';
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
  final bool needsKeepalive;

  DeviceConnectedState(
    this.name,
    this.displayName,
    this.index,
    this.identifier, {
    this.needsKeepalive = false,
  });
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
  final bool needsKeepalive;

  const EngineDevice(this.index, this.name, this.identifier, {this.needsKeepalive = false});
}

class EngineControlBloc extends Bloc<EngineControlEvent, EngineControlState> {
  final EngineRepository _repo;
  final Map<int, EngineDevice> _devices = {};
  bool _isRunning = false;
  int _keepaliveDeviceCount = 0;

  bool get anyDeviceNeedsKeepalive => _keepaliveDeviceCount > 0;

  void _updateWakelockIfNeeded(bool previouslyNeeded) {
    if (!Platform.isAndroid) return;
    if (anyDeviceNeedsKeepalive == previouslyNeeded) return;
    FlutterForegroundTask.updateService(
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: anyDeviceNeedsKeepalive,
        allowWifiLock: true,
      ),
    );
  }

  // HACK We have the engine control bloc representing too many things right now, as it handles both the engine control
  // and messages about the engine sessions. This should be divided out into a EngineControlBloc that handles engine
  // started/stopped/etc, and an EngineSessionBloc that handles events while the engine is running. However, that's a
  // good bit of refactoring and I just want to get foregrounding out, so for now we're doing this the gross way.
  bool get isRunning {
    return _isRunning;
  }

  EngineControlBloc(this._repo) : super(EngineStoppedState()) {
    on<EngineControlEventStart>((event, emit) async {
      // Guard against concurrent start requests. _isRunning is set synchronously
      // before any await, making the check+set atomic within Dart's single-threaded
      // event loop. Any second Start event that starts executing will see _isRunning=true
      // before it reaches its first await.
      if (_isRunning) {
        logWarning("EngineControlEventStart: already starting/running (_isRunning=true), dropping duplicate start request. currentState=${state.runtimeType}");
        return;
      }
      _isRunning = true;

      var alreadyRunning = await _repo.runtimeStarted();
      logInfo("EngineControlEventStart: runtimeStarted=$alreadyRunning, currentState=${state.runtimeType}");
      if (alreadyRunning) {
        logWarning("Runtime already started (Rust-side), ignoring restart request.");
        _isRunning = false;
        return;
      }
      logInfo("Trying to start engine...");
      try {
        await _repo.start(options: event.options);
      } catch (e) {
        logError("Failed to start engine repo: $e");
        _isRunning = false;
        emit(EngineStoppedState());
        return;
      }
      emit(EngineStartingState());
      return emit.forEach(
        _repo.messageStream,
        onData: (EngineOutput message) {
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
              return ClientConnectedState(
                engineMessage.clientConnected!.clientName,
              );
            }
            if (engineMessage.clientDisconnected != null) {
              return ClientDisconnectedState();
            }
            if (engineMessage.deviceConnected != null) {
              var deviceInfo = engineMessage.deviceConnected!;
              _devices[deviceInfo.index] = EngineDevice(
                deviceInfo.index,
                deviceInfo.name,
                deviceInfo.identifier.toExposedUserDeviceIdentifier(),
                needsKeepalive: deviceInfo.needsKeepalive,
              );
              if (deviceInfo.needsKeepalive) {
                var wasPreviouslyNeeded = anyDeviceNeedsKeepalive;
                _keepaliveDeviceCount++;
                _updateWakelockIfNeeded(wasPreviouslyNeeded);
              }
              return DeviceConnectedState(
                deviceInfo.name,
                deviceInfo.displayName,
                deviceInfo.index,
                deviceInfo.identifier.toExposedUserDeviceIdentifier(),
                needsKeepalive: deviceInfo.needsKeepalive,
              );
            }
            if (engineMessage.deviceDisconnected != null) {
              var removedDevice = _devices.remove(engineMessage.deviceDisconnected!.index);
              if (removedDevice != null && removedDevice.needsKeepalive) {
                var wasPreviouslyNeeded = anyDeviceNeedsKeepalive;
                _keepaliveDeviceCount--;
                _updateWakelockIfNeeded(wasPreviouslyNeeded);
              }
              return DeviceDisconnectedState(
                engineMessage.deviceDisconnected!.index,
              );
            }
            if (engineMessage.engineStopped != null) {
              logInfo("Received EngineStopped message");
              return EngineStoppedState();
            }
          } else if (message.buttplugServerMessage != null) {
            return ButtplugServerMessageState(message.buttplugServerMessage!);
          }
          return state;
        },
      );
    });
    on<EngineControlEventBackdoorMessage>((event, emit) async {
      _repo.sendBackdoorMessage(event.message);
    });
    on<EngineControlEventStop>((event, emit) async {
      logInfo("EngineControlEventStop: _isRunning=$_isRunning, currentState=${state.runtimeType}");
      await _repo.stop();
      // Clear _isRunning here, after stop() has fully completed. We cannot rely
      // on emit.forEach receiving the engineStopped message to clear it: stop()
      // can return before the async stream delivery chain delivers engineStopped
      // to emit.forEach, leaving _isRunning stuck true and silently dropping all
      // future start events even though the UI shows stopped.
      _isRunning = false;
      _keepaliveDeviceCount = 0;
      logInfo("EngineControlEventStop: repo stop complete, emitting EngineStoppedState. _isRunning=$_isRunning");
      emit(EngineStoppedState());
    });
  }

  List<EngineDevice> get devices => _devices.values.toList();
}
