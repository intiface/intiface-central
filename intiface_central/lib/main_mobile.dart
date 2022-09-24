import 'package:flutter/cupertino.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/configuration/intiface_configuration_provider_shared_preferences.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:intiface_central/engine/library_engine_provider.dart';
import 'package:intiface_central/main_core.dart';
import 'package:permission_handler/permission_handler.dart';

// We don't want to link against the bridge plugin on desktop, so we have to provide our own main for each platform.
void main() async {
  // Bring up our settings repo.
  var prefs = await IntifaceConfigurationProviderSharedPreferences.create();
  var configRepo = IntifaceConfigurationRepository(prefs);
  var configCubit = IntifaceConfigurationCubit(configRepo);

  WidgetsFlutterBinding.ensureInitialized();

  await [
    Permission.location,
    Permission.bluetooth,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.locationWhenInUse,
  ].request();

  await mainCore(configCubit, EngineRepository(LibraryEngineProvider(), configRepo));
}
