# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This crate is the FFI bridge between Flutter/Dart and the Buttplug/Intiface Engine. It exposes Rust APIs to Flutter via `flutter_rust_bridge` and handles platform-specific initialization.

## Build Commands

```bash
# Build the Rust library (usually done via flutter build)
cargo build

# Check/lint
cargo clippy
cargo fmt

# Regenerate FFI bindings (run from project root)
flutter_rust_bridge_codegen generate
```

## Module Structure

- **api/** - Public API exposed to Flutter (added to `flutter_rust_bridge.yaml` as `rust_input`)
  - `runtime.rs` - Engine lifecycle: start, stop, message passing
  - `device_config.rs` - Device configuration types and management
  - `device_config_manager.rs` - Global device config state
  - `enums.rs` - Shared enumerations
  - `specifiers.rs` - Device specifier types
  - `util.rs` - Utility functions (Sentry init, crash triggers)
- **mobile_init/** - Platform-specific runtime creation
  - `setup/android.rs` - JNI class loader setup, `JNI_OnLoad` entry point
  - `setup/not_android.rs` - Simple tokio runtime for non-Android
- **in_process_frontend.rs** - Flutter frontend implementation for engine events
- **logging.rs** - Tracing subscriber that pipes logs to Flutter via StreamSink
- **frb_generated.rs** - Auto-generated bridge code (do not edit)

## flutter_rust_bridge Patterns

### Exposing External Types

Use `#[frb(mirror(...))]` to expose types from external crates:

```rust
#[frb(mirror(EngineOptionsExternal))]
pub struct _EngineOptionsExternal {
  // Mirror all fields from intiface_engine::EngineOptionsExternal
}
```

### Streaming Data to Flutter

Use `StreamSink<T>` for continuous data flow (logs, events):

```rust
pub fn run_engine(sink: StreamSink<String>, args: EngineOptionsExternal) -> Result<()>
```

## Platform-Specific Notes

### Android JNI

- `JNI_OnLoad` initializes btleplug and jni-utils
- Each tokio thread needs class loader context set via JNI calls
- **Warning in android.rs:** The `JNI_OnLoad` function must be commented out or removed when building iOS codegen, otherwise iOS builds fail

### Shutdown Timing

Platform-specific Bluetooth cleanup in `stop_engine()`:
- **macOS:** 1000ms delay (CoreBluetooth delegate callbacks are slow)
- **Other platforms:** 500ms delay (Android JNI, Windows UWP)

## Critical Version Alignment

From Cargo.toml:
> btleplug version MUST match whatever Buttplug links, otherwise there will be static misalignment and debugging is painful.

Same applies to `jni` and `jni-utils` versions for Android.

## Global State

Engine state managed via `lazy_static!` globals in `runtime.rs`:
- `ENGINE_NOTIFIER` - RwLock (not OnceCell) to allow reset between runs
- `RUNTIME` - The tokio runtime
- `RUN_STATUS` - Whether engine is running
- `ENGINE_SHUTDOWN` - Prevents sending to closed StreamSinks during shutdown

## Log Filtering

`logging.rs` filters benign third-party errors (e.g., btleplug's "Error dispatching event: SendError" on macOS) to avoid confusing users.

## Dependencies

Local path dependencies (must exist as sibling directories):
- `../../buttplug/crates/buttplug_core`
- `../../buttplug/crates/buttplug_server`
- `../../buttplug/crates/buttplug_server_device_config`
- `../../buttplug/crates/intiface_engine`
