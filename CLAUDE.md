# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Intiface Central is a cross-platform frontend for the Buttplug Sex Toy Control Library. It's a Flutter + Rust hybrid application using BLoC state management.

**Platforms:** Windows, macOS, Linux, Android, iOS

## Build Commands

```bash
# Get dependencies
flutter pub get

# Run development version
flutter run

# Build for current platform
flutter build

# Build for specific platform
flutter build windows --release
flutter build macos --release
flutter build linux --release
flutter build apk --release
flutter build ios --release

# Run Dart linter
flutter analyze

# Format Dart code
dart format lib/

# Generate code (freezed models, FFI bindings)
flutter pub run build_runner build

# Regenerate Rust-Dart FFI bridge
flutter_rust_bridge_codegen generate
```

**Linux build dependencies:** `ninja-build`, `libudev-dev`, `libgtk-3-dev`, `libcurl4-openssl-dev`

## Architecture

### Flutter/Dart (lib/)

- **BLoC Pattern** - State management via `flutter_bloc`
  - `bloc/engine/` - Engine lifecycle (start/stop, state transitions)
  - `bloc/device/` - Connected device management
  - `bloc/configuration/` - App settings
  - `bloc/device_configuration/` - User device customization
  - `bloc/update/` - App/engine update management
  - `bloc/util/` - Settings, navigation, Discord integration, errors
- **page/** - Screen widgets
- **widget/** - Reusable UI components
- **util/** - Helper utilities
- **src/rust/** - Auto-generated FFI bindings (do not edit manually)

### Rust FFI (rust/)

- `api/` - Public API exposed to Flutter via flutter_rust_bridge
  - `runtime.rs` - Buttplug runtime management
  - `device_config.rs` - Device configuration API
- `mobile_init/` - Platform-specific initialization (Android/iOS)
- `frb_generated.rs` - Auto-generated bridge code (do not edit manually)

### Key Data Flow

Widgets → Pages → BLoCs → Rust FFI → Buttplug Engine

## Critical Dependencies

**Local path dependencies required as sibling directories:**
- `../buttplug_dart` - Dart Buttplug client library
- `../../buttplug/` - Rust Buttplug crates (buttplug_core, buttplug_server, intiface_engine)

**Version alignment warning from Cargo.toml:**
> btleplug version MUST match whatever Buttplug links, otherwise there will be static misalignment issues.

## External Services

- **Sentry** - Error tracking (configured via SENTRY_DSN)
- **Discord** - Rich Presence integration
- **GitHub API** - Update checking

## Testing

Tests are currently disabled in pubspec.yaml. To enable:
1. Uncomment `flutter_test`, `integration_test`, and `test` in dev_dependencies
2. Run `flutter test`

## Platform Notes

- **Android:** minSdkVersion 27, NDK 28.2.13676358, uses foreground service for background operation
- **Windows:** MSIX packaging configured for Windows Store capabilities (bluetooth, USB, serial, HID)
- **Desktop:** Window management via `window_manager` package

## Contributing

PRs require prior discussion via GitHub issues. CLA required for all contributions.
