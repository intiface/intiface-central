# Mobile mDNS Fixes Plan

## Summary

Mobile mDNS should be treated as a host-platform service, not only as an engine-internal Rust feature. Intiface Engine should continue to own the service contract: whether mDNS is enabled, service type, instance name, port, TXT records, and server lifecycle intent. Intiface Central should own the mobile platform mechanics: Android multicast lock handling, iOS local-network/Bonjour integration, native permission prompts, and foreground-service lifecycle coordination.

The target end state is exactly one publisher per platform. Desktop can keep using the existing Rust/libmdns publisher. Mobile should either keep Rust publishing with Central-provided platform support, or delegate publishing to a Central-owned native implementation. iOS should prefer native Bonjour publishing because raw multicast from Rust/Dart may require Apple's restricted multicast entitlement.

## Goals

- Android mDNS advertisement is discoverable while the engine is running and mDNS is enabled.
- iOS mDNS advertisement is discoverable by standard DNS-SD/mDNS clients, including Windows clients using libmdns.
- Mobile does not publish duplicate mDNS records from both Rust and native Central.
- Engine lifecycle, foreground-service lifecycle, and mDNS lifecycle shut down cleanly across start, stop, stale foreground-service recovery, and app termination.
- Implementation can be split into bounded tasks for smaller-model worker agents where write scopes are clear.

## Non-Goals

- Replacing desktop libmdns publishing.
- Changing the public DNS-SD wire contract unless required for repeater discovery.
- Adding a UI-only "request mDNS permission" button. Android multicast state is not a runtime dangerous permission, and iOS local-network permission is triggered by local-network/Bonjour activity.
- Solving the advertised-IP filtering bug in Central if the effective fix lives in buttplug/libmdns.

## Current State

Central already has the user-facing settings and configuration flow:

- `lib/widget/engine_config_widget.dart` exposes "Broadcast Server Info via mDNS" and "mDNS Identifier Suffix".
- `lib/bloc/configuration/intiface_configuration_cubit.dart` persists `broadcastServerMdns` and `mdnsSuffix`, then passes them into `EngineOptionsExternal`.
- `rust/src/api/runtime.rs` mirrors `EngineOptionsExternal` and calls `IntifaceEngine::run(...)`.
- `LibraryEngineProvider` and `ForegroundTaskLibraryEngineProvider` both start the Rust engine through `runEngine(args: ...)`.

The engine owns the current publisher:

- `../buttplug/crates/intiface_engine/src/engine.rs` creates `IntifaceMdns` when `broadcast_server_mdns` is true.
- `../buttplug/crates/intiface_engine/src/mdns.rs` registers `_intiface_engine._tcp`.
- The current engine message `EngineServerCreated` has no payload, so a host-owned publisher cannot reliably know the effective bound port unless Central independently assumes it from config.

Central now has the app metadata needed for the first mobile fixes:

- Android manifest includes `android.permission.CHANGE_WIFI_MULTICAST_STATE`.
- iOS `Info.plist` includes `NSBonjourServices` for `_intiface_engine._tcp` and `NSLocalNetworkUsageDescription`.

## Architecture Decision

Use a two-stage implementation.

Stage 1 is Android-only hardening with minimal architecture change: keep Rust/libmdns publishing, and have Central hold Android's `WifiManager.MulticastLock` for the duration of a mobile mDNS engine run.

Stage 2 introduces a host-owned mDNS publisher path for mobile. The engine should expose enough lifecycle data for the host app to publish the same service contract, and mobile engine startup should avoid also starting the Rust publisher.

This gives a low-risk Android fix early while preserving the cleaner iOS-native path.

## Service Contract

The publisher, whether Rust or native, must publish the same DNS-SD contract:

- Service type: `_intiface_engine._tcp`
- Instance name: engine-generated or Central-generated `Intiface ...` name, including the optional suffix
- Port: actual bound websocket/server port
- TXT records: currently `path=/`

If repeater discovery needs a separate service later, add a second explicit contract rather than overloading `_intiface_engine._tcp`.

## Implementation Phases

### Phase 0: Metadata and Contract Audit

Status: partially done in Central.

Tasks:

- Confirm Android manifest contains `CHANGE_WIFI_MULTICAST_STATE`.
- Confirm iOS `Info.plist` contains `NSBonjourServices` with `_intiface_engine._tcp`.
- Confirm iOS `Info.plist` contains `NSLocalNetworkUsageDescription`.
- Confirm buttplug's advertised service type remains `_intiface_engine._tcp`.
- Add a short test checklist for real-device validation because simulator/emulator behavior is not enough for mDNS.

Acceptance criteria:

- Android and iOS metadata validate with `xmllint` and `plutil`.
- The documented service type matches the engine constant.

Suggested subagent:

- Small explorer agent: verify metadata and service constants, no edits.

### Phase 1: Android Multicast Lock Support

Intent: keep Rust/libmdns as the publisher, but make Android receive/send multicast reliably while mDNS is enabled.

Central changes:

- Add a narrow Dart service, for example `lib/util/mdns_platform_service.dart`.
- Add a platform channel implemented in `android/app/src/main/kotlin/com/nonpolynomial/intiface_central/MainActivity.kt`.
- Implement methods:
  - `acquireMdnsMulticastLock`
  - `releaseMdnsMulticastLock`
- In Kotlin, use `WifiManager.createMulticastLock("IntifaceCentralMdns")`, call `setReferenceCounted(false)`, then `acquire()` / `release()`.
- Make release idempotent.
- Log failures back to Dart, but do not hard-fail engine start unless we intentionally decide mDNS should be a hard requirement.

Lifecycle hook:

- Primary mobile hook: `lib/bloc/engine/foreground_task_library_engine_provider.dart`.
- Start/acquire in `IntifaceEngineTaskHandler.onStart` only when `engineOptions.broadcastServerMdns` is true.
- Release in the graceful shutdown path after `stopEngine()` completes, and also in `onDestroy`.
- If non-foreground mobile engine runs are supported, mirror the same lifecycle in `LibraryEngineProvider` or a shared wrapper owned by `EngineRepository`.

Acceptance criteria:

- Android acquires the multicast lock only when mDNS is enabled.
- Android releases the multicast lock on normal stop, stale foreground-service replacement, and `onDestroy`.
- Starting/stopping twice does not leak or double-release.
- Existing Bluetooth wakelock behavior in `EngineControlBloc._updateWakelockIfNeeded` is not changed.
- Real Android device can be discovered from another host on the same network while mDNS is enabled.

Suggested subagents:

- Worker A, small model: implement the Android Kotlin platform channel and Dart wrapper. Owns `MainActivity.kt` and the new Dart service file.
- Worker B, small model: integrate the wrapper into `ForegroundTaskLibraryEngineProvider` lifecycle. Owns only that provider and any focused tests.

### Phase 2: Engine Lifecycle Payload for Host-Owned Publishing

Intent: make native Central publishing possible without guessing the actual port or duplicating engine logic.

Buttplug / Intiface Engine changes:

- Add server-created payload to an engine message, or add a new message variant.
- Minimum payload:
  - service type
  - instance name
  - port
  - TXT records
  - optional mode, such as `engine` vs `repeater`, if needed
- Surface the actual bound port from the websocket server binding point rather than assuming the configured port.
- Keep the message backward compatible where possible. If `EngineServerCreated` gains fields, Dart should tolerate missing fields while transition builds exist.

Central changes:

- Update `lib/bloc/engine/engine_messages.dart` and generated JSON code.
- Route the payload through `EngineRepository` / `EngineControlBloc`.
- Add a Dart interface for a host mDNS publisher, but keep it disabled until Phase 3.

Acceptance criteria:

- Central receives service metadata from the engine when the server is actually created.
- The metadata reflects the actual bound port.
- Existing Central versions can still start against older message shapes during local transition, or the repo pair is updated atomically.

Suggested subagents:

- Worker C, small-to-medium model: implement engine message payload in buttplug. Owns `crates/intiface_engine` message/server files and tests.
- Worker D, small model: update Central Dart message models and generated code. Owns `engine_messages.dart`, generated `.g.dart`, and focused tests.

### Phase 3: iOS Native Bonjour Publisher

Intent: avoid raw multicast on iOS by using Apple's Bonjour APIs through Central.

Central changes:

- Add a Swift helper in `ios/Runner/AppDelegate.swift` or a small separate Swift class.
- Use `NetService` or `NWListener`/Bonjour APIs to publish `_intiface_engine._tcp` with the engine-provided instance name, port, and TXT records.
- Expose methods through a Flutter platform channel:
  - `startMdnsPublisher`
  - `stopMdnsPublisher`
- Add a Dart `MdnsPlatformService` implementation that calls the same high-level service interface used by Android.
- Start native iOS publishing when the engine emits service metadata and mDNS is enabled.
- Stop native iOS publishing on engine stop and app shutdown.

Buttplug / Intiface Engine changes:

- Add an option to suppress engine-internal mDNS publishing when the host app will publish.
- For mobile/iOS Central builds, pass "host publishes mDNS" so the Rust/libmdns publisher is not also started.

Acceptance criteria:

- iOS presents the Local Network permission prompt at the appropriate first advertisement attempt.
- iOS publishes exactly one `_intiface_engine._tcp` service.
- Windows/libmdns clients can discover the iOS-published service on the same network.
- Denied local-network permission fails gracefully and is logged.
- Stopping the engine unregisters the service.

Suggested subagents:

- Worker E, medium model: implement Swift Bonjour publisher and platform channel. Owns iOS native files only.
- Worker F, small model: wire host-publisher lifecycle in Dart once the native methods exist. Owns the Dart platform service and provider integration.

### Phase 4: Duplicate Publisher Prevention

Intent: guarantee exactly one publisher for every platform.

Rules:

- Desktop: engine/libmdns publishes when `broadcast_server_mdns` is true.
- Android Phase 1: engine/libmdns publishes; Central only holds multicast lock.
- Android future native path, if chosen: Central publishes; engine/libmdns disabled.
- iOS: Central native Bonjour publishes; engine/libmdns disabled.

Implementation options:

- Add an engine option such as `mdns_publish_mode` with values:
  - `disabled`
  - `engine`
  - `host`
- Or add a simpler boolean such as `host_publish_mdns` while preserving `broadcast_server_mdns` as user intent.

Acceptance criteria:

- Logs clearly state which publisher is active.
- No platform starts both publishers for the same service.
- Tests cover option translation from Central config to engine options.

Suggested subagent:

- Worker G, small model: implement the option translation and focused tests once Phase 2/3 contracts are stable.

### Phase 5: Real-Device Validation

Validation matrix:

- Android phone, foreground process on, mDNS enabled.
- Android phone, foreground process off if supported.
- iPhone/iPad, mDNS enabled, first-run Local Network prompt accepted.
- iPhone/iPad, Local Network permission denied.
- Desktop Windows libmdns discovery of mobile-published service.
- Desktop macOS Bonjour discovery of mobile-published service.
- Server start/stop repeated five times.
- App killed while engine foreground service is active.
- Network switch from Wi-Fi to cellular/no Wi-Fi.

Tools:

- `dns-sd -B _intiface_engine._tcp` on macOS.
- Windows test client using the same discovery path as Central/client apps.
- Android logcat for multicast lock acquire/release.
- iOS device logs for Bonjour publish failures and local-network denial.

Acceptance criteria:

- Discovery appears within a few seconds of engine server creation.
- Discovery disappears after engine stop.
- No duplicate records for a single mobile device.
- App does not hang during shutdown.

## Subagent Coordination Plan

Use smaller model subagents only for bounded, disjoint write sets. The parent agent should keep ownership of architecture, cross-repo integration, and final review.

Recommended sequence:

1. Parent: confirm current metadata and service contract.
2. Worker A: Android native multicast lock channel.
3. Worker B: Android lifecycle wiring in foreground provider.
4. Parent: review Android integration and run focused tests.
5. Worker C: buttplug engine service metadata payload.
6. Worker D: Central Dart message model update.
7. Parent: integrate cross-repo message contract.
8. Worker E: iOS native Bonjour publisher.
9. Worker F: Dart host publisher lifecycle.
10. Parent: duplicate-publisher guard, real-device test checklist, final cleanup.

Delegation rules:

- Do not assign two workers to the same file.
- Tell every worker the repo may be dirty and they must not revert unrelated changes.
- Prefer one worker per platform boundary.
- Ask workers to list changed files and validation commands in their final response.
- Parent reviews all generated platform-channel names, message contracts, and lifecycle ordering before merging.

## Open Questions

- Should Android stay permanently on Rust/libmdns plus multicast lock, or eventually use a native publisher too?
- Should `EngineServerCreated` be extended, or should a new `MdnsAdvertisementRequested` engine message be added?
- Should repeaters use `_intiface_engine._tcp`, or a distinct service type and TXT schema?
- Should local-network denial be surfaced in UI, logs only, or both?
- Do we need the Apple multicast entitlement for any fallback iOS raw-multicast path, or can native Bonjour fully avoid it?
