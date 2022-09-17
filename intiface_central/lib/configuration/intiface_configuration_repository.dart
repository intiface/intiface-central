import 'package:intiface_central/configuration/intiface_configuration_provider.dart';
import 'dart:io';

import 'package:intiface_central/util/intiface_util.dart';

class IntifaceConfigurationRepository {
  IntifaceConfigurationProvider provider;

  IntifaceConfigurationRepository(this.provider) {
    // Check all of our values to make sure they exist. If not, set defaults, based on platform if needed.
    serverName = provider.getString("serverName") ?? "Intiface Server";
    serverMaxPingTime = provider.getInt("maxPingTime") ?? 0;
    websocketServerAllInterfaces = provider.getBool("websocketServerAllInterfaces") ?? false;
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
    withBluetoothLE = provider.getBool("withBluetoothLE") ?? true;

    // Only works on Windows
    withXInput = provider.getBool("withXInput") ?? Platform.isWindows;

    // Always default off, require user to turn them on.
    withLovenseConnectService = provider.getBool("withLovenseConnectService") ?? false;
    withDeviceWebsocketServer = provider.getBool("withDeviceWebsocketServer") ?? false;
    withSerialPort = provider.getBool("withSerialPort") ?? false;
    withHID = provider.getBool("withHID") ?? false;
    withLovenseHIDDongle = provider.getBool("withLovenseHIDDongle") ?? false;
    withLovenseSerialDongle = provider.getBool("withLovenseSerialDongle") ?? false;
  }
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
  bool get withBluetoothLE => provider.getBool("withBluetoothLE")!;
  set withBluetoothLE(bool value) => provider.setBool("withBluetoothLE", value);
  bool get withSerialPort => provider.getBool("withSerialPort")!;
  set withSerialPort(bool value) => provider.setBool("withSerialPort", value);
  bool get withHID => provider.getBool("withHID")!;
  set withHID(bool value) => provider.setBool("withHID", value);
  bool get withLovenseHIDDongle => provider.getBool("withLovenseHIDDongle")!;
  set withLovenseHIDDongle(bool value) => provider.setBool("withLovenseHIDDongle", value);
  bool get withLovenseSerialDongle => provider.getBool("withLovenseSerialDongle")!;
  set withLovenseSerialDongle(bool value) => provider.setBool("withLovenseSerialDongle", value);
  bool get withLovenseConnectService => provider.getBool("withLovenseConnectService")!;
  set withLovenseConnectService(bool value) => provider.setBool("withLovenseConnectService", value);
  bool get withXInput => provider.getBool("withXInput")!;
  set withXInput(bool value) => provider.setBool("withXInput", value);
  bool get withDeviceWebsocketServer => provider.getBool("withDeviceWebsocketServer")!;
  set withDeviceWebsocketServer(bool value) => provider.setBool("withDeviceWebsocketServer", value);
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
}
