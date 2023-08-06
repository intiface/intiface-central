import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intiface_central/app_reset_cubit.dart';
import 'package:intiface_central/asset_cubit.dart';
import 'package:intiface_central/body_widget.dart';
import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/control_widget.dart';
import 'package:intiface_central/device/device_manager_bloc.dart';
import 'package:intiface_central/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';
import 'package:intiface_central/engine/engine_repository.dart';
import 'package:intiface_central/engine/foreground_task_library_engine_provider.dart';
import 'package:intiface_central/gui_settings_cubit.dart';
import 'package:intiface_central/navigation_cubit.dart';
import 'package:intiface_central/network_info_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:window_manager/window_manager.dart';
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
import 'package:device_info_plus/device_info_plus.dart';

class IntifaceCentralApp extends StatelessWidget with WindowListener {
  final GuiSettingsCubit guiSettingsCubit;

  IntifaceCentralApp._create({required this.guiSettingsCubit});

  static Future<IntifaceCentralApp> create() async {
    WidgetsFlutterBinding.ensureInitialized();
    var guiSettingsCubit = await GuiSettingsCubit.create();
    return IntifaceCentralApp._create(guiSettingsCubit: guiSettingsCubit);
  }

  void windowDisplayModeResize(bool useCompactDisplay, GuiSettingsCubit settingsCubit) {
    const compactSize = Size(500, 175);
    if (useCompactDisplay) {
      windowManager.setMinimumSize(compactSize);
      windowManager.setMaximumSize(compactSize);
      windowManager.setSize(compactSize);
    } else {
      windowManager.setMinimumSize(const Size(800, 600));
      windowManager.setMaximumSize(const Size(10000, 10000));
      var size = settingsCubit.getWindowSize();
      windowManager.setSize(size);
    }
  }

  @override
  void onWindowResize() async {
    guiSettingsCubit.setWindowSize(await windowManager.getSize());
  }

  @override
  void onWindowMove() async {
    guiSettingsCubit.setWindowPosition(await windowManager.getPosition());
  }

  Future<Widget> buildApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    await IntifacePaths.init();

    // Bring up our settings repo.
    var configCubit = await IntifaceConfigurationCubit.create();
    // Set up Update/Configuration Pipe/Cubit.
    var updateRepo = UpdateRepository(configCubit.currentNewsEtag, configCubit.currentDeviceConfigEtag);
    EngineRepository engineRepo;

    if (isDesktop()) {
      engineRepo = EngineRepository(LibraryEngineProvider());
      // Must add this line before we work with the manager.
      await windowManager.ensureInitialized();

      const String windowTitle = kDebugMode ? "Intiface® Central DEBUG" : "Intiface® Central";

      WindowOptions windowOptions = const WindowOptions(
        //center: true,
        title: windowTitle,
        //backgroundColor: Colors.transparent,
      );

      windowManager.addListener(this);
      windowManager.setPosition(guiSettingsCubit.getWindowPosition());
      windowDisplayModeResize(configCubit.useCompactDisplay, guiSettingsCubit);
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      configCubit.stream.listen((event) {
        if (event is! UseCompactDisplay) {
          return;
        }
        windowDisplayModeResize(event.value, guiSettingsCubit);
      });

      // Only add app update checks on desktop, mobile apps will use stores.
      updateRepo.addProvider(IntifaceCentralDesktopUpdater(configCubit.currentAppVersion));
    } else {
      engineRepo = configCubit.useForegroundProcess
          ? EngineRepository(ForegroundTaskLibraryEngineProvider())
          : EngineRepository(LibraryEngineProvider());

      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      // For older android builds, ask for location perms.
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

        if (androidInfo.version.sdkInt <= 30) {
          await [
            Permission.bluetooth,
            Permission.location,
            Permission.locationWhenInUse,
            Permission.locationAlways,
          ].request();
        }
      }
      await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();

      if (configCubit.useForegroundProcess) {
        FlutterForegroundTask.init(
          androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'notification_channel_id',
            channelName: 'Intiface Engine Notification',
            channelDescription: 'This notification appears when the Intiface Engine foreground service is running.',
            channelImportance: NotificationChannelImportance.LOW,
            priority: NotificationPriority.LOW,
            iconData: const NotificationIconData(
              resType: ResourceType.mipmap,
              resPrefix: ResourcePrefix.ic,
              name: 'launcher',
            ),
            buttons: [
              const NotificationButton(id: 'stopServerButton', text: 'Stop Server'),
            ],
          ),
          iosNotificationOptions: const IOSNotificationOptions(),
          foregroundTaskOptions: const ForegroundTaskOptions(
            interval: 1000,
            isOnceEvent: false,
            autoRunOnBoot: false,
            allowWakeLock: true,
            allowWifiLock: true,
          ),
        );
      }
    }

    var errorNotifier = ErrorNotifier();
    // Logging setup needs to happen after we've done initial setup.
    initLogging(errorNotifier);
    logInfo("Running main builder");

    var errorNotifierCubit = ErrorNotifierCubit();

    errorNotifier.stream.listen((record) {
      errorNotifierCubit.emitError(record);
    });

    logInfo("Intiface Central Starting...");

    if (kDebugMode) {
      logWarning("Intiface currently running in DEBUG MODE.");
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    configCubit.currentAppVersion = packageInfo.version;

    var deviceConfigVersion = await DeviceConfiguration.getFileVersion();
    configCubit.currentDeviceConfigVersion = deviceConfigVersion;

    var userConfigCubit = await UserDeviceConfigurationCubit.create();

    var networkCubit = await NetworkInfoCubit.create();

    var engineControlBloc = EngineControlBloc(engineRepo);

    var deviceControlBloc = DeviceManagerBloc(engineControlBloc.stream, engineControlBloc.add);

    if (kDebugMode) {
      // Make sure the engine is stopped, just in case we've reloaded.
      engineControlBloc.add(EngineControlEventStop());
    }

    engineControlBloc.stream.forEach((state) async {
      if (state is ServerLogMessageState) {
        // TODO Turn level into an enum
        var message = state.message.message!;
        var level = message.level;
        if (level == "DEBUG") {
          logDebug(message.fields["message"]);
        } else if (level == "INFO") {
          logInfo(message.fields["message"]);
        } else if (level == "ERROR") {
          logError(message.fields["message"]);
        } else if (level == "WARN") {
          logWarning(message.fields["message"]);
        } else if (level == "TRACE") {
          // TODO Implement trace logging level for loggy
          //log(message.engineLog!.message!.fields["message"]);
        }
      }
      if (state is ProviderLogMessageState) {
        // TODO Turn level into an enum
        var message = state.message.message;
        var level = state.message.level;
        if (level == "DEBUG") {
          logDebug(message);
        } else if (level == "INFO") {
          logInfo(message);
        } else if (level == "ERROR") {
          logError(message);
        } else if (level == "WARN") {
          logWarning(message);
        } else if (level == "TRACE") {
          // TODO Implement trace logging level for loggy
          //log(message.engineLog!.message!.fields["message"]);
        }
      }
      if (state is EngineServerCreatedState) {
        deviceControlBloc.add(DeviceManagerEngineStartedEvent());
      }
      if (state is EngineStoppedState) {
        deviceControlBloc.add(DeviceManagerEngineStoppedEvent());
      }
      if (state is DeviceConnectedState) {
        logInfo("Updating device ${state.name} index to ${state.index}");
        await userConfigCubit.updateName(state.identifier, state.name);
        await userConfigCubit.updateDeviceIndex(state.identifier, state.index);
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

    if (configCubit.startServerOnStartup) {
      engineControlBloc.add(EngineControlEventStart(options: await configCubit.getEngineOptions()));
    }

    return MultiBlocProvider(providers: [
      BlocProvider(create: (context) => engineControlBloc),
      BlocProvider(create: (context) => deviceControlBloc),
      BlocProvider(create: (context) => NavigationCubit()),
      BlocProvider(create: (context) => updateBloc),
      BlocProvider(create: (context) => assetCubit),
      BlocProvider(create: (context) => configCubit),
      BlocProvider(create: (context) => networkCubit),
      BlocProvider(create: (context) => errorNotifierCubit),
      BlocProvider(create: (context) => userConfigCubit),
      BlocProvider(create: (context) => guiSettingsCubit),
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
                return const MaterialApp(
                    title: 'Intiface Central',
                    debugShowCheckedModeBanner: false,
                    home: Scaffold(
                      body: Center(
                        child: Image(image: AssetImage('assets/icons/intiface_central_icon.png')),
                      ),
                    ));
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
              /*
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
              }
              */
              if (!isDesktop() || !useCompactDisplay) {
                widgets.addAll(const [Divider(height: 2), Expanded(child: BodyWidget())]);
              }
              return Scaffold(body: Column(mainAxisSize: MainAxisSize.max, children: widgets));
            }));
  }
}
