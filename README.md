# Intiface® Central

[![Patreon donate button](https://img.shields.io/badge/patreon-donate-yellow.svg)](https://www.patreon.com/qdot)
[![Github donate button](https://img.shields.io/badge/github-donate-ff69b4.svg)](https://www.github.com/sponsors/qdot)
[![Discourse Forums](https://img.shields.io/discourse/status?label=buttplug.io%20forums&server=https%3A%2F%2Fdiscuss.buttplug.io)](https://discuss.buttplug.io)
[![Discord](https://img.shields.io/discord/353303527587708932.svg?logo=discord)](https://discord.buttplug.io)
[![Twitter](https://img.shields.io/twitter/follow/buttplugio.svg?style=social&logo=twitter)](https://twitter.com/buttplugio)

Intiface Central is a frontend application for the [Buttplug Sex Toy Control Library](https://buttplug.io), for Desktop (Win/macOS/Linux) and Mobile (Android/iOS).

For users, it provides simple, friendly capabilites for managing, connecting, customizing devices.

For developers, it allows their application to connect to and control sex toys, without having to worry about constantly updating the underlying libraries or dealing with bugs and crashes in a difficult-to-debug cross langauge environment.

## How to Get Binaries/Installers

- **Windows:**
  - Use the [latest github release](https://intiface.com/central)
  - [Steam](https://store.steampowered.com/app/2273160/Intiface_Central/) support coming soon.
- **macOS:**
  - Use the [latest github release](https://intiface.com/central)
  - [Steam](https://store.steampowered.com/app/2273160/Intiface_Central/) and macOS App Store
    support coming soon.
- **Linux:**
  - **Ubuntu 20.04/22.04:** Use the [latest github release](https://intiface.com/central)
  - **Arch:** [Use the intiface-central-bin package in AUR](https://aur.archlinux.org/packages/intiface-central-bin) (Maintained by community)
  - **Alpine:** [Use the intiface-central package in the Alpine repo](https://pkgs.alpinelinux.org/package/edge/testing/x86_64/intiface-central)
  - **Steam Deck:** [Steam](https://store.steampowered.com/app/2273160/Intiface_Central/) support
    coming soon, for now Ubuntu 20.04 builds seem to work.
  - **All others:** Recommended to build yourself using instructions below (Flatpak coming
    soon)[https://github.com/intiface/intiface-central/issues/62]
- **Android:** 
  - Use the [Google Play Store](https://play.google.com/store/apps/details?id=com.nonpolynomial.intiface_central&hl=en_US&gl=US)
  - For countires where the Play Store is not available, APKs are now included in [Github
    Releases](https://github.com/intiface/intiface-central/releases) for sideloading.
- **iOS:** 
  - Use the [Apple App Store](https://apps.apple.com/us/app/intiface-central/id6444728067)

## How to Build

Building Intiface Central will require the following tools:

- Flutter SDK (3.27.1 or greater) and it's requirements for your platform (XCode for iOS/macOS,
  Android SDK/JDK etc for Android, etc...)
- Rust (Latest version)

To run a development version instead of making a build, switch out the `flutter build -d [target]` statements below with `flutter run [target]` (or just `flutter run` if the default platform is what you're aiming for).

### Desktop

To build for Desktop, simply run 

`flutter build`

Or, if you have multiple targets available

`flutter build -d [target]`

All platforms now build through the main build command, there is no longer a need to issue separate commands when building Android.

## How to Get Support

Support is currently available via:

- [On our Discourse forums](https://discuss.buttplug.io)
- Posting issues to this github repo, assuming you have a github account
- On [our discord server](https://discord.buttplug.io)

## Contributing

If you have issues or feature requests, please feel free to [file an
issue](https://github.com/intiface/intiface-central/issues) or [let us know on our
forums](https://discuss.buttplug.io).

We are not looking for code contributions or pull requests at this time, and will not accept pull
requests that do not have a matching issue where the matter was previously discussed. Pull requests
should only be submitted after talking to [qdot](https://github.com/qdot) via issues (or on [our
forums](https://discuss.buttplug.io), [discord](https://discord.buttplug.io) or [twitter
DMs](https://twitter.com/buttplugio) if you would like to stay anonymous and out of recorded info on
the repo) before submitting PRs. Random PRs without matching issues and discussion are likely to be
closed without merging. and receiving approval to develop code based on an issue. Any random or
non-issue pull requests will most likely be closed without merging.

In accordance with the licensing and management of open source projects created by Nonpolynomial
Labs, all contributors must sign a CLA.

If you'd like to contribute in a non-technical way, we need money to keep up with supporting the
latest and greatest hardware. We have multiple ways to donate!

- [Patreon](https://patreon.com/qdot)
- [Github Sponsors](https://github.com/sponsors/qdot)
- [Ko-Fi](https://ko-fi.com/qdot76367)

## License

Intiface® is a registered trademark of Nonpolynomial Labs, LLC.

Intiface Central and its components are Copyright Nonpolynomial Labs, LLC, 2022-2024

Intiface Central is covered under a dual GPL 3/Commercial license. For inquiries
about commercial licensing, or other questions pertaining to licenses around Buttplug/Intiface,
please contact support@nonpolynomial.com

Text of the GPL3 License is included in [LICENSE.md](LICENSE.md).

The Intiface Engine Flutter Bridge component is covered under a BSD 3-Clause License.

Text of the BSD 3-Clause License is included in [that component's LICENSE.md](intiface-engine-flutter-bridge/LICENSE.md)