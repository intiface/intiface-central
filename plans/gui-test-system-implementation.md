# GUI Test System — Implementation Plan

**Design doc:** `docs/design-plans/2026-05-22-gui-test-system.md`
**Branch:** `gui-test-system` (from `device-dialog-update`)
**Agent guidance:** Use sonnet/haiku task-implementor-fast for straightforward tasks (file creation, dependency wiring, mechanical test writing). Use sonnet for tasks requiring pattern judgment (fake BLoCs, pumpApp design, integration bootstrap). Reserve opus for debugging issues that arise.

---

## Phase 0: Production Test Seams

**Commit after this phase.** These seams keep tests close to production wiring without forcing the harness to duplicate private bootstrap logic or mutate private global state.

### Step 0.1 — Add an `IntifacePaths` test initialization seam

**File:** `lib/util/intiface_util.dart`

Integration tests need isolated config/log/news/engine paths. `IntifacePaths` currently owns private static `late` fields and can only initialize from `getApplicationSupportDirectory()`, which makes temp-directory isolation impossible without platform mocks.

Add a small, explicit seam:

```dart
class IntifacePaths {
  static Future<void> init({Directory? baseDirectory}) async {
    final docsDir = baseDirectory?.path ?? (await getApplicationSupportDirectory()).path;
    await _initFromBaseDirectory(docsDir);
  }

  @visibleForTesting
  static Future<void> initForTest(Directory baseDirectory) async {
    await _initFromBaseDirectory(baseDirectory.path);
  }

  static Future<void> _initFromBaseDirectory(String docsDir) async {
    // Existing path construction logic moves here.
  }
}
```

Production keeps calling `IntifacePaths.init()` with no args. Tests call `IntifacePaths.initForTest(tempDir)`. Do not expose setters for individual path fields; keep the override scoped to initialization.

**Verify:** existing app startup still compiles; a tiny test can call `IntifacePaths.initForTest(tempDir)` and observe `userDeviceConfigFile.path` under `tempDir`.

### Step 0.2 — Add app bootstrap options instead of duplicating provider setup

**File:** `lib/intiface_central_app.dart`

The integration test plan must not duplicate the entire provider tree from `IntifaceCentralApp.buildApp()`. That will drift. Add a bootstrap options object and a shared builder used by production and integration tests.

```dart
class IntifaceCentralBootstrapOptions {
  final bool initializePaths;
  final Directory? pathsBaseDirectory;
  final bool initializeWindowing;
  final bool initializeTray;
  final bool initializeUpdates;
  final bool initializeSentry;
  final bool initializeDiscord;
  final bool requestPlatformPermissions;
  final Future<void> Function()? afterRustInit;
  final Future<void> Function(UserDeviceConfigurationCubit userConfigCubit)?
      afterUserDeviceConfigurationInit;

  const IntifaceCentralBootstrapOptions({
    this.initializePaths = true,
    this.pathsBaseDirectory,
    this.initializeWindowing = true,
    this.initializeTray = true,
    this.initializeUpdates = true,
    this.initializeSentry = true,
    this.initializeDiscord = true,
    this.requestPlatformPermissions = true,
    this.afterRustInit,
    this.afterUserDeviceConfigurationInit,
  });
}
```

Refactor `buildApp()` so production calls the shared builder with default options, while integration tests can call it with:

- `pathsBaseDirectory: tempDir` if bootstrap owns path initialization, or `initializePaths: false` if `TestAppEnvironment` already called `IntifacePaths.initForTest(tempDir)`
- `initializeWindowing: false`
- `initializeTray: false`
- `initializeUpdates: false`
- `initializeSentry: false`
- `initializeDiscord: false`
- `requestPlatformPermissions: false`
- `afterUserDeviceConfigurationInit: (userConfigCubit) async { await addTestDevice(...); await userConfigCubit.update(); }`

The user-device hook is important: simulated devices require the Rust library and device config manager to be initialized, but they must be created and reloaded before the test starts the engine. Keep `afterRustInit` for lower-level Rust setup, and use `afterUserDeviceConfigurationInit` for simulated-device setup.

**Verify:** production `IntifaceCentralApp.create()` and `IntifaceCentralApp.buildApp()` behaviour remains unchanged with default options.

### Step 0.3 — Extract public device controls widget

**Files:**
- `lib/page/device_detail_page.dart`
- Optional new file: `lib/widget/device_controls_widget.dart`

`_DeviceControlsSection` is private inside `device_detail_page.dart`, so widget tests cannot render it directly. Extract it to a public widget, for example:

```dart
class DeviceControlsSection extends StatelessWidget {
  final DeviceCubit deviceCubit;

  const DeviceControlsSection({super.key, required this.deviceCubit});
  // Existing _DeviceControlsSection build implementation moves here.
}
```

Then update `DeviceDetailPage` to use `DeviceControlsSection(deviceCubit: deviceCubit)`.

**Verify:** no behaviour change in the detail page, and widget tests can import the public widget.

---

## Phase 1: Test Infrastructure Foundation

**Commit after this phase.** All subsequent phases depend on this.

### Step 1.1 — Enable test dependencies

**File:** `pubspec.yaml`

Uncomment lines 68–69, 71–72, 75 to restore:
```yaml
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  test: ^1.28.0
```

Add new dev_dependencies (after the existing `msix` entry):
```yaml
  bloc_test: ^10.0.0
  mocktail: ^1.0.4
  alchemist: ^0.14.0
```

Run `flutter pub get` to verify resolution.

**Verify:** `flutter test` exits 0 (no test files yet, should print "No tests found").

### Step 1.2 — Create mock declarations

**File:** `test/helpers/mocks.dart`

Central file declaring all mocktail mocks. Import the real types and declare mock classes:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

// Provider/repository mocks (for BLoC unit tests)
class MockEngineProvider extends Mock implements EngineProvider {}
class MockEngineRepository extends Mock implements EngineRepository {}

// BLoC/Cubit mocks (for widget tests — stream/event only, not sync getters)
class MockEngineControlBloc extends MockBloc<EngineControlEvent, EngineControlState>
    implements EngineControlBloc {}
class MockDeviceManagerBloc extends MockBloc<DeviceManagerEvent, DeviceManagerState>
    implements DeviceManagerBloc {}
class MockNavigationCubit extends MockCubit<NavigationPage>
    implements NavigationCubit {}
class MockUpdateBloc extends MockBloc<UpdateEvent, UpdateState>
    implements UpdateBloc {}
class MockErrorNotifierCubit extends MockCubit<ErrorNotifierState>
    implements ErrorNotifierCubit {}
```

Imports will need adjusting based on exact import paths. The implementor should read the actual BLoC/Cubit files to get correct import paths and generic type params.

**Note:** `IntifaceConfigurationCubit`, `GuiSettingsCubit`, `UserDeviceConfigurationCubit`, and `DeviceCubit` have heavy synchronous getter usage. Do not use raw unstubbed mocks for these; create shared stubbing helpers or narrowly scoped fakes in `fake_blocs.dart` (Step 1.3).

### Step 1.3 — Create provider doubles for getter-heavy Cubits

**File:** `test/helpers/fake_blocs.dart`

Several widgets call synchronous getters on Cubits (not just `BlocBuilder` stream state). Pure mocks break if every getter is manually stubbed in every test, but fully implementing concrete Cubit classes is also expensive because several have private constructors and broad public getter/setter surfaces.

Use this order of preference:

1. Use a real Cubit with isolated platform state where cheap (`SharedPreferences.setMockInitialValues`, `IntifacePaths.initForTest(...)`).
2. Use a `MockCubit`/`MockBloc` plus helper functions that stub the common synchronous getters.
3. Only create a fake implementation if it can realistically implement the full public API that tests/widgets call.

**Provider doubles needed:**

1. **`IntifaceConfigurationCubit`**
   - Prefer a real Cubit initialized with `SharedPreferences.setMockInitialValues(...)` for tests that call setters or `getEngineOptions()`.
   - For pure widget rendering tests, provide `MockIntifaceConfigurationCubit` plus a helper like `stubConfigurationCubit(...)` that stubs `state`, `stream`, `appMode`, `themeModeSetting`, `useProcessEngine`, `websocketServerPort`, `websocketServerAllInterfaces`, update-version getters, and any getter used by the widget under test.

2. **`GuiSettingsCubit`**
   - Prefer a real Cubit initialized with mock shared preferences.
   - If mocked, stub `state`, `stream`, `getExpansionValue()`, `getWindowSize()`, and `getWindowPosition()`.

3. **`UserDeviceConfigurationCubit`**
   - Use a mock/stub helper for widget tests: `configs`, `specifiers`, `serialSpecifiers`, `simulatedArchetypes`, `simulatedDevices`, `protocols`, `createError`, `state`, and `stream`.
   - If a test exercises configuration mutation methods (`updateDefinition`, `removeDeviceConfig`, etc.), either use `RustLib.initMock(...)` with a real Cubit or explicitly stub/verify those methods on the mock.

4. **`DeviceCubit` and output Cubits**
   - For device list/detail tests, provide a fake or mock `DeviceCubit` with stable `device`, `outputs`, `inputs`, `observations`, `state`, and `stream`.
   - For slider tests, prefer real `ValueOutputCubit`/`PositionWithDurationOutputCubit` with mocked `ButtplugClientDeviceFeature` so the test can verify `setValue()`/command dispatch behaviour. If a fake output Cubit is used, it must expose the same sync getters the widget reads and record value changes.

**Important:** If a double uses `implements SomeCubit`, Dart requires the full public interface, including getters, setters, and methods. Do not create half-fakes that only implement `state`; they will not compile or will fail as soon as widgets call mutation paths.

### Step 1.4 — Create RustLib mock lifecycle helpers

**File:** `test/helpers/rust_lib_mock.dart`

`RustLib` (defined in `lib/src/rust/frb_generated.dart:22-83`) has:
- `static Future<void> init(...)` — async, loads real Rust .so/.dylib
- `static void initMock({required RustLibApi api})` — sync, injects a mock API
- `static void dispose()` — cleans up

Helper functions:

```dart
import 'package:intiface_central/src/rust/frb_generated.dart';
import 'package:mocktail/mocktail.dart';

class MockRustLibApi extends Mock implements RustLibApi {}

void setUpRustLibMock([RustLibApi? api]) {
  try { RustLib.dispose(); } catch (_) {}
  RustLib.initMock(api: api ?? MockRustLibApi());
}

void tearDownRustLibMock() {
  try { RustLib.dispose(); } catch (_) {}
}
```

The try/catch around dispose handles the case where RustLib wasn't initialized.

### Step 1.5 — Create FFI opaque object fixtures

**File:** `test/helpers/ffi_fixtures.dart`

The generated FFI types (`ExposedUserDeviceIdentifier`, `ExposedServerDeviceDefinition`, `ExposedServerDeviceFeature`, etc.) are abstract classes implementing `RustOpaqueInterface`. Their constructors call `RustLib.instance.api` — they can't be instantiated without either a real Rust library or a mock.

Create mocktail-backed fixtures:

```dart
import 'package:mocktail/mocktail.dart';

class MockExposedUserDeviceIdentifier extends Mock
    implements ExposedUserDeviceIdentifier {}

class MockExposedServerDeviceDefinition extends Mock
    implements ExposedServerDeviceDefinition {}

class MockExposedServerDeviceFeature extends Mock
    implements ExposedServerDeviceFeature {}

class MockExposedServerDeviceFeatureOutput extends Mock
    implements ExposedServerDeviceFeatureOutput {}

class MockExposedServerDeviceFeatureOutputProperties extends Mock
    implements ExposedServerDeviceFeatureOutputProperties {}
```

Then factory functions returning configured mocks:

```dart
ExposedUserDeviceIdentifier fakeDeviceIdentifier({
  String address = 'test-device-0',
  String protocol = 'lovense',
  String? identifier,
}) {
  final mock = MockExposedUserDeviceIdentifier();
  when(() => mock.address).thenReturn(address);
  when(() => mock.protocol).thenReturn(protocol);
  when(() => mock.identifier).thenReturn(identifier);
  return mock;
}

ExposedServerDeviceDefinition fakeDeviceDefinition({
  required String name,
  bool allow = true,
  bool deny = false,
  List<ExposedServerDeviceFeature> features = const [],
  // ... other fields with defaults
}) {
  final mock = MockExposedServerDeviceDefinition();
  when(() => mock.name).thenReturn(name);
  when(() => mock.allow).thenReturn(allow);
  when(() => mock.deny).thenReturn(deny);
  when(() => mock.features).thenReturn(features);
  // ... stub remaining getters
  return mock;
}
```

The implementor should read `lib/src/rust/api/device_config.dart:35-157` for the full interface list and stub all getters.

### Step 1.6 — Create BLoC state fixtures

**File:** `test/helpers/bloc_fixtures.dart`

Pre-built state objects for common scenarios. Since state classes don't implement `Equatable`, tests will use `isA<T>()` matchers — but fixtures are still useful for `when().thenReturn()` and widget rendering setup.

```dart
// Engine states
final engineStopped = EngineStoppedState();
final engineStarting = EngineStartingState();
final engineStarted = EngineStartedState();

// Device connected state (needs FFI fixture)
DeviceConnectedState deviceConnected({
  String name = 'Test Vibrator',
  String? displayName,
  int index = 0,
}) => DeviceConnectedState(
  /* fields from constructor — implementor should read
     EngineControlBloc state classes at lib/bloc/engine/engine_control_bloc.dart:15-63 */
);
```

### Step 1.7 — Create device data fixtures

**File:** `test/helpers/device_fixtures.dart`

Static fake device data for widget tests. This wraps `ffi_fixtures.dart` factories into higher-level scenarios:

```dart
/// A single-feature vibrator for simple widget tests
DeviceTestFixture singleVibrator() => DeviceTestFixture(
  identifier: fakeDeviceIdentifier(address: 'vibrator-0', protocol: 'lovense'),
  definition: fakeDeviceDefinition(name: 'Test Vibrator', features: [
    fakeVibrateFeature(),
  ]),
);

/// A multi-feature device for complex widget tests
DeviceTestFixture multiFeatureDevice() => DeviceTestFixture(
  identifier: fakeDeviceIdentifier(address: 'multi-0', protocol: 'lovense'),
  definition: fakeDeviceDefinition(name: 'Test Multi', features: [
    fakeVibrateFeature(),
    fakeRotateFeature(),
    fakeLinearFeature(),
  ]),
);
```

The implementor should define `DeviceTestFixture` as a simple data holder and create feature factory functions.

### Step 1.8 — Create pumpApp helper

**File:** `test/helpers/pump_app.dart`

The core test utility. Wraps a widget in `MaterialApp` + `MultiBlocProvider` with mocked/fake BLoCs. Never calls `IntifaceCentralApp.create()` or `buildApp()`.

```dart
Future<void> pumpApp(
  WidgetTester tester, {
  required Widget child,
  // Optional BLoC/Cubit overrides — defaults to mocks/fakes with sensible state
  EngineControlBloc? engineControlBloc,
  DeviceManagerBloc? deviceManagerBloc,
  NavigationCubit? navigationCubit,
  IntifaceConfigurationCubit? configCubit,
  GuiSettingsCubit? guiSettingsCubit,
  UserDeviceConfigurationCubit? userConfigCubit,
  // ... other providers from IntifaceCentralApp.buildApp() lines 519-535
  Size windowSize = const Size(800, 600),
  double textScaleFactor = 1.0,
}) async {
  // Create defaults for anything not provided
  final engine = engineControlBloc ?? _defaultEngineControlBloc();
  // ... etc

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: windowSize, textScaler: TextScaler.linear(textScaleFactor)),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<EngineControlBloc>.value(value: engine),
          BlocProvider<DeviceManagerBloc>.value(value: deviceManager),
          // ... all providers matching IntifaceCentralApp.buildApp() line 519-535
        ],
        child: MaterialApp(
          // Pin theme for determinism
          theme: /* match production theme */,
          home: child,
        ),
      ),
    ),
  );
}
```

The implementor should read `IntifaceCentralApp.buildApp()` lines 519-535 in `lib/intiface_central_app.dart` for the exact provider list and replicate it. The `IntifaceCentralView` widget (the `child` of `MultiBlocProvider` in production) expects all those providers to be available.

**Important:** `pumpApp` must provide ALL providers that `IntifaceCentralView` and its descendants might `context.read<T>()`. Missing providers cause runtime errors in widget tests.

### Step 1.9 — Smoke test

**File:** `test/bloc/engine/engine_control_bloc_test.dart`

One minimal test proving the harness works:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

// ... imports for EngineControlBloc, MockEngineRepository, states

void main() {
  group('EngineControlBloc', () {
    late MockEngineRepository mockRepo;

    setUp(() {
      mockRepo = MockEngineRepository();
      // Stub the stream getter that EngineControlBloc subscribes to
      when(() => mockRepo.messageStream).thenAnswer((_) => const Stream.empty());
    });

    test('initial state is EngineStoppedState', () {
      final bloc = EngineControlBloc(mockRepo);
      expect(bloc.state, isA<EngineStoppedState>());
      bloc.close();
    });
  });
}
```

The implementor should read `EngineControlBloc` constructor at `lib/bloc/engine/engine_control_bloc.dart:115` and `EngineRepository` at `lib/bloc/engine/engine_repository.dart` to understand what streams/methods need stubbing.

**Verify:** `flutter test test/bloc/engine/engine_control_bloc_test.dart` passes.

---

## Phase 2: BLoC Unit Tests

**Commit after this phase.**

### Step 2.1 — EngineControlBloc tests

**File:** `test/bloc/engine/engine_control_bloc_test.dart` (extend the smoke test)

Test groups:

1. **Start → Started flow:**
   - Mock `EngineRepository.messageStream` to emit engine lifecycle messages
   - Add `EngineControlEventStart` with a mock `EngineOptionsExternal`
   - Assert state sequence includes `isA<EngineStartingState>()` then `isA<EngineStartedState>()`

2. **Start failure → Stopped:**
   - Mock `EngineRepository.start(...)` to throw
   - Assert state returns to `isA<EngineStoppedState>()`
   - Do not model this by emitting `engineStopped`; current `EngineControlBloc` ignores `engineStopped` messages and only emits stopped on start exception or stream completion

3. **Device connected/disconnected:**
   - Mock repository stream to emit device-connected message
   - Assert `isA<DeviceConnectedState>()` with correct device name/index
   - Then emit device-disconnected, assert `isA<DeviceDisconnectedState>()`

**Key detail:** `EngineControlBloc` calls `await _repo.start(...)`, emits `EngineStartingState`, then uses `await emit.forEach(_repo.messageStream, onData: ...)`. The mock needs `when(() => mockRepo.start(options: any(named: 'options'))).thenAnswer((_) async {})` and `when(() => mockRepo.messageStream).thenAnswer((_) => streamController.stream)` where the test drives and closes the `StreamController`.

**State assertions:** Use `isA<T>()` and `having()` matchers since states don't implement `Equatable`:
```dart
expect: () => [
  isA<EngineStartingState>(),
  isA<DeviceConnectedState>().having((s) => s.name, 'name', 'Test Device'),
],
```

The implementor must read `EngineControlBloc` event handlers at `lib/bloc/engine/engine_control_bloc.dart:115-220+` and `EngineRepository` message types to understand the message→state mapping.

### Step 2.2 — DeviceManagerBloc tests

**File:** `test/bloc/device/device_manager_bloc_test.dart`

Constructor takes `(Stream<EngineControlState>, SendFunc, Stream<DeviceOutputObservation> Function())`.

Test groups:

1. **Device added:** Emit `DeviceManagerDeviceAddedEvent` with a mock `ButtplugClientDevice`, verify `isA<DeviceManagerDeviceOnlineState>()` and `bloc.devices` list grows.

2. **Device removed:** Add then remove, verify `isA<DeviceManagerDeviceOfflineState>()` and `bloc.devices` shrinks.

3. **Engine stopped clears devices:** Emit `DeviceManagerEngineStoppedEvent`, verify device list empties.

The implementor should read `DeviceManagerBloc` at `lib/bloc/device/device_manager_bloc.dart:59-145` for the full event handler logic. `ButtplugClientDevice` is from the external `buttplug_dart` package — will need a mock for that too (add to `mocks.dart`).

### Step 2.3 — Cubit tests

**File:** `test/bloc/configuration/configuration_bloc_test.dart`

Test `IntifaceConfigurationCubit` state transitions. Since it uses a private constructor with async `create()` factory that reads `SharedPreferences`:

- Use `SharedPreferences.setMockInitialValues({})` in setUp
- Call `IntifacePaths.initForTest(tempDir)` before testing `getEngineOptions()` or any setter/path-dependent behaviour
- Call `IntifaceConfigurationCubit.create()`
- Test setter→getter roundtrips (e.g., set `useSimulatedDevices = true`, verify getter returns true)

**File:** `test/bloc/util/navigation_cubit_test.dart`

Simple — `NavigationCubit()` with no deps, `emit(NavigationPage.settings)`, verify state.

**Verify:** `flutter test test/bloc/` — all pass.

---

## Phase 3: Widget + Golden Tests

**Commit after this phase.**

### Step 3.1 — DeviceListCard widget test

**File:** `test/widget/device_list_card_test.dart`

`DeviceListCard` is at `lib/widget/device_list_card_widget.dart`. Read it to understand:
- What constructor params it takes
- What BLoCs/Cubits it reads from context
- What it renders in different states

Test:
- Render with a fake `DeviceCubit` for a connected device → verify device name text appears
- Render with null/offline device state → verify disconnected UI
- Verify allow/deny badges render correctly based on `ExposedServerDeviceDefinition.allow`/`.deny`

Use `pumpApp()` helper with the widget as child. Provide fake BLoCs via constructor or provider overrides.

### Step 3.2 — Control widget test

**File:** `test/widget/control_widget_test.dart`

Test the engine start/stop controls. Read `lib/widget/control_widget.dart` (or wherever the start/stop button lives) to understand its BLoC dependencies.

- Mock `EngineControlBloc` in stopped state → verify "Start" button appears
- Tap start via `find.byTooltip('Start Server')` or the play icon — the button label is a tooltip, not visible `Text`
- Verify `EngineControlEventStart` was added to the bloc
- Mock in started state → verify "Stop" button appears
- Tap stop via `find.byTooltip('Stop Server')` and verify `EngineControlEventStop` was added

### Step 3.3 — Device detail controls test

**File:** `test/widget/device_detail_controls_test.dart`

Test slider interaction on the device detail page. Read `lib/page/device_detail_page.dart` to find the controls section.

- Create fake `DeviceCubit` with output features
- Render the public `DeviceControlsSection` extracted in Phase 0 (not the private `_DeviceControlsSection`)
- Find slider, drag it
- Verify the `DeviceOutputCubit` received the value change or the mocked `ButtplugClientDeviceFeature.runOutput(...)` was called

This test needs real or fake `DeviceOutputCubit` instances since widgets read sync getters from them. Prefer real output Cubits with mocked `ButtplugClientDeviceFeature` unless that becomes more brittle than a focused recording fake.

### Step 3.4 — Device page navigation test

**File:** `test/page/device_page_test.dart`

Test navigation from device list → device detail. Read `lib/page/device_page.dart` — it uses internal `setState` with `_DeviceSubPage` enum.

- Render `DevicePage` with a fake `DeviceManagerBloc` containing one device
- Tap the device card
- Verify detail page appears (find a widget unique to detail view)
- Tap back → verify list view returns

### Step 3.5 — Golden tests: device list card

**File:** `test/golden/device_list_card_golden_test.dart`

Use Alchemist `goldenTest()`:

```dart
import 'package:alchemist/alchemist.dart';

void main() {
  goldenTest(
    'DeviceListCard states',
    fileName: 'device_list_card_states',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'connected vibrator',
          child: /* pumpApp-wrapped card with fake connected state */,
        ),
        GoldenTestScenario(
          name: 'disconnected',
          child: /* card with offline state */,
        ),
        GoldenTestScenario(
          name: 'denied device',
          child: /* card with deny=true */,
        ),
      ],
    ),
  );
}
```

**Important for determinism (AC4.5):**
- Pin viewport size via `constraints` in GoldenTestScenario
- Use fixed theme (not system theme)
- No live sparklines or observation charts — exclude or replace with static data
- No timestamps or dynamic text
- Set `textScaleFactor: 1.0`

**Generate reference images:** `flutter test --update-goldens test/golden/device_list_card_golden_test.dart`

### Step 3.6 — Golden tests: control widgets

**Files:**
- `test/golden/control_widget_golden_test.dart`
- `test/golden/device_controls_golden_test.dart`

Same pattern as 3.5. `control_widget_golden_test.dart` should cover engine stopped/starting/running/client-connected states. `device_controls_golden_test.dart` should cover sliders at 0%, 50%, 100%, and button active/inactive states using `DeviceControlsSection`.

**Verify:** `flutter test test/widget/ test/page/ test/golden/` — all pass.

---

## Optional Command Probe Seam

Only implement this phase if `DeviceOutputObservation` cannot reliably prove that UI interactions reached the simulated Rust device.

### Step 3.5.1 — Add a simulator command inspection API

**Files:**
- Rust API module that owns/has access to simulated device state
- Generated FRB bindings via `flutter_rust_bridge_codegen generate`
- `integration_test/helpers/command_probe.dart`

Add the narrowest possible test/debug-facing API for last-command inspection, for example:

```rust
pub fn get_last_simulated_device_output(address: String) -> Option<ExposedSimulatedDeviceOutput> {
  // Read simulator state and return the last output command for that device.
}
```

Keep this API generic enough to be useful to Rust tests too, and avoid coupling it to Flutter widget names. If output observations are sufficient, do not add this seam.

---

## Phase 4: Integration Tests with Simulated Engine

**Commit after this phase.**

### Step 4.1 — App environment isolation

**File:** `integration_test/helpers/app_environment.dart`

Integration tests must not touch real user preferences, config files, or log directories. Create helpers that:

1. Set `SharedPreferences.setMockInitialValues({})` with test defaults
2. Call `IntifacePaths.initForTest(tempDir)` from Phase 0 to point config/log/news/engine paths at a temporary directory
3. Provide flags to skip:
   - Window/tray manager initialization (`windowManager.ensureInitialized()`)
   - Discord integration
   - Update checking (both desktop and mobile)
   - Sentry initialization
   - Bluetooth permission requests

The implementor should read `IntifaceCentralApp.buildApp()` at `lib/intiface_central_app.dart:172-536` carefully — all 9 phases of the bootstrap are documented in the codebase investigation. Each side effect needs to be either isolated or disabled.

```dart
class TestAppEnvironment {
  late Directory tempDir;

  Future<void> setUp() async {
    tempDir = await Directory.systemTemp.createTemp('intiface_test_');
    SharedPreferences.setMockInitialValues({
      // defaults that skip update checks, set test paths, etc.
      'checkForUpdateOnStart': false,
      'startServerOnStartup': false,
      'useSimulatedDevices': true,
      'trayIconMode': 'none',
      'useDiscordRichPresence': false,
    });
    await IntifacePaths.initForTest(tempDir);
  }

  Future<void> tearDown() async {
    await tempDir.delete(recursive: true);
  }
}
```

### Step 4.2 — Test-controlled app bootstrap

**File:** `integration_test/test_app.dart`

A test entry point that calls the production bootstrap with controlled options. This is NOT a mock — it uses real BLoCs, real `EngineRepository`, real `LibraryEngineProvider`, and real `RustLib.init()`. It just disables side effects through the Phase 0 bootstrap options.

```dart
Future<Widget> createTestApp({
  Future<void> Function()? afterRustInit,
  Future<void> Function(UserDeviceConfigurationCubit userConfigCubit)?
      afterUserDeviceConfigurationInit,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final app = await IntifaceCentralApp.create();
  return app.buildApp(
    options: IntifaceCentralBootstrapOptions(
      initializePaths: false, // TestAppEnvironment already called IntifacePaths.initForTest(...)
      initializeWindowing: false,
      initializeTray: false,
      initializeUpdates: false,
      initializeSentry: false,
      initializeDiscord: false,
      requestPlatformPermissions: false,
      afterRustInit: afterRustInit,
      afterUserDeviceConfigurationInit: afterUserDeviceConfigurationInit,
    ),
  );
}
```

The implementor should not replicate the provider list from `lib/intiface_central_app.dart`. Keep the provider tree in one production builder. If manual construction is unavoidable during the refactor, wire `DeviceManagerBloc` exactly like production: `DeviceManagerBloc(engineControlBloc.stream, engineControlBloc.add, () => engineRepo.observationStream)`. Do not pass `engineRepo.send`; `DeviceManagerBloc` expects a `SendFunc` that accepts `EngineControlEvent`.

### Step 4.3 — Simulated device setup helper

**File:** `integration_test/helpers/sim_device_setup.dart`

Wraps the FFI API from `lib/src/rust/api/simulated_devices.dart`:

```dart
Future<void> addTestDevice({
  required String identifier,
  String? displayName,
}) async {
  await addSimulatedDevice(identifier: identifier, displayName: displayName);
}

Future<void> clearTestDevices() async {
  final devices = await getUserSimulatedDevices();
  for (final device in devices) {
    await removeSimulatedDevice(address: device.address);
  }
}

Future<List<ExposedSimulatedDeviceConfigEntry>> listTestDevices() async {
  return getUserSimulatedDevices();
}
```

### Step 4.4 — Command verification probe

**File:** `integration_test/helpers/command_probe.dart`

Proves that UI interactions actually produced Rust-side device output. Two approaches, try in order:

1. **Output observation stream:** If `DeviceOutputObservation` events are flowing, subscribe and verify the expected value arrived after a UI interaction.

2. **Explicit probe API:** If observations aren't sufficient, this may require a small Rust FFI addition that exposes the simulated device's last received command. Flag this as a potential follow-up if the observation approach works.

```dart
Future<void> verifyCommandReachedDevice({
  required Stream<DeviceOutputObservation> observationStream,
  required int deviceIndex,
  required int featureIndex,
  required double expectedValue,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final observation = await observationStream
    .where((o) => o.deviceIndex == deviceIndex && o.featureIndex == featureIndex)
    .first
    .timeout(timeout);
  expect(observation.value, closeTo(expectedValue, 0.01));
}
```

### Step 4.5 — Engine lifecycle integration test

**File:** `integration_test/flows/engine_lifecycle_test.dart`

```dart
void main() {
  final env = TestAppEnvironment();

  setUp(() async => await env.setUp());
  tearDown(() async {
    await clearTestDevices();
    RustLib.dispose();
    await env.tearDown();
  });

  testWidgets('engine starts and stops', (tester) async {
    await tester.pumpWidget(await createTestApp());
    await tester.pumpAndSettle();

    // Find and tap start button
    await tester.tap(find.byTooltip('Start Server'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify engine running state (check for stop button or status indicator)
    expect(find.byTooltip('Stop Server'), findsOneWidget);

    // Stop
    await tester.tap(find.byTooltip('Stop Server'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byTooltip('Start Server'), findsOneWidget);
  });
}
```

The implementor should read the actual UI to find the correct button text/icons for start/stop.

### Step 4.6 — Device connect + control integration test

**File:** `integration_test/flows/device_connect_test.dart`

```dart
testWidgets('connect and control simulated vibrator', (tester) async {
  // Create simulated device after RustLib and the device config manager are initialized.
  await tester.pumpWidget(await createTestApp(
    afterUserDeviceConfigurationInit: (userConfigCubit) async {
      await addTestDevice(identifier: 'lovense-domi', displayName: 'Test Domi');
      await userConfigCubit.update();
    },
  ));
  await tester.pumpAndSettle();

  // TestAppEnvironment should set useSimulatedDevices = true
  // Start engine
  await tester.tap(find.byTooltip('Start Server'));
  await tester.pumpAndSettle(const Duration(seconds: 5));

  // Device should auto-connect and appear in list
  // Navigate to devices tab
  // Verify device name appears
  expect(find.text('Test Domi'), findsOneWidget);

  // Tap into device detail
  await tester.tap(find.text('Test Domi'));
  await tester.pumpAndSettle();

  // Interact with controls (find slider, drag it)
  // Verify command reached device via observation probe

  // Cleanup
  await clearTestDevices();
});
```

### Step 4.7 — Integration test entry point

**File:** `integration_test/app_test.dart`

```dart
import 'flows/engine_lifecycle_test.dart' as engine_lifecycle;
import 'flows/device_connect_test.dart' as device_connect;

void main() {
  engine_lifecycle.main();
  device_connect.main();
}
```

### Step 4.8 — CI workflow

**File:** `.github/workflows/test.yml`

New workflow file, separate from the existing `central.yml` (which is tag-triggered release builds).

```yaml
name: Tests
on:
  pull_request:
    branches: [main, dev]

concurrency:
  group: test-${{ github.head_ref || github.ref }}
  cancel-in-progress: true

jobs:
  unit-widget-golden:
    runs-on: macos-latest
    defaults:
      run:
        working-directory: ./intiface-central
    steps:
      - uses: actions/checkout@v4
        with:
          repository: buttplugio/buttplug
          path: buttplug
      - uses: actions/checkout@v4
        with:
          repository: buttplugio/buttplug_dart
          path: buttplug_dart
      - uses: actions/checkout@v4
        with:
          path: intiface-central
      - uses: dtolnay/rust-toolchain@stable
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter test test/golden/
        name: golden tests
```

Integration tests run on merge to main (more expensive):

```yaml
  integration:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: macos-latest
    defaults:
      run:
        working-directory: ./intiface-central
    steps:
      # same checkout + toolchain setup
      - run: flutter test integration_test/
        name: integration tests
```

The implementor should update `actions/checkout` to v4 and `dtolnay/rust-toolchain` instead of the deprecated `actions-rs/toolchain@v1` used in the existing workflow.

**Verify:** Push branch, confirm workflow triggers on PR.

---

## Phase Summary

| Phase | Steps | Agent | Key verification |
|-------|-------|-------|-----------------|
| 0: Production Seams | 0.1–0.3 | sonnet | app compiles; paths can initialize under temp dir; public controls widget imports |
| 1: Foundation | 1.1–1.9 | sonnet | `flutter test` passes smoke test |
| 2: BLoC Tests | 2.1–2.3 | sonnet | `flutter test test/bloc/` all pass |
| 3: Widget + Golden | 3.1–3.6 | sonnet | `flutter test test/widget/ test/page/ test/golden/` all pass |
| Optional: Command Probe | optional | sonnet/opus if Rust simulator changes get complex | only if observations cannot verify command delivery |
| 4: Integration | 4.1–4.8 | sonnet (4.1–4.2 may need opus for bootstrap complexity) | `flutter test integration_test/` passes |
