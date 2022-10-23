import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_loggy/flutter_loggy.dart';
import 'package:intiface_central/asset_cubit.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/configuration/intiface_configuration_provider_shared_preferences.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/device_configuration/device_configuration.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:intiface_central/engine/library_engine_provider.dart';
import 'package:intiface_central/intiface_central_app.dart';
import 'package:intiface_central/navigation_cubit.dart';
import 'package:intiface_central/network_info_cubit.dart';
import 'package:intiface_central/update/github_update_provider.dart';
import 'package:intiface_central/update/update_bloc.dart';
import 'package:intiface_central/update/update_repository.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:loggy/loggy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

void windowDisplayModeResize(bool useCompactDisplay) {
  const compactSize = Size(500, 175);
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

// From https://github.com/infinum/floggy/issues/50
class MultiPrinter extends LoggyPrinter {
  const MultiPrinter();

  final LoggyPrinter devPrinter = const PrettyDeveloperPrinter();
  final LoggyPrinter consolePrinter = const PrettyPrinter();
  //final LoggyPrinter filePrinter;

  @override
  void onLog(LogRecord record) {
    //filePrinter.onLog(record);
    devPrinter.onLog(record);

    if (!kReleaseMode) {
      consolePrinter.onLog(record);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IntifacePaths.init();

  // Bring up our settings repo.
  var prefs = await IntifaceConfigurationProviderSharedPreferences.create();
  var configRepo = await IntifaceConfigurationRepository.create(prefs);
  var configCubit = IntifaceConfigurationCubit(configRepo);
  // Set up Update/Configuration Pipe/Cubit.
  var updateRepo = UpdateRepository(configCubit.currentNewsEtag, configCubit.currentDeviceConfigEtag);
  var engineRepo = EngineRepository(LibraryEngineProvider(), configRepo);

  if (isDesktop()) {
    // Must add this line before we work with the manager.
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

    // Only add app update checks on desktop, mobile apps will use stores.
    updateRepo.addProvider(IntifaceCentralDesktopUpdater(configCubit.currentAppVersion));
  }

  if (isMobile()) {
    await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();
  }

  Loggy.initLoggy(
    logPrinter: StreamPrinter(
      const MultiPrinter(),
    ),
    logOptions: const LogOptions(
      LogLevel.all,
      stackTraceLevel: LogLevel.error,
    ),
  );
  logInfo("Intiface Central Starting...");

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  configCubit.currentAppVersion = packageInfo.version;

  var deviceConfigVersion = await DeviceConfiguration.getFileVersion();
  configCubit.currentDeviceConfigVersion = deviceConfigVersion;

  var networkCubit = await NetworkInfoCubit.create();

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

  var assetCubit = await AssetCubit.create();

  var updateBloc = UpdateBloc(updateRepo);

  updateBloc.stream.forEach((state) async {
    if (state is NewsUpdateRetrieved) {
      configCubit.currentNewsEtag = state.version;
      await assetCubit.update();
    }
    if (state is DeviceConfigUpdateRetrieved) {
      configCubit.currentDeviceConfigEtag = state.version;
      // Load the file and pull internal version while we're at it.
      var deviceConfigVersion = await DeviceConfiguration.getFileVersion();
      configCubit.currentDeviceConfigVersion = deviceConfigVersion;
    }
    // While this should probably live in the main Desktop code, we can put this here because it won't bring in any new
    // dependencies. It'll just update settings for things that only the desktop bloc can access, like intiface engine
    // updates.
    if (isDesktop()) {
      if (state is IntifaceEngineUpdateRetrieved) {
        configCubit.currentEngineVersion = state.version;
      }
      if (state is IntifaceCentralUpdateAvailable) {
        configCubit.latestAppVersion = state.version;
      }
    }
  });

  if (configCubit.checkForUpdateOnStart) {
    updateBloc.add(RunUpdate());
  }

  runApp(MultiBlocProvider(providers: [
    BlocProvider(create: (context) => EngineControlBloc(engineRepo)),
    BlocProvider(create: (context) => NavigationCubit()),
    BlocProvider(create: (context) => updateBloc),
    BlocProvider(create: (context) => assetCubit),
    BlocProvider(create: (context) => configCubit),
    BlocProvider(create: (context) => networkCubit),
  ], child: const IntifaceCentralView()));
}
