import 'package:flutter/cupertino.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/configuration/intiface_configuration_provider_shared_preferences.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:intiface_central/engine/library_engine_provider.dart';
import 'package:intiface_central/main_core.dart';
import 'package:intiface_central/update/update_repository.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:permission_handler/permission_handler.dart';

// We don't want to link against the bridge plugin on desktop, so we have to provide our own main for each platform.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IntifacePaths.init();

  // Bring up our settings repo.
  var prefs = await IntifaceConfigurationProviderSharedPreferences.create();
  var configRepo = IntifaceConfigurationRepository(prefs);
  var configCubit = IntifaceConfigurationCubit(configRepo);

  await [
    Permission.location,
    Permission.bluetooth,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.locationWhenInUse,
  ].request();

  var updateRepo = UpdateRepository(configCubit.currentNewsVersion, configCubit.currentDeviceConfigVersion);

  await mainCore(configCubit, updateRepo, EngineRepository(LibraryEngineProvider(), configRepo));
}
