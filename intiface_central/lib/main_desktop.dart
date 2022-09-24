import 'package:bloc/bloc.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/configuration/intiface_configuration_provider_shared_preferences.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:intiface_central/engine/process_engine_provider.dart';
import 'package:intiface_central/main_core.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';

void windowDisplayModeResize(bool useCompactDisplay) {
  const compactSize = Size(500, 165);
  if (useCompactDisplay) {
    windowManager.setMinimumSize(compactSize);
    windowManager.setMaximumSize(compactSize);
    windowManager.setSize(compactSize);
  } else {
    windowManager.setMinimumSize(const Size(800, 600));
    windowManager.setMaximumSize(const Size(10000, 10000));
    windowManager.setSize(const Size(800, 600));
  }
}

// We don't want to link against the bridge plugin on desktop, so we have to provide our own main for each platform.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bring up our settings repo.
  var prefs = await IntifaceConfigurationProviderSharedPreferences.create();
  var configRepo = IntifaceConfigurationRepository(prefs);
  var configCubit = IntifaceConfigurationCubit(configRepo);

  // Must add this line.
  await windowManager.ensureInitialized();

  const String windowTitle = kDebugMode ? "Intiface Central DEBUG" : "Intiface Central";

  WindowOptions windowOptions = const WindowOptions(
    //center: true,
    title: windowTitle,
    //backgroundColor: Colors.transparent,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  configCubit.stream.listen((event) {
    if (event is! UseCompactDisplay) {
      return;
    }
    windowDisplayModeResize(event.value);
  });

  windowDisplayModeResize(configRepo.useCompactDisplay);

  await mainCore(configCubit, EngineRepository(ProcessEngineProvider(), configRepo));
}
