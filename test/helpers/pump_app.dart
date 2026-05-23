import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/device/device_manager_bloc.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/bloc/update/update_bloc.dart';
import 'package:intiface_central/bloc/util/asset_cubit.dart';
import 'package:intiface_central/bloc/util/error_notifier_cubit.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';
import 'package:intiface_central/bloc/util/navigation_cubit.dart';
import 'package:intiface_central/bloc/util/network_info_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'mocks.dart';
import 'fake_blocs.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  required Widget child,
  EngineControlBloc? engineControlBloc,
  DeviceManagerBloc? deviceManagerBloc,
  NavigationCubit? navigationCubit,
  IntifaceConfigurationCubit? configCubit,
  GuiSettingsCubit? guiSettingsCubit,
  UserDeviceConfigurationCubit? userConfigCubit,
  UpdateBloc? updateBloc,
  AssetCubit? assetCubit,
  NetworkInfoCubit? networkInfoCubit,
  ErrorNotifierCubit? errorNotifierCubit,
  Size windowSize = const Size(800, 600),
  double textScaleFactor = 1.0,
}) async {
  final engine = engineControlBloc ?? _defaultEngineControlBloc();
  final deviceManager = deviceManagerBloc ?? _defaultDeviceManagerBloc();
  final navigation = navigationCubit ?? NavigationCubit();
  final config = configCubit ?? _defaultConfigCubit();
  final guiSettings = guiSettingsCubit ?? _defaultGuiSettingsCubit();
  final userConfig = userConfigCubit ?? _defaultUserDeviceConfigCubit();
  final update = updateBloc ?? _defaultUpdateBloc();
  final asset = assetCubit ?? _defaultAssetCubit();
  final network = networkInfoCubit ?? _defaultNetworkInfoCubit();
  final errorNotifier = errorNotifierCubit ?? ErrorNotifierCubit();

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: windowSize,
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<EngineControlBloc>.value(value: engine),
          BlocProvider<DeviceManagerBloc>.value(value: deviceManager),
          BlocProvider<NavigationCubit>.value(value: navigation),
          BlocProvider<UpdateBloc>.value(value: update),
          BlocProvider<AssetCubit>.value(value: asset),
          BlocProvider<IntifaceConfigurationCubit>.value(value: config),
          BlocProvider<NetworkInfoCubit>.value(value: network),
          BlocProvider<ErrorNotifierCubit>.value(value: errorNotifier),
          BlocProvider<UserDeviceConfigurationCubit>.value(value: userConfig),
          BlocProvider<GuiSettingsCubit>.value(value: guiSettings),
        ],
        child: MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: child,
        ),
      ),
    ),
  );
}

MockEngineControlBloc _defaultEngineControlBloc() {
  final mock = MockEngineControlBloc();
  when(() => mock.state).thenReturn(EngineStoppedState());
  when(() => mock.isRunning).thenReturn(false);
  return mock;
}

MockDeviceManagerBloc _defaultDeviceManagerBloc() {
  final mock = MockDeviceManagerBloc();
  when(() => mock.state).thenReturn(DeviceManagerInitialState());
  when(() => mock.devices).thenReturn([]);
  when(() => mock.scanning).thenReturn(false);
  return mock;
}

MockIntifaceConfigurationCubit _defaultConfigCubit() {
  final mock = MockIntifaceConfigurationCubit();
  stubConfigurationCubit(mock);
  return mock;
}

MockGuiSettingsCubit _defaultGuiSettingsCubit() {
  final mock = MockGuiSettingsCubit();
  stubGuiSettingsCubit(mock);
  return mock;
}

MockUserDeviceConfigurationCubit _defaultUserDeviceConfigCubit() {
  final mock = MockUserDeviceConfigurationCubit();
  stubUserDeviceConfigurationCubit(mock);
  return mock;
}

MockUpdateBloc _defaultUpdateBloc() {
  final mock = MockUpdateBloc();
  when(() => mock.state).thenReturn(UpdaterInitialized());
  return mock;
}

MockAssetCubit _defaultAssetCubit() {
  final mock = MockAssetCubit();
  stubAssetCubit(mock);
  return mock;
}

MockNetworkInfoCubit _defaultNetworkInfoCubit() {
  final mock = MockNetworkInfoCubit();
  stubNetworkInfoCubit(mock);
  return mock;
}
