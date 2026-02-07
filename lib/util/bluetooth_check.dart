import 'package:intiface_central/util/intiface_util.dart';
import 'package:permission_handler/permission_handler.dart';

/// Checks whether Bluetooth is ready for BLE scanning on mobile platforms.
///
/// Returns `null` if Bluetooth is ready, or a user-facing message describing
/// the problem. Always returns `null` on desktop (different BLE stacks).
Future<String?> checkBluetoothReady() async {
  if (!isMobile()) return null;

  // Check whether the BLUETOOTH_SCAN permission has been granted.
  var scanStatus = await Permission.bluetoothScan.status;
  if (!scanStatus.isGranted) {
    return 'Bluetooth scan permission was not granted. '
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
