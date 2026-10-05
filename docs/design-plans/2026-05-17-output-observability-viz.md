# Output Observability Visualization Design

## Summary

Intiface Central currently provides sliders and toggle controls for each output feature of a connected device, but gives no visual feedback about what values are actually being sent to the hardware. This design adds a real-time stepped line chart beneath each output feature slider on the device detail page, showing the last 10 seconds of commanded output values as a rolling history. A user can see at a glance whether a ramp, pattern, or steady hold is being applied — without needing to interpret raw log output.

The implementation threads a new event type — `DeviceOutputObservation` — from the buttplug Rust engine through the existing FFI `StreamSink`, routes it to a dedicated Dart broadcast stream to keep high-frequency data (up to 60fps) off the main BLoC state pipeline, and buffers it per-feature in a new `ObservationCubit`. A timer-driven 30fps state emission cap ensures the chart redraws smoothly without overwhelming Flutter's layout engine. The feature is enabled by a single boolean option on engine startup (`emitOutputObservations: true`) and adds no persistent storage or new network surface.

## Definition of Done
Per-feature stepped line chart (fl_chart) below each output feature slider in the device detail page, displaying a rolling 10-second history of output observation values (0.0–1.0). The chart is always visible when the device is connected (flat at 0 when idle). Observations flow through the existing shared StreamSink as `DeviceOutputObservation` engine messages, enabled via a new `emit_output_observations` option in `EngineOptionsExternal`. This requires: updating the Rust FFI to expose and forward the new observation events, a new Dart model + cubit to buffer time-series data per feature, and the fl_chart widget integrated inline with the existing controls layout.

**Out of scope:** Separate observation stream, per-device aggregated charts, persistent history beyond the 10s window, chart for input/sensor data.

## Acceptance Criteria

### output-observability-viz.AC1: Observation messages flow from Rust to Dart
- **output-observability-viz.AC1.1 Success:** `DeviceOutputObservation` JSON messages from the engine are deserialized into `DeviceOutputObservation` Dart objects
- **output-observability-viz.AC1.2 Success:** Observations route to a dedicated stream, not the main engine message stream
- **output-observability-viz.AC1.3 Failure:** Malformed observation JSON is logged and discarded without crashing the message pipeline

### output-observability-viz.AC2: Per-feature time-series buffering
- **output-observability-viz.AC2.1 Success:** Each output feature has its own `ObservationCubit` that receives only observations matching its `(deviceIndex, featureIndex)`
- **output-observability-viz.AC2.2 Success:** Buffer maintains a rolling 10-second window, pruning entries older than 10s
- **output-observability-viz.AC2.3 Success:** Buffer starts empty when device connects (chart shows flat at 0)
- **output-observability-viz.AC2.4 Edge:** Rapid observations (60fps) are buffered without frame-dropping; chart rebuilds are capped at ~30fps via timer

### output-observability-viz.AC3: Chart visualization
- **output-observability-viz.AC3.1 Success:** A stepped line chart appears below each output feature slider in the device detail page
- **output-observability-viz.AC3.2 Success:** Chart X-axis shows relative time (-10s to 0), Y-axis shows 0.0–1.0
- **output-observability-viz.AC3.3 Success:** Chart is always visible when device is connected, even with no observations (empty/flat state)
- **output-observability-viz.AC3.4 Success:** Chart updates in real-time as new observations arrive

### output-observability-viz.AC4: Configuration
- **output-observability-viz.AC4.1 Success:** Engine starts with `emit_output_observations: true` when launched from Intiface Central

## Glossary

- **BLoC (Business Logic Component)**: Flutter state management pattern separating UI from business logic using streams. This project uses `flutter_bloc`; cubits are a simplified variant.
- **Cubit**: A lightweight BLoC-family state class that emits state changes via `emit()`. Used here for per-feature observation buffering (`ObservationCubit`) and output control (`DeviceOutputCubit`).
- **BlocBuilder**: A Flutter widget that rebuilds its subtree whenever a cubit/BLoC emits new state. Connects `ObservationCubit` state to the chart widget.
- **buttplug**: The underlying Rust sex toy control library. The `output-observability` branch adds the `DeviceOutputObservation` message this design depends on.
- **DeviceOutputObservation**: New engine message variant emitted each time a command value is sent to a device feature, carrying `device_index`, `feature_index`, `output_type`, and `value` (0.0–1.0).
- **EngineMessage**: Dart discriminated union type (JSON-deserialized) representing all messages from the Rust engine.
- **EngineOptionsExternal**: Rust struct (mirrored to Dart via FRB) configuring the engine at startup. A new `emit_output_observations: bool` field opts in to observation events.
- **EngineRepository**: Dart repository layer owning the FFI stream and fanning out engine messages. This design adds a second output stream for observations.
- **DeviceCubit**: Per-device cubit managing device lifecycle and owning child cubits per feature.
- **DeviceOutputCubit**: Existing per-feature cubit tracking the current commanded output value.
- **fl_chart**: Flutter charting library. `isStepLineChart: true` produces the staircase-style line for discrete values.
- **flutter_rust_bridge (FRB)**: Code-generation layer producing Dart bindings for Rust functions/structs. `#[frb(mirror(...))]` reflects Rust structs in generated Dart API.
- **StreamSink**: Rust-side write handle to a Dart stream. The engine writes JSON into a shared `StreamSink<String>`.
- **serde / externally-tagged enum**: Rust serialization. Externally-tagged enums serialize as `{"VariantName": {...fields}}` — the pattern used for `EngineMessage` variants.
- **`@JsonSerializable` / `build_runner`**: Dart code-gen annotations from `json_serializable`. `build_runner` regenerates `.g.dart` deserialization boilerplate.
- **broadcast StreamController**: Dart stream supporting multiple concurrent listeners, required here for sharing observations across many `ObservationCubit` instances.
- **stepped line chart**: Chart variant where the line holds horizontally at current value then steps vertically at the next data point, rather than interpolating diagonally.

## Architecture

Output observations flow from the buttplug engine through the existing `StreamSink<String>` as JSON-serialized `EngineMessage::DeviceOutputObservation` variants. On the Dart side, `EngineRepository` bifurcates the message stream — observation messages route to a dedicated broadcast `StreamController<DeviceOutputObservation>` instead of the main `EngineOutput` stream. This keeps high-frequency observation data (up to 60fps) off the BLoC state pipeline that handles engine lifecycle events.

Each output feature gets an `ObservationCubit` created alongside its `DeviceOutputCubit` in `DeviceCubit.setOnline()`. The cubit subscribes to the repository's observation stream, filters by `(deviceIndex, featureIndex)`, and maintains a rolling 10-second buffer of `(DateTime, double)` pairs. A periodic timer (~30fps) prunes stale entries and emits state updates, capping chart rebuilds regardless of observation frequency.

The chart widget uses `BlocBuilder<ObservationCubit, ObservationState>` wrapping an fl_chart `LineChart` with `isStepLineChart: true`. Fixed axes: X is relative time (-10s to 0), Y is 0.0–1.0. Compact height (~80px) fits inline below each feature slider.

### Data Flow

```
Rust Engine
  → EngineMessage::DeviceOutputObservation (JSON via StreamSink)
  → EngineRepository (bifurcates: observations → dedicated stream, others → main stream)
  → ObservationCubit (filters by device_index + feature_index, buffers 10s window)
  → ObservationChartWidget (fl_chart LineChart, stepped, ~30fps rebuild)
```

### Contracts

**Rust → Dart observation message** (JSON, serde externally-tagged enum):
```json
{"DeviceOutputObservation": {"device_index": 0, "feature_index": 1, "output_type": "Vibrate", "value": 0.75}}
```

**Dart observation model:**
```dart
class DeviceOutputObservation {
  final int deviceIndex;
  final int featureIndex;
  final String outputType;
  final double value;
}
```

**ObservationCubit state contract:**
```dart
class ObservationState {
  final List<ObservationPoint> points; // sorted by timestamp, max 10s window
}

class ObservationPoint {
  final DateTime timestamp;
  final double value; // 0.0–1.0
}
```

### Feature Matching

Observations carry `device_index` + `feature_index`. Each `DeviceOutputCubit` exposes `feature.deviceIndex` and `feature.feature.featureIndex`. `ObservationCubit` instances are created with the same index pair and stored in a list parallel to `DeviceCubit._outputs`. The chart widget pairs them by list position in `_DeviceControlsSection`.

## Existing Patterns

**Stream forwarding:** All engine events flow through a single `StreamSink<String>` in `runtime.rs`, deserialized in `EngineRepository` via `EngineMessage.fromJson()`. This design adds a second stream at the repository level (not the FFI level) to avoid BLoC congestion. The `EngineMessage` class uses `@JsonSerializable(fieldRename: FieldRename.pascal)` — adding a `DeviceOutputObservation?` field will match Rust's serde `PascalCase` enum variant naming.

**FFI mirror structs:** `runtime.rs` uses `#[frb(mirror(EngineOptionsExternal))]` to expose the engine's option struct to Dart. Adding `emit_output_observations: bool` follows the existing field-for-field mirror pattern.

**Device cubits:** `DeviceCubit.setOnline()` iterates device features and creates output/input cubits per feature. `ObservationCubit` creation follows this same loop pattern.

**BlocBuilder in controls:** `_DeviceControlsSection` already uses `BlocBuilder<DeviceOutputCubit, DeviceOutputState>` per feature. Adding `BlocBuilder<ObservationCubit, ObservationState>` below each slider follows the identical pattern.

**No divergence from existing patterns.** This design extends the current architecture without introducing new conventions.

## Implementation Phases

<!-- START_PHASE_1 -->
### Phase 1: Rust FFI Mirror Update
**Goal:** Add `emit_output_observations` field to the FFI mirror struct and regenerate bindings so Dart can pass the flag to the engine.

**Components:**
- `_EngineOptionsExternal` mirror struct in `rust/src/api/runtime.rs` (line 48–77) — add `pub emit_output_observations: bool` field
- Regenerate FFI bindings via `flutter_rust_bridge_codegen generate`

**Dependencies:** Buttplug `output-observability` branch merged and available as local path dependency.

**Done when:** `flutter build` succeeds with the new field, Dart side can construct `EngineOptionsExternal` with `emitOutputObservations: true`.
<!-- END_PHASE_1 -->

<!-- START_PHASE_2 -->
### Phase 2: Dart Message Model + Repository Bifurcation
**Goal:** Deserialize `DeviceOutputObservation` engine messages and route them to a dedicated stream separate from the main engine message pipeline.

**Components:**
- `DeviceOutputObservation` class in `lib/bloc/engine/engine_messages.dart` — `@JsonSerializable()` with `@JsonKey` for snake_case field mapping
- `deviceOutputObservation` field on `EngineMessage` class
- Regenerate `engine_messages.g.dart` via `build_runner`
- Observation stream (`StreamController<DeviceOutputObservation>.broadcast()`) in `lib/bloc/engine/engine_repository.dart`
- Bifurcation logic in `EngineRepository.start()` listener — check for observation before adding to main stream
- Stream lifecycle management in `EngineRepository.start()` and `stop()`

**Dependencies:** Phase 1 (FFI bindings with new field).

**Done when:** Observation messages from the engine are deserialized and available on `EngineRepository.observationStream`. Other engine messages continue flowing through `messageStream` unaffected. Covers `output-observability-viz.AC1.1`, `output-observability-viz.AC1.2`, `output-observability-viz.AC1.3`.
<!-- END_PHASE_2 -->

<!-- START_PHASE_3 -->
### Phase 3: ObservationCubit + Time-Series Buffer
**Goal:** Per-feature cubit that subscribes to the observation stream, filters by device/feature indices, and maintains a rolling 10-second buffer with timer-driven pruning.

**Components:**
- `ObservationCubit` in `lib/bloc/device/observation_cubit.dart` — stream subscription, index filtering, buffer management, periodic timer (~33ms), state emission
- `ObservationState` and `ObservationPoint` data classes in same file
- Integration into `DeviceCubit` (`lib/bloc/device/device_cubit.dart`) — create `ObservationCubit` per output feature in `setOnline()`, clean up in `setOffline()`, expose via getter

**Dependencies:** Phase 2 (observation stream on repository).

**Done when:** `ObservationCubit` correctly buffers observations for its feature, prunes entries older than 10s, and emits state at ~30fps. Buffer starts empty (flat at 0). Covers `output-observability-viz.AC2.1`, `output-observability-viz.AC2.2`, `output-observability-viz.AC2.3`, `output-observability-viz.AC2.4`.
<!-- END_PHASE_3 -->

<!-- START_PHASE_4 -->
### Phase 4: Chart Widget + UI Integration
**Goal:** Render per-feature stepped line charts below each output slider in the device detail page.

**Components:**
- `fl_chart` dependency in `pubspec.yaml`
- `ObservationChartWidget` in `lib/widget/observation_chart_widget.dart` — `BlocBuilder` wrapping fl_chart `LineChart` with `isStepLineChart: true`, fixed Y-axis 0.0–1.0, rolling X-axis -10s to 0, compact height
- Integration into `_DeviceControlsSection` in `lib/page/device_detail_page.dart` (lines 415–483) — insert chart below each output feature's slider, paired with the corresponding `ObservationCubit`

**Dependencies:** Phase 3 (ObservationCubit providing state).

**Done when:** Each output feature slider has a live stepped line chart below it showing the rolling 10-second observation history. Chart displays flat at 0 when idle. Covers `output-observability-viz.AC3.1`, `output-observability-viz.AC3.2`, `output-observability-viz.AC3.3`, `output-observability-viz.AC3.4`.
<!-- END_PHASE_4 -->

<!-- START_PHASE_5 -->
### Phase 5: Configuration Flag + Enable by Default
**Goal:** Wire the `emit_output_observations` flag through Dart configuration so the engine enables observation emission.

**Components:**
- Engine options construction in `lib/bloc/configuration/intiface_configuration_cubit.dart` — set `emitOutputObservations: true` when building `EngineOptionsExternal`

**Dependencies:** Phase 1 (FFI field available), Phase 4 (UI ready to display).

**Done when:** Starting the engine in Intiface Central enables output observations. Connecting a device and sending commands produces live chart updates. Covers `output-observability-viz.AC4.1`.
<!-- END_PHASE_5 -->

## Additional Considerations

**High-frequency data volume:** At 60fps with 5 features, observation messages add ~300 JSON strings/second to the shared StreamSink. The broadcast channel has a 256-element buffer; the Dart listener processes events synchronously. If the Dart side falls behind, broadcast channel lagging drops oldest messages — acceptable for visualization (dropped frames are invisible in a 10s window).

**Memory:** 600 `ObservationPoint` entries per feature (60fps × 10s) × ~32 bytes each = ~19KB per feature. Negligible even with many devices connected.

**Timer cleanup:** Each `ObservationCubit` holds a periodic timer. Must be cancelled in `close()`. Since cubits are created/destroyed in `DeviceCubit.setOnline()`/`setOffline()`, lifecycle is managed.
