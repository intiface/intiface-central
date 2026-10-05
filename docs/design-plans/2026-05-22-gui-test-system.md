# GUI Test System Design

## Summary

Intiface Central has no test infrastructure — `flutter_test`, `integration_test`, and `test` are all commented out in `pubspec.yaml`, and no `test/` or `integration_test/` directory exists. This design adds a full testing pyramid: BLoC unit tests, widget behavioural tests, golden visual regression tests, and integration tests powered by the simulated device engine.

The architecture exploits two existing strengths: (1) constructor-injected dependencies throughout the BLoC→Repository→Provider chain make most layers independently mockable without refactoring, and (2) the simulated device engine in Rust provides a programmatically-controllable hardware substitute for integration tests — real FFI round-trips, fake hardware. Unit tests mock `EngineProvider`, repositories, or `RustLibApi` depending on the boundary under test. Widget and golden tests use a mix of `mocktail` mocks and small fake Cubits/BLoCs because several widgets read synchronous Cubit getters in addition to stream state. Integration tests launch a test-controlled app bootstrap with the real Rust engine and sim devices created via FFI, not the production bootstrap unchanged.

## Definition of Done

All four test layers operational and passing: BLoC unit tests covering engine lifecycle and device management state transitions, widget tests verifying UI responses to state changes, golden tests capturing reference images for deterministic key components, and integration tests exercising full user journeys through the simulated device engine. A `flutter test` run executes unit + widget + golden tests. Integration tests run separately via `flutter test integration_test/`. CI pipeline configured with a concrete PR test workflow and macOS integration/golden runners. Test helpers isolate FFI mock lifecycle, shared preferences, filesystem paths, and app bootstrap side effects.

**Out of scope:** Cross-platform CI (Linux/Windows runners), Patrol native interaction tests, real hardware test automation, performance benchmarking, test coverage for the Rust side (tested independently via `cargo test`).

## Acceptance Criteria

### gui-test-system.AC1: Test infrastructure bootstrapped
- **gui-test-system.AC1.1 Success:** `flutter_test`, `integration_test`, `test`, `bloc_test`, `mocktail`, and `alchemist` are active dev_dependencies
- **gui-test-system.AC1.2 Success:** `flutter test` runs without errors (even if no tests exist yet)
- **gui-test-system.AC1.3 Success:** Shared test helpers exist: mock declarations, fake Cubit/BLoC implementations where synchronous getters are needed, `pumpApp()` widget wrapper, BLoC state fixtures, and FFI object fixtures
- **gui-test-system.AC1.4 Success:** `RustLib.initMock(...)`/`RustLib.dispose()` lifecycle helpers exist for tests that touch generated FFI types without loading the real Rust library

### gui-test-system.AC2: BLoC unit tests
- **gui-test-system.AC2.1 Success:** `EngineControlBloc` tests cover start→started, start failure→stopped (current behaviour), and device connected/disconnected state transitions
- **gui-test-system.AC2.2 Success:** `DeviceManagerBloc` tests cover device list add/remove/update
- **gui-test-system.AC2.3 Success:** At least one Cubit test covers settings or navigation state changes
- **gui-test-system.AC2.4 Success:** All BLoC tests mock at `EngineProvider` or `RustLibApi` level — no real Rust execution
- **gui-test-system.AC2.5 Success:** State assertions use type/predicate matchers unless state classes gain value equality (`Equatable` or equivalent)

### gui-test-system.AC3: Widget behavioural tests
- **gui-test-system.AC3.1 Success:** `DeviceListCard` widget test verifies rendering in connected and disconnected states
- **gui-test-system.AC3.2 Success:** Device detail control widget test verifies slider interaction updates state and dispatches an output command through a fake device output
- **gui-test-system.AC3.3 Success:** Page-level test verifies navigation between device list and device detail
- **gui-test-system.AC3.4 Success:** All widget tests use mocked or fake BLoCs/Cubits via `MultiBlocProvider`, with no production app bootstrap and no real Rust execution

### gui-test-system.AC4: Golden visual regression tests
- **gui-test-system.AC4.1 Success:** Alchemist golden tests generate reference images for device list cards in multiple deterministic states, excluding live sparklines/observation charts
- **gui-test-system.AC4.2 Success:** Golden tests generate reference images for control widgets
- **gui-test-system.AC4.3 Success:** Reference images are committed to the repository under `test/golden/goldens/`
- **gui-test-system.AC4.4 Success:** `flutter test test/golden/` passes when widget rendering matches reference images
- **gui-test-system.AC4.5 Success:** Golden tests pin viewport, theme, text scale, animation state, and font strategy so local macOS and CI output are reproducible

### gui-test-system.AC5: Integration tests with simulated engine
- **gui-test-system.AC5.1 Success:** Integration test starts the real engine through a test-controlled app bootstrap, creates a simulated device via FFI, and verifies it appears in the device list
- **gui-test-system.AC5.2 Success:** Integration test connects to a simulated device, interacts with control widgets, and proves the command reached Rust via output observation or an explicit test probe
- **gui-test-system.AC5.3 Success:** Integration test exercises engine start→stop lifecycle
- **gui-test-system.AC5.4 Success:** Simulated device cleanup runs after each test (no leaked state between tests)
- **gui-test-system.AC5.5 Success:** Integration test bootstrap isolates preferences, app support directory, update checks, tray/window setup, and network-dependent startup behaviour

## Glossary

- **BLoC (Business Logic Component)**: Flutter state management pattern separating UI from business logic using streams. This project uses `flutter_bloc`; cubits are a simplified variant.
- **Cubit**: A lightweight BLoC-family state class that emits state changes via `emit()`. Used throughout the app for settings, navigation, and device state.
- **EngineProvider**: Abstract Dart interface wrapping all Rust engine lifecycle operations (start, stop, send message). `LibraryEngineProvider` is the real FFI implementation; `TestEngineProvider` is an existing stub.
- **RustLibApi**: Auto-generated abstract class from `flutter_rust_bridge` that centralizes all Rust FFI calls. Mockable via `mocktail` to test Dart logic without any Rust execution.
- **mocktail**: Dart mocking library. No code generation needed — mock classes are one-liners: `class MockFoo extends Mock implements Foo {}`.
- **bloc_test**: Testing utility for BLoC/Cubit. Provides `blocTest()` function for arranging conditions, acting on events, and asserting state emission sequences.
- **Alchemist**: Golden test framework by Betterment. Generates deterministic reference images for widget snapshots. Supports platform tests (real fonts) and CI tests (Ahem font).
- **Golden test**: Visual regression test that renders a widget, captures a screenshot, and compares it pixel-by-pixel against a stored reference image.
- **Simulated device engine**: Rust-side feature that creates virtual Buttplug devices without real hardware. Devices auto-connect on scan and accept commands via the normal Buttplug protocol.
- **pumpApp()**: Shared test helper that wraps a widget under test in `MaterialApp` + `MultiBlocProvider` with mocked or fake BLoCs/Cubits, eliminating boilerplate from every widget test.
- **Test-controlled app bootstrap**: A test entry point that builds the same production widget tree and real engine wiring, but lets tests inject temporary paths/preferences, disable tray/window/update side effects, and run setup after `RustLib.init()`.
- **Opaque FFI fixture**: Test double for generated `flutter_rust_bridge` opaque classes such as `ExposedServerDeviceDefinition` and `ExposedUserDeviceIdentifier`. These are usually `mocktail` mocks or objects returned through `RustLib.initMock(...)`, because direct constructors may call `RustLib.instance.api`.
- **Command verification probe**: An integration-test-only observation mechanism that proves a UI interaction produced a Rust-side simulated-device output, either by reading `DeviceOutputObservation` events or by exposing the simulator's last command through a small FFI API.

## Architecture

### Test Pyramid

```
┌─────────────────────────────────────────┐
│  Integration Tests (simulated engine)   │  Real Rust engine, fake hardware
│  Full app, sim devices, user journeys   │  Slow, high fidelity
├─────────────────────────────────────────┤
│  Golden Tests (Alchemist)               │  Mocked/fake BLoCs, snapshot comparison
│  Visual regression for key components   │  Medium speed, catches layout bugs
├─────────────────────────────────────────┤
│  Widget Tests                           │  Mocked/fake BLoCs, behavioural
│  Tap/interact, verify UI responds       │  Fast, catches interaction bugs
├─────────────────────────────────────────┤
│  BLoC Unit Tests                        │  Mocked providers/repositories
│  State transitions, event handling      │  Fastest, catches logic bugs
└─────────────────────────────────────────┘
```

### Mock Boundaries

| Layer | What's real | What's mocked |
|-------|-------------|---------------|
| BLoC unit | BLoC logic, event→state transitions | `EngineProvider`, `RustLibApi`, repositories |
| Widget | Widget rendering, user interaction | BLoCs/Cubits via `MockBloc`/`MockCubit` or purpose-built fakes for synchronous getters |
| Golden | Widget rendering | Same as widget tests, plus frozen animation/timer/chart state |
| Integration | Production widget tree + real Rust engine + FFI, launched through test bootstrap | Hardware (replaced by simulated device engine), production update/tray/window side effects |

The key architectural insight: the existing dependency chain — Widget → BLoC → Repository → Provider → FFI — uses constructor injection at most boundaries. Tests can intercept at those layers without large refactors. The exceptions are generated FFI object construction, `DeviceConfigManager` direct FFI calls, and app bootstrap side effects. Those are handled explicitly through FFI lifecycle helpers, opaque fixtures, and a test-controlled integration bootstrap instead of being left implicit.

### File Structure

```
test/
├── bloc/                          # BLoC unit tests
│   ├── engine/
│   │   └── engine_control_bloc_test.dart
│   ├── device/
│   │   ├── device_manager_bloc_test.dart
│   │   └── device_cubit_test.dart
│   └── configuration/
│       └── configuration_bloc_test.dart
├── widget/                        # Widget behavioural tests
│   ├── device_list_card_test.dart
│   ├── control_widget_test.dart
│   └── observation_chart_test.dart
├── golden/                        # Golden snapshot tests
│   ├── goldens/                   # Reference images (committed to repo)
│   ├── device_list_card_golden_test.dart
│   └── control_widget_golden_test.dart
├── page/                          # Page-level widget tests
│   ├── device_page_test.dart
│   └── settings_page_test.dart
└── helpers/                       # Shared test utilities
    ├── mocks.dart                 # All mock class declarations
    ├── pump_app.dart              # pumpApp() helper with MultiBlocProvider
    ├── fake_blocs.dart            # Small fake Cubits/BLoCs for widgets that read sync getters
    ├── rust_lib_mock.dart         # RustLib.initMock/dispose lifecycle helpers
    ├── ffi_fixtures.dart          # Opaque FFI object fixtures/mocks
    ├── bloc_fixtures.dart         # Pre-built BLoC states for common scenarios
    └── device_fixtures.dart       # Fake device data for widget/golden tests

integration_test/
├── app_test.dart                  # Main integration test entry point
├── test_app.dart                  # Test-controlled Intiface Central bootstrap
├── flows/
│   ├── engine_lifecycle_test.dart # Start → stop engine
│   ├── device_connect_test.dart   # Scan → connect → control sim device
│   └── device_config_test.dart    # Modify device settings
└── helpers/
    ├── app_environment.dart       # Temporary prefs/paths and side-effect suppression
    ├── command_probe.dart         # Output observation or simulator last-command verification
    └── sim_device_setup.dart      # Simulated device creation/removal via FFI
```

### Shared Test Helpers

**`test/helpers/mocks.dart`** — Central mock declaration file. All mocks in one place, imported by every test.

```dart
class MockEngineProvider extends Mock implements EngineProvider {}
class MockEngineRepository extends Mock implements EngineRepository {}
class MockEngineControlBloc extends MockBloc<EngineControlEvent, EngineControlState>
    implements EngineControlBloc {}
class MockDeviceManagerBloc extends MockBloc<DeviceManagerEvent, DeviceManagerState>
    implements DeviceManagerBloc {}
// ... one mock per BLoC/Cubit used in widget tests
```

Use mocks when the widget only depends on `state`/`stream`/`add`. Use fake Cubits/BLoCs when the widget reads synchronous getters such as `devices`, `configs`, `scanning`, `appMode`, `useProcessEngine`, or `ip`; pure mocks become brittle for those cases.

**`test/helpers/pump_app.dart`** — Wraps a widget under test in the full provider tree with mocked or fake BLoCs/Cubits. Every widget and golden test calls this instead of manually constructing `MultiBlocProvider`.

```dart
Future<void> pumpApp(
  WidgetTester tester, {
  required Widget child,
  EngineControlState? engineState,
  DeviceManagerState? deviceState,
  EngineControlBloc? engineControlBloc,
  DeviceManagerBloc? deviceManagerBloc,
  // ... other overridable states
});
```

`pumpApp()` should also fix `MediaQuery` size, `textScaleFactor`, theme mode, and platform brightness for golden tests, and it should never call `IntifaceCentralApp.create()` or `IntifaceCentralApp.buildApp()`.

**`test/helpers/rust_lib_mock.dart`** — Owns global FFI mock state.

```dart
void setUpRustLibMock(RustLibApi api) {
  RustLib.dispose();
  RustLib.initMock(api: api);
}

void tearDownRustLibMock() {
  RustLib.dispose();
}
```

Every test that touches generated FFI API objects should opt into this helper or use opaque mock fixtures that avoid direct FFI calls.

**`test/helpers/ffi_fixtures.dart`** — Creates mocktail-backed `ExposedUserDeviceIdentifier`, `ExposedServerDeviceDefinition`, feature, output, and range objects. These fixtures are the default source for device list/detail widget data because the generated classes are Rust opaque interfaces, not plain Dart data classes.

**`test/helpers/bloc_fixtures.dart`** — Pre-built states representing common scenarios ("engine running, 2 devices connected", "engine stopped", "start failed and returned to stopped"). Reused across BLoC, widget, and golden tests.

**`test/helpers/device_fixtures.dart`** — Fake device data objects for widget rendering tests. Static data — no FFI dependency.

### Golden Test Strategy

macOS-only CI means we use Alchemist **platform tests** (real font rendering) for both local development and CI. No need for the dual platform/CI test mode that cross-platform projects require.

**What to golden test:**
- Device list cards (connected, disconnected, allow/deny badges, multiple feature types, no live sparklines)
- Control widgets (sliders at various positions, buttons in active/inactive states)
- Settings panels
- Error states, empty states

**What NOT to golden test:**
- Charts with animation (sparklines, observation charts — timing-dependent, flaky)
- Full pages (too brittle — test components in isolation)
- Anything with timestamps or dynamic data

Each golden test file groups related scenarios into a `GoldenTestGroup` so a single reference image captures multiple states of a component.

Golden tests should render with fixed dimensions and deterministic state: no timers, no live `ObservationCubit`, no network-derived text, no current timestamps, no update banners based on external version checks. If chart rendering needs coverage, use behavioural widget tests with a fixed data model instead of pixel snapshots.

### Integration Test Strategy

Integration tests use the real Rust engine with the simulated device engine feature. They do not mock runtime/device behaviour, but they do run through a test-controlled app bootstrap so startup side effects are deterministic. The full Dart→FFI→Rust→simulated hardware→Rust→FFI→Dart round-trip executes for engine and device interactions.

**Test lifecycle:**
1. Initialize a temporary app environment: isolated `SharedPreferences`, app support directory, config files, and logging paths
2. Start the test-controlled app bootstrap, allowing it to call `RustLib.init()` before simulated-device setup
3. Create simulated devices via FFI API (`addSimulatedDevice`) and ensure engine options enable `useSimulatedDevices`
4. Start the engine (triggers scan, sim devices auto-connect)
5. Drive the UI via `WidgetTester` — tap controls, verify visible state changes
6. Verify command delivery through `DeviceOutputObservation` or a test-only simulator command probe
7. Stop engine, remove simulated devices, dispose `RustLib`, and clear temporary state in teardown

**What integration tests uniquely cover:**
- Real FFI serialization/deserialization round-trips
- Engine state machine under real async timing
- Device connection lifecycle with real event ordering
- UI responsiveness to actual Rust-originated async events
- UI command dispatch all the way to simulated-device output handling

**Not covered:** real Bluetooth/USB/serial, platform permission dialogs, performance under real device load.

## Existing Patterns

**Constructor injection:** Core BLoCs take repositories/streams/functions as constructor args, and repositories take providers. This is the core testability enabler for unit tests. Widget tests still need fakes in places where widgets read synchronous getters from Cubits/BLoCs.

**EngineProvider interface:** Abstract class with `LibraryEngineProvider` (real), `ForegroundTaskLibraryEngineProvider` (Android), and `TestEngineProvider` (stub) implementations. Tests mock this interface for BLoC unit tests.

**MultiBlocProvider at app root:** `IntifaceCentralApp.buildApp()` wraps the widget tree in `MultiBlocProvider`. Widget tests replicate this pattern with mocked or fake BLoCs/Cubits via `pumpApp()`.

**BlocBuilder in widgets:** Widgets read state via `BlocBuilder<SpecificBloc, SpecificState>`, `context.read<T>()`, and direct getter access. Tests provide mock BLoCs for stream/event behaviour and fake Cubits/BLoCs where getter-heavy widgets need stable in-memory state.

**Generated FFI mock mode:** `RustLib.initMock(api: mockApi)` allows Dart tests to exercise generated API surfaces without loading the Rust library. Tests using this mode must dispose/reset global FFI state after each test.

**Simulated device FFI API:** `lib/src/rust/api/simulated_devices.dart` exposes simulated device add/list/remove APIs. Integration tests call this directly after the real Rust library is initialized to set up the test world.

**Minimal, explicit divergence from production bootstrap:** Unit/widget/golden tests never call the full app bootstrap. Integration tests build the production widget tree through a test-controlled bootstrap that disables or stubs side effects unrelated to engine/device behaviour: update checks, tray/window management, persistent user paths, and external network-dependent startup.

## Implementation Phases

<!-- START_PHASE_1 -->
### Phase 1: Test Infrastructure Foundation
**Goal:** Enable test dependencies, create shared helpers, and verify the test harness runs.

**Components:**
- Uncomment `flutter_test`, `integration_test`, `test` in `pubspec.yaml` dev_dependencies
- Add `bloc_test`, `mocktail`, `alchemist` to dev_dependencies
- Create `test/helpers/mocks.dart` with mock declarations for all BLoCs, Cubits, and providers
- Create `test/helpers/fake_blocs.dart` with minimal fake Cubits/BLoCs for getter-heavy widgets
- Create `test/helpers/pump_app.dart` with `pumpApp()` helper
- Create `test/helpers/rust_lib_mock.dart` with `RustLib.initMock(...)`/`RustLib.dispose()` lifecycle helpers
- Create `test/helpers/ffi_fixtures.dart` with mocktail-backed opaque FFI object fixtures
- Create `test/helpers/bloc_fixtures.dart` with initial state fixtures
- Create `test/helpers/device_fixtures.dart` with fake device data
- Write one smoke test (e.g., `EngineControlBloc` emits initial state) to prove the harness works

**Dependencies:** None.

**Done when:** `flutter test` runs and the smoke test passes. Covers `gui-test-system.AC1.1`–`gui-test-system.AC1.4`.
<!-- END_PHASE_1 -->

<!-- START_PHASE_2 -->
### Phase 2: BLoC Unit Tests
**Goal:** Test state transitions for the core BLoCs and Cubits using mocked dependencies.

**Components:**
- `test/bloc/engine/engine_control_bloc_test.dart` — start→started, start failure→stopped, device connected/disconnected transitions
- `test/bloc/device/device_manager_bloc_test.dart` — device list add, remove, update
- `test/bloc/device/device_cubit_test.dart` — device online/offline state, feature cubit creation
- `test/bloc/configuration/configuration_bloc_test.dart` — settings state changes
- Mock `EngineProvider` for engine tests, mock `RustLibApi` for areas without provider abstraction
- Use `isA<T>()`, predicates, or `having(...)` matchers for state assertions unless value equality is added to state classes

**Dependencies:** Phase 1 (test helpers and mock declarations).

**Done when:** All BLoC tests pass with mocked dependencies. No real Rust execution in any unit test. Covers `gui-test-system.AC2.1`–`gui-test-system.AC2.5`.
<!-- END_PHASE_2 -->

<!-- START_PHASE_3 -->
### Phase 3: Widget + Golden Tests
**Goal:** Test widget rendering and interaction with mocked/fake BLoCs and Cubits, and establish golden reference images.

**Components:**
- `test/widget/device_list_card_test.dart` — render in connected/disconnected states, verify text and icons
- `test/widget/control_widget_test.dart` — engine start/stop button taps and state verification
- `test/widget/device_detail_controls_test.dart` — slider interaction updates control state and dispatches output commands through fake device outputs
- `test/page/device_page_test.dart` — navigation from list to detail
- `test/golden/device_list_card_golden_test.dart` — Alchemist golden tests with multiple deterministic scenarios per component, excluding live observation charts/sparklines
- `test/golden/control_widget_golden_test.dart` — control widget visual states
- `test/golden/goldens/` — committed reference images

**Dependencies:** Phase 1 (test helpers), Phase 2 (proven mock patterns to reuse).

**Done when:** Widget tests verify behavioural correctness, golden tests pass against committed reference images. Covers `gui-test-system.AC3.1`–`gui-test-system.AC3.4`, `gui-test-system.AC4.1`–`gui-test-system.AC4.5`.
<!-- END_PHASE_3 -->

<!-- START_PHASE_4 -->
### Phase 4: Integration Tests with Simulated Engine
**Goal:** Full user journey tests using the real Rust engine with simulated devices.

**Components:**
- `integration_test/test_app.dart` — test-controlled app bootstrap that builds production providers/widgets while disabling tray/window/update/network side effects
- `integration_test/helpers/app_environment.dart` — temporary prefs, filesystem paths, config files, and cleanup
- `integration_test/helpers/sim_device_setup.dart` — helper functions wrapping simulated device FFI API (add/list/remove devices, configure features if supported)
- `integration_test/helpers/command_probe.dart` — output-observation or simulator last-command verification
- `integration_test/flows/engine_lifecycle_test.dart` — start engine, verify UI shows running state, stop engine
- `integration_test/flows/device_connect_test.dart` — create sim device, start engine, verify device appears, tap into detail, interact with controls, verify command delivery
- `integration_test/flows/device_config_test.dart` — modify device settings, verify persistence
- `integration_test/app_test.dart` — test entry point importing all flow tests
- CI workflow for macOS integration test runner and PR-time unit/widget/golden checks

**Dependencies:** Phases 1–3 (all other test layers operational).

**Done when:** Integration tests pass with real Rust engine and simulated devices. Test cleanup leaves no leaked state. Covers `gui-test-system.AC5.1`–`gui-test-system.AC5.5`.
<!-- END_PHASE_4 -->

## Additional Considerations

**DeviceConfigManager tight coupling:** `DeviceConfigManager` calls FFI directly without an abstract interface, and generated device config objects are Rust opaque interfaces. For BLoC/widget tests that touch device configuration UI, use `RustLib.initMock(...)` or mocktail-backed opaque fixtures at the `RustLibApi` level. If this becomes cumbersome, adding a `DeviceConfigProvider` interface (mirroring `EngineProvider`) is the natural refactoring — but that's deferred per minimal-refactoring constraint.

**Production bootstrap side effects:** `IntifaceCentralApp.buildApp()` initializes paths, logging, preferences, window/tray plugins, update providers, and Rust FFI. Integration tests should not rely on those side effects being safe in arbitrary order. The test-controlled bootstrap is a small intentional seam that keeps production wiring while making startup deterministic.

**Test execution speed:** BLoC + widget + golden tests should complete in under 30 seconds. Integration tests with real engine startup will be slower (10–30 seconds per flow). Keep integration tests focused on high-value journeys, not comprehensive UI coverage.

**Golden image maintenance:** Golden reference images will need regeneration when widget styling changes intentionally. Run `flutter test --update-goldens test/golden/` to regenerate. Commit the updated images alongside the style change.

**Global state cleanup:** `RustLib`, `SharedPreferences`, filesystem paths, timers, and debouncers are process-global or long-lived enough to leak between tests. Helpers should centralize setup/teardown instead of making each test remember the exact cleanup order.

**Command verification:** The current simulated-device FFI surface adds/lists/removes devices. If output observations are not sufficient to prove that a UI command reached the simulated device, add a small test-only Rust FFI probe that exposes the simulator's last command. Do not settle for asserting only that a slider moved.

**Simulated device limitations:** Sensor features don't exist yet in the sim engine. Integration tests for sensor UI will need to wait for that capability, or mock at a higher layer for those specific scenarios.

**CI pipeline:** The existing repository workflow is release-build oriented and tag-triggered. Add a separate PR test workflow that checks out the required sibling repos (`buttplug`, `buttplug_dart`), installs Flutter/Rust, runs `flutter analyze`, `flutter test`, and `flutter test test/golden/` on a pinned macOS image. Run integration tests on merge to main or nightly to control macOS runner cost.
