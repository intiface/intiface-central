import 'dart:ffi';

import 'bridge_generated.dart';

// Re-export the bridge so it is only necessary to import this file.
export 'bridge_generated.dart';
import 'dart:io' as io;

const _base = 'intiface_engine_flutter_bridge';

// On MacOS, the dynamic library is not bundled with the binary,
// but rather directly **linked** against the binary.

final _dylib = io.Platform.isWindows
    ? '$_base.dll'
    : io.Platform.isLinux
        ? 'lib/lib$_base.so'
        : 'lib$_base.so';

// The late modifier delays initializing the value until it is actually needed,
// leaving precious little time for the program to quickly start up.
final IntifaceEngineFlutterBridge api = IntifaceEngineFlutterBridgeImpl(
    io.Platform.isIOS || io.Platform.isMacOS ? DynamicLibrary.executable() : DynamicLibrary.open(_dylib));
