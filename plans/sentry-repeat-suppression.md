### Goal

Prevent a single Intiface Central process from flooding Sentry with repeating automatic error reports while preserving the first diagnostically useful occurrence, periodic evidence of persistent failures, manual log submissions, and distinct failure signatures across Dart/Flutter and Rust/native reporting.

### Implementation Summary

Implement bounded, process-local repeat suppression at both Sentry client boundaries:

- Dart/Flutter: attach an early event limiter directly to `SentryFlutter.init` in `lib/main.dart`, before application construction can fail.
- Rust/native: configure the independent `sentry` client in `rust/src/api/util.rs` with equivalent native filtering and consent-aware initialization.

Use two safeguards for automatic exception/panic events: one event per normalized signature per five-minute cooldown and a global automatic-event ceiling of 20 events per five minutes per process. Manual events tagged `ManualLogSubmit` bypass both safeguards. Keep app-hang handling separate because Sentry evidence shows repeated hangs across many users and changing stack snapshots; do not accidentally classify them as ordinary exception repeats.

Observed Sentry evidence motivating this design:

- `INTIFACE-CENTRAL-KV`: Flutter paint-loop `StateError`, 7,530 lifetime events and several identical reports per second.
- `INTIFACE-CENTRAL-XV`: closed-BLoC `StateError`, 2,752 lifetime events with dozens of identical events in the same second.
- `INTIFACE-CENTRAL-NB`: startup filesystem failure, 5,360 lifetime events, demonstrating that protection must exist before `IntifaceCentralApp.buildApp` completes.
- `INTIFACE-CENTRAL-10B`: native panic group with 166,546 lifetime events; recent samples include several distinct panic messages collapsed under symbol-poor `store_dart_post_cobject` frames.
- `INTIFACE-CENTRAL-4M`: native index panic with 52,963 lifetime events.
- `INTIFACE-CENTRAL-1A1`: iOS app-hang group with 3,277 lifetime events across 154 users, requiring a policy distinct from exception suppression.

Primary touch points are `lib/main.dart`, a new reusable Dart limiter module under `lib/util/`, `lib/intiface_central_app.dart`, `lib/page/submit_logs_page.dart`, `rust/src/api/util.rs`, and focused Dart/Rust tests. Generated FFI files under `lib/src/rust/` and `rust/src/frb_generated.rs` must not be edited manually. Direct fixes for the individual Sentry issues above are out of scope; this work is a reporting safety net, not a substitute for fixing root causes.

Implementation should be delegated in bounded work packages to the operator-approved cheaper model families, Luna or z.ai. A recommended split is: Luna for the pure Dart limiter/tests, z.ai for the Rust limiter/tests, then one of those models for integration after both contracts are fixed. The execute agent remains responsible for reconciling behavior, running the full verification suite, and reviewing generated diffs; delegates must not independently alter shared contracts without reporting the change.

### Implementation Plan

#### Phase 1 — Define a shared behavioral contract and event classifications

1. Introduce explicit constants/configuration for:
   - Per-signature cooldown: five minutes.
   - Global automatic-event budget: 20 **allowed automatic exception/panic events in an exact sliding five-minute window**.
   - Maximum retained signatures: 256.
2. Define classifications before implementing language-specific adapters:
   - `manual`: the `ManualLogSubmit` tag value is exactly the serialized string `true`; bypass consent and all suppression. Absent, empty, `false`, differently cased, or other values are not manual.
   - `automaticException`: Flutter/Dart errors and Rust panic/error events; apply signature cooldown and global budget.
   - `appHang`: Sentry app-hang mechanism/type; do not pass through the ordinary exception signature limiter or consume its global budget.
   - `other`: preserve existing SDK behavior and do not consume the automatic exception budget unless later explicitly classified and tested.
3. Define the exact language-neutral decision algorithm, in this order:
   - Classify the event; manual and app-hang events exit through their dedicated policies.
   - Normalize the automatic exception/panic signature.
   - Check signature cooldown first. A matching event is eligible exactly when `now - lastAllowed >= five minutes`; a cooldown drop increments that signature's suppressed count but does not consume global budget.
   - Remove global allowed-event timestamps where `now - timestamp >= five minutes`, making capacity available exactly at the boundary.
   - If 20 allowed-event timestamps remain, drop the eligible candidate globally. Record a global-drop counter for metadata, but do not advance the signature's `lastAllowed`; retain/create the bounded signature record so repeated attempts remain observable.
   - Otherwise allow the event, append its timestamp to the global window, set the signature's `lastAllowed`, attach and reset that signature's cooldown/global suppression counters, and preserve diagnostic identity.
4. Use monotonic/injectable time for limiter decisions. Keep all state in memory and per process; do not persist signatures across restarts.
5. Define a shared timestamped contract table that both Dart and Rust tests encode verbatim: first event at `t=0`; same signature at `t=window-epsilon` and `t=window`; 20 unique signatures at `t=0`; a 21st at `t=window-epsilon` and `t=window`; partial timestamp expiry; a repeated signature while the global budget is exhausted; and unique-signature capacity/eviction. Expected allow/drop reason, state mutation, and metadata counters must be listed for every row before delegates implement adapters.
6. Bootstrap and runtime privacy contract: synchronously read the persisted `crashReporting2` preference through a lightweight bootstrap-owned consent controller/provider before `SentryFlutter.init`. Unknown/missing remains the existing default `false`. Install one idempotent bootstrap-owned `beforeSend` pipeline with known consent before any application construction. Route the configuration cubit's crash-reporting setter/state changes into this controller and dispose its subscription with the owning bootstrap/app lifecycle; do not re-register processors. The installed Dart pipeline must honor both `false→true` and `true→false` immediately, while exact-tag manual submission remains possible in the disabled state. Native initialization remains consent-gated, but because Rust's process-global client cannot be uninstalled after opt-in, its `before_send` callback must consult a thread-safe runtime consent flag updated over an explicit non-generated/public bridge seam; after runtime opt-out it drops subsequent automatic native events. Runtime opt-in may initialize native Sentry once if it was not initialized yet. Tests must cover both transition directions without resetting the native `OnceCell`.
7. Define result metadata produced by the pure limiter decision, including whether the event is allowed, drop reason, normalized key, and per-signature cooldown/global suppression counts since the previous allowed event. Language adapters should be thin translations around this contract.
8. Document that Sentry fingerprints affect grouping but not ingestion. Suppression decisions must not use Sentry issue IDs or server-side group IDs, which are unavailable before transmission and can merge distinct native errors.

#### Phase 2 — Implement and test the Dart limiter early in startup (Luna-suitable work package)

1. Add a pure Dart limiter module under `lib/util/` with:
   - A bounded map of normalized signature records.
   - First-event pass-through.
   - Five-minute per-signature cooldown.
   - Global 20-per-five-minute automatic-event budget that still protects against streams of unique signatures.
   - Expiry/LRU-style eviction that keeps memory bounded at 256 signatures.
   - Injectable clock for deterministic tests.
2. Build Dart signatures conservatively from stable Sentry fields:
   - Mechanism/source.
   - Exception type.
   - Exception value/message.
   - Culprit or first useful application frame/function/file when available.
   - Do not include event ID, timestamp, user/geo, release, device identity, or other per-occurrence context.
3. Normalize only clearly volatile values. Strip or canonicalize memory addresses, UUID-like identifiers, and equivalent obvious runtime IDs, while preserving semantic error names/codes such as `EmptyHost`, `InvalidIpv4Address`, HRESULT/error codes, bounds, and OS error kind/errno. Do not broadly erase all numbers because bounds and error codes distinguish failures.
4. Attach the limiter directly in `SentryFlutter.init` in `lib/main.dart` so startup failures are covered. Preserve the existing `IntifaceCentralApp.eventProcessors` chain and consent behavior, but make processor ordering explicit:
   - Manual submission bypass check.
   - Existing consent processors.
   - Automatic repeat/global limiter.
   The implementation must ensure a manual event remains sendable when crash reporting is disabled, matching current behavior.
5. When an event is allowed after prior suppression, annotate it without changing its diagnostic identity, using stable tags/extra context such as suppression count, cooldown seconds, and source `dart`. The very first event should indicate zero prior suppressions or omit the count consistently.
6. Avoid recursively logging through a path that Sentry captures while processing/dropping an event. Suppression diagnostics may use debug-safe local logging only if proven non-recursive; otherwise expose counters solely through the next allowed event.
7. Add focused unit tests under `test/util/` constructing representative Sentry events for the observed paint-loop, closed-BLoC, startup filesystem, dynamic-message, and manual-submission cases.

#### Phase 3 — Correct consent and implement native Rust suppression (z.ai-suitable work package)

1. Inspect the exact `sentry` 0.41.0 APIs resolved in `rust/Cargo.lock` and use supported `ClientOptions.before_send`/event APIs rather than assuming newer SDK signatures.
2. Gate native crash-reporting initialization in `lib/intiface_central_app.dart` on the same user consent represented by `configCubit.crashReporting`/`canUseCrashReporting`. Preserve manual Dart log submission behavior. Introduce an app-level injected `initializeNativeCrashReporting` callback in the existing bootstrap/options seam, defaulting to the generated FFI function, and route the sole production initialization call through it. Tests must use a recording fake to assert disabled and enabled branches without attempting to reset Rust's process-global `OnceCell`. Separately expose/build native `ClientOptions` and its callback in a pure Rust helper so Rust tests can validate configuration without installing a global client.
3. Add a pure Rust limiter module with behavior equivalent to the Dart contract:
   - Five-minute per-signature cooldown.
   - Global 20-per-five-minute automatic-event budget.
   - Maximum 256 signature records with bounded eviction.
   - Monotonic/injectable time abstraction for deterministic tests.
   - Thread-safe access suitable for Sentry callbacks without holding locks during expensive work or transport.
4. Build native signatures from mechanism, exception/panic type and normalized value, plus the first useful non-wrapper frame when available. Treat symbol-poor bridge frames such as `store_dart_post_cobject` and generated FRB wrappers as weak fallback data, not the primary identity.
5. Preserve distinct panic discriminators observed inside `INTIFACE-CENTRAL-10B`: `EmptyHost`, `InvalidIpv4Address`, slice/index bounds, HRESULT/error code, and IO error kind. Canonicalize only volatile/localized portions so localized OS strings do not create unlimited signatures.
6. Configure an explicit native fingerprint from the same normalized panic identity when reliable. This improves Sentry triage by separating unrelated native panics currently collapsed into one group, but must remain independent from the suppression decision.
7. Annotate allowed follow-up events with prior suppression count, cooldown, and source `rust` using supported Sentry tags/extra fields.
8. Ensure the callback fails safely: signature-extraction failure may allow the event subject to the global budget, while limiter/internal errors must not panic or recursively report.
9. Add Rust unit tests in the crate for normalization, distinct panic preservation, cooldown, global budget, eviction, concurrency safety where practical, metadata, and callback failure behavior.

#### Phase 4 — Build iOS verification infrastructure and handle app hangs deliberately

1. Inspect the resolved `sentry_flutter` 9.21.0 and Cocoa SDK sources/configuration for app-hang controls and determine whether app-hang events reach Dart `beforeSend` or are sent independently by the native Cocoa integration.
2. Add a small iOS-host Sentry configuration seam plus a native XCTest/Flutter integration probe that can assert the actual resolved app-hang option values and callback/delivery path without inducing a real multi-minute hang. Keep production defaults in one adapter so the test exercises the same configuration path. Add the test target/harness if the repository lacks one.
3. Do not route `mechanism=AppHang` events through the five-minute exception-signature limiter. Changing sampled stacks during one continuous hang must not create unlimited unique exception keys, and a title-only key must not erase all performance prevalence.
4. Prefer SDK-provided app-hang configuration if available. Configure a defensible cadence/threshold that avoids several reports every few seconds from one continuing hang while retaining evidence across affected devices. Target no more than approximately one hang report per process/device per minute if the SDK exposes a suitable control.
5. If the SDK cannot enforce a cadence at the client boundary and these native events bypass Dart `beforeSend`, use the native probe to lock down that observed limitation, document it in project-facing Sentry guidance, and do not claim app-hang flood protection. Do not build unsupported native interception solely to emulate a limiter; surface the remaining operational risk explicitly.
6. Add both `dart_before_send_app_hang_classification_test`, proving ordinary Dart exceptions are limited while app-hang-shaped events bypass the generic limiter, and `ios_sentry_app_hang_configuration_test`, proving the actual Cocoa configuration/path selected by the implementation. Include a short manual iOS device sanity procedure as supplemental validation, not as a substitute for these tests.

#### Phase 5 — Integrate, verify, and document operations

1. Reconcile Dart and Rust tests against the shared behavioral contract. Equivalent input sequences should produce equivalent allow/drop decisions, though event parsing APIs differ.
2. Verify existing consent semantics:
   - Automatic Dart reports are dropped when disabled.
   - Native Sentry is not initialized when disabled.
   - Manual `ManualLogSubmit` events still send when the user explicitly submits logs.
3. Verify processor initialization order protects failures occurring before `IntifaceCentralApp.buildApp` completes.
4. Run formatting, static analysis, Dart tests, Rust tests/checks, and the existing integration tests relevant to bootstrap and engine lifecycle. Do not regenerate FFI unless a public Rust API signature actually changes; if regeneration is required, inspect and include generated changes deliberately.
5. Add concise project-facing documentation near existing Sentry/bootstrap guidance (prefer `CLAUDE.md` only if it is the repository’s maintained operational reference; otherwise a focused document under `docs/`) describing:
   - The two independent Sentry clients.
   - Consent ownership.
   - Suppression thresholds and exemptions.
   - Signature normalization rules.
   - App-hang policy/limitation.
   - How to tune constants and validate volume in Sentry after release.
6. After release, use Sentry queries for the cited issues and new suppression metadata to confirm that same-process bursts are reduced while distinct signatures and affected-platform visibility remain. This production observation is a release follow-up, not a prerequisite for merging.

### Acceptance Criteria

- **AC.1:** For an automatic Dart event with a previously unseen normalized signature, the first event is allowed, all matching events during the next five minutes are dropped, and the first matching event at/after the cooldown is allowed.
- **AC.2:** Streams of automatic Dart events with unique signatures cannot exceed 20 allowed events within the configured five-minute process budget, and limiter state never retains more than 256 signatures.
- **AC.3:** Events tagged `ManualLogSubmit=true` bypass consent-related automatic suppression and both volume limits, preserving explicit user log submission behavior.
- **AC.4:** The Dart limiter is installed during `SentryFlutter.init`, so a representative startup failure occurring before application construction is evaluated by the limiter.
- **AC.5:** Native Rust panic/error events follow the same first-event, five-minute cooldown, global-budget, and bounded-state semantics without panicking or deadlocking in the Sentry callback.
- **AC.6:** Native signatures keep observed semantic panic classes distinct (`EmptyHost`, `InvalidIpv4Address`, bounds errors, and different HRESULT/error codes) even when wrapper frames are identical, while obvious volatile/localized portions do not create unlimited signatures.
- **AC.7:** Native Sentry is not initialized when crash reporting consent is disabled, while enabled operation continues to initialize it successfully.
- **AC.8:** An allowed Dart or Rust event following suppressed repeats contains the prior suppressed count, configured window, and source metadata without changing the underlying exception/panic identity.
- **AC.9:** App-hang events are not accidentally governed by the ordinary exception signature cooldown; the selected SDK cadence/configuration is tested where supported, or the inability to enforce it is explicitly documented and surfaced as a remaining risk.
- **AC.10:** Existing Flutter bootstrap/engine behavior and manual log submission continue to pass the repository’s relevant automated tests, and no generated FFI file is manually edited.
- **AC.11:** The single installed Dart reporting pipeline immediately honors runtime consent changes in both directions without re-registration, exact-tag manual submission still works while disabled, and the native callback drops automatic events after runtime opt-out even though its process-global client remains installed.

### Test Strategy

| Acceptance criterion | Named test/check | Layer |
|---|---|---|
| AC.1 | Dart `repeat_event_limiter_first_repeat_and_cooldown_test` | Unit |
| AC.2 | Dart `repeat_event_limiter_global_budget_and_capacity_test` | Unit |
| AC.3 | Dart `sentry_processor_manual_submission_bypasses_limits_test` plus existing/focused submit-log widget test | Unit/widget |
| AC.4 | Dart `sentry_bootstrap_installs_limiter_before_app_runner_test`, `automatic_startup_event_respects_persisted_consent_test`, and `enabled_startup_reporting_reaches_pipeline_test` using an extracted/configurable bootstrap helper and fake persisted-consent provider | Unit/integration |
| AC.5 | Rust `native_limiter_first_repeat_cooldown_and_budget`, shared-table `native_limiter_contract_vectors`, and `native_before_send_never_panics_or_deadlocks` | Unit/concurrency |
| AC.6 | Rust `native_signature_preserves_semantic_panic_variants` and `native_signature_normalizes_volatile_os_text` | Unit |
| AC.7 | Dart bootstrap test `native_sentry_initialization_respects_consent` with the production branch routed through a recording injected callback; Rust `native_client_options_builds_without_global_install` | Unit/integration |
| AC.8 | Dart `allowed_followup_contains_suppression_metadata` and Rust `allowed_followup_contains_suppression_metadata` | Unit |
| AC.9 | Dart `dart_before_send_app_hang_classification_test` and native `ios_sentry_app_hang_configuration_test` through the production iOS configuration seam | Unit/native integration |
| AC.10 | New `bootstrap_registers_single_sentry_pipeline_across_recreate_test`, `submit_logs_manual_event_reaches_capture_with_expected_tag_test`, and `generated_ffi_diff_guard`, plus existing `flutter test`, relevant bootstrap/widget tests, `integration_test/flows/engine_lifecycle_test.dart`, Rust `cargo test`, `flutter analyze`, Dart formatting check, and Rust formatting/check/clippy as supported by repository conventions | Regression/static |
| AC.11 | Dart `sentry_bootstrap_pipeline_tracks_runtime_consent_changes_test` (install once; automatic event before/after `false→true→false`; manual event while false; unchanged registration count) and Rust `native_before_send_tracks_runtime_consent_without_oncecell_reset` through the thread-safe consent callback seam | Unit/integration |

Use fake clocks rather than sleeping. Include table-driven normalization cases drawn from the inspected Sentry events. Test budget-boundary timestamps and eviction explicitly. For Rust callback safety, use `catch_unwind` in the test harness where appropriate and concurrent calls sufficient to exercise synchronization without relying on timing-sensitive sleeps.

The app-hang verification must first establish SDK capability. If client-side cadence cannot be configured or intercepted with current infrastructure, AC.9 remains verifiable as a classification/bypass guarantee plus a concrete documentation check; the plan does not claim that app-hang ingestion is reduced in that case.

### Review Strategy

Before handoff, run the `plan-reviewer` subagent and fix or rebut all findings; repeat review if any high/critical findings remain.

During execution, delegate the Dart and Rust phases to Luna and/or z.ai as bounded packages, then have a separate cheaper-model delegate review the integrated implementation. The execute agent must inspect all delegate output, resolve behavioral drift between the two implementations, and run the complete verification suite.

After implementation and all automatable tests, dispatch a review subagent to inspect correctness, event-key privacy/stability, consent behavior, bounded memory, lock safety, startup ordering, manual-report exemption, and accidental app-hang suppression. Fix or explicitly rebut every finding; repeat after critical findings until none remain.

### Documentation Strategy

Add concise maintained guidance describing the dual-client Sentry architecture, consent boundary, limiter policy, manual exemption, normalization rules, app-hang policy, and tuning/production-validation procedure. Update existing bootstrap/Sentry comments where they currently imply DSN presence alone is sufficient for native reporting. Do not document issue-specific root-cause fixes as part of this change.

### Risks, Blockers, and Required Decisions

- Sentry SDK event models differ between Dart 9.21.0 and Rust 0.41.0; execution must inspect the resolved APIs and keep adapters thin around independently tested pure limiters.
- Native crash/panic delivery may terminate the process before suppression metadata can be attached to a later event. The first representative event remains the primary guarantee.
- `before_send` may not cover every Cocoa app-hang event. The plan requires capability inspection and honest documentation rather than claiming unsupported protection.
- Two independent clients mean the global ceiling is per client, not globally shared across Dart and Rust. A pathological process could therefore send up to each client’s budget. Cross-language shared limiter state is intentionally out of scope due to FFI complexity and failure-path risk.
- Conservative normalization may initially preserve more signatures than ideal; aggressive normalization risks merging distinct failures. Tests based on observed native variants should bias toward preserving diagnostic distinctions.
- Manual submissions bypass limits by design and could still be repeatedly invoked by a user; this is explicit user action rather than an automatic loop and is outside the flood-protection scope.
- The individual painter, BLoC lifecycle, filesystem, panic, and logging-performance root causes remain separate fixes. Suppression must not be used to mark those issues resolved.
- Working tree contains unrelated untracked files; execution must avoid modifying or incorporating them.