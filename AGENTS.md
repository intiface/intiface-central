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

- **Android:** minSdkVersion 27, compileSdk 37, NDK 28.2.13676358, uses foreground service for background operation
  - AGP 9.1.1 / Gradle 9.3.1. AGP 9.1.1 is the minimum for compileSdk 37 and the highest AGP Flutter 3.44 supports, so these move together with the Flutter version.
  - `android.builtInKotlin=false` and `android.newDsl=false` in `gradle.properties` opt out of AGP 9 behaviour changes. AGP 10 removes the opt-out, so the app and any plugins applying KGP directly (currently `flutter_foreground_task` and `sentry_flutter`) must migrate to Built-in Kotlin before then.
  - `rust_builder/android/build.gradle` has its own `compileSdk` that must stay >= the app's, or AGP fails the AndroidX dependency check.
  - Do not add `<uses-sdk>` to `AndroidManifest.xml`; AGP 9 rejects it. SDK levels belong in `build.gradle`.
  - Shipped ABIs are `armeabi-v7a`, `arm64-v8a`, and `x86_64` (x86_64 covers ChromeOS and emulators). The list is repeated in the `cargo ndk` targets in `android/app/build.gradle`, the `--target-platform` flags and `rustup target add` in the Forgejo workflow, and `scripts/verify-android-native-libs.sh`; all four must agree. Android infers supported ABIs from which `lib/<abi>/` directories exist, so a partially populated one makes the platform install that ABI and crash on `UnsatisfiedLinkError` (issue #256).
  - Rust native libraries are built by the `cargoBuild*` tasks in `android/app/build.gradle` and attached with `variant.sources.jniLibs.addGeneratedSourceDirectory`. That registration is what orders cargo before `merge*NativeLibs` — copying into `src/main/jniLibs` instead races the merge and silently ships an APK with no Rust library (see issue #262). Cargokit is not used on Android; its Gradle plugin depends on `project.buildDir` and `android.applicationVariants`, both removed in Gradle 9 / AGP 9.
- **iOS:** Requires Xcode 26 or newer to build for device.
  - `device_info_plus` 12.4.0+ references `-[NSProcessInfo isiOSAppOnVision]`, declared only in the iOS 26.1 SDK and up. Its `if (@available(iOS 26.1, *))` guard is a runtime check and does nothing for the compiler, so an older SDK fails with an unrelated-looking ARC semantic error in `FPPDeviceInfoPlusPlugin.m`. Pinning to `device_info_plus` 12.3.0 avoids it but drags `network_info_plus` back to 7.x as well, since 12.x wants win32 5.x and `network_info_plus` 8.x wants win32 6.x.
  - Xcode 26.3 (iOS 26.2 SDK) is the last release that runs on macOS Sequoia 15.6+; 26.4 and later require macOS Tahoe 26.2. Install it from developer.apple.com/download/all — the App Store only offers the current release.
  - App Store Connect has rejected uploads not built with Xcode 26 against an iOS 26 SDK since 2026-04-28.
  - `flutter run` launches debug builds by driving Xcode over AppleEvents. Inside a terminal multiplexer whose server is parented to `launchd` (zellij, tmux), macOS cannot attribute the request to a GUI app, so the Automation consent prompt never renders and the run hangs forever at "Installing and launching...". Grant it once from a real terminal window; `tccutil reset AppleEvents` clears a stale deny.
  - Debug builds cannot be started with `xcrun devicectl device process launch` — the Dart VM needs JIT, which iOS only permits under a debugger, so a cold launch dies on SIGSEGV. Use `--profile` or `--release` to launch without the tooling attached.
  - `flutter_tools` rewrites `ios/Runner.xcodeproj/project.pbxproj` on every run (objectVersion 60 -> 54, empty `inputPaths`/`outputPaths` stripped from the CocoaPods script phases). This is normalization, not an Xcode migration; commit it rather than fighting it.
- **Windows:** MSIX packaging configured for Windows Store capabilities (bluetooth, USB, serial, HID)
- **Desktop:** Window management via `window_manager` package

## Contributing

PRs require prior discussion via GitHub issues. CLA required for all contributions.
