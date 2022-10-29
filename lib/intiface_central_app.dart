import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/app_reset_cubit.dart';
import 'package:intiface_central/asset_cubit.dart';
import 'package:intiface_central/body_widget.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/control_widget.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:intiface_central/navigation_cubit.dart';
import 'package:intiface_central/network_info_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intiface_central/configuration/intiface_configuration_provider_shared_preferences.dart';
import 'package:intiface_central/configuration/intiface_configuration_repository.dart';
import 'package:intiface_central/device_configuration/device_configuration.dart';
import 'package:intiface_central/engine/library_engine_provider.dart';
import 'package:intiface_central/error_notifier_cubit.dart';
import 'package:intiface_central/logging/logging.dart';
import 'package:intiface_central/update/github_update_provider.dart';
import 'package:intiface_central/update/update_bloc.dart';
import 'package:intiface_central/update/update_repository.dart';
import 'package:loggy/loggy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class IntifaceCentralApp extends StatelessWidget {
  const IntifaceCentralApp({super.key});

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

  Future<Widget> buildApp() async {
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

    var errorNotifier = ErrorNotifier();
    // Logging setup needs to happen after we've done initial setup.
    initLogging(errorNotifier);
    logInfo!("Running main builder");

    var errorNotifierCubit = ErrorNotifierCubit();

    errorNotifier.stream.listen((record) {
      errorNotifierCubit.emitError(record);
    });

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
      if (isDesktop()) {
        if (state is IntifaceCentralUpdateAvailable) {
          configCubit.latestAppVersion = state.version;
        }
      }
    });

    if (configCubit.checkForUpdateOnStart) {
      updateBloc.add(RunUpdate());
    }

    return MultiBlocProvider(providers: [
      BlocProvider(create: (context) => EngineControlBloc(engineRepo)),
      BlocProvider(create: (context) => NavigationCubit()),
      BlocProvider(create: (context) => updateBloc),
      BlocProvider(create: (context) => assetCubit),
      BlocProvider(create: (context) => configCubit),
      BlocProvider(create: (context) => networkCubit),
      BlocProvider(create: (context) => errorNotifierCubit),
    ], child: const IntifaceCentralView());
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => AppResetCubit(),
        child: BlocBuilder<AppResetCubit, AppResetState>(builder: (context, state) {
          return FutureBuilder(
              future: buildApp(),
              builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data!;
                }
                return MaterialApp(
                    title: 'Intiface Central',
                    debugShowCheckedModeBanner: false,
                    home: Row(children: const [Expanded(child: Text("Waiting"))]));
              });
        }));
  }
}

class IntifaceCentralView extends StatelessWidget {
  const IntifaceCentralView({super.key});

  @override
  Widget build(BuildContext context) {
    logInfo(
        "Using theme ${BlocProvider.of<IntifaceConfigurationCubit>(context).useLightTheme ? ThemeMode.light : ThemeMode.dark}");
    return BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
        buildWhen: (previous, current) => current is UseLightThemeState || current is ConfigurationReset,
        builder: (context, state) => MaterialApp(
            title: 'Intiface Central',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.blue, useMaterial3: true),
            darkTheme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blue, useMaterial3: true),
            themeMode:
                BlocProvider.of<IntifaceConfigurationCubit>(context).useLightTheme ? ThemeMode.light : ThemeMode.dark,
            home: const IntifaceCentralPage()));
  }
}

class IntifaceCentralPage extends StatelessWidget {
  const IntifaceCentralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: BlocBuilder<IntifaceConfigurationCubit, IntifaceConfigurationState>(
            buildWhen: (previous, current) => current is UseCompactDisplay || current is ConfigurationReset,
            builder: (context, state) {
              var useCompactDisplay = BlocProvider.of<IntifaceConfigurationCubit>(context).useCompactDisplay;
              List<Widget> widgets = [const ControlWidget()];
              if (isDesktop()) {
                widgets.addAll([
                  const Divider(height: 2),
                  Row(
                    children: [
                      Expanded(
                          child: IconButton(
                              onPressed: () {
                                BlocProvider.of<IntifaceConfigurationCubit>(context).useCompactDisplay =
                                    !useCompactDisplay;
                              },
                              icon: useCompactDisplay
                                  ? const Icon(Icons.arrow_drop_down)
                                  : const Icon(Icons.arrow_drop_up)))
                    ],
                  )
                ]);
                if (!useCompactDisplay) {
                  widgets.addAll(const [Divider(height: 2), BodyWidget()]);
                }
              } else {
                // Always render body on mobile.
                widgets.addAll(const [Divider(height: 2), BodyWidget()]);
              }
              return Scaffold(body: Column(mainAxisSize: MainAxisSize.max, children: widgets));
            }));
  }
}
