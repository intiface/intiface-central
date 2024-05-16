# 1.1.0 (2024/05/15)

## Features

- Update to Buttplug v3/Intiface Engine v3
  - Expands local API to allow for config management in native code

# 1.0.15 (2024/04/20)

## Features

- Update to Buttplug v7.1.16/Intiface Engine v2.0.4
  - Add hardware support for many JoyHub devices, some Kiiroo, Lioness
  - Fix bugs with Lovense Solace, some JoyHub devices

# 1.0.14 (2024/03/17)

## Features

- Update to Buttplug v7.1.15/Intiface Engine v2.0.3
  - Fix a bunch of shutdown panics in lovense dongle
  - Remove or fix a bunch of futures that weren't being awaited

# 1.0.13 (2024/03/16)

## Features

- Update to Buttplug v7.1.14/Intiface Engine v2.0.2
  - Hardware support updates

# 1.0.12 (2024/01/28)

## Features

- Update to Buttplug v7.1.13/Intiface Engine v2.0.1
  - Hardware support, mostly

# 1.0.11 (2024/01/21)

## Features

- Update to Buttplug v7.1.12/Intiface Engine v2.0.0
  - Move logging and sentry handling up to this level, since this is the application level now

# 1.0.10 (2023/11/18)

## Features

- Update to Buttplug v7.1.10/Intiface Engine v1.4.9
  - Fixes bug with invalid strings in android bluetooth advertisement handling

# 1.0.9 (2023/11/16)

## Features

- Update to Buttplug v7.1.9/Intiface Engine v1.4.8
  - Added Lovense Solace, OhMiBod Foxy, Chill support

# 1.0.8 (2023/11/04)

## Features

- Update to Buttplug v7.1.8/Intiface Engine v1.4.7
  - Code fix required for a lovense devices to work, which is pretty much a forcing factor for a
    new version. :c

## Bugfixes

- Set rust log env var to make reqwest and its dependencies shut up.

# 1.0.7 (2023/10/19)

## Features

- Update to Intiface Engine 1.4.6/Buttplug 7.1.7
  - Add device keepalive on iOS
- Reshuffle some logging methods (still needs cleanup)

# 1.0.6 (2023/10/08)

## Features

- Update to Intiface Engine 1.4.5/Buttplug 7.1.6
  - Check respective changelogs for updates
  - Only code change: Add mDNS options

# 1.0.5 (2023/07/16)

## Features

- Update to Intiface Engine 1.4.2/Buttplug 7.1.2
  - Magic Motion device additions, Lovense Connect fix

# 1.0.4 (2023/07/09)

## Features

- Update to Intiface Engine 1.4.1
- Add methods for handling user config import/export to dart

# 1.0.3 (2023/02/19)

## Features

- Update to Intiface Engine 1.3.0, adding new Websocket Client connection option
  - Engine v1.3.0 contains Buttplug v7.0.2, which also has some hardware protocol updates.

# 1.0.2 (2023/01/30)

## Bugfixes

- Update to Intiface Engine 1.2.2, fixing EngineStopped message timing

# 1.0.1 (2023/01/16)

## Features

- Update to Intiface Engine 1.2.1/Buttplug 7.0.1

# 1.0.0 (2022/12/19)

## Features

- Totally forgot to keep a changelog and versioning for this so far. Oops.
- Update to Intiface Engine 1.1.0/Buttplug 6.3.0

# 0.0.1 (2022/09/11)

- First version