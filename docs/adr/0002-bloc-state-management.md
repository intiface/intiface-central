# ADR 0002: BLoC for State Management

## Status

Accepted

## Context

Flutter offers many state management options (Provider, Riverpod, GetX, BLoC, MobX, Redux, etc.). Intiface Central needs to manage several concerns: engine lifecycle, device lists, per-device feature state, app configuration, and real-time observation streams. The state is largely event-driven — the Rust engine emits events via FFI and the UI reacts.

The primary pattern is "something happens externally (Rust engine event or user interaction), update state." Most state holders are simple: method in, state out.

## Alternatives Considered

**Riverpod:** Less boilerplate for simple state (no class per state holder). `autoDispose` + `family` providers would simplify per-device/per-feature lifecycle management — parameterised providers replace manually managing lists of cubits. `StreamProvider` handles the Rust event stream case. The main trade-off: migrating an existing BLoC app is a full state-layer rewrite, not incremental.

**GetX:** All-in-one solution (state, routing, DI). Opinionated and tightly coupled. Community polarised on code quality and long-term maintenance.

**Redux / MobX:** Established patterns from other ecosystems. Redux's boilerplate is heavy for a UI this size. MobX's code generation adds another build step.

**BLoC (flutter_bloc):** Stream-native — designed around reacting to events and emitting state changes. The `flutter_bloc` package provides both full BLoCs (event classes → state transitions) and cubits (method calls → state emission). Cubits are the simplified variant that skip the event indirection.

## Decision

Use `flutter_bloc` with **cubits as the default**. Full BLoCs (with discrete event classes) are reserved for cases where event-level semantics matter — event replay, debouncing, or multiple distinct events triggering transitions on the same state. In practice, nearly everything in Intiface Central is a cubit because the event source is already external (the Rust engine stream), and the UI layer just needs "method in, state out."

## Consequences

- **Cubits everywhere.** The BLoC/Cubit divide is simple: if you just need to call a method and emit state, use a cubit. If you need to inspect, debounce, or replay the event stream itself, use a full BLoC. Almost nothing in this app needs the latter.
- **Stream-native pattern** fits the architecture — the Rust engine pushes events through a stream, cubits subscribe and react.
- **Mirror vs. Derived cubits** emerged as a natural pattern (see CONTEXT.md). Mirror cubits project engine state; derived cubits synthesize UI-only state. Both are cubits, not full BLoCs.
- **Per-device and per-feature cubits** are created/torn down as devices connect/disconnect. The `close()` lifecycle maps cleanly to device lifecycle events. A Riverpod `family` + `autoDispose` approach would be terser here, but the manual approach works.
- **Boilerplate is moderate.** Cubits are lightweight. The ceremony cost is acceptable for this codebase's size.
- **Testing story is good** — `bloc_test` supports verifying state transitions. Not currently used (tests are disabled in pubspec) but the path is there when needed.
- **Riverpod remains a viable future option** if the cubit management becomes unwieldy, but migration would be a dedicated effort, not incremental.
