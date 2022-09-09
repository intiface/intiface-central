import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intiface_central/configuration/intiface_configuration_provider_shared_preferences.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:intiface_central/engine/process_engine_provider.dart';
import 'package:intiface_central/intiface_central_app.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IntifacePaths.init();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Must add this line.
    await windowManager.ensureInitialized();

    const String windowTitle = kDebugMode ? "Intiface Central DEBUG" : "Intiface Central";

    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      center: true,
      title: windowTitle,
      //backgroundColor: Colors.transparent,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  // You can request multiple permissions at once.
  if (Platform.isAndroid || Platform.isIOS) {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();
  }

  // Bring up our settings repo.
  var prefs = await IntifaceConfigurationProviderSharedPreferences.create();
  var configRepo = IntifaceConfigurationRepository(prefs);

  // Bring up our process provider, which pretty much the whole app will be listening to.
  var engineRepo = EngineRepository(ProcessEngineProvider(), configRepo);

  runApp(IntifaceCentralApp(engineRepo: engineRepo, configRepo: configRepo));
}
