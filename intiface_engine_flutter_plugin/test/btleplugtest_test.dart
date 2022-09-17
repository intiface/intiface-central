import 'package:flutter_test/flutter_test.dart';
import 'package:btleplugtest/btleplugtest.dart';
import 'package:btleplugtest/btleplugtest_platform_interface.dart';
import 'package:btleplugtest/btleplugtest_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBtleplugtestPlatform 
    with MockPlatformInterfaceMixin
    implements BtleplugtestPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BtleplugtestPlatform initialPlatform = BtleplugtestPlatform.instance;

  test('$MethodChannelBtleplugtest is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBtleplugtest>());
  });

  test('getPlatformVersion', () async {
    Btleplugtest btleplugtestPlugin = Btleplugtest();
    MockBtleplugtestPlatform fakePlatform = MockBtleplugtestPlatform();
    BtleplugtestPlatform.instance = fakePlatform;
  
    expect(await btleplugtestPlugin.getPlatformVersion(), '42');
  });
}
