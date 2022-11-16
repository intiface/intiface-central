# 0.0.4

## Features

- Device panel implementation
  - Can connect to and test device movements.
  - Allows for reading of sensors (subscribing coming later)
  - Can be used while clients are connected, or if clients are not connected.

## Bugfixes

- Fixed Lovense Connect settings
- Fixed Android App Permissions
- Default to expanded UI on Desktop

# 0.0.3

## Features

- Device Panel has beginnings of device controls
- Re-enable macOS Sandbox
- Add link handling in news display
- Log to files (limited to last 5 sessions)
- App reset works completely within the app (needed for iOS)
- Error notifications now show up in icon color and compact display
- App splash screen

## Bugfixes

- Links now clickable in News panel
- macOS has sandbox activated again
- Add guard to make sure multiple servers can't run at once
- Reset server on start when in Debug (for GUI reloading)
- Consolidate bridge tasks but make sure they don't stall

# 0.0.2 (Desktop) - 2022/10/23

## Features

- Update to Intiface engine v1.0.2/Buttplug v6.1.0
  - Adds new Bluetooth device finding methods
  - Fixes Keon naming
  - Fixes issues with Buttplug servers not connecting to older clients
- Engine is now built into Intiface Central.
  - Good news: Less external engine breakage and weird OS security issues. Bad news: Gotta update
    app any time Buttplug updates.
- Ability to set Websocket server port.

## Bugfixes

- Fixed issue with Android dead code elimination removing btleplug symbols in release
- Settings changes now only allowed when server not running

# 0.0.1 (Desktop) - 2022/10/15

## Features

- Add check for Intiface Central Desktop updates
- Removed control panel status icons, now only display when status is live (i.e. update waiting)
- Added ability to reset configuration
- Update check now happens on start automatically, with option to disable

## Bugfixes

- Start/Stop server button now actually looks like a button
- Intiface Central Desktop now checks for engine existence, warns if it doesn't exist

# 0.0.0 (Desktop, Android) - 2022/10/02

## Features

- First released version, discord distribution only
- Basic server start/stop, hosting on websockets on desktop/mobile
- Can download news and engine updates
- Simple settings panel
- Device panel shows currently connected devices