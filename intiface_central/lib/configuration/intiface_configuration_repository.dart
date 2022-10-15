import 'package:intiface_central/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/configuration/intiface_configuration_provider.dart';
import 'dart:io';

import 'package:intiface_central/util/intiface_util.dart';

class IntifaceConfigurationRepository {
  IntifaceConfigurationProvider provider;

  IntifaceConfigurationRepository(this.provider) {
    _init();
  }

  void _init() {
// Our initializer runs through all of our known configuration values, either setting them to what they already are,
    // or providing them with default values.

    // Window settings for desktop. Will be ignored on mobile.

    useCompactDisplay = provider.getBool("useCompactDisplay") ?? isDesktop();

    // Check all of our values to make sure they exist. If not, set defaults, based on platform if needed.
    serverName = provider.getString("serverName") ?? "Intiface Server";
    serverMaxPingTime = provider.getInt("maxPingTime") ?? 0;
    // This should automatically be true on phones, otherwise people are going to be VERY confused.
    websocketServerAllInterfaces = provider.getBool("websocketServerAllInterfaces") ?? isMobile();
    websocketServerPort = provider.getInt("websocketServerPort") ?? 12345;
    serverLogLevel = provider.getString("serverLogLevel") ?? "info";
    usePrereleaseEngine = provider.getBool("usePrereleaseEngine") ?? false;
    checkForUpdateOnStart = provider.getBool("checkForUpdateOnStart") ?? true;
    startServerOnStartup = provider.getBool("startServerOnStartup") ?? false;
    crashReporting = provider.getBool("crashReporting") ?? true;
    showNotifications = provider.getBool("showNotifications") ?? false;
    hasRunFirstUse = provider.getBool("hasRunFirstUse") ?? false;
    showExtendedUI = provider.getBool("showExtendedUI") ?? false;
    allowRawMessages = provider.getBool("allowRawMessages") ?? false;
    unreadNews = provider.getBool("unreadNews") ?? false;
    useSideNavigationBar = provider.getBool("useSideNavigationBar") ?? isDesktop();
    useLightTheme = provider.getBool("useLightTheme") ?? true;

    // True on all platforms
    useBluetoothLE = provider.getBool("useBluetoothLE") ?? true;

    // Only works on Windows
    useXInput = provider.getBool("useXInput") ?? Platform.isWindows;

    // Always default off, require user to turn them on.
    useLovenseConnectService = provider.getBool("useLovenseConnectService") ?? false;
    useDeviceWebsocketServer = provider.getBool("useDeviceWebsocketServer") ?? false;
    useSerialPort = provider.getBool("useSerialPort") ?? false;
    useHID = provider.getBool("useHID") ?? false;
    useLovenseHIDDongle = provider.getBool("useLovenseHIDDongle") ?? false;
    useLovenseSerialDongle = provider.getBool("useLovenseSerialDongle") ?? false;

    // Update settings
    currentNewsEtag = provider.getString("currentNewsEtag") ?? "";
    currentDeviceConfigEtag = provider.getString("currentDeviceConfigEtag") ?? "";
    currentEngineVersion = provider.getString("currentEngineVersion") ?? "0.0.0";
    currentAppVersion = provider.getString("currentAppVersion") ?? "0";
    currentDeviceConfigVersion = provider.getString("currentDeviceConfigVersion") ?? "0.0";
  }

  Future<bool> reset() async {
    var result = await provider.reset();
    _init();
    return result;
  }

  String get currentNewsEtag => provider.getString("currentNewsEtag")!;
  set currentNewsEtag(String value) => provider.setString("currentNewsEtag", value);

  String get currentDeviceConfigEtag => provider.getString("currentDeviceConfigEtag")!;
  set currentDeviceConfigEtag(String value) => provider.setString("currentDeviceConfigEtag", value);

  bool get useCompactDisplay => provider.getBool("useCompactDisplay")!;
  set useCompactDisplay(bool value) => provider.setBool("useCompactDisplay", value);

  bool get useSideNavigationBar => provider.getBool("useSideNavigationBar")!;
  set useSideNavigationBar(bool value) => provider.setBool("useSideNavigationBar", value);
  bool get useLightTheme => provider.getBool("useLightTheme")!;
  set useLightTheme(bool value) => provider.setBool("useLightTheme", value);
  String get serverName => provider.getString("serverName")!;
  set serverName(String value) => provider.setString("serverName", value);
  int get serverMaxPingTime => provider.getInt("maxPingTime")!;
  set serverMaxPingTime(int value) => provider.setInt("maxPingTime", value);
  bool get websocketServerAllInterfaces => provider.getBool("websocketServerAllInterfaces")!;
  set websocketServerAllInterfaces(bool value) => provider.setBool("websocketServerAllInterfaces", value);
  int get websocketServerPort => provider.getInt("websocketServerPort")!;
  set websocketServerPort(int value) => provider.setInt("websocketServerPort", value);
  String get serverLogLevel => provider.getString("serverLogLevel")!;
  set serverLogLevel(String value) => provider.setString("serverLogLevel", value);
  bool get usePrereleaseEngine => provider.getBool("usePrereleaseEngine")!;
  set usePrereleaseEngine(bool value) => provider.setBool("usePrereleaseEngine", value);
  bool get checkForUpdateOnStart => provider.getBool("checkForUpdateOnStart")!;
  set checkForUpdateOnStart(bool value) => provider.setBool("checkForUpdateOnStart", value);
  bool get hasUsableEngineExecutable => provider.getBool("hasUsableEngineExecutable")!;
  set hasUsableEngineExecutable(bool value) => provider.setBool("hasUsableEngineExecutable", value);
  bool get startServerOnStartup => provider.getBool("startServerOnStartup")!;
  set startServerOnStartup(bool value) => provider.setBool("startServerOnStartup", value);
  bool get useBluetoothLE => provider.getBool("useBluetoothLE")!;
  set useBluetoothLE(bool value) => provider.setBool("useBluetoothLE", value);
  bool get useSerialPort => provider.getBool("useSerialPort")!;
  set useSerialPort(bool value) => provider.setBool("useSerialPort", value);
  bool get useHID => provider.getBool("useHID")!;
  set useHID(bool value) => provider.setBool("useHID", value);
  bool get useLovenseHIDDongle => provider.getBool("useLovenseHIDDongle")!;
  set useLovenseHIDDongle(bool value) => provider.setBool("useLovenseHIDDongle", value);
  bool get useLovenseSerialDongle => provider.getBool("useLovenseSerialDongle")!;
  set useLovenseSerialDongle(bool value) => provider.setBool("useLovenseSerialDongle", value);
  bool get useLovenseConnectService => provider.getBool("useLovenseConnectService")!;
  set useLovenseConnectService(bool value) => provider.setBool("useLovenseConnectService", value);
  bool get useXInput => provider.getBool("useXInput")!;
  set useXInput(bool value) => provider.setBool("useXInput", value);
  bool get useDeviceWebsocketServer => provider.getBool("useDeviceWebsocketServer")!;
  set useDeviceWebsocketServer(bool value) => provider.setBool("useDeviceWebsocketServer", value);
  bool get crashReporting => provider.getBool("crashReporting")!;
  set crashReporting(bool value) => provider.setBool("crashReporting", value);
  bool get showNotifications => provider.getBool("showNotifications")!;
  set showNotifications(bool value) => provider.setBool("showNotifications", value);
  bool get hasRunFirstUse => provider.getBool("hasRunFirstUse")!;
  set hasRunFirstUse(bool value) => provider.setBool("hasRunFirstUse", value);
  bool get showExtendedUI => provider.getBool("showExtendedUI")!;
  set showExtendedUI(bool value) => provider.setBool("showExtendedUI", value);
  bool get allowRawMessages => provider.getBool("allowRawMessages")!;
  set allowRawMessages(bool value) => provider.setBool("allowRawMessages", value);
  bool get unreadNews => provider.getBool("unreadNews")!;
  set unreadNews(bool value) => provider.setBool("unreadNews", value);
  String get currentEngineVersion => provider.getString("currentEngineVersion")!;
  set currentEngineVersion(String value) => provider.setString("currentEngineVersion", value);
  String get currentAppVersion => provider.getString("currentAppVersion")!;
  set currentAppVersion(String value) => provider.setString("currentAppVersion", value);
  String get currentDeviceConfigVersion => provider.getString("currentDeviceConfigVersion")!;
  set currentDeviceConfigVersion(String value) => provider.setString("currentDeviceConfigVersion", value);
}
