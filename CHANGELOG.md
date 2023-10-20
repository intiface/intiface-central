# v2.5.0 - 2023/10/19

## Features

- iOS Backgrounding now stable, defaulted to on
- Crash Reporting and Log Submission moved to main settings

## Bugfixes

- Fixed issue where app window can disappear in multi-monitor situations on desktop
- Fixed issue with server shutdown instability on android
- Device Settings UX now expands correctly
- Fixed memory leak when mDNS system on
- Fixed icons on iOS
- Application display name on macOS, Android should now be "Intiface Central"
- Trying to delete non-existent config files will no longer freeze app load
- Desktop-only device managers no longer show up in mobile advanced settings

# v2.4.5 - 2023/10/08

## Bugfixes

- Update to Buttplug v7.1.6/Engine v1.4.5
  - Fixes issues with Lovense Dongles

# v2.4.4 - 2023/10/04

## Features

- Update to Buttplug v7.1.5/Intiface Engine v1.4.3
  - See [Buttplug Changelog](https://github.com/buttplugio/buttplug/blob/master/buttplug/CHANGELOG. md) for full info
- Added HID Manager for supporting Joycon connections
- (EXPERIMENTAL) Added Crash Reporting (opt-in, off by default)
- (EXPERIMENTAL) Added mDNS broadcast capabilities for engine
- (EXPERIMENTAL) Added manual log submission capabilities

# v2.4.3 - 2023/07/22

## Features

- Intiface Central now generates from CI builds

## Bugfixes

- Fix freeze on boot for macOS
- Move linux build image from Ubuntu 20.04 to Ubuntu 22.04
  - Should fix library compat issues on modern linux distros
- Fix device tab page going blank on first device connect
- Fix device title not showing in disconnected devices on first device connect

# v2.4.2 - 2023/07/16

## Features

- Update to Buttplug v7.1.2/Intiface Engine v1.4.2
  - Mostly device additions, maybe some bluetooth bug fixes, lovense connect fixes
  - See [Buttplug Changelog](https://github.com/buttplugio/buttplug/blob/master/buttplug/CHANGELOG.md) for full info
- Websocket Device setup now has UI
- Created Advanced Settings section
  - Adds raw message settings
  - Moved less-used device managers to advanced

## Bugfixes

- Devices with Raw Message exposure no longer throw errors
- Invalid configurations now deleted on startup, versus stalling app load
- Vague icons now have wording in control panel
- Changes from No symbol to Sleep symbol when engine not running
- Fixed control widget layout to not linebreak on mobile
- Added ws:// prefix for server address
- "Listen on All Interfaces" on desktop now shows 0.0.0.0 instead of null in control panel

# v2.4.1 - 2023/06/10 (iOS)

## Bugfixes

- Only query for android info on android (freezes other platforms)

# v2.4.0 - 2023/05/21 (All Platforms)

## Features

- Upgrade to Flutter v3.10
  - There's more material components, so who knows what UI might've changed.
- User Device Configuation
  - List all known (previously connected to) devices even when server not up
  - Device indexes now saved between sessions
  - Ability to add a "display name" to a device
  - Ability to choose whether or not to connect to a device
- Added Start Server on Startup Options
- Desktop - Window now remembers size, position on desktop
- Collapsable mode removed for now
  - Causes tons of issues on linux, doesn't resize right, etc...
  - Will come back in another version
- Android now defaults to foreground task mode
  - Can still opt-out on settings, but not recommended
- Update to Buttplug v7.1.0
  - Tons of device protocol fixes/updates

## Bugfixes

- Simplified internal configuration system
- Fixed bug where engine messages may possibly be repeated on engine restart

# v2.3.1 - 2023/04/14 (Android)

## Features

- Builds now include binaries for 32/64-bit ARM CPUs
- Removes background scanning perm on Android
  - Should allow app to pass review, but will break scanning in background for now.

# v2.3.0 - 2023/02/19 (All Platforms)

## Features

- Update to Flutter v3.7
  - I guess we're changing colors now too since that changed the main theme color.
- Update to Intiface Engine v1.3.0/Buttplug v7.0.2
  - Fixes bug with unordered shutdown causing engine hangs
  - Addition of Websocket Client Connector for Engine (no UI in Engine for this yet)
  - Hardware support updates for Kizuna, Svakom, Sakuraneko products
- Add option for using foregrounding (Android only)

## Bugfixes

- Actually release the correct Linux version of the app this time. :|

# v2.2.2 - 2023/01/16 (All platforms)

## Features

- Update to Intiface Engine v1.2.1/Buttplug v7.0.1
  - Mostly hardware protocol updates and bug fixes, see Buttplug v7.0.1 CHANGELOG for more info.

# v2.2.1 - 2023/01/05 (iOS)

## Bugfixes

- Fixed iOS symbol stripping being too overzealous and stripping rust symbols.
- Fixed Version updater showing updates available for Mobile builds.

# v2.2.0 - 2023/01/02 (Desktop)

## Features

- Update to Intifice Engine 1.2.0/Buttplug v7.0.0
  - Added Device Support
    - GBalls v3
    - The Cowgirl/The Unicorn
  - Bugfixes for user config loading
  - Bugfixes for Svakom Iker

# v2.1.0 - 2022/12/19 (Desktop)

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

# v2 - 2022/11/26 (Desktop/iOS)

## Bugfixes

- Remove some spammy log messages
- Update to Buttplug v6.2.2
  - Server should run StopAllDevices before exiting
  - Fix issues with only Bluetooth DCMs working
  - Fix issues with XInput devices panicking
  - Fix issues with Lovense Dongle devices panicking
  - Fix error message that's not actually an error on iOS/macOS

# v1 - 2022/11/24 (All Platforms) 

## Features

- Added basic help/about panel content
- Updated to Intiface Engine v1.0.4
  - Includes Buttplug v6.2.1, w/ Lovense Flexer support, Lovense Connect fixes

## Bugfixes

- Fixed device panel scrolling on mobile
- Removed "Start Server on Startup" option until we've shipped a few versions and have a fallback
  for the server possibly crashing on startup.

# v0.0.4 - 2022/11/15 (Desktop/Android)

## Features

- Device panel implementation
  - Can connect to and test device movements.
  - Allows for reading of sensors (subscribing coming later)
  - Can be used while clients are connected, or if clients are not connected.

## Bugfixes

- Fixed Lovense Connect settings
- Fixed Android App Permissions
- Default to expanded UI on Desktop

# 0.0.3 - 2022/11/06 (Desktop)

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

# 0.0.2 - 2022/10/23 (Desktop)

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

# 0.0.1 - 2022/10/15 (Desktop)

## Features

- Add check for Intiface Central Desktop updates
- Removed control panel status icons, now only display when status is live (i.e. update waiting)
- Added ability to reset configuration
- Update check now happens on start automatically, with option to disable

## Bugfixes

- Start/Stop server button now actually looks like a button
- Intiface Central Desktop now checks for engine existence, warns if it doesn't exist

# 0.0.0 - 2022/10/02 (Desktop/Android)

## Features

- First released version, discord distribution only
- Basic server start/stop, hosting on websockets on desktop/mobile
- Can download news and engine updates
- Simple settings panel
- Device panel shows currently connected devices