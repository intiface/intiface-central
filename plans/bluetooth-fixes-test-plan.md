# Manual Test Plan: Bluetooth Fixes

Covers two related changes:
1. **Pre-flight Bluetooth checks** (`1e3cbba`) -- prevents BLE scanner NPE crashes
2. **Request Bluetooth Permissions button** (`389a69b`) -- recovery path for denied permissions

---

## Prerequisites

- Android device (API 31+ / Android 12+) with debug build installed
- iOS device with debug build installed
- Ability to toggle Bluetooth on/off in system quick-settings
- Ability to revoke app permissions via OS Settings > Apps > Intiface Central

---

## Feature 1: Pre-flight Bluetooth Checks

These tests verify that starting the engine with missing permissions or disabled
Bluetooth shows a dialog instead of crashing.

### Test 1.1 -- Engine start with Bluetooth OFF (Android & iOS)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Turn Bluetooth OFF in system settings | |
| 2 | Open Intiface Central | App launches normally |
| 3 | Tap the Start Server button | Dialog appears: "Bluetooth Not Ready" with message about Bluetooth not being enabled |
| 4 | Tap "Ok" to dismiss | Dialog closes, server remains stopped (no crash) |
| 5 | Turn Bluetooth ON | |
| 6 | Tap Start Server again | Engine starts successfully |

### Test 1.2 -- Engine start with scan permission denied (Android)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Go to OS Settings > Apps > Intiface Central > Permissions | |
| 2 | Revoke "Nearby devices" (Bluetooth) permission | |
| 3 | Open Intiface Central | App launches normally |
| 4 | Tap Start Server | Dialog appears: "Bluetooth Not Ready" with message about scan permission |
| 5 | Tap "Ok" | Dialog closes, server remains stopped (no crash) |

### Test 1.3 -- Engine start with scan permission denied (iOS)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Go to iOS Settings > Intiface Central | |
| 2 | Toggle Bluetooth OFF | |
| 3 | Open Intiface Central | App launches normally |
| 4 | Tap Start Server | Dialog appears: "Bluetooth Not Ready" with permission message |
| 5 | Tap "Ok" | Dialog closes, server remains stopped (no crash) |

### Test 1.4 -- Autostart skipped when Bluetooth not ready (Android & iOS)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Enable "Start Server on Startup" in app settings | |
| 2 | Turn Bluetooth OFF | |
| 3 | Force-close and reopen Intiface Central | App launches, server does NOT auto-start. Console log shows "Skipping autostart" warning |
| 4 | Turn Bluetooth ON | |
| 5 | Force-close and reopen | Server auto-starts normally |

### Test 1.5 -- Desktop unaffected (Windows / macOS / Linux)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open Intiface Central on desktop | |
| 2 | Tap Start Server | Engine starts normally; no pre-flight dialog (check is skipped on desktop) |

---

## Feature 2: Request Bluetooth Permissions Button

These tests verify the settings button for re-requesting BT permissions.

### Test 2.1 -- Button visibility (mobile only)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open Settings page on Android or iOS | "Advanced Mobile Settings" section visible, contains "Request Bluetooth Permissions" tile |
| 2 | Open Settings page on desktop | "Advanced Mobile Settings" section is NOT shown |

### Test 2.2 -- Permissions already granted (Android & iOS)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Ensure BT permissions are already granted (default after first install + accept) | |
| 2 | Open Settings > Advanced Mobile Settings | |
| 3 | Tap "Request Bluetooth Permissions" | Confirmation dialog: "Bluetooth permissions granted" |
| 4 | Tap "Ok" | Dialog dismisses cleanly |

### Test 2.3 -- First denial, re-promptable (Android)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Fresh install (or revoke permissions without "Don't ask again") | |
| 2 | On first BT permission prompt at app startup, tap "Don't Allow" | App starts with permissions denied |
| 3 | Open Settings > Advanced Mobile Settings | |
| 4 | Tap "Request Bluetooth Permissions" | OS permission dialog appears again |
| 5 | Tap "Allow" | Confirmation dialog: "Bluetooth permissions granted" |

### Test 2.4 -- Permanently denied (Android "Don't ask again")

| Step | Action | Expected |
|------|--------|----------|
| 1 | Deny BT permission twice (or check "Don't ask again") so it becomes permanently denied | |
| 2 | Open Settings > Advanced Mobile Settings | |
| 3 | Tap "Request Bluetooth Permissions" | OS App Settings page opens (system settings for Intiface Central) |
| 4 | Manually grant "Nearby devices" permission in OS settings | |
| 5 | Return to Intiface Central | App still functional |
| 6 | Tap "Request Bluetooth Permissions" again | Confirmation dialog: "Bluetooth permissions granted" |

### Test 2.5 -- Permanently denied (iOS)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Deny BT permission when prompted at startup | Permission is permanently denied on iOS (no re-prompt) |
| 2 | Open Settings > Advanced Mobile Settings | |
| 3 | Tap "Request Bluetooth Permissions" | iOS Settings page for Intiface Central opens |
| 4 | Toggle Bluetooth ON in the app's iOS settings | |
| 5 | Return to Intiface Central | App still functional |
| 6 | Tap "Request Bluetooth Permissions" again | Confirmation dialog: "Bluetooth permissions granted" |

### Test 2.6 -- Dismiss OS dialog without choosing (Android)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set up state where permission is denied (not permanently) | |
| 2 | Tap "Request Bluetooth Permissions" | OS permission dialog appears |
| 3 | Tap back / dismiss the OS dialog without granting or denying | No confirmation dialog, no crash, app remains responsive |

---

## Integration: Both Features Together

### Test 3.1 -- Full recovery flow (Android)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Revoke BT permissions + turn Bluetooth OFF | |
| 2 | Open app, tap Start Server | Pre-flight dialog: "Bluetooth Not Ready" (permission message) |
| 3 | Dismiss dialog, go to Settings | |
| 4 | Tap "Request Bluetooth Permissions" | OS prompt or app settings opens |
| 5 | Grant permission | |
| 6 | Turn Bluetooth ON | |
| 7 | Tap Start Server | Engine starts successfully |

### Test 3.2 -- Full recovery flow (iOS)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Deny BT permission + turn Bluetooth OFF | |
| 2 | Open app, tap Start Server | Pre-flight dialog: "Bluetooth Not Ready" |
| 3 | Dismiss dialog, go to Settings | |
| 4 | Tap "Request Bluetooth Permissions" | iOS Settings opens |
| 5 | Grant Bluetooth permission, turn BT ON | |
| 6 | Return to app, tap Start Server | Engine starts successfully |

---

## Notes

- On Android API <= 30, legacy location permissions are also requested at startup.
  These tests focus on API 31+ BT permissions (`bluetoothConnect`, `bluetoothScan`).
- The `openAppSettings()` call navigates to the OS-level app info page, not directly
  to the permission toggle. Users must find the permission setting themselves. This is
  an OS limitation, not something the app can control.
- On iOS, the first denial of a permission is effectively permanent. The OS will never
  re-show the permission prompt, so `openAppSettings()` is always the recovery path.
