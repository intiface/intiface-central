# Sentry Error Reporting Architecture

Intiface Central has **two independent Sentry clients** that operate in the same
process. This document describes their configuration, consent model, and the
repeat-suppression safety net that prevents a single process from flooding
Sentry with repeating automatic error reports.

## Two Independent Clients

| Client | SDK | Language | Installed at | Lifecycle |
|--------|-----|----------|-------------|-----------|
| Dart/Flutter | `sentry_flutter` 9.21.0 | Dart | `SentryFlutter.init` in `lib/main.dart` | Process-global, installed before app construction |
| Native/Rust | `sentry` 0.41.0 | Rust | `crash_reporting()` in `rust/src/api/util.rs` | Process-global `OnceCell`, installed on first consent-granted startup or runtime opt-in |

Each client has its own `beforeSend`/`before_send` callback, its own in-memory
signature map, and its own 20-event-per-5-minute budget. The budgets are **per
client, not shared** across Dart and Rust.

## Consent Model

- The persisted preference `crashReporting2` is read synchronously from
  `SharedPreferences` in `main()` **before** `SentryFlutter.init`.
- A `SentryReportingController` holds the current consent value in memory and
  is passed into `IntifaceCentralBootstrapOptions.reportingController`.
- The Dart `beforeSend` callback reads `reporting.consent` at call time, so
  runtime consent changes take effect immediately in both directions.
- The native client stores consent in a shared `Arc<AtomicBool>` that the
  `before_send` callback checks on every event. Runtime changes are pushed
  from Dart via the generated `setCrashReportingConsent` FFI method.
- Native Sentry is **not initialized** when consent is disabled. Runtime
  `false→true` triggers a one-time initialization; `true→false` flips the
  atomic flag so subsequent automatic events are dropped by the callback.
  `initializeSentry=false` (used in tests) suppresses all native calls.

## Repeat Suppression (Automatic Events)

Both clients apply identical logic to **automatic** exception/panic events:

1. **Manual exemption**: Events tagged `ManualLogSubmit=true` (exact string
   match, case-sensitive) bypass consent and all volume limits.
2. **Consent gate**: If consent is false, all non-manual events are dropped.
3. **App-hang / non-exception bypass**: App-hang events and events without
   exceptions require consent but do **not** consume the exception limiter
   budget. This preserves performance/health evidence without drowning it in
   repeat suppression.
4. **Per-signature cooldown**: After an automatic exception is allowed, the
   same normalized signature is dropped for the next 5 minutes.
5. **Global automatic budget**: At most 20 automatic events are allowed per
   5-minute sliding window per process per client.
6. **Bounded state**: At most 256 signature records are retained (LRU eviction).

When an event is allowed after prior suppression, it carries metadata tags:
`SentryRepeatSuppressed` / `sentry_suppressed_count`, cooldown drop count,
global drop count, and the window duration in seconds.

## Signature Normalization

Signatures are built from stable Sentry fields:
- Mechanism/source type
- Exception type
- Exception value/message (normalized)
- First useful non-wrapper application frame

Normalization canonicalizes:
- Memory addresses (`0x7fff...` → `0xADDR`)
- UUIDs (`550e8400-e29b-...` → `<UUID>`)

Normalization **preserves**:
- Ordinary numbers (array bounds, error codes, HRESULT codes)
- Semantic error names (`EmptyHost`, `InvalidIpv4Address`)
- OS error kinds / errno values

Wrapper frames (`store_dart_post_cobject`, `flutter_rust_bridge`) are excluded
from the primary identity but retained as fallback data.

## Fingerprints vs. Ingestion

The Rust client sets an explicit Sentry `fingerprint` from the normalized key
on allowed events. This improves Sentry grouping by separating unrelated
panics that may currently be collapsed under symbol-poor bridge frames.

**Suppression decisions do not use Sentry fingerprints, issue IDs, or
server-side group IDs.** Those are unavailable before transmission and can
merge distinct failures. The fingerprint is set *after* the suppression
decision and is purely a grouping aid.

## App-Hang Limitation (iOS/Cocoa)

Native Cocoa app-hang events are captured by the native Sentry SDK integration
and **bypass the Dart `beforeSend` callback entirely**. The Cocoa SDK does not
expose a client-side cadence control for app-hang reports.

**What we guarantee:**
- If an app-hang event does reach our native `before_send` or Dart `beforeSend`,
  it is classified as an app-hang and bypasses the exception-signature limiter.
  It still requires consent.

**What we cannot guarantee:**
- Reducing the ingestion rate of native Cocoa app-hang events at the client
  boundary. The SDK has no cadence control, and these events bypass Dart
  `beforeSend`. This is a known remaining operational risk for iOS.

## Tuning

Constants live in:
- Dart: `lib/util/sentry_repeat_limiter.dart` — `sentryRepeatWindow` (5 min),
  `sentryAutomaticEventBudget` (20), `sentryMaximumSignatures` (256).
- Rust: `rust/src/sentry_limiter.rs` — `WINDOW` (5 min), `GLOBAL_BUDGET` (20),
  `MAX_SIGNATURES` (256).

After release, validate volume in Sentry:
1. Search for the metadata tags (`SentryRepeatSuppressed`,
   `sentry_suppressed_count`) to confirm follow-up events carry suppression data.
2. Compare event counts for previously-flooding issues before and after release.
3. Verify distinct native panic signatures remain separated (not collapsed).
