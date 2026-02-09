import 'dart:io';

import 'package:intiface_central/util/intiface_util.dart';
import 'package:permission_handler/permission_handler.dart';

/// Checks whether Bluetooth is ready for BLE scanning on mobile platforms.
///
/// Returns `null` if Bluetooth is ready, or a user-facing message describing
/// the problem. Always returns `null` on desktop (different BLE stacks).
Future<String?> checkBluetoothReady() async {
  if (!isMobile()) return null;

  // Check whether Bluetooth permission has been granted.
  // Android 12+ uses BLUETOOTH_SCAN; iOS uses CBManagerAuthorization via Permission.bluetooth.
  var permissionStatus = Platform.isAndroid
      ? await Permission.bluetoothScan.status
      : await Permission.bluetooth.status;
  if (!permissionStatus.isGranted) {
    return 'Bluetooth permission was not granted. '
        'Please grant the permission in your device settings.';
  }

  // Check whether the Bluetooth adapter is actually turned on.
  var serviceStatus = await Permission.bluetooth.serviceStatus;
  if (serviceStatus != ServiceStatus.enabled) {
    return 'Bluetooth is not enabled. '
        'Please enable Bluetooth in your device settings.';
  }

  return null;
}
