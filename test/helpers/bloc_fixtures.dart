import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'ffi_fixtures.dart';

final engineStopped = EngineStoppedState();
final engineStarting = EngineStartingState();
final engineStarted = EngineStartedState();
final engineServerCreated = EngineServerCreatedState();

DeviceConnectedState deviceConnected({
  String name = 'Test Vibrator',
  String? displayName,
  int index = 0,
}) =>
    DeviceConnectedState(
      name,
      displayName,
      index,
      fakeDeviceIdentifier(address: 'test-device-$index'),
    );
