import 'package:mocktail/mocktail.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/bloc/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/bloc/util/gui_settings_cubit.dart';
import 'package:intiface_central/bloc/util/asset_cubit.dart';
import 'package:intiface_central/bloc/util/network_info_cubit.dart';
import 'package:intiface_central/src/rust/api/device_config.dart';
import 'package:intiface_central/src/rust/api/simulated_devices.dart'
    as simulated_api;
import 'package:intiface_central/src/rust/api/specifiers.dart';
import 'mocks.dart';

void stubConfigurationCubit(
  MockIntifaceConfigurationCubit mock, {
  String themeModeSetting = 'system',
  bool useCompactDisplay = false,
  bool useSideNavigationBar = true,
  bool startServerOnStartup = false,
  bool checkForUpdateOnStart = false,
  bool useSimulatedDevices = false,
  bool useBluetoothLE = true,
  bool useSerialPort = false,
  bool useHID = true,
  bool useProcessEngine = false,
  bool useDeviceWebsocketServer = false,
  bool websocketServerAllInterfaces = false,
  int websocketServerPort = 12345,
  String serverName = 'Intiface Central',
  String currentAppVersion = '3.0.0',
  String latestAppVersion = '3.0.0',
  String currentDeviceConfigVersion = '0.0',
  bool crashReporting = false,
  bool canUseCrashReporting = false,
  bool restoreWindowLocation = true,
  bool useDiscordRichPresence = false,
  String trayIconMode = 'both',
  bool usePrereleaseVersion = false,
  bool useForegroundProcess = true,
  bool useLovenseConnectService = false,
  bool useLovenseHIDDongle = false,
  bool useLovenseSerialDongle = false,
  bool hasAcknowledgedLovenseConnectDeprecation = true,
  bool hasAcknowledgedLovenseDongleDeprecation = true,
  AppMode appMode = AppMode.engine,
  bool broadcastServerMdns = true,
  String mdnsSuffix = '',
  bool allowExperimentalRestServer = false,
  int repeaterLocalPort = 12345,
  String repeaterRemoteAddress = '192.168.1.1:12345',
  String displayLogLevel = 'info',
}) {
  when(() => mock.state).thenReturn(IntifaceConfigurationStateNone());
  when(() => mock.stream).thenAnswer((_) => const Stream.empty());
  when(() => mock.themeModeSetting).thenReturn(themeModeSetting);
  when(() => mock.useCompactDisplay).thenReturn(useCompactDisplay);
  when(() => mock.useSideNavigationBar).thenReturn(useSideNavigationBar);
  when(() => mock.startServerOnStartup).thenReturn(startServerOnStartup);
  when(() => mock.checkForUpdateOnStart).thenReturn(checkForUpdateOnStart);
  when(() => mock.useSimulatedDevices).thenReturn(useSimulatedDevices);
  when(() => mock.useBluetoothLE).thenReturn(useBluetoothLE);
  when(() => mock.useSerialPort).thenReturn(useSerialPort);
  when(() => mock.useHID).thenReturn(useHID);
  when(() => mock.useProcessEngine).thenReturn(useProcessEngine);
  when(
    () => mock.useDeviceWebsocketServer,
  ).thenReturn(useDeviceWebsocketServer);
  when(
    () => mock.websocketServerAllInterfaces,
  ).thenReturn(websocketServerAllInterfaces);
  when(() => mock.websocketServerPort).thenReturn(websocketServerPort);
  when(() => mock.serverName).thenReturn(serverName);
  when(() => mock.currentAppVersion).thenReturn(currentAppVersion);
  when(() => mock.latestAppVersion).thenReturn(latestAppVersion);
  when(
    () => mock.currentDeviceConfigVersion,
  ).thenReturn(currentDeviceConfigVersion);
  when(() => mock.crashReporting).thenReturn(crashReporting);
  when(() => mock.canUseCrashReporting).thenReturn(canUseCrashReporting);
  when(() => mock.restoreWindowLocation).thenReturn(restoreWindowLocation);
  when(() => mock.useDiscordRichPresence).thenReturn(useDiscordRichPresence);
  when(() => mock.trayIconMode).thenReturn(trayIconMode);
  when(() => mock.usePrereleaseVersion).thenReturn(usePrereleaseVersion);
  when(() => mock.useForegroundProcess).thenReturn(useForegroundProcess);
  when(
    () => mock.useLovenseConnectService,
  ).thenReturn(useLovenseConnectService);
  when(() => mock.useLovenseHIDDongle).thenReturn(useLovenseHIDDongle);
  when(() => mock.useLovenseSerialDongle).thenReturn(useLovenseSerialDongle);
  when(
    () => mock.hasAcknowledgedLovenseConnectDeprecation,
  ).thenReturn(hasAcknowledgedLovenseConnectDeprecation);
  when(
    () => mock.hasAcknowledgedLovenseDongleDeprecation,
  ).thenReturn(hasAcknowledgedLovenseDongleDeprecation);
  when(() => mock.appMode).thenReturn(appMode);
  when(() => mock.broadcastServerMdns).thenReturn(broadcastServerMdns);
  when(() => mock.mdnsSuffix).thenReturn(mdnsSuffix);
  when(
    () => mock.allowExperimentalRestServer,
  ).thenReturn(allowExperimentalRestServer);
  when(() => mock.repeaterLocalPort).thenReturn(repeaterLocalPort);
  when(() => mock.repeaterRemoteAddress).thenReturn(repeaterRemoteAddress);
  when(() => mock.displayLogLevel).thenReturn(displayLogLevel);
}

void stubGuiSettingsCubit(MockGuiSettingsCubit mock) {
  when(() => mock.state).thenReturn(GuiSettingsStateInitial());
  when(() => mock.stream).thenAnswer((_) => const Stream.empty());
  when(() => mock.getExpansionValue(any())).thenReturn(null);
}

void stubUserDeviceConfigurationCubit(
  MockUserDeviceConfigurationCubit mock, {
  Map<ExposedUserDeviceIdentifier, ExposedServerDeviceDefinition> configs =
      const {},
  List<String> protocols = const [],
  List<(String, ExposedWebsocketSpecifier)> specifiers = const [],
  List<(String, ExposedSerialSpecifier)> serialSpecifiers = const [],
  List<simulated_api.ExposedSimulatedDeviceArchetype> simulatedArchetypes =
      const [],
  List<simulated_api.ExposedSimulatedDeviceConfigEntry> simulatedDevices =
      const [],
  Object? createError,
}) {
  when(() => mock.state).thenReturn(UserDeviceConfigurationStateInitial());
  when(() => mock.stream).thenAnswer((_) => const Stream.empty());
  when(() => mock.configs).thenReturn(configs);
  when(() => mock.protocols).thenReturn(protocols);
  when(() => mock.specifiers).thenReturn(specifiers);
  when(() => mock.serialSpecifiers).thenReturn(serialSpecifiers);
  when(() => mock.simulatedArchetypes).thenReturn(simulatedArchetypes);
  when(() => mock.simulatedDevices).thenReturn(simulatedDevices);
  when(() => mock.createError).thenReturn(createError);
}

void stubAssetCubit(MockAssetCubit mock) {
  when(() => mock.state).thenReturn(AssetLoadedEvent());
  when(() => mock.stream).thenAnswer((_) => const Stream.empty());
}

void stubNetworkInfoCubit(MockNetworkInfoCubit mock) {
  when(() => mock.state).thenReturn(NetworkUp('127.0.0.1'));
  when(() => mock.stream).thenAnswer((_) => const Stream.empty());
  when(() => mock.ip).thenReturn('127.0.0.1');
}
