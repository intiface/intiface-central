# Intiface Central

A cross-platform GUI frontend for the Buttplug sex toy control library. Presents the Buttplug engine's capabilities through a Flutter application using BLoC state management. Domain terminology defers to the [Buttplug CONTEXT.md](../buttplug/CONTEXT.md) — this glossary covers only the concepts Intiface Central adds at the presentation and integration layers.

## Language

**Gateway** (EngineRepository):
The boundary-crossing layer between the Rust FFI and the Flutter/BLoC world. Owns the single `StreamSink<String>` from Rust, deserializes JSON engine messages, and fans them out into typed Dart broadcast streams for BLoC consumption. Also owns engine lifecycle control (start/stop). One side is untyped JSON over FFI; the other side is typed streams.
_Avoid_: Treating as just a stream wrapper — it also owns the engine lifecycle.

**Mirror Cubit**:
A cubit that projects engine-owned state into BLoC without adding logic. The engine is the source of truth; the cubit reflects transitions. Examples: `DeviceCubit` (online/offline), engine state cubits. Mirror cubits should never contradict the engine.
_Avoid_: Adding derived state or buffering logic to a mirror cubit — use a Derived Cubit instead.

**Derived Cubit**:
A cubit that synthesizes UI-only state from engine events. The engine provides raw data; the cubit buffers, prunes, rate-limits, or transforms it into something the UI can render. Examples: `ObservationCubit` (time-series buffer from raw observation events). Derived cubits can be lossy — dropped events or pruned history is acceptable.
_Avoid_: Conflating with mirror cubits. Derived cubits own state the engine doesn't know about.

**Engine States**:
The engine lifecycle as seen from the GUI: **Stopped** (not running, no devices possible), **Starting** (spinning up, connecting hardware managers), **Running** (active, scanning/devices possible), **Stopping** (tearing down, waiting for Rust-side cleanup), **Error** (crashed or failed to start). These states gate most UI behaviour.
_Avoid_: Assuming stop is instantaneous — cross-runtime teardown is a real phase.

**Device List**:
The compact view of all known devices. Each device is a card showing summary state (name, connection status, per-feature sparklines). Serves as the dashboard — there is no separate aggregated view.

**Device Detail**:
The full interaction surface for a single device. Shows device info, feature configuration, live output controls (sliders), and observation charts. Navigated to from the device list.

## Principles

**Single FFI pipe, route in Dart.** All engine communication flows through one `StreamSink<String>`. Message routing and stream fan-out happen in the Gateway (Dart side), not at the FFI layer. This keeps the cross-language surface minimal and pushes complexity into the side where Flutter tooling helps.

**Gateway absorbs shutdown.** When the engine transitions to Stopping, the Gateway closes its broadcast controllers. Cubits observe stream-done and clean up via their existing `close()` lifecycle. No cubit should interact directly with the FFI layer or need to know about Rust-side teardown.

**Simulated devices are configuration-time special, runtime-time identical.** The "add device" wizard has a distinct flow for simulated devices (picking an archetype vs. scanning hardware). Once created, simulated devices appear in the device list and detail pages identically to real hardware — no special rendering, no badges, no different controls.

**Upstream terminology.** Device, Feature, Output, Input, Simulated Device, Output Observation, User Configuration, Device Configuration, Scanning, Hardware Manager, and all other Buttplug domain terms are defined in the Buttplug CONTEXT.md. Intiface Central uses them as-is.
