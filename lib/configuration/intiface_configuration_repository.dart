import 'package:intiface_central/configuration/intiface_configuration_provider.dart';
import 'dart:io';

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

  String get serverName => provider.getString("serverName")!;
  set serverName(String value) => provider.setString("serverName", value);
  get serverMaxPingTime => provider.getInt("maxPingTime")!;
  set serverMaxPingTime(value) => provider.setInt("maxPingTime", value);
  get websocketServerAllInterfaces => provider.getBool("websocketServerAllInterfaces")!;
  set websocketServerAllInterfaces(value) => provider.setBool("websocketServerAllInterfaces", value);
  get websocketServerPort => provider.getInt("websocketServerPort")!;
  set websocketServerPort(value) => provider.setInt("websocketServerPort", value);
  get serverLogLevel => provider.getString("serverLogLevel")!;
  set serverLogLevel(value) => provider.setString("serverLogLevel", value);
  get usePrereleaseEngine => provider.getBool("usePrereleaseEngine")!;
  set usePrereleaseEngine(value) => provider.setBool("usePrereleaseEngine", value);
  get checkForUpdateOnStart => provider.getBool("checkForUpdateOnStart")!;
  set checkForUpdateOnStart(value) => provider.setBool("checkForUpdateOnStart", value);
  get hasUsableEngineExecutable => provider.getBool("hasUsableEngineExecutable")!;
  set hasUsableEngineExecutable(value) => provider.setBool("hasUsableEngineExecutable", value);
  get startServerOnStartup => provider.getBool("startServerOnStartup")!;
  set startServerOnStartup(value) => provider.setBool("startServerOnStartup", value);
  get withBluetoothLE => provider.getBool("withBluetoothLE")!;
  set withBluetoothLE(value) => provider.setBool("withBluetoothLE", value);
  get withSerialPort => provider.getBool("withSerialPort")!;
  set withSerialPort(value) => provider.setBool("withSerialPort", value);
  get withHID => provider.getBool("withHID")!;
  set withHID(value) => provider.setBool("withHID", value);
  get withLovenseHIDDongle => provider.getBool("withLovenseHIDDongle")!;
  set withLovenseHIDDongle(value) => provider.setBool("withLovenseHIDDongle", value);
  get withLovenseSerialDongle => provider.getBool("withLovenseSerialDongle")!;
  set withLovenseSerialDongle(value) => provider.setBool("withLovenseSerialDongle", value);
  get withLovenseConnectService => provider.getBool("withLovenseConnectService")!;
  set withLovenseConnectService(value) => provider.setBool("withLovenseConnectService", value);
  get withXInput => provider.getBool("withXInput")!;
  set withXInput(value) => provider.setBool("withXInput", value);
  get withDeviceWebsocketServer => provider.getBool("withDeviceWebsocketServer")!;
  set withDeviceWebsocketServer(value) => provider.setBool("withDeviceWebsocketServer", value);
  get crashReporting => provider.getBool("crashReporting")!;
  set crashReporting(value) => provider.setBool("crashReporting", value);
  get showNotifications => provider.getBool("showNotifications")!;
  set showNotifications(value) => provider.setBool("showNotifications", value);
  get hasRunFirstUse => provider.getBool("hasRunFirstUse")!;
  set hasRunFirstUse(value) => provider.setBool("hasRunFirstUse", value);
  get showExtendedUI => provider.getBool("showExtendedUI")!;
  set showExtendedUI(value) => provider.setBool("showExtendedUI", value);
  get allowRawMessages => provider.getBool("allowRawMessages")!;
  set allowRawMessages(value) => provider.setBool("allowRawMessages", value);
  get unreadNews => provider.getBool("unreadNews")!;
  set unreadNews(value) => provider.setBool("unreadNews", value);
}
