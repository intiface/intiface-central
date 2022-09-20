import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:intiface_central/configuration/intiface_configuration_provider_shared_preferences.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:intiface_central/engine/process_engine_provider.dart';
import 'package:intiface_central/main_core.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';

// We don't want to link against the bridge plugin on desktop, so we have to provide our own main for each platform.
void main() async {
  // Bring up our settings repo.
  var prefs = await IntifaceConfigurationProviderSharedPreferences.create();
  var configRepo = IntifaceConfigurationRepository(prefs);

  WidgetsFlutterBinding.ensureInitialized();

  // Must add this line.
  await windowManager.ensureInitialized();

  const String windowTitle = kDebugMode ? "Intiface Central DEBUG" : "Intiface Central";

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    //center: true,
    title: windowTitle,
    //backgroundColor: Colors.transparent,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  await mainCore(configRepo, EngineRepository(ProcessEngineProvider(), configRepo));
}
