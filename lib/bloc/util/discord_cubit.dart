import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:discord_rich_presence/discord_rich_presence.dart';
import 'package:intiface_central/bloc/device/device_cubit.dart';
import 'package:loggy/loggy.dart';

class DiscordEvent {}

class DiscordConnectedEvent extends DiscordEvent {}

class DiscordEngineStartedEvent extends DiscordEvent {}

class DiscordEngineStoppedEvent extends DiscordEvent {}

class DiscordDeviceAddedEvent extends DiscordEvent {
  final DeviceCubit device;

  DiscordDeviceAddedEvent(this.device);
}

class DiscordDeviceRemovedEvent extends DiscordEvent {
  final DeviceCubit device;

  DiscordDeviceRemovedEvent(this.device);
}

class DiscordState {}

class DiscordNotReadyState extends DiscordState {}

class DiscordReadyState extends DiscordState {}

class DiscordBloc extends Bloc<DiscordEvent, DiscordState> {
  final String _clientId = const String.fromEnvironment(
    "DISCORD_CLIENT_ID",
    defaultValue: "",
  );
  final List<DeviceCubit> _devices = [];

  Client? _discordClient;
  DateTime? _startTime;

  DiscordBloc() : super(DiscordNotReadyState()) {
    if (_clientId != "") {
      logInfo("Discord Rich Presence available, registering events.");
    } else {
      logInfo("Discord Rich Presence not available in this build.");
    }
    on<DiscordEvent>(_handleEvent, transformer: sequential());
  }

  Future<void> _handleEvent(DiscordEvent event, Emitter<DiscordState> _) async {
    if (_clientId == "") {
      return;
    }

    if (event is DiscordEngineStartedEvent) {
      _startTime = DateTime.now();
      final client = Client(clientId: _clientId);
      _discordClient = client;

      final connected = await _runDiscordOperation("connect", () async {
        await client.connect();
      });
      if (!connected) {
        if (identical(_discordClient, client)) {
          _discordClient = null;
        }
        _startTime = null;
        return;
      }
      await updateDiscordStatus();
      return;
    }

    if (event is DiscordEngineStoppedEvent) {
      final client = _discordClient;
      _discordClient = null;
      _startTime = null;
      _devices.clear();
      if (client != null) {
        await _runDiscordOperation("disconnect", () async {
          await client.disconnect();
        });
      }
      return;
    }

    if (event is DiscordDeviceAddedEvent) {
      _devices.add(event.device);
      await updateDiscordStatus();
      return;
    }

    if (event is DiscordDeviceRemovedEvent) {
      _devices.remove(event.device);
      await updateDiscordStatus();
    }
  }

  Future<void> updateDiscordStatus() async {
    final client = _discordClient;
    final startTime = _startTime;
    if (client == null || startTime == null) {
      return;
    }

    final List<DeviceCubit> connectedDevices = _devices
        .where((device) => device.device?.connected ?? false)
        .toList();
    String details = "No toys connected.";

    if (connectedDevices.length == 1) {
      DeviceCubit device = connectedDevices.first;
      details = "${device.device?.name} connected.";
    }

    if (connectedDevices.length > 1) {
      details = "${connectedDevices.length} toys connected.";
    }

    await _runDiscordOperation("set activity", () async {
      await client.setActivity(
        Activity(
          type: ActivityType.playing,
          name: "Intiface Central",
          details: details,
          timestamps: ActivityTimestamps(start: startTime),
        ),
      );
    });
  }

  Future<bool> _runDiscordOperation(
    String action,
    Future<void> Function() callback,
  ) async {
    var reported = false;
    Future<void>? operation;
    void report(Object error, StackTrace stackTrace) {
      if (reported) {
        return;
      }
      reported = true;
      _handleDiscordError(action, error, stackTrace);
    }

    try {
      runZonedGuarded(() {
        operation = callback();
      }, report);
      await operation;
      return !reported;
    } catch (error, stackTrace) {
      report(error, stackTrace);
      return false;
    }
  }

  void _handleDiscordError(String action, Object error, StackTrace stackTrace) {
    logWarning("Discord Rich Presence $action failed: $error");
    logDebug(stackTrace.toString());
    final client = _discordClient;
    _discordClient = null;
    if (client != null) {
      unawaited(_discardDiscordClient(client));
    }
  }

  Future<void> _discardDiscordClient(Client client) async {
    try {
      await client.disconnect();
    } catch (_) {
      // Best effort cleanup after Discord IPC failure.
    }
  }
}
