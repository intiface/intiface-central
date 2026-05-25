import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:buttplug/buttplug.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/device/device_cubit.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/device/device_output_cubit.dart';
import 'package:intiface_central/bloc/device/observation_cubit.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/bloc/util/asset_cubit.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';
import 'package:intiface_central/bloc/util/navigation_cubit.dart';
import 'package:intiface_central/src/rust/api/device_config.dart';
import 'package:intiface_central/src/rust/api/simulated_devices.dart'
    as simulated_api;
import 'package:intiface_central/src/rust/api/specifiers.dart';
import 'package:intiface_central/util/logging.dart';
import 'package:intiface_central/widget/body_widget.dart';
import 'package:intiface_central/widget/control_widget.dart';
import 'package:loggy/loggy.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

import '../helpers/ffi_fixtures.dart';
import '../helpers/fake_blocs.dart';
import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';
import 'docs_screenshot_spec.dart';

const _artifactDirectory = 'docs/assets/screenshots/generated';
const _calloutColors = [
  Color(0xff0f6cbd),
  Color(0xffb45309),
  Color(0xff0f766e),
  Color(0xff7c3aed),
  Color(0xffbe123c),
];
const _calloutTextStyle = TextStyle(
  color: Color(0xff17202a),
  fontFamily: 'Roboto',
  fontSize: 18,
  fontWeight: FontWeight.w600,
  height: 1.25,
);
const _defaultStartupNewsMarkdown = '''
# Intiface News

Welcome to Intiface Central. News and update notes appear here.
''';

class DocsWidgetScreenshotGenerator {
  DocsWidgetScreenshotGenerator(this.spec);

  final DocsScreenshotSpec spec;

  Future<void> generate(WidgetTester tester) async {
    if (spec.mode != DocsScreenshotMode.widget) {
      throw TestFailure(
        'Spec ${spec.id} is ${spec.mode.name}, not widget mode',
      );
    }

    _setViewport(tester);

    final rawBoundaryKey = GlobalKey();
    await _pumpSpec(tester, rawBoundaryKey, const []);
    await _writeBoundaryPng(
      tester,
      rawBoundaryKey,
      p.join(_artifactDirectory, '${spec.id}.png'),
      pixelRatio: spec.pixelRatio,
    );

    if (spec.callouts.isEmpty) return;

    final targetRects = _resolveCalloutTargets(tester);
    final laidOutCallouts = _layoutCallouts(targetRects);

    final calloutBoundaryKey = GlobalKey();
    await _pumpSpec(tester, calloutBoundaryKey, laidOutCallouts);
    await _writeBoundaryPng(
      tester,
      calloutBoundaryKey,
      p.join(_artifactDirectory, '${spec.id}-callouts.png'),
      pixelRatio: spec.pixelRatio,
    );
  }

  void _setViewport(WidgetTester tester) {
    tester.view.physicalSize = spec.viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> _pumpSpec(
    WidgetTester tester,
    GlobalKey boundaryKey,
    List<DocsLaidOutCallout> callouts,
  ) async {
    _configureLogFixture();
    await pumpApp(
      tester,
      windowSize: spec.viewport,
      child: DocsScreenshotFrame(
        boundaryKey: boundaryKey,
        viewport: spec.viewport,
        presentation: spec.presentation,
        background: spec.background,
        window: spec.window,
        callouts: callouts,
        child: _buildEntrypoint(),
      ),
      engineControlBloc: _engineBlocForFixture(),
      deviceManagerBloc: _deviceManagerBlocForFixture(),
      navigationCubit: _navigationCubitForFixture(),
      configCubit: _configCubitForFixture(),
      guiSettingsCubit: _guiSettingsCubitForFixture(),
      userConfigCubit: _userConfigCubitForFixture(),
      assetCubit: _assetCubitForFixture(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await _performFixtureActions(tester);
  }

  Widget _buildEntrypoint() {
    return switch (spec.entrypoint) {
      'controlWidget' => const ControlWidget(),
      'desktopStartup' || 'mobileStartup' => const DocsStartupWindow(),
      _ => throw TestFailure(
        'Unsupported widget screenshot entrypoint "${spec.entrypoint}" '
        'in ${spec.sourcePath}',
      ),
    };
  }

  EngineControlBloc _engineBlocForFixture() {
    final engineBloc = MockEngineControlBloc();
    final engineFixture = spec.fixture['engine'] as String? ?? 'stopped';

    final EngineControlState state;
    final bool isRunning;
    switch (engineFixture) {
      case 'stopped':
        state = EngineStoppedState();
        isRunning = false;
      case 'starting':
        state = EngineStartingState();
        isRunning = true;
      case 'running':
        state = EngineStartedState();
        isRunning = true;
      case 'clientConnected':
        state = ClientConnectedState(
          spec.fixture['clientName'] as String? ?? 'Test App',
        );
        isRunning = true;
      default:
        throw TestFailure(
          'Unsupported engine fixture "$engineFixture" in ${spec.sourcePath}',
        );
    }

    when(() => engineBloc.state).thenReturn(state);
    when(() => engineBloc.isRunning).thenReturn(isRunning);
    return engineBloc;
  }

  DeviceManagerBloc _deviceManagerBlocForFixture() {
    final deviceManagerBloc = MockDeviceManagerBloc();
    final devices = _deviceFixturesForSpec()
        .where((device) => device.connected)
        .map(_deviceCubitForFixture)
        .toList();

    when(() => deviceManagerBloc.state).thenReturn(DeviceManagerInitialState());
    when(() => deviceManagerBloc.devices).thenReturn(devices);
    when(
      () => deviceManagerBloc.scanning,
    ).thenReturn(spec.fixture['scanning'] as bool? ?? false);
    return deviceManagerBloc;
  }

  UserDeviceConfigurationCubit _userConfigCubitForFixture() {
    final userConfigCubit = MockUserDeviceConfigurationCubit();
    final configs = {
      for (final device in _deviceFixturesForSpec())
        device.identifier: device.definition,
    };
    stubUserDeviceConfigurationCubit(
      userConfigCubit,
      configs: configs,
      protocols: _protocolsForFixture(),
      specifiers: _websocketSpecifiersForFixture(),
      serialSpecifiers: _serialSpecifiersForFixture(),
      simulatedArchetypes: _simulatedArchetypesForFixture(),
      simulatedDevices: _simulatedDevicesForFixture(),
    );
    return userConfigCubit;
  }

  NavigationCubit _navigationCubitForFixture() {
    final navigationCubit = NavigationCubit();
    switch (spec.fixture['navigationPage'] as String? ?? 'news') {
      case 'news':
        break;
      case 'appControl':
        navigationCubit.goAppControl();
      case 'deviceControl':
        navigationCubit.goDeviceControl();
      case 'logs':
        navigationCubit.goLogs();
      case 'settings':
        navigationCubit.goSettings();
      case 'about':
        navigationCubit.goAbout();
      default:
        throw TestFailure(
          'Unsupported navigationPage fixture '
          '"${spec.fixture['navigationPage']}" in ${spec.sourcePath}',
        );
    }
    return navigationCubit;
  }

  GuiSettingsCubit _guiSettingsCubitForFixture() {
    final guiSettingsCubit = MockGuiSettingsCubit();
    final expansionValues = <String, bool>{
      for (final name in _expandedSettingsForFixture()) name: true,
    };
    final streamController = StreamController<GuiSettingsState>.broadcast();
    addTearDown(streamController.close);

    when(() => guiSettingsCubit.state).thenReturn(GuiSettingsStateInitial());
    when(
      () => guiSettingsCubit.stream,
    ).thenAnswer((_) => streamController.stream);
    when(() => guiSettingsCubit.getExpansionValue(any())).thenAnswer((
      invocation,
    ) {
      final expansionName = invocation.positionalArguments.first as String;
      return expansionValues[expansionName];
    });
    when(() => guiSettingsCubit.setExpansionValue(any(), any())).thenAnswer((
      invocation,
    ) {
      final expansionName = invocation.positionalArguments[0] as String;
      final isExpanded = invocation.positionalArguments[1] as bool;
      expansionValues[expansionName] = isExpanded;
      streamController.add(GuiSettingStateUpdate(valueName: expansionName));
    });

    return guiSettingsCubit;
  }

  IntifaceConfigurationCubit _configCubitForFixture() {
    final configCubit = MockIntifaceConfigurationCubit();
    stubConfigurationCubit(
      configCubit,
      useCompactDisplay: spec.fixture['useCompactDisplay'] as bool? ?? false,
      useSideNavigationBar:
          spec.fixture['useSideNavigationBar'] as bool? ?? true,
      useDeviceWebsocketServer:
          spec.fixture['useDeviceWebsocketServer'] as bool? ?? false,
      useSimulatedDevices:
          spec.fixture['useSimulatedDevices'] as bool? ?? false,
      useSerialPort: spec.fixture['useSerialPort'] as bool? ?? false,
      websocketServerAllInterfaces:
          spec.fixture['websocketServerAllInterfaces'] as bool? ?? false,
      websocketServerPort: spec.fixture['websocketServerPort'] as int? ?? 12345,
      currentAppVersion:
          spec.fixture['currentAppVersion'] as String? ?? '3.0.0',
      latestAppVersion: spec.fixture['latestAppVersion'] as String? ?? '3.0.0',
      currentDeviceConfigVersion:
          spec.fixture['currentDeviceConfigVersion'] as String? ?? '0.0',
      appMode: _appModeForFixture(),
      themeModeSetting: spec.fixture['themeModeSetting'] as String? ?? 'system',
      checkForUpdateOnStart:
          spec.fixture['checkForUpdateOnStart'] as bool? ?? true,
      crashReporting: spec.fixture['crashReporting'] as bool? ?? false,
      canUseCrashReporting:
          spec.fixture['canUseCrashReporting'] as bool? ?? false,
      restoreWindowLocation:
          spec.fixture['restoreWindowLocation'] as bool? ?? true,
      useDiscordRichPresence:
          spec.fixture['useDiscordRichPresence'] as bool? ?? false,
      trayIconMode: spec.fixture['trayIconMode'] as String? ?? 'both',
      allowExperimentalRestServer:
          spec.fixture['allowExperimentalRestServer'] as bool? ?? false,
      usePrereleaseVersion:
          spec.fixture['usePrereleaseVersion'] as bool? ?? false,
      useForegroundProcess:
          spec.fixture['useForegroundProcess'] as bool? ?? true,
      repeaterLocalPort: spec.fixture['repeaterLocalPort'] as int? ?? 12345,
      repeaterRemoteAddress:
          spec.fixture['repeaterRemoteAddress'] as String? ??
          '192.168.1.1:12345',
      displayLogLevel: spec.fixture['displayLogLevel'] as String? ?? 'info',
    );
    return configCubit;
  }

  AppMode _appModeForFixture() {
    return switch (spec.fixture['appMode'] as String? ?? 'engine') {
      'engine' => AppMode.engine,
      'repeater' => AppMode.repeater,
      'restApi' => AppMode.restApi,
      final value => throw TestFailure(
        'Unsupported appMode fixture "$value" in ${spec.sourcePath}',
      ),
    };
  }

  AssetCubit _assetCubitForFixture() {
    final newsMarkdown =
        spec.fixture['newsMarkdown'] as String? ?? _defaultStartupNewsMarkdown;
    final aboutMarkdown = spec.fixture['aboutMarkdown'] as String? ?? '';
    return AssetCubit(newsMarkdown, aboutMarkdown);
  }

  List<String> _expandedSettingsForFixture() {
    final settings = spec.fixture['expandedSettings'];
    if (settings == null) return const [];
    if (settings is! List) {
      throw TestFailure(
        'Fixture "expandedSettings" must be a list in ${spec.sourcePath}',
      );
    }
    return settings.map((value) {
      if (value is String && value.isNotEmpty) return value;
      throw TestFailure(
        'Fixture "expandedSettings" entries must be strings in '
        '${spec.sourcePath}',
      );
    }).toList();
  }

  void _configureLogFixture() {
    final navigationPage = spec.fixture['navigationPage'] as String?;
    if (navigationPage != 'logs' && !spec.fixture.containsKey('logMessages')) {
      return;
    }

    final printer = IntifaceStreamPrinter(_DocsDiscardingLogPrinter());
    Loggy.initLoggy(
      logPrinter: printer,
      logOptions: const LogOptions(
        LogLevel.all,
        stackTraceLevel: LogLevel.error,
      ),
    );
    addTearDown(printer.dispose);
    printer.logRecord.add(_logRecordsForFixture());
  }

  List<LogRecord> _logRecordsForFixture() {
    final messages = spec.fixture['logMessages'];
    if (messages == null) return _defaultLogRecordsForFixture();
    if (messages is! List) {
      throw TestFailure(
        'Fixture "logMessages" must be a list in ${spec.sourcePath}',
      );
    }
    return messages.indexed.map((entry) {
      final (index, value) = entry;
      if (value is! Map) {
        throw TestFailure(
          'Log message fixture at index $index must be an object in '
          '${spec.sourcePath}',
        );
      }
      final json = Map<String, Object?>.from(value);
      return _logRecord(
        _logLevelForFixture(_requiredString(json, 'level')),
        _requiredString(json, 'message'),
        elapsed: _optionalDouble(json, 'elapsed') ?? index / 100.0,
      );
    }).toList();
  }

  List<LogRecord> _defaultLogRecordsForFixture() {
    return [
      _logRecord(
        LogLevel.error,
        'Error loading previous device session: simulated docs fixture failure',
        elapsed: 0.586,
      ),
      _logRecord(
        LogLevel.warning,
        'DSN not set, crash reporting cannot be used in this version of Intiface Central',
        elapsed: 0.421,
      ),
      _logRecord(
        LogLevel.info,
        'Sentry initialization skipped by bootstrap options.',
        elapsed: 0.398,
      ),
      _logRecord(LogLevel.info, 'Starting file logger...', elapsed: 0.265),
      _logRecord(LogLevel.info, 'Initializing paths...', elapsed: 0.173),
      _logRecord(LogLevel.info, 'Running main builder', elapsed: 0.064),
      _logRecord(
        LogLevel.info,
        'Intiface Central 3.0.0 Starting...',
        elapsed: 0.012,
      ),
    ];
  }

  LogRecord _logRecord(
    LogLevel level,
    String message, {
    required double elapsed,
  }) {
    return LogRecord(
      level,
      message,
      'IntifaceCentral',
      null,
      null,
      null,
      RecordMetadata(elapsed),
    );
  }

  LogLevel _logLevelForFixture(String value) {
    final normalizedValue = value.toLowerCase();
    for (final level in LogLevel.values) {
      if (level.name.toLowerCase() == normalizedValue) return level;
    }
    throw TestFailure('Unsupported log level "$value" in ${spec.sourcePath}');
  }

  double? _optionalDouble(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw TestFailure(
      'Fixture field "$key" must be numeric in ${spec.sourcePath}',
    );
  }

  Future<void> _performFixtureActions(WidgetTester tester) async {
    final actions = spec.fixture['actions'];
    if (actions == null) return;
    if (actions is! List) {
      throw TestFailure(
        'Fixture "actions" must be a list in ${spec.sourcePath}',
      );
    }

    for (final action in actions) {
      if (action is! Map) {
        throw TestFailure(
          'Fixture action must be an object in ${spec.sourcePath}',
        );
      }
      final actionJson = Map<String, Object?>.from(action);
      final tapText = actionJson['tapText'];
      if (tapText is String && tapText.isNotEmpty) {
        final finder = find.text(tapText);
        if (finder.evaluate().isEmpty) {
          throw TestFailure(
            'Could not find text "$tapText" for fixture action in '
            '${spec.sourcePath}',
          );
        }
        await tester.ensureVisible(finder.first);
        await tester.pump();
        await tester.tap(finder.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        continue;
      }

      final ensureVisibleText = actionJson['ensureVisibleText'];
      if (ensureVisibleText is String && ensureVisibleText.isNotEmpty) {
        final finder = find.text(ensureVisibleText);
        if (finder.evaluate().isEmpty) {
          throw TestFailure(
            'Could not find text "$ensureVisibleText" for fixture action in '
            '${spec.sourcePath}',
          );
        }
        await tester.ensureVisible(finder.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        continue;
      }

      final ensureVisibleKey = actionJson['ensureVisibleKey'];
      if (ensureVisibleKey is String && ensureVisibleKey.isNotEmpty) {
        final finder = find.byKey(ValueKey<String>(ensureVisibleKey));
        final matches = finder.evaluate();
        if (matches.isEmpty) {
          throw TestFailure(
            'Could not find key "$ensureVisibleKey" for fixture action in '
            '${spec.sourcePath}',
          );
        }
        final alignmentJson = actionJson['alignment'];
        final alignment = alignmentJson is num ? alignmentJson.toDouble() : 0.0;
        await Scrollable.ensureVisible(
          matches.first,
          alignment: alignment,
          duration: Duration.zero,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        continue;
      }

      throw TestFailure(
        'Unsupported fixture action $actionJson in ${spec.sourcePath}',
      );
    }
  }

  List<String> _protocolsForFixture() {
    final protocols = spec.fixture['protocols'];
    if (protocols == null) return const ['lovense', 'buttplug'];
    if (protocols is! List) {
      throw TestFailure(
        'Fixture "protocols" must be a list in ${spec.sourcePath}',
      );
    }
    return protocols.map((value) {
      if (value is String && value.isNotEmpty) return value;
      throw TestFailure(
        'Fixture "protocols" entries must be strings in ${spec.sourcePath}',
      );
    }).toList();
  }

  List<(String, ExposedWebsocketSpecifier)> _websocketSpecifiersForFixture() {
    final devices = spec.fixture['websocketDevices'];
    if (devices == null) return const [];
    if (devices is! List) {
      throw TestFailure(
        'Fixture "websocketDevices" must be a list in ${spec.sourcePath}',
      );
    }
    return devices.map((value) {
      if (value is! Map) {
        throw TestFailure(
          'Websocket device fixture must be an object in ${spec.sourcePath}',
        );
      }
      final json = Map<String, Object?>.from(value);
      return (
        _requiredString(json, 'protocol'),
        ExposedWebsocketSpecifier(name: _requiredString(json, 'name')),
      );
    }).toList();
  }

  List<(String, ExposedSerialSpecifier)> _serialSpecifiersForFixture() {
    final devices = spec.fixture['serialDevices'];
    if (devices == null) return const [];
    if (devices is! List) {
      throw TestFailure(
        'Fixture "serialDevices" must be a list in ${spec.sourcePath}',
      );
    }
    return devices.map((value) {
      if (value is! Map) {
        throw TestFailure(
          'Serial device fixture must be an object in ${spec.sourcePath}',
        );
      }
      final json = Map<String, Object?>.from(value);
      return (
        _requiredString(json, 'protocol'),
        ExposedSerialSpecifier(
          port: _requiredString(json, 'port'),
          baudRate: _optionalInt(json, 'baudRate') ?? 115200,
          dataBits: _optionalInt(json, 'dataBits') ?? 8,
          stopBits: _optionalInt(json, 'stopBits') ?? 1,
          parity: _optionalString(json, 'parity') ?? 'N',
        ),
      );
    }).toList();
  }

  List<simulated_api.ExposedSimulatedDeviceArchetype>
  _simulatedArchetypesForFixture() {
    final archetypes = spec.fixture['simulatedArchetypes'];
    if (archetypes == null) {
      return const [
        simulated_api.ExposedSimulatedDeviceArchetype(
          identifier: 'single-vibrator',
          displayName: 'Single Vibrator',
          outputFeatures: [
            simulated_api.ExposedSimulatedDeviceFeatureSummary(
              description: 'Vibrate',
              outputType: 'Vibrate',
              index: 0,
            ),
          ],
        ),
        simulated_api.ExposedSimulatedDeviceArchetype(
          identifier: 'double-vibrator',
          displayName: 'Double Vibrator',
          outputFeatures: [
            simulated_api.ExposedSimulatedDeviceFeatureSummary(
              description: 'Left vibrator',
              outputType: 'Vibrate',
              index: 0,
            ),
            simulated_api.ExposedSimulatedDeviceFeatureSummary(
              description: 'Right vibrator',
              outputType: 'Vibrate',
              index: 1,
            ),
          ],
        ),
      ];
    }
    if (archetypes is! List) {
      throw TestFailure(
        'Fixture "simulatedArchetypes" must be a list in ${spec.sourcePath}',
      );
    }
    return archetypes.map((value) {
      if (value is! Map) {
        throw TestFailure(
          'Simulated archetype fixture must be an object in ${spec.sourcePath}',
        );
      }
      final json = Map<String, Object?>.from(value);
      return simulated_api.ExposedSimulatedDeviceArchetype(
        identifier: _requiredString(json, 'identifier'),
        displayName: _requiredString(json, 'displayName'),
        outputFeatures: const [
          simulated_api.ExposedSimulatedDeviceFeatureSummary(
            description: 'Vibrate',
            outputType: 'Vibrate',
            index: 0,
          ),
        ],
      );
    }).toList();
  }

  List<simulated_api.ExposedSimulatedDeviceConfigEntry>
  _simulatedDevicesForFixture() {
    final devices = spec.fixture['simulatedDevices'];
    if (devices == null) return const [];
    if (devices is! List) {
      throw TestFailure(
        'Fixture "simulatedDevices" must be a list in ${spec.sourcePath}',
      );
    }
    return devices.map((value) {
      if (value is! Map) {
        throw TestFailure(
          'Simulated device fixture must be an object in ${spec.sourcePath}',
        );
      }
      final json = Map<String, Object?>.from(value);
      return simulated_api.ExposedSimulatedDeviceConfigEntry(
        identifier: _requiredString(json, 'identifier'),
        displayName: _optionalString(json, 'displayName'),
        address: _requiredString(json, 'address'),
      );
    }).toList();
  }

  String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw TestFailure(
      'Fixture field "$key" must be a non-empty string in ${spec.sourcePath}',
    );
  }

  String? _optionalString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    throw TestFailure(
      'Fixture field "$key" must be a non-empty string in ${spec.sourcePath}',
    );
  }

  int? _optionalInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    throw TestFailure(
      'Fixture field "$key" must be an integer in ${spec.sourcePath}',
    );
  }

  List<_DocsDeviceFixture> _deviceFixturesForSpec() {
    final devicesJson = spec.fixture['devices'];
    if (devicesJson == null) return const [];
    if (devicesJson is! List) {
      throw TestFailure(
        'Fixture "devices" must be a list in ${spec.sourcePath}',
      );
    }

    return devicesJson.indexed.map((entry) {
      final (index, value) = entry;
      if (value is! Map) {
        throw TestFailure(
          'Device fixture at index $index must be an object in '
          '${spec.sourcePath}',
        );
      }
      return _DocsDeviceFixture.fromJson(
        Map<String, Object?>.from(value),
        fallbackIndex: index,
        sourcePath: spec.sourcePath,
      );
    }).toList();
  }

  DeviceCubit _deviceCubitForFixture(_DocsDeviceFixture deviceFixture) {
    final device = MockButtplugClientDevice();
    when(() => device.index).thenReturn(deviceFixture.index);
    when(() => device.name).thenReturn(deviceFixture.hardwareName);
    when(() => device.displayName).thenReturn(deviceFixture.displayName);

    final outputs = <DeviceOutputCubit>[];
    final observations = <int, ObservationCubit>{};
    for (final feature in deviceFixture.outputFeatures) {
      outputs.add(
        _deviceOutputCubitForFeature(
          deviceIndex: deviceFixture.index,
          feature: feature,
        ),
      );
      observations[feature.index] = _observationCubitForFeature(
        deviceIndex: deviceFixture.index,
        featureIndex: feature.index,
        values: feature.observationValues,
      );
    }

    final deviceCubit = MockDeviceCubit();
    when(() => deviceCubit.state).thenReturn(DeviceStateOnline());
    when(() => deviceCubit.device).thenReturn(device);
    when(() => deviceCubit.outputs).thenReturn(outputs);
    when(() => deviceCubit.observations).thenReturn(observations);
    when(() => deviceCubit.inputs).thenReturn([]);
    return deviceCubit;
  }

  DeviceOutputCubit _deviceOutputCubitForFeature({
    required int deviceIndex,
    required _DocsDeviceOutputFeature feature,
  }) {
    final clientFeature = ClientDeviceFeature()
      ..featureIndex = feature.index
      ..featureDescription = feature.description
      ..output = {
        feature.type: ClientDeviceFeatureOutputInfo()
          ..value = [0, feature.maxSteps]
          ..duration = feature.type == OutputType.hwPositionWithDuration
              ? [0, 3000]
              : null,
      };

    final deviceFeature = MockButtplugClientDeviceFeature();
    when(() => deviceFeature.deviceIndex).thenReturn(deviceIndex);
    when(() => deviceFeature.feature).thenReturn(clientFeature);

    if (feature.type == OutputType.hwPositionWithDuration) {
      return PositionWithDurationOutputCubit(deviceFeature);
    }
    return ValueOutputCubit(deviceFeature, feature.type);
  }

  ObservationCubit _observationCubitForFeature({
    required int deviceIndex,
    required int featureIndex,
    required List<double> values,
  }) {
    final observationCubit = MockObservationCubit();
    when(() => observationCubit.state).thenReturn(ObservationState(values));
    when(() => observationCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => observationCubit.deviceIndex).thenReturn(deviceIndex);
    when(() => observationCubit.featureIndex).thenReturn(featureIndex);
    when(() => observationCubit.maxSteps).thenReturn(20);
    return observationCubit;
  }

  List<Rect> _resolveCalloutTargets(WidgetTester tester) {
    final screenRect = Offset.zero & spec.viewport;

    return spec.callouts.map((callout) {
      final rect = _resolveTargetRect(tester, callout);
      if (rect.isEmpty || !rect.overlaps(screenRect)) {
        throw TestFailure(
          'Callout "${callout.id}" in ${spec.sourcePath} resolved offscreen '
          'or empty target ${callout.target.description}: $rect',
        );
      }
      return rect;
    }).toList();
  }

  Rect _resolveTargetRect(WidgetTester tester, DocsCalloutSpec callout) {
    if (callout.target.bounds != null) return callout.target.bounds!;

    final finder = _finderForTarget(callout.target);
    final matches = finder.evaluate().toList();
    if (matches.length != 1) {
      throw TestFailure(
        'Callout "${callout.id}" in ${spec.sourcePath} target '
        '${callout.target.description} resolved ${matches.length} widgets; '
        'expected exactly one.',
      );
    }
    return tester.getRect(finder);
  }

  Finder _finderForTarget(DocsCalloutTarget target) {
    if (target.key != null) {
      return find.byKey(ValueKey<String>(target.key!));
    }
    if (target.text != null) return find.text(target.text!);
    if (target.tooltip != null) return find.byTooltip(target.tooltip!);
    if (target.semanticsLabel != null) {
      return find.bySemanticsLabel(target.semanticsLabel!);
    }
    throw TestFailure('Explicit bounds target does not need a Finder');
  }

  List<DocsLaidOutCallout> _layoutCallouts(List<Rect> targetRects) {
    final labels = <Rect>[];
    final laidOut = <DocsLaidOutCallout>[];

    for (var index = 0; index < spec.callouts.length; index += 1) {
      final callout = spec.callouts[index];
      final targetRect = targetRects[index];

      if (callout.markerOnly) {
        laidOut.add(
          DocsLaidOutCallout(
            number: index + 1,
            label: callout.label,
            placement: callout.placement,
            targetRect: targetRect,
            highlightPadding: callout.highlightPadding,
            markerOnly: true,
            labelRect: Rect.zero,
            markerCenter: _markerCenter(targetRect, callout.placement),
            leaderEnd: Offset.zero,
            color: _calloutColors[index % _calloutColors.length],
          ),
        );
        continue;
      }

      final labelSize = _measureLabel(callout.label);
      final labelRect = _placeLabel(targetRect, labelSize, callout);

      if (_isOffscreen(labelRect)) {
        throw TestFailure(
          'Callout "${callout.id}" in ${spec.sourcePath} placed label '
          'outside the viewport: $labelRect',
        );
      }
      if (labelRect.overlaps(targetRect.inflate(8))) {
        throw TestFailure(
          'Callout "${callout.id}" in ${spec.sourcePath} label overlaps '
          'its target.',
        );
      }
      for (final previousLabel in labels) {
        if (labelRect.inflate(8).overlaps(previousLabel.inflate(8))) {
          throw TestFailure(
            'Callout "${callout.id}" in ${spec.sourcePath} label overlaps '
            'another callout label.',
          );
        }
      }

      labels.add(labelRect);
      laidOut.add(
        DocsLaidOutCallout(
          number: index + 1,
          label: callout.label,
          placement: callout.placement,
          targetRect: targetRect,
          highlightPadding: callout.highlightPadding,
          markerOnly: false,
          labelRect: labelRect,
          markerCenter: _markerCenter(targetRect, callout.placement),
          leaderEnd: _leaderEnd(labelRect, callout.placement),
          color: _calloutColors[index % _calloutColors.length],
        ),
      );
    }

    return laidOut;
  }

  Size _measureLabel(String label) {
    const horizontalPadding = 28.0;
    const verticalPadding = 18.0;
    final painter = TextPainter(
      text: TextSpan(text: label, style: _calloutTextStyle),
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: 272);

    final width = math.max(220.0, painter.width + horizontalPadding);
    return Size(math.min(320.0, width), painter.height + verticalPadding);
  }

  Rect _placeLabel(Rect targetRect, Size labelSize, DocsCalloutSpec callout) {
    const gap = 70.0;
    double left;
    double top;

    switch (callout.placement) {
      case DocsCalloutPlacement.left:
        left = targetRect.left - gap - labelSize.width;
        top = targetRect.center.dy - labelSize.height / 2;
      case DocsCalloutPlacement.right:
        left = targetRect.right + gap;
        top = targetRect.center.dy - labelSize.height / 2;
      case DocsCalloutPlacement.top:
        left = targetRect.center.dx - labelSize.width / 2;
        top = targetRect.top - gap - labelSize.height;
      case DocsCalloutPlacement.bottom:
        left = targetRect.center.dx - labelSize.width / 2;
        top = targetRect.bottom + gap;
    }

    const margin = 24.0;
    if (labelSize.width > spec.viewport.width - margin * 2 ||
        labelSize.height > spec.viewport.height - margin * 2) {
      throw TestFailure(
        'Callout "${callout.id}" in ${spec.sourcePath} label is too large '
        'for the viewport.',
      );
    }

    left = _clamp(left, margin, spec.viewport.width - margin - labelSize.width);
    top = _clamp(top, margin, spec.viewport.height - margin - labelSize.height);
    return Rect.fromLTWH(left, top, labelSize.width, labelSize.height);
  }

  Offset _markerCenter(Rect targetRect, DocsCalloutPlacement placement) {
    const markerGap = 22.0;
    return switch (placement) {
      DocsCalloutPlacement.left => Offset(
        targetRect.left - markerGap,
        targetRect.center.dy,
      ),
      DocsCalloutPlacement.right => Offset(
        targetRect.right + markerGap,
        targetRect.center.dy,
      ),
      DocsCalloutPlacement.top => Offset(
        targetRect.center.dx,
        targetRect.top - markerGap,
      ),
      DocsCalloutPlacement.bottom => Offset(
        targetRect.center.dx,
        targetRect.bottom + markerGap,
      ),
    };
  }

  Offset _leaderEnd(Rect labelRect, DocsCalloutPlacement placement) {
    return switch (placement) {
      DocsCalloutPlacement.left => Offset(labelRect.right, labelRect.center.dy),
      DocsCalloutPlacement.right => Offset(labelRect.left, labelRect.center.dy),
      DocsCalloutPlacement.top => Offset(labelRect.center.dx, labelRect.bottom),
      DocsCalloutPlacement.bottom => Offset(labelRect.center.dx, labelRect.top),
    };
  }

  bool _isOffscreen(Rect rect) {
    const margin = 0.5;
    return rect.left < margin ||
        rect.top < margin ||
        rect.right > spec.viewport.width - margin ||
        rect.bottom > spec.viewport.height - margin;
  }

  double _clamp(double value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }
}

class _DocsDeviceFixture {
  _DocsDeviceFixture({
    required this.index,
    required this.hardwareName,
    required this.displayName,
    required this.connected,
    required this.outputFeatures,
    required this.identifier,
    required this.definition,
  });

  final int index;
  final String hardwareName;
  final String displayName;
  final bool connected;
  final List<_DocsDeviceOutputFeature> outputFeatures;
  final ExposedUserDeviceIdentifier identifier;
  final ExposedServerDeviceDefinition definition;

  factory _DocsDeviceFixture.fromJson(
    Map<String, Object?> json, {
    required int fallbackIndex,
    required String sourcePath,
  }) {
    final kind = _optionalString(json, 'kind') ?? 'single-vibrator';
    final id = _optionalString(json, 'id') ?? 'simulated-$fallbackIndex';
    final displayName =
        _optionalString(json, 'displayName') ?? _defaultDisplayName(kind);
    final hardwareName =
        _optionalString(json, 'hardwareName') ?? _defaultHardwareName(kind);
    final index = _optionalInt(json, 'index') ?? fallbackIndex;
    final connected = _optionalBool(json, 'connected') ?? true;
    final allow = _optionalBool(json, 'allow') ?? false;
    final deny = _optionalBool(json, 'deny') ?? false;
    final outputFeatures = _outputFeaturesForKind(kind, sourcePath);
    final identifier = fakeDeviceIdentifier(
      address: 'simulated://$id',
      protocol: 'simulated',
    );
    final definition = fakeDeviceDefinition(
      name: hardwareName,
      displayName: displayName,
      index: index,
      allow: allow,
      deny: deny,
      features: outputFeatures
          .map(
            (feature) => fakeFeature(
              description: feature.description,
              output: _fakeDefinitionOutputForType(feature.type),
            ),
          )
          .toList(),
    );

    return _DocsDeviceFixture(
      index: index,
      hardwareName: hardwareName,
      displayName: displayName,
      connected: connected,
      outputFeatures: outputFeatures,
      identifier: identifier,
      definition: definition,
    );
  }

  static String _defaultDisplayName(String kind) {
    return switch (kind) {
      'single-vibrator' || 'singleVibrator' => 'Alpha Single Vibrator',
      'double-vibrator' || 'doubleVibrator' => 'Beta Double Vibrator',
      'stroker' => 'Gamma Stroker',
      _ => 'Simulated Device',
    };
  }

  static String _defaultHardwareName(String kind) {
    return switch (kind) {
      'single-vibrator' || 'singleVibrator' => 'Simulated Single Vibrator',
      'double-vibrator' || 'doubleVibrator' => 'Simulated Double Vibrator',
      'stroker' => 'Simulated Stroker',
      _ => 'Simulated Device',
    };
  }

  static List<_DocsDeviceOutputFeature> _outputFeaturesForKind(
    String kind,
    String sourcePath,
  ) {
    return switch (kind) {
      'single-vibrator' ||
      'singleVibrator' => [_DocsDeviceOutputFeature.vibrate(0, 'Vibrate')],
      'double-vibrator' || 'doubleVibrator' => [
        _DocsDeviceOutputFeature.vibrate(0, 'Left vibrator'),
        _DocsDeviceOutputFeature.vibrate(1, 'Right vibrator'),
      ],
      'stroker' => [
        _DocsDeviceOutputFeature.positionWithDuration(0, 'Stroke position'),
      ],
      _ => throw TestFailure(
        'Unsupported device fixture kind "$kind" in $sourcePath',
      ),
    };
  }

  static String? _optionalString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    throw TestFailure('Device fixture field "$key" must be a string');
  }

  static int? _optionalInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    throw TestFailure('Device fixture field "$key" must be an integer');
  }

  static bool? _optionalBool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is bool) return value;
    throw TestFailure('Device fixture field "$key" must be a boolean');
  }
}

class _DocsDeviceOutputFeature {
  _DocsDeviceOutputFeature({
    required this.index,
    required this.description,
    required this.type,
    required this.maxSteps,
    required this.observationValues,
  });

  final int index;
  final String description;
  final OutputType type;
  final int maxSteps;
  final List<double> observationValues;

  factory _DocsDeviceOutputFeature.vibrate(int index, String description) {
    return _DocsDeviceOutputFeature(
      index: index,
      description: description,
      type: OutputType.vibrate,
      maxSteps: 20,
      observationValues: _seededObservationValues(index + 1),
    );
  }

  factory _DocsDeviceOutputFeature.positionWithDuration(
    int index,
    String description,
  ) {
    return _DocsDeviceOutputFeature(
      index: index,
      description: description,
      type: OutputType.hwPositionWithDuration,
      maxSteps: 100,
      observationValues: _seededObservationValues(index + 3),
    );
  }

  static List<double> _seededObservationValues(int seed) {
    return List<double>.generate(ObservationCubit.bufferSize, (index) {
      final phase = (index + seed * 7) % 24;
      final value = phase < 12 ? phase / 12 : (24 - phase) / 12;
      return value.clamp(0.0, 1.0).toDouble();
    });
  }
}

ExposedServerDeviceFeatureOutput _fakeDefinitionOutputForType(OutputType type) {
  final output = MockExposedServerDeviceFeatureOutput();
  final props = fakeOutputProperties(
    maxValue: type == OutputType.vibrate ? 20 : 100,
  );
  when(
    () => output.vibrate,
  ).thenReturn(type == OutputType.vibrate ? props : null);
  when(() => output.rotate).thenReturn(null);
  when(() => output.oscillate).thenReturn(null);
  when(() => output.constrict).thenReturn(null);
  when(() => output.temperature).thenReturn(null);
  when(() => output.led).thenReturn(null);
  when(() => output.spray).thenReturn(null);
  when(() => output.position).thenReturn(null);
  when(
    () => output.positionWithDuration,
  ).thenReturn(type == OutputType.hwPositionWithDuration ? props : null);
  return output;
}

class _DocsDiscardingLogPrinter extends LoggyPrinter {
  @override
  void onLog(LogRecord record) {}
}

class DocsStartupWindow extends StatelessWidget {
  const DocsStartupWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: ColoredBox(
        color: backgroundColor,
        child: const Column(
          children: [
            ControlWidget(),
            Divider(height: 2),
            Expanded(child: BodyWidget()),
          ],
        ),
      ),
    );
  }
}

class DocsScreenshotFrame extends StatelessWidget {
  const DocsScreenshotFrame({
    super.key,
    required this.boundaryKey,
    required this.viewport,
    required this.presentation,
    required this.background,
    required this.window,
    required this.callouts,
    required this.child,
  });

  final GlobalKey boundaryKey;
  final Size viewport;
  final DocsScreenshotPresentation presentation;
  final DocsScreenshotBackground background;
  final Size? window;
  final List<DocsLaidOutCallout> callouts;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenshotTheme = theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
      primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
      bottomNavigationBarTheme: theme.bottomNavigationBarTheme.copyWith(
        elevation: 0,
      ),
    );

    return Theme(
      data: screenshotTheme,
      child: DefaultTextStyle(
        style:
            screenshotTheme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Roboto',
            ) ??
            const TextStyle(fontFamily: 'Roboto'),
        child: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox.fromSize(
            size: viewport,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (background == DocsScreenshotBackground.solid)
                  const ColoredBox(color: Color(0xfff5f7fb)),
                _buildPresentedChild(context, screenshotTheme),
                if (callouts.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: DocsCalloutPainter(callouts)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresentedChild(BuildContext context, ThemeData screenshotTheme) {
    return switch (presentation) {
      DocsScreenshotPresentation.card => Center(
        child: SizedBox(
          width: 720,
          child: Material(
            color: screenshotTheme.colorScheme.surface,
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: screenshotTheme.colorScheme.outlineVariant,
                ),
              ),
              child: Padding(padding: const EdgeInsets.all(32), child: child),
            ),
          ),
        ),
      ),
      DocsScreenshotPresentation.window => Center(
        child: SizedBox.fromSize(
          size: window ?? viewport,
          child: Material(
            color: screenshotTheme.colorScheme.surface,
            elevation: 3,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: screenshotTheme.colorScheme.outlineVariant,
                ),
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(size: window ?? viewport),
                child: child,
              ),
            ),
          ),
        ),
      ),
    };
  }
}

class DocsLaidOutCallout {
  DocsLaidOutCallout({
    required this.number,
    required this.label,
    required this.placement,
    required this.targetRect,
    required this.highlightPadding,
    required this.markerOnly,
    required this.labelRect,
    required this.markerCenter,
    required this.leaderEnd,
    required this.color,
  });

  final int number;
  final String label;
  final DocsCalloutPlacement placement;
  final Rect targetRect;
  final double highlightPadding;
  final bool markerOnly;
  final Rect labelRect;
  final Offset markerCenter;
  final Offset leaderEnd;
  final Color color;
}

class DocsCalloutPainter extends CustomPainter {
  DocsCalloutPainter(this.callouts);

  final List<DocsLaidOutCallout> callouts;

  @override
  void paint(Canvas canvas, Size size) {
    final labelFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final labelStroke = Paint()
      ..color = const Color(0xffcbd5e1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final callout in callouts) {
      final highlightRect = callout.targetRect.inflate(
        callout.highlightPadding,
      );
      final highlightPaint = Paint()
        ..color = callout.color.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill;
      final highlightStroke = Paint()
        ..color = callout.color.withValues(alpha: 0.80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final leaderPaint = Paint()
        ..color = callout.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final highlight = RRect.fromRectAndRadius(
        highlightRect,
        const Radius.circular(12),
      );
      canvas.drawRRect(highlight, highlightPaint);
      canvas.drawRRect(highlight, highlightStroke);
      if (!callout.markerOnly) {
        canvas.drawLine(callout.markerCenter, callout.leaderEnd, leaderPaint);

        final labelRRect = RRect.fromRectAndRadius(
          callout.labelRect,
          const Radius.circular(8),
        );
        canvas.drawShadow(Path()..addRRect(labelRRect), Colors.black, 4, false);
        canvas.drawRRect(labelRRect, labelFill);
        canvas.drawRRect(labelRRect, labelStroke);

        final labelPainter = TextPainter(
          text: TextSpan(text: callout.label, style: _calloutTextStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: callout.labelRect.width - 28);
        labelPainter.paint(
          canvas,
          callout.labelRect.topLeft + const Offset(14, 9),
        );
      }

      canvas.drawCircle(
        callout.markerCenter,
        19,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        callout.markerCenter,
        16,
        Paint()..color = callout.color,
      );

      final numberPainter = TextPainter(
        text: TextSpan(
          text: '${callout.number}',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      numberPainter.paint(
        canvas,
        callout.markerCenter -
            Offset(numberPainter.width / 2, numberPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(DocsCalloutPainter oldDelegate) {
    return oldDelegate.callouts != callouts;
  }
}

Future<void> _writeBoundaryPng(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String outputPath, {
  required double pixelRatio,
}) async {
  final context = boundaryKey.currentContext;
  if (context == null) {
    throw TestFailure('Screenshot boundary was not mounted for $outputPath');
  }

  final boundary = context.findRenderObject();
  if (boundary is! RenderRepaintBoundary) {
    throw TestFailure('Screenshot boundary is not a RepaintBoundary');
  }

  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw TestFailure('Unable to encode screenshot PNG $outputPath');
    }

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());
  });
}
