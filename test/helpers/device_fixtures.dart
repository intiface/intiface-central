import 'package:intiface_central/src/rust/api/device_config.dart';
import 'ffi_fixtures.dart';

class DeviceTestFixture {
  final ExposedUserDeviceIdentifier identifier;
  final ExposedServerDeviceDefinition definition;

  DeviceTestFixture({required this.identifier, required this.definition});
}

DeviceTestFixture singleVibrator() => DeviceTestFixture(
      identifier:
          fakeDeviceIdentifier(address: 'vibrator-0', protocol: 'lovense'),
      definition: fakeDeviceDefinition(
        name: 'Test Vibrator',
        features: [
          fakeFeature(
            description: 'Vibrate',
            output: fakeVibrateOutput(),
          ),
        ],
      ),
    );

DeviceTestFixture multiFeatureDevice() => DeviceTestFixture(
      identifier:
          fakeDeviceIdentifier(address: 'multi-0', protocol: 'lovense'),
      definition: fakeDeviceDefinition(
        name: 'Test Multi',
        features: [
          fakeFeature(description: 'Vibrate', output: fakeVibrateOutput()),
          fakeFeature(
              description: 'Rotate',
              output: fakeVibrateOutput(stepCount: 10)),
        ],
      ),
    );
