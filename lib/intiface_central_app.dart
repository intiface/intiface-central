import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intiface_central/bloc/api_log/native_api_log.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/device_configuration.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/bloc/engine/engine_repository.dart';
import 'package:intiface_central/bloc/engine/foreground_task_library_engine_provider.dart';
import 'package:intiface_central/bloc/engine/library_engine_provider.dart';
import 'package:intiface_central/bloc/update/github_update_provider.dart';
import 'package:intiface_central/bloc/update/update_bloc.dart';
import 'package:intiface_central/bloc/update/update_repository.dart';
import 'package:intiface_central/bloc/util/app_reset_cubit.dart';
import 'package:intiface_central/bloc/util/asset_cubit.dart';
import 'package:intiface_central/bloc/util/error_notifier_cubit.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';
import 'package:intiface_central/bloc/util/navigation_cubit.dart';
import 'package:intiface_central/bloc/util/network_info_cubit.dart';
import 'package:intiface_central/ffi.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:intiface_central/util/logging.dart';
import 'package:intiface_central/widget/body_widget.dart';
import 'package:intiface_central/widget/control_widget.dart';
import 'package:loggy/loggy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:sentry/sentry_io.dart';
import 'package:window_manager/window_manager.dart';

class IntifaceCentralApp extends StatelessWidget with WindowListener {
  IntifaceCentralApp._create({required this.guiSettingsCubit});

  static List<bool Function(SentryEvent, {Hint? hint})> eventProcessors = [];
  final GuiSettingsCubit guiSettingsCubit;

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
    var windowPosition = await windowManager.getPosition();
    guiSettingsCubit.setWindowPosition(windowPosition);
  }

  Future<Widget> buildApp() async {
    var errorNotifier = ErrorNotifier();
    var multiPrinter = MultiPrinter(errorNotifier);
    // Logging setup needs to happen after we've done initial setup.
    initLogging(multiPrinter);
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String packageVersion = "${packageInfo.version}+${packageInfo.buildNumber}";
    logInfo("Intiface Central $packageVersion Starting...");
    logInfo("Running main builder");

    logInfo("Initializing paths...");
    await IntifacePaths.init();
    logInfo("Starting file logger...");
    multiPrinter.addFilePrinter();

    // Bring up our settings repo.
    var configCubit = await IntifaceConfigurationCubit.create();
    // Set up Update/Configuration Pipe/Cubit.
    var updateRepo = UpdateRepository(configCubit.currentNewsEtag, configCubit.currentDeviceConfigEtag);

    // Set up attachments to be sent with sentry events.
    if (configCubit.canUseCrashReporting) {
      logInfo("Sentry URL set, crash and log reporting available.");
      final dir = Directory(IntifacePaths.logPath.path);
      logInfo(IntifacePaths.logPath.path);
      var entities = (await dir.list().toList()).whereType<File>();
      Sentry.configureScope((scope) {
        scope.clearAttachments();
        final logAttachments = entities.map((e) => IoSentryAttachment.fromFile(e));
        final userConfigAttachment = IoSentryAttachment.fromFile(IntifacePaths.userDeviceConfigFile);
        for (var attachment in logAttachments) {
          scope.addAttachment(attachment);
        }
        scope.addAttachment(userConfigAttachment);
      });
    } else {
      logWarning("DSN not set, crash reporting cannot be used in this version of Intiface Central");
    }

    if (isDesktop()) {
      // Must add this line before we work with the manager.
      await windowManager.ensureInitialized();

      String windowTitle = kDebugMode ? "Intiface® Central $packageVersion DEBUG" : "Intiface® Central $packageVersion";

      WindowOptions windowOptions = const WindowOptions(
          //center: true,
          //title: windowTitle,
          //backgroundColor: Colors.transparent,
          );

      windowManager.setTitle(windowTitle);

      windowManager.addListener(this);

      // #87: Fetch our displays and make sure what we're trying to show is in bounds. If it isn't, set to top left of
      // main display.

      var displays = await screenRetriever.getAllDisplays();
      var windowPosition = guiSettingsCubit.getWindowPosition();
      var windowInBounds = false;
      for (var display in displays) {
        logInfo(
            "Testing window position $windowPosition against ${display.name} (${display.size} ${display.visiblePosition})");
        if (display.visiblePosition!.dx < windowPosition.dx &&
            (display.visiblePosition!.dx + display.size.width) > windowPosition.dx &&
            display.visiblePosition!.dy < windowPosition.dy &&
            (display.visiblePosition!.dy + display.size.height) > windowPosition.dy) {
          windowInBounds = true;
          logInfo("Window in bounds for ${display.name}");
          break;
        }
      }
      if (!windowInBounds) {
        logInfo("Window position out of bounds, resetting position");
        guiSettingsCubit.setWindowPosition(const Offset(0.0, 0.0));
      } else if (configCubit.restoreWindowLocation) {
        // Only restore the window location if the option to do so is on.
        logInfo("Restoring window position to ${guiSettingsCubit.getWindowPosition()}");
        await windowManager.setPosition(guiSettingsCubit.getWindowPosition());
      } else {
        logInfo("Window location not restored due to configuration settings");
      }

      windowDisplayModeResize(configCubit.useCompactDisplay, guiSettingsCubit);
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      configCubit.stream.listen((event) {
        if (event is! UseCompactDisplayState) {
          return;
        }
        windowDisplayModeResize(event.value, guiSettingsCubit);
      });

      // Only add app update checks on desktop, mobile apps will use stores.
      updateRepo.addProvider(IntifaceCentralDesktopUpdater());
    } else {
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
            allowWifiLock: true,
          ),
        );
      }
    }
    var errorNotifierCubit = ErrorNotifierCubit();

    errorNotifier.stream.listen((record) {
      errorNotifierCubit.emitError(record);
    });

    if (kDebugMode) {
      logWarning("Intiface currently running in DEBUG MODE.");
    }

    configCubit.currentAppVersion = packageInfo.version;

    var deviceConfigVersion = await DeviceConfiguration.getBaseConfigFileVersion();
    configCubit.currentDeviceConfigVersion = deviceConfigVersion;

    var networkCubit = await NetworkInfoCubit.create();

    EngineRepository engineRepo;
    if (isDesktop()) {
      engineRepo = EngineRepository(LibraryEngineProvider());
    } else {
      engineRepo = configCubit.useForegroundProcess
          ? EngineRepository(ForegroundTaskLibraryEngineProvider())
          : EngineRepository(LibraryEngineProvider());
    }

    var assetCubit = await AssetCubit.create();

    var updateBloc = UpdateBloc(updateRepo);

    updateBloc.stream.listen((state) async {
      if (state is NewsUpdateRetrieved) {
        configCubit.currentNewsEtag = state.version;
        await assetCubit.update();
      }
      if (state is DeviceConfigUpdateRetrieved) {
        configCubit.currentDeviceConfigEtag = state.version;
        // Load the file and pull internal version while we're at it.
        var deviceConfigVersion = await DeviceConfiguration.getBaseConfigFileVersion();
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

    var engineControlBloc = EngineControlBloc(engineRepo);

    var deviceControlBloc = DeviceManagerBloc(engineControlBloc.stream, engineControlBloc.add);

    ///
    /// ORDER MATTERS HERE
    ///
    /// We need to bind to our library and start making calls as late as possible, so we can collect as much information
    /// about bootup as possible before we possibly crash on a native error.

    // Bring up the FFI now that we have logging available and crash logging set up.
    initializeApi();

    var userConfigCubit = await UserDeviceConfigurationCubit.create();

    var apiLog = NativeApiLog();
    apiLog.logMessageStream.listen((message) {
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
    });

    if (const String.fromEnvironment('SENTRY_DSN').isNotEmpty) {
      await api!.crashReporting(sentryApiKey: const String.fromEnvironment('SENTRY_DSN'));
    }

    engineControlBloc.stream.listen((state) async {
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
        await userConfigCubit.update();
      }
    });

    if (kDebugMode) {
      // Make sure the engine is stopped, just in case we've reloaded.
      engineControlBloc.add(EngineControlEventStop());
    }

    if (configCubit.startServerOnStartup) {
      engineControlBloc.add(EngineControlEventStart(options: await configCubit.getEngineOptions()));
    }

    // Make sure we only send crash reports if crash reporting is on or if the user is doing a manual log submission.
    IntifaceCentralApp.eventProcessors.add((event, {hint}) {
      logInfo(event.eventId);
      if (!configCubit.crashReporting) {
        if (event.tags?.containsKey("ManualLogSubmit") != true) {
          logWarning("Crash/error received but CrashReporting is off, not sending to devs.");
          return false;
        }
        logWarning("Manual log submission, crashReporting is off, overriding and sending to devs.");
      } else {
        logWarning("Submitting crash report/logs to developers.");
      }
      return true;
    });

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
        buildWhen: (previous, current) => current is UseLightThemeState || current is ConfigurationResetState,
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
            buildWhen: (previous, current) => current is UseCompactDisplayState || current is ConfigurationResetState,
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
              return Scaffold(body: Column(children: widgets));
            }));
  }
}
