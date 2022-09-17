import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:btleplugtest/btleplugtest_method_channel.dart';

void main() {
  MethodChannelBtleplugtest platform = MethodChannelBtleplugtest();
  const MethodChannel channel = MethodChannel('btleplugtest');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
