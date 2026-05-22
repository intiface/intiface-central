# ADR 0001: Flutter for Cross-Platform GUI

## Status

Accepted

## Context

Intiface Central is the user-facing frontend for the Buttplug library. The previous version was built on Electron (Intiface Desktop), which worked well for Windows/macOS/Linux but could not target mobile platforms. A significant portion of users want to connect to devices through their phones — Bluetooth LE on mobile is often more reliable and convenient than desktop BLE adapters, and phones are the natural controller for wearable devices.

The core requirement was a single codebase producing native builds for Windows, macOS, Linux, Android, and iOS. The Buttplug engine is written in Rust, so the GUI framework needed viable Rust FFI integration.

## Alternatives Considered

**Electron (status quo):** Desktop-only. No path to iOS/Android without a separate codebase. The existing Intiface Desktop proved Electron works for the desktop case but doesn't solve the mobile problem.

**React Native:** Mobile-first but weak desktop story. Desktop support via react-native-windows/macos is less mature. Rust FFI possible but not well-trodden.

**Kotlin Multiplatform / Compose Multiplatform:** Promising but iOS and desktop targets were experimental at evaluation time. Rust interop would require JNI on Android and separate bindings elsewhere.

**Flutter:** Single codebase for all five platforms. `flutter_rust_bridge` provides mature, code-generated FFI bindings for Rust. Large ecosystem. Dart is not a language anyone is passionate about, but it's adequate. Desktop support is stable enough for a settings/control panel style app (not a complex creative tool).

**.NET MAUI:** Cross-platform but iOS/Android tooling has been inconsistent. Rust FFI via P/Invoke is possible but manual. Smaller community for this use case.

## Decision

Use Flutter with `flutter_rust_bridge` for the Intiface Central rewrite. All Buttplug engine logic stays in Rust; Flutter handles presentation and state management only.

## Consequences

- **Single codebase** for all five target platforms, reducing maintenance from "two apps" to one.
- **flutter_rust_bridge** handles FFI code generation, keeping the cross-language boundary manageable. The trade-off is a dependency on FRB's code generation and its constraints on what Rust types can cross the boundary.
- **Dart** is the UI language. It's fine. Nobody's writing blog posts about how much they love it, but it compiles, the tooling works, and Flutter's widget model is productive for settings-panel-style UIs.
- **Desktop is a second-class citizen in Flutter's ecosystem.** Window management, system tray, native menus — all require third-party packages of varying quality. Acceptable for this app's complexity level, but a constraint.
- **Mobile BLE access** is now possible, which was the entire motivation. Android and iOS builds work from the same codebase that produces desktop builds.
- **Electron expertise doesn't transfer.** The rewrite was a ground-up effort, not a port.
