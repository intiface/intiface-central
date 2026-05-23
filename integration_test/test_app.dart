import 'package:flutter/widgets.dart';
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
      afterRustInit: afterRustInit,
      afterUserDeviceConfigurationInit: afterUserDeviceConfigurationInit,
    ),
  );
}
