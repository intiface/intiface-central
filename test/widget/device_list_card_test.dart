import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intiface_central/widget/device_list_card_widget.dart';

import '../helpers/ffi_fixtures.dart';

void main() {
  group('DeviceListCard', () {
    testWidgets('displays device name', (tester) async {
      final id = fakeDeviceIdentifier(address: 'test-0');
      final def = fakeDeviceDefinition(name: 'Test Vibrator');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DeviceListCard(
            identifier: id,
            definition: def,
            isConnected: false,
            onTap: () {},
          ),
        ),
      ));

      expect(find.text('Test Vibrator'), findsOneWidget);
    });

    testWidgets('displays display name over hardware name', (tester) async {
      final id = fakeDeviceIdentifier(address: 'test-0');
      final def = fakeDeviceDefinition(
        name: 'HW Name',
        displayName: 'My Custom Name',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DeviceListCard(
            identifier: id,
            definition: def,
            isConnected: false,
            onTap: () {},
          ),
        ),
      ));

      expect(find.text('My Custom Name'), findsOneWidget);
      expect(find.text('HW Name'), findsNothing);
    });

    testWidgets('shows connected icon when connected', (tester) async {
      final id = fakeDeviceIdentifier(address: 'test-0');
      final def = fakeDeviceDefinition(name: 'Test Device');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DeviceListCard(
            identifier: id,
            definition: def,
            isConnected: true,
            onTap: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
    });

    testWidgets('shows disconnected icon when not connected', (tester) async {
      final id = fakeDeviceIdentifier(address: 'test-0');
      final def = fakeDeviceDefinition(name: 'Test Device');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DeviceListCard(
            identifier: id,
            definition: def,
            isConnected: false,
            onTap: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
    });

    testWidgets('shows ALLOW badge when allow is true', (tester) async {
      final id = fakeDeviceIdentifier(address: 'test-0');
      final def = fakeDeviceDefinition(name: 'Test', allow: true);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DeviceListCard(
            identifier: id,
            definition: def,
            isConnected: false,
            onTap: () {},
          ),
        ),
      ));

      expect(find.text('ALLOW'), findsOneWidget);
    });

    testWidgets('shows DENY badge when deny is true', (tester) async {
      final id = fakeDeviceIdentifier(address: 'test-0');
      final def = fakeDeviceDefinition(name: 'Test', deny: true);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DeviceListCard(
            identifier: id,
            definition: def,
            isConnected: false,
            onTap: () {},
          ),
        ),
      ));

      expect(find.text('DENY'), findsOneWidget);
    });

    testWidgets('shows feature icons for vibrate output', (tester) async {
      final id = fakeDeviceIdentifier(address: 'test-0');
      final def = fakeDeviceDefinition(
        name: 'Test Vibrator',
        features: [
          fakeFeature(
            description: 'Vibrate',
            output: fakeVibrateOutput(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DeviceListCard(
            identifier: id,
            definition: def,
            isConnected: false,
            onTap: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.vibration), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      var tapped = false;
      final id = fakeDeviceIdentifier(address: 'test-0');
      final def = fakeDeviceDefinition(name: 'Test Device');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DeviceListCard(
            identifier: id,
            definition: def,
            isConnected: false,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.text('Test Device'));
      expect(tapped, isTrue);
    });
  });
}
