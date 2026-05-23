import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';
import 'package:intiface_central/src/rust/api/device_config.dart';

class MockExposedUserDeviceIdentifier extends Mock
    implements ExposedUserDeviceIdentifier {}

class MockExposedServerDeviceDefinition extends Mock
    implements ExposedServerDeviceDefinition {}

class MockExposedServerDeviceFeature extends Mock
    implements ExposedServerDeviceFeature {}

class MockExposedServerDeviceFeatureOutput extends Mock
    implements ExposedServerDeviceFeatureOutput {}

class MockExposedServerDeviceFeatureOutputProperties extends Mock
    implements ExposedServerDeviceFeatureOutputProperties {}

class MockExposedServerDeviceFeatureInput extends Mock
    implements ExposedServerDeviceFeatureInput {}

class MockExposedRangeWithLimit extends Mock implements ExposedRangeWithLimit {}

ExposedUserDeviceIdentifier fakeDeviceIdentifier({
  String address = 'test-device-0',
  String protocol = 'lovense',
  String? identifier,
}) {
  final mock = MockExposedUserDeviceIdentifier();
  when(() => mock.address).thenReturn(address);
  when(() => mock.protocol).thenReturn(protocol);
  when(() => mock.identifier).thenReturn(identifier);
  return mock;
}

ExposedServerDeviceDefinition fakeDeviceDefinition({
  required String name,
  bool allow = true,
  bool deny = false,
  String? displayName,
  int index = 0,
  int? messageGapMs,
  List<ExposedServerDeviceFeature> features = const [],
}) {
  final mock = MockExposedServerDeviceDefinition();
  when(() => mock.name).thenReturn(name);
  when(() => mock.allow).thenReturn(allow);
  when(() => mock.deny).thenReturn(deny);
  when(() => mock.displayName).thenReturn(displayName);
  when(() => mock.index).thenReturn(index);
  when(() => mock.messageGapMs).thenReturn(messageGapMs);
  when(() => mock.features).thenReturn(features);
  when(() => mock.id).thenReturn(const Uuid().v4obj());
  return mock;
}

ExposedServerDeviceFeature fakeFeature({
  String description = 'Vibrate',
  ExposedServerDeviceFeatureOutput? output,
  ExposedServerDeviceFeatureInput? input,
}) {
  final mock = MockExposedServerDeviceFeature();
  when(() => mock.description).thenReturn(description);
  when(() => mock.id).thenReturn(const Uuid().v4obj());
  when(() => mock.output).thenReturn(output);
  when(() => mock.input).thenReturn(input);
  return mock;
}

ExposedServerDeviceFeatureOutput fakeVibrateOutput({
  int stepCount = 20,
}) {
  final mock = MockExposedServerDeviceFeatureOutput();
  final props = fakeOutputProperties(maxValue: stepCount);
  when(() => mock.vibrate).thenReturn(props);
  when(() => mock.rotate).thenReturn(null);
  when(() => mock.oscillate).thenReturn(null);
  when(() => mock.constrict).thenReturn(null);
  when(() => mock.temperature).thenReturn(null);
  when(() => mock.led).thenReturn(null);
  when(() => mock.spray).thenReturn(null);
  when(() => mock.position).thenReturn(null);
  when(() => mock.positionWithDuration).thenReturn(null);
  return mock;
}

ExposedServerDeviceFeatureOutputProperties fakeOutputProperties({
  int maxValue = 20,
  bool disabled = false,
}) {
  final mock = MockExposedServerDeviceFeatureOutputProperties();
  final range = MockExposedRangeWithLimit();
  when(() => range.base).thenReturn((0, maxValue));
  when(() => range.user).thenReturn((0, maxValue));
  when(() => mock.value).thenReturn(range);
  when(() => mock.position).thenReturn(null);
  when(() => mock.duration).thenReturn(null);
  when(() => mock.disabled).thenReturn(disabled);
  when(() => mock.reversePosition).thenReturn(false);
  return mock;
}
