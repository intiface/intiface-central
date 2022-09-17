# Intiface Engine Flutter Bridge

This flutter plugin uses [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge) to create a binding layer between Flutter/Dart and [Intiface Engine](https://github.com/intiface/intiface-engine). While it is included with and only meant to be built for Intiface Central (and therefore not distributed on the flutter pub repo), it could certainly be used in other flutter applications for embedding a Buttplug hardware server on mobile.

## Compiling

Setup and compilation of the plugin requires two steps:

- Running codegen
- Compiling and/or integrating the output library

### Codegen

FRB codegen files are normally included with the project and do not need to be regenerated unless new methods are being added to the api.rs file.

Due to flutter_rust_bridge exporting all pub symbols it can find in a project ([relevant github issue here](https://github.com/fzyzcjy/flutter_rust_bridge/issues/717)), running codegen on an unedited codebase can export symbols we don't want. Specifically, Android JNI symbols required to be unmangled for JVM loading that will appear in iOS symbols if care is not taken. 

To run codegen, the JNI_OnLoad method in the `intiface-engine-flutter-bridge/src/mobile_init/setup/android.rs` file needs to be commented out. Then the following command should be run in the `intiface-engine-flutter-bridge` directory:

`flutter_rust_bridge_codegen --rust-input ./src/api.rs --dart-output ../lib/bridge_generated.dart -c ../example/ios/Runner/bridge_generated.h`

After this, the JNI_OnLoad method should be uncommented, and the new generated files checked into the repo.

### Compilation

Compilation of the plugin should usually be integrated with whatever project is using it (in this case, Intiface Central, which is part of the same monorepo).

### Notes and Warnings

- Compiling the library will require a vendored version of OpenSSL. This requires a version of perl
  capable of creating unix style paths, making this difficult to build on stock windows. It is recommended to build the Android libraries on WSL if windows compilation is required. After that library is built, all flutter work can be done in windows as normal.
- The versions of the rust btleplug and jni packages in this project **MUST** match those in the
  version of Buttplug that is in the intiface-engine dependency. Otherwise there will be a static storage mismatch, which will usually end up in `droidplug failed to initialize` errors with notes about the JAVAVM missing. If this happens, the first things to check is that the versions are the same across the Cargo.toml files.