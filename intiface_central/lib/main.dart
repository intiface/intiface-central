import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:intiface_central/configuration/intiface_configuration_provider_shared_preferences.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/engine/engine_messages.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:intiface_central/engine/library_engine_provider.dart';
import 'package:intiface_central/engine/process_engine_provider.dart';
import 'package:intiface_central/intiface_central_app.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';
import 'package:loggy/loggy.dart';

void main() async {
  Loggy.initLoggy(
    logPrinter: StreamPrinter(
      const PrettyDeveloperPrinter(),
    ),
    logOptions: const LogOptions(
      LogLevel.all,
      stackTraceLevel: LogLevel.error,
    ),
  );
  logInfo("Intiface Central Starting...");
  WidgetsFlutterBinding.ensureInitialized();
  await IntifacePaths.init();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
  }
  // You can request multiple permissions at once.
  if (Platform.isAndroid || Platform.isIOS) {
    await [
      Permission.location,
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
  var engineRepo;
  if (isDesktop()) {
    engineRepo = EngineRepository(ProcessEngineProvider(), configRepo);
  } else {
    engineRepo = EngineRepository(LibraryEngineProvider(), configRepo);
  }

  engineRepo.messageStream.forEach((message) {
    if (message.engineLog != null) {
      // TODO Turn level into an enum
      var level = message.engineLog!.message!.level;
      if (level == "DEBUG") {
        logDebug(message.engineLog!.message!.fields["message"]);
      } else if (level == "INFO") {
        logInfo(message.engineLog!.message!.fields["message"]);
      } else if (level == "ERROR") {
        logError(message.engineLog!.message!.fields["message"]);
      } else if (level == "WARN") {
        logWarning(message.engineLog!.message!.fields["message"]);
      } else if (level == "TRACE") {
        // TODO Implement trace logging level for loggy
        //log(message.engineLog!.message!.fields["message"]);
      }
    }
  });

  runApp(IntifaceCentralApp(engineRepo: engineRepo, configRepo: configRepo));
}
