# Windows Exit Crash in cnativeapi (Intiface Central 3.2.0)

Investigated: 2026-09-25

## Summary

The spike in Windows fatal crashes in 3.2.0 (`intiface_central@3.2.0+44`) is a
single bug: a C++ static-destruction-order use-after-free inside
`cnativeapi.dll` that runs during process exit. `cnativeapi` is new in 3.2.0,
pulled in transitively by `tray_manager` 0.5.3 -> 0.7.0 (which moved onto
leanflutter's `nativeapi` FFI library).

It is **not** the SDL gamepad hardware manager.

## Evidence

### Sentry (org `nonpolynomial`, project `intiface-central`)

- ~25 issues, ~1,900 events, 900+ users, all `EXCEPTION_ACCESS_VIOLATION_READ / 0x48`.
  Largest: INTIFACE-CENTRAL-11M (1251 events / 510 users), 1B8 (300 / 124),
  1KZ (249 / 243), 1KR (53 / 21), 1KG (15 / 14), plus ~20 small ones.
- Every event faults at the same instruction: `cnativeapi.dll+0x4b9ee`, same
  module build (`code_id 6ab073b0a9000`).
- Stack: `__scrt_common_main_seh` -> `common_exit` -> `RtlExitUserProcess` ->
  `LdrShutdownProcess` -> `execute_onexit_table` -> cnativeapi. Only one thread
  remains in each dump (normal once `ExitProcess` has terminated the rest).
- No event has `rust_lib_intiface_central.dll` (where SDL is statically linked)
  on the crashing stack. The one apparent hit (1M7) is a stack-scan artifact at
  `0x7ffcffffffff`.
- `cnativeapi.dll` has no PDB (`debug_status=missing`), so the stackwalker falls
  back to scanning and invents a different "culprit" per event (setupapi
  `DllMain`, `FlsGetValue`, flutter `UpdatePopupPosition`, ...). That is why
  one bug became ~25 issues.

### Dependency diff (v3.1.1+43 -> v3.2.0+44 `pubspec.lock`)

- `tray_manager` 0.5.3 -> 0.7.0
- `nativeapi` 0.3.0 and `cnativeapi` 0.3.0 added (did not exist in 3.1.1)

### Mechanism (cnativeapi 0.3.0 source)

- `capi/tray_icon_c.cpp`: `native_tray_icon_create` does
  `HandleTable::GetInstance().Insert(std::make_shared<TrayIcon>())`. C++17
  sequences `GetInstance()` before the argument, so `HandleTable`'s
  function-local static is constructed first.
- `platform/windows/tray_icon_windows.cpp`: the `TrayIcon::Impl` constructor
  lazily creates the `TaskbarRestartWatcher` Meyers singleton (added in 0.2.6,
  "tray icons are added again when Explorer restarts").
- Static destruction runs in reverse: the watcher is destroyed first, then
  `HandleTable`'s destructor drops the last `shared_ptr<TrayIcon>`, whose
  `~Impl()` calls `TaskbarRestartWatcher::GetInstance().Remove(id)` on a
  destroyed `std::unordered_map` -> read of freed/zeroed memory at `0x48`.
- cnativeapi 0.4.0 (released 2026-09-25) still has the same singleton.
  Upgrading does not fix it.

### App exit paths (all reach CRT exit with a live tray icon)

- Window X when tray mode is not `tray_only`: runner `main()` returns.
- Tray -> Quit (`lib/intiface_central_app.dart`): calls `trayManager.destroy()`
  then `exit(0)`, but `destroy()` defers the menu binding dispose via
  `Timer.run`, which never runs before `exit(0)`.
- Steam Deck exit (`lib/widget/body_widget.dart`) and updater
  (`lib/bloc/update/github_update_provider.dart`): `exit(0)` with no destroy.

## Ruled Out

- **SDL gamepad manager**: its task lives in a `static OnceLock` that Rust never
  drops; `SDL_Quit` never runs and nothing SDL executes during DLL detach. This
  is the exit-safe design on Windows. Do not add `SDL_Quit` in a `Drop`, atexit
  handler, or DLL detach; that would reproduce this bug class in our own DLL.
- **INTIFACE-CENTRAL-1H2 `EngineCleanupTimeout`**: 69 of 70 events are from
  3.1.1; not a 3.2.0 regression.

## Plan

### Phase 0: Confirm (no code)

1. On Windows, run 3.2.0 with tray mode not `tray_only`, close with the window X.
   Event Viewer -> Windows Logs -> Application should show
   `Faulting module name: cnativeapi.dll` with fault offset `0x4b9ee`. Repeat
   with tray -> Quit.
2. Controls: 3.1.1 exits cleanly. Tray mode `none` (no icon ever created) is
   expected not to crash.

### Phase 1: Fix

Option A, hotfix for 3.2.1:

- Commit: `fix: Pin tray_manager to 0.5.3 to avoid Windows exit crash`
- Risk: 0.7.0 may have been adopted for Flutter 3.47 compatibility or to drop
  the Linux `libayatana-appindicator3-dev` requirement. Verify 0.5.3 builds on
  all desktop targets before shipping.

Option B, proper fix (and path back to 0.7.x):

- Patch cnativeapi so the watcher is leaked, matching the existing
  `WindowMessageDispatcher` pattern:
  `static auto* instance = new TaskbarRestartWatcher(); return *instance;`
- File issue + PR on leanflutter/nativeapi.
- Optionally carry it via `dependency_overrides` on a git fork until released.
- Commit: `fix: Override cnativeapi with exit-safe TaskbarRestartWatcher`

Not recommended as the fix: calling `trayManager.destroy()` on every exit path.
The window-X path ends in the native runner, outside Dart's control, and the
deferred menu-binding dispose makes the Quit path unreliable anyway.

### Phase 2: Sentry hygiene

1. Build Windows plugin DLLs with `/Zi` + `/DEBUG` in Release and add
   `sentry debug-files upload` for them to Windows CI.
   Commit: `build: Upload Windows plugin PDBs to Sentry`
2. Upload Dart symbols (`--split-debug-info`) if not already; the `0x01c3...`
   frames are unsymbolicated Dart AOT code.
3. Merge the ~25 issues into INTIFACE-CENTRAL-11M and add a fingerprint rule on
   `stack.package:*cnativeapi.dll` so this cannot fragment again.

### Phase 3: Re-check after the fix ships

- INTIFACE-CENTRAL-1M6 (`mtx_do_lock` null read, 26 events / 3 users): Dart
  calls into cnativeapi via FFI and hits a null mutex. Probably the same
  teardown family; confirm it disappears.
- INTIFACE-CENTRAL-NA (`FormatException` on NUL-filled JSON): almost entirely
  3.1.x. Looks like a config file zeroed by a non-atomic write. Separate issue.
- Watch the 3.2.1 Windows crash-free rate in Sentry.

## Reproducing the Analysis

```bash
# Windows 3.2.0 issues by frequency
sentry api "/api/0/projects/nonpolynomial/intiface-central/issues/?query=release:intiface_central@3.2.0%2B44%20os.name:Windows&statsPeriod=14d&limit=50&sort=freq"

# Latest event for an issue (run from a directory where sentry auth resolves)
sentry api "/api/0/organizations/nonpolynomial/issues/INTIFACE-CENTRAL-11M/events/latest/"
```
