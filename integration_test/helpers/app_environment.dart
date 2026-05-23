import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestAppEnvironment {
  late Directory tempDir;

  Future<void> setUp() async {
    WidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('intiface_test_');
    SharedPreferences.setMockInitialValues({
      'checkForUpdateOnStart': false,
      'startServerOnStartup': false,
      'useSimulatedDevices': true,
      'trayIconMode': 'none',
      'useDiscordRichPresence': false,
      'crashReporting2': false,
      'useBluetoothLE': true,
      'useCompactDisplay': false,
      'useSideNavigationBar': true,
      'serverName': 'Intiface Test Server',
      'maxPingTime': 0,
      'websocketServerAllInterfaces': false,
      'websocketServerPort': 12345,
      'showNotifications': false,
      'hasRunFirstUse': true,
      'showExtendedUI': false,
      'unreadNews': false,
      'themeMode': 'light',
      'restoreWindowLocation': false,
      'useXInput': false,
      'useLovenseConnectService': false,
      'useDeviceWebsocketServer': false,
      'useSerialPort': false,
      'useHID': false,
      'useLovenseHIDDongle': false,
      'useLovenseSerialDongle': false,
      'hasAcknowledgedLovenseConnectDeprecation': true,
      'hasAcknowledgedLovenseDongleDeprecation': true,
      'currentNewsEtag': '',
      'currentDeviceConfigEtag': '',
      'currentDeviceConfigVersion': '0.0',
      'usePrereleaseVersion': false,
      'useProcessEngine': false,
      'useForegroundProcess3': false,
      'broadcastServerMdns': false,
      'mdnsSuffix': '',
      'displayLogLevel': 'info',
      'repeaterLocalPort': 12345,
      'repeaterRemoteAddress': '192.168.1.1:12345',
      'restLocalPort': 3000,
      'allowExperimentalRestServer': false,
    });
    await IntifacePaths.init(baseDirectory: tempDir);
  }

  Future<void> tearDown() async {
    await tempDir.delete(recursive: true);
  }
}
