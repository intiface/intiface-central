import 'package:bloc/bloc.dart';
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
  final String _clientId = const String.fromEnvironment("DISCORD_CLIENT_ID", defaultValue: "");
  final List<DeviceCubit> _devices = [];

  Client? _discordClient;
  DateTime? _startTime;

  DiscordBloc() : super(DiscordNotReadyState()) {
    if (_clientId != "") {
      logInfo("Discord Rich Presence available, registering events.");
      on<DiscordEngineStartedEvent>((event, emit) async {
        _startTime = DateTime.now();
        _discordClient = Client(clientId: _clientId);

        await _discordClient?.connect();
        await updateDiscordStatus();
      });

      on<DiscordEngineStoppedEvent>((event, emit) async {
        await _discordClient?.disconnect();

        _discordClient = null;
        _startTime = null;
        _devices.clear();
      });

      on<DiscordDeviceAddedEvent>((event, emit) async {
        _devices.add(event.device);
        await updateDiscordStatus();
      });

      on<DiscordDeviceRemovedEvent>((event, emit) async {
        _devices.remove(event.device);
        await updateDiscordStatus();
      });
    } else {
      logInfo("Discord Rich Presence not available in this build.");
    }
  }

  Future<void> updateDiscordStatus() async {
    final List<DeviceCubit> connectedDevices = _devices.where((device) => device.device?.connected ?? false).toList();
    String details = "No toys connected.";

    if (connectedDevices.length == 1) {
      DeviceCubit device = connectedDevices.first;
      details = "${device.device?.name} connected.";
    }

    if (connectedDevices.length > 1) {
      details = "${connectedDevices.length} toys connected.";
    }

    await _discordClient?.setActivity(
      Activity(
        type: ActivityType.playing,
        name: "Intiface Central",
        details: details,
        timestamps: ActivityTimestamps(start: _startTime!),
      ),
    );
  }
}
