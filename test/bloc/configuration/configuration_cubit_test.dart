import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intiface_central/bloc/configuration/intiface_configuration_cubit.dart';
import 'package:intiface_central/util/intiface_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IntifaceConfigurationCubit', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('intiface_config_test_');
      await IntifacePaths.initForTest(tempDir);
      SharedPreferences.setMockInitialValues({});

      // Mock the pubspec.yaml asset so Pubspec.parse works
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key == 'pubspec.yaml') {
          return ByteData.sublistView(utf8.encode(
            'name: intiface_central\nversion: 3.0.0+1\n'
            'environment:\n  sdk: ">=3.8.0 <4.0.0"\n',
          ));
        }
        return null;
      });
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
      await tempDir.delete(recursive: true);
    });

    test('create() returns a cubit with default values', () async {
      final cubit = await IntifaceConfigurationCubit.create();
      expect(cubit.serverName, 'Intiface Server');
      expect(cubit.websocketServerPort, 12345);
      expect(cubit.startServerOnStartup, false);
      expect(cubit.useSimulatedDevices, true);
      cubit.close();
    });

    test('setter/getter roundtrip for useSimulatedDevices', () async {
      final cubit = await IntifaceConfigurationCubit.create();
      expect(cubit.useSimulatedDevices, true);
      cubit.useSimulatedDevices = false;
      expect(cubit.useSimulatedDevices, false);
      cubit.close();
    });

    test('setter/getter roundtrip for websocketServerPort', () async {
      final cubit = await IntifaceConfigurationCubit.create();
      cubit.websocketServerPort = 54321;
      expect(cubit.websocketServerPort, 54321);
      cubit.close();
    });

    test('setter emits corresponding state', () async {
      final cubit = await IntifaceConfigurationCubit.create();
      final states = <IntifaceConfigurationState>[];
      final sub = cubit.stream.listen(states.add);

      cubit.useSimulatedDevices = true;
      await Future.delayed(const Duration(milliseconds: 10));

      expect(states, contains(isA<UseSimulatedDevicesState>()));
      await sub.cancel();
      cubit.close();
    });
  });
}
