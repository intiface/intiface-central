# Android Native Crash in btleplug FnAdapter

Investigated: 2026-09-25

## Summary

Nearly all Android native crashes in Intiface Central are one long-standing
bug: a race between waking and closing a btleplug `droidplug` `FnAdapter`,
which jni-rs 0.22.4's `take_rust_field` turns into a use-after-free. It predates
3.2.0 and survived the btleplug 0.12.0 -> 0.13.2 / jni 0.19 -> 0.22 upgrade.

It is not SDL (SDL is not in the Android build).

## Evidence

### Google Play Developer Reporting API (`com.nonpolynomial.intiface_central`)

Crash rate (`crashRateMetricSet`, user-weighted daily average):

| versionCode | Release | User-days | Crash rate |
|---|---|---|---|
| 42 | 3.1.0 | 2,460 | 1.077% |
| 43 | 3.1.1 | 29,000 | 1.102% |
| 44 | 3.2.0 | 1,000 (3 days) | 1.145% |

Flat across releases, and right around Play's 1.09% bad-behaviour threshold
(which is measured on user-perceived crash rate).

Error issues (2026-03-01 to 2026-09-25): the overwhelming majority are SIGSEGV
or SIGBUS in `librust_lib_intiface_central.so` at
`btleplug::droidplug::jni_utils::ops::fn_adapter_call_internal`, split across
~30 Play issues for vc 43 alone (largest: 76 / 51 / 31 / 30 / 28 reports), plus
vc 40 and 42. A smaller group crashes in
`btleplug::droidplug::jni_utils::exceptions::throw_unwind`. On vc 44 the top
frame is `jni::env::EnvUnowned::with_env` with `fn_adapter_call_internal`
directly below it.

Representative stack (vc 44):

```
#00 librust_lib_intiface_central.so  jni::env::EnvUnowned::with_env
#01 librust_lib_intiface_central.so  btleplug::droidplug::jni_utils::ops::fn_adapter_call_internal
#03 io.github.gedgygedgy.rust.ops.FnAdapter.call
#05 io.github.gedgygedgy.rust.ops.FnRunnableImpl.run
    io.github.gedgygedgy.rust.task.Waker.wake            (some reports)
#06 io.github.gedgygedgy.rust.stream.QueueStream.doEvent
#07 com.nonpolynomial.btleplug.android.impl.Peripheral$Callback.onCharacteristicChanged
#09 android.bluetooth.BluetoothGattCallback.onCharacteristicChanged
    ... binder thread
```

The symbol offsets in the Play stacks (`+23461888` on every frame) show that
names come from the nearest export, not real symbolication. Treat function names
as approximate.

### Mechanism

Java side (`btleplug-0.13.2/src/droidplug/java/.../rust/stream/QueueStream.java`):

- `doEvent` (Android binder thread) reads `this.waker` under `this.lock`, then
  calls `waker.wake()` **after releasing the lock**.
- `pollNext` (Rust poll thread) swaps in a new waker under the lock, then calls
  `oldWaker.close()` **outside the lock**.
- So `FnAdapter.call` (wake) and `FnAdapter.close` can run on the same adapter
  from two threads at once. `SimpleFuture` has the same pattern.

Rust side (`droidplug/jni_utils/ops.rs`):

- `fn_adapter_call_internal` uses `env.get_rust_field(&obj, "data")` and clones
  the `Arc` while holding the returned `MutexGuard`.
- `fn_adapter_close_internal` uses `env.take_rust_field(&obj, "data")`.

jni-rs 0.22.4 (`src/env.rs`):

- `get_rust_field` takes the Java monitor, but releases it on return while
  handing back a `MutexGuard` into the heap-allocated `Mutex<T>`.
- `take_rust_field` takes the monitor, does `Box::from_raw(ptr)`, then
  `drop(mbox.try_lock()?)`. If a guard is outstanding, `try_lock` fails and the
  `?` early return **drops the Box, freeing the Mutex while the other thread
  still holds its guard**. The Java field is not zeroed on this path, so later
  calls dereference freed memory too.
- Result: SIGSEGV/SIGBUS in the call path; the `throw_unwind` variants fit a
  panic from `lock().unwrap()` on garbage memory.

This jni-rs failure-path bug does not appear to be filed upstream
(related but different: jni-rs #219, #535).

## Plan

### Phase 1: btleplug fix (deviceplug/btleplug)

1. Replace `get_rust_field` / `take_rust_field` in `droidplug/jni_utils/ops.rs`
   with an `Arc`-raw-pointer scheme stored in the `data` long field:
   - create: `Arc::into_raw` into the field.
   - call: lock the object monitor, read the pointer, if non-null
     `Arc::increment_strong_count` + `Arc::from_raw`, unlock, then invoke. An
     in-flight call owns its own reference.
   - close: lock the monitor, read and zero the field, unlock, then drop the
     `Arc` via `Arc::from_raw`.
   This is sound regardless of Java-side concurrency.
   Commit: `fix(droidplug): Make FnAdapter call/close race-free`
2. Add a stress test that calls `wake` and `close` on the same adapter
   concurrently from two threads.
   Commit: `test(droidplug): Stress concurrent FnAdapter wake and close`
3. Optional hardening: close the old waker inside the lock in `QueueStream` and
   `SimpleFuture`, or document the race as tolerated. Phase 1.1 is the real fix.
4. Audit other `get_rust_field` / `take_rust_field` users in droidplug for the
   same pattern.
5. Cut a btleplug patch release.

### Phase 2: Upstream

- File a jni-rs issue: `take_rust_field` frees the boxed `Mutex` when
  `try_lock` fails (should `Box::into_raw` it back and leave the field intact).

### Phase 3: Ship

1. Bump btleplug in buttplug (`buttplug_server_hwmgr_btleplug`) and cut releases.
2. Bump buttplug / intiface-engine in Intiface Central.
   Commit: `build: Update btleplug for Android FnAdapter crash fix`
3. Watch Play crash rate by versionCode for the new build.

### Phase 4: Symbolication

- Add `ndk { debugSymbolLevel 'FULL' }` (or upload `native-debug-symbols.zip`)
  so Play symbolicates Rust/Flutter native frames properly.
  Commit: `build: Upload Android native debug symbols to Play`

## Reproducing the Analysis

Access: service account `claude-play-console@calender-sync-490506.iam.gserviceaccount.com`
(read-only in Play Console), impersonated via the `nonpoly` gcloud configuration.

```bash
SA=claude-play-console@calender-sync-490506.iam.gserviceaccount.com
T=$(gcloud auth print-access-token --configuration=nonpoly \
  --impersonate-service-account=$SA \
  --scopes=https://www.googleapis.com/auth/playdeveloperreporting)
B=https://playdeveloperreporting.googleapis.com/v1beta1/apps/com.nonpolynomial.intiface_central

# Issues over a window (both start and end dates are required)
curl -s -G -H "Authorization: Bearer $T" "$B/errorIssues:search" \
  --data-urlencode pageSize=100 \
  --data-urlencode interval.startTime.year=2026 --data-urlencode interval.startTime.month=3 --data-urlencode interval.startTime.day=1 \
  --data-urlencode interval.endTime.year=2026 --data-urlencode interval.endTime.month=9 --data-urlencode interval.endTime.day=25

# Individual reports with full stack text (reportText)
curl -s -H "Authorization: Bearer $T" "$B/errorReports:search?pageSize=50"

# Crash rate by versionCode
curl -s -X POST -H "Authorization: Bearer $T" -H 'Content-Type: application/json' \
  "$B/crashRateMetricSet:query" -d '{"timelineSpec":{"aggregationPeriod":"DAILY",
  "startTime":{"year":2026,"month":8,"day":1,"timeZone":{"id":"America/Los_Angeles"}},
  "endTime":{"year":2026,"month":9,"day":24,"timeZone":{"id":"America/Los_Angeles"}}},
  "dimensions":["versionCode"],"metrics":["crashRate","userPerceivedCrashRate","distinctUsers"]}'
```
