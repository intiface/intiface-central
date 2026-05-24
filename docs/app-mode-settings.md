# Settings Reference

These tables list the settings currently shown by the Engine app mode,
Repeater app mode, and main Settings panel. The App Mode selector itself is
shared UI and is not included here.

## Engine App Mode Settings

### Server Settings

| Setting | Control | Default | Availability / notes |
|---|---:|---:|---|
| Start Server when Intiface Central Launches | Toggle | Off | Disabled while engine is running |
| Server Name | Text entry | `Intiface Server` | Disabled while engine is running |
| Server Port | Numeric entry | `12345` | Disabled while engine is running; valid range `1025`-`65535` |
| Listen on all network interfaces | Toggle | On mobile, off elsewhere | Disabled while engine is running |

### Device Managers

| Setting | Control | Default | Availability / notes |
|---|---:|---:|---|
| Bluetooth LE | Toggle | On | Disabled while engine is running |
| XBox Compatible Gamepads (XInput) | Toggle | On on Windows | Windows only; disabled while engine is running |
| HID Devices (Joycon, etc...) | Toggle | Off | Desktop only; disabled while engine is running |
| Lovense Connect Service (DEPRECATED) | Toggle | Off | Desktop only; shows deprecation dialog when enabled |
| Lovense USB Dongle (HID/White Circuit Board) (DEPRECATED) | Toggle | Off | Desktop only; shows deprecation dialog when enabled |
| Other Device Managers are in Advanced Settings Below | Info row | N/A | Visible hint, not configurable |

### Advanced/Experimental Settings

| Setting | Control | Default | Availability / notes |
|---|---:|---:|---|
| Show Advanced/Experimental Settings | Toggle | Collapsed unless previously expanded | Controls visibility of advanced rows |
| Broadcast Server Info via mDNS | Toggle | Off | Advanced only; disabled while engine is running |
| mDNS Identifier Suffix (Optional) | Text entry | Empty | Advanced only; disabled while engine is running |

### Advanced Device Managers

| Setting | Control | Default | Availability / notes |
|---|---:|---:|---|
| Device Websocket Server | Toggle | Off | Advanced only; disabled while engine is running |
| Simulated Devices | Toggle | Off | Advanced only; disabled while engine is running |
| Lovense USB Dongle (Serial/Black Circuit Board) (DEPRECATED) | Toggle | Off | Advanced, non-mobile only; shows deprecation dialog when enabled |
| Serial Port | Toggle | Off | Advanced, non-mobile only; disabled while engine is running |

## Repeater App Mode Settings

### Repeater Settings

| Setting | Control | Default | Availability / notes |
|---|---:|---:|---|
| Repeater Port | Numeric entry | `12345` | Disabled while engine is running; valid range `1025`-`65535` |
| Remote Server Address | Text entry | `192.168.1.1:12345` | Disabled while engine is running |

## Settings Panel

### Help / About

| Setting | Control | Default | Availability / notes |
|---|---:|---:|---|
| Help / About | Button | N/A | Shown in Settings when the side navigation bar is disabled |

### Versions and Updates

| Setting | Control | Default | Availability / notes |
|---|---:|---:|---|
| App Version | Info row | Current app version | Shows the running Intiface Central version |
| Device Config Version | Info row | Current device config version | Shows the active device config version |
| Desktop update available | Link | N/A | Desktop only; shown when visible updates are enabled and a newer app version is available |
| Manual downloads site | Link | N/A | Windows only; shown with the desktop update link |
| Check For App and Config Updates | Button | N/A | Desktop only; disabled while engine is running |
| Check for Config Updates | Button | N/A | Mobile only; disabled while engine is running |

### App Settings

| Setting | Control | Default | Availability / notes |
|---|---:|---:|---|
| Theme | Selector | System | Options are System, Light, and Dark |
| Side Navigation Bar | Toggle | On desktop, off mobile | Controls whether navigation appears as a side rail |
| Restore Window Location on Start | Toggle | On | Desktop only |
| Enable Discord Rich Presence | Toggle | Off | Desktop only |
| System Tray Icon | Selector | Tray + Taskbar | macOS and Windows only; options are No Tray Icon, Tray + Taskbar, and Tray Only |
| Check For Updates when Intiface Central Launches | Toggle | On | Checks for updates on startup |
| Crash Reporting | Toggle | Off | Disabled when crash reporting is not configured in the build |
| Send Logs to Developers | Navigation action | N/A | Opens the send-logs workflow |

### Experimental Features

| Setting | Control | Default | Availability / notes |
|---|---:|---:|---|
| REST Server | Toggle | Off | Enables the experimental REST server app mode |
| Use Prerelease (Beta) Version | Toggle | Off | Desktop only |

### Reset Application

| Setting | Control | Default | Availability / notes |
|---|---:|---:|---|
| Reset User Device Configuration | Action | N/A | Disabled while engine is running; deletes per-device user configuration |
| Reset Application Configuration | Action | N/A | Disabled while engine is running; deletes app configuration, downloaded engine/config files, news, and user device configuration |

### Advanced Mobile Settings

| Setting | Control | Default | Availability / notes |
|---|---:|---:|---|
| Use Foreground Process | Toggle | On | Android and iOS only; disabled while engine is running; changing this requires app restart |
| Request Bluetooth Permissions | Action | N/A | Android and iOS only; opens OS permission request flow and app settings if permissions are permanently denied |
