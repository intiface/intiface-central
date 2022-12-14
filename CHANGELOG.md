# v2.2.1 - 2023/01/05

## Bugfixes

- Fixed iOS symbol stripping being too overzealous and stripping rust symbols.
- Fixed Version updater showing updates available for Mobile builds.

# v2.2.0 - 2023/01/02

## Features

- Update to Intifice Engine 1.2.0/Buttplug v7.0.0
  - Added Device Support
    - GBalls v3
    - The Cowgirl/The Unicorn
  - Bugfixes for user config loading
  - Bugfixes for Svakom Iker

# v2.1.0 - 2022/12/19

## Features

- Update to Intiface Engine 1.1.0/Buttplug v6.3.0
  - Added Device Support
    - MetaXSire (all products)
    - Lovense Gemini, Gravity, Flexer
    - Roselex (all products)
    - Hismith Widolo devices
    - TryFun Yuan series devices
  - Add support for the Kiiroo Pearl 2.1 Sensors and Battery Level

## Bugfixes

- Buttplug v6.3.0 bugfixes
  - Buttplug #532: Simplify Generic Command Manager Match-all Processing
    - Fixes issues with Satisfyer/WeVibe/Magic Motion for applications with high thruput
  - Fix issues with Lovense vibration command formation between single/multi vibrator devices
  - Fix issue with the Vorze Cyclone SA not being addressed correctly
  - Fix Hgod protocol update loop
  - Fix deserialization of multi-type battery field in Lovense Connect service

# v2 - 2022/11/26

## Bugfixes

- Remove some spammy log messages
- Update to Buttplug v6.2.2
  - Server should run StopAllDevices before exiting
  - Fix issues with only Bluetooth DCMs working
  - Fix issues with XInput devices panicking
  - Fix issues with Lovense Dongle devices panicking
  - Fix error message that's not actually an error on iOS/macOS

# v1 (All Platforms) - 2022/11/24

## Features

- Added basic help/about panel content
- Updated to Intiface Engine v1.0.4
  - Includes Buttplug v6.2.1, w/ Lovense Flexer support, Lovense Connect fixes

## Bugfixes

- Fixed device panel scrolling on mobile
- Removed "Start Server on Startup" option until we've shipped a few versions and have a fallback
  for the server possibly crashing on startup.

# v0.0.4 (Desktop/Android) - 2022/11/15

## Features

- Device panel implementation
  - Can connect to and test device movements.
  - Allows for reading of sensors (subscribing coming later)
  - Can be used while clients are connected, or if clients are not connected.

## Bugfixes

- Fixed Lovense Connect settings
- Fixed Android App Permissions
- Default to expanded UI on Desktop

# 0.0.3 (Desktop Only) - 2022/11/06

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