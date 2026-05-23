import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show ExternalLibrary;
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/intiface_central_app.dart';

Future<Widget> createTestApp({
  Future<void> Function()? afterRustInit,
  Future<void> Function(UserDeviceConfigurationCubit userConfigCubit)?
  afterUserDeviceConfigurationInit,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final app = await IntifaceCentralApp.create();
  return app.buildApp(
    options: IntifaceCentralBootstrapOptions(
      initializePaths: false,
      initializeWindowing: false,
      initializeTray: false,
      initializeUpdates: false,
      initializeSentry: false,
      initializeDiscord: false,
      requestPlatformPermissions: false,
      rustExternalLibrary: _bundledRustLibraryForIntegrationTest(),
      afterRustInit: afterRustInit,
      afterUserDeviceConfigurationInit: afterUserDeviceConfigurationInit,
    ),
  );
}

ExternalLibrary? _bundledRustLibraryForIntegrationTest() {
  if (!Platform.isMacOS) return null;

  final contentsDir = File(Platform.resolvedExecutable).parent.parent;
  final frameworkBinary = File(
    '${contentsDir.path}/Frameworks/rust_lib_intiface_central.framework/rust_lib_intiface_central',
  );
  if (!frameworkBinary.existsSync()) return null;

  return ExternalLibrary.open(frameworkBinary.path);
}
