import 'package:intiface_central/src/rust/api/simulated_devices.dart';

Future<void> addTestDevice({
  required String identifier,
  String? displayName,
}) async {
  await addSimulatedDevice(identifier: identifier, displayName: displayName);
}

Future<void> clearTestDevices() async {
  final devices = await getUserSimulatedDevices();
  for (final device in devices) {
    await removeSimulatedDevice(address: device.address);
  }
}

Future<List<ExposedSimulatedDeviceConfigEntry>> listTestDevices() async {
  return getUserSimulatedDevices();
}
