import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/bloc/engine/engine_repository.dart';
import 'package:intiface_central/bloc/engine/engine_messages.dart';
import 'package:intiface_central/src/rust/api/runtime.dart';

import '../../helpers/ffi_fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/rust_lib_mock.dart';

class FakeEngineOptionsExternal extends Fake implements EngineOptionsExternal {}

void main() {
  late MockEngineRepository mockRepo;
  late StreamController<EngineOutput> streamController;

  late MockRustLibApi mockRustApi;

  setUpAll(() {
    registerFallbackValue(FakeEngineOptionsExternal());

    // Set up RustLib mock for the entire test file — needed for
    // ExposedUserDeviceIdentifier factory constructor calls.
    mockRustApi = MockRustLibApi();
    setUpRustLibMock(mockRustApi);
    final fakeId = fakeDeviceIdentifier();
    when(() => mockRustApi.crateApiDeviceConfigExposedUserDeviceIdentifierNew(
          address: any(named: 'address'),
          protocol: any(named: 'protocol'),
          identifier: any(named: 'identifier'),
        )).thenReturn(fakeId);
  });

  tearDownAll(() {
    tearDownRustLibMock();
  });

  EngineControlBloc buildBloc() {
    mockRepo = MockEngineRepository();
    streamController = StreamController<EngineOutput>();
    when(() => mockRepo.messageStream)
        .thenAnswer((_) => streamController.stream);
    when(() => mockRepo.start(options: any(named: 'options')))
        .thenAnswer((_) async {});
    when(() => mockRepo.stop()).thenAnswer((_) async {});
    when(() => mockRepo.send(any())).thenReturn(null);
    return EngineControlBloc(mockRepo);
  }

  group('EngineControlBloc', () {
    test('initial state is EngineStoppedState', () {
      final bloc = buildBloc();
      expect(bloc.state, isA<EngineStoppedState>());
      bloc.close();
    });

    test('isRunning is false when stopped', () {
      final bloc = buildBloc();
      expect(bloc.isRunning, isFalse);
      bloc.close();
    });

    test('devices list is initially empty', () {
      final bloc = buildBloc();
      expect(bloc.devices, isEmpty);
      bloc.close();
    });

    blocTest<EngineControlBloc, EngineControlState>(
      'emits EngineStartingState then EngineStartedState on engine started',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(EngineControlEventStart(
          options: FakeEngineOptionsExternal(),
        ));
        await Future.delayed(const Duration(milliseconds: 50));

        final msg = EngineMessage()..engineStarted = EngineStarted();
        streamController.add(EngineOutput(msg, null));
        await Future.delayed(const Duration(milliseconds: 50));

        await streamController.close();
        await Future.delayed(const Duration(milliseconds: 50));
      },
      expect: () => [
        isA<EngineStartingState>(),
        isA<EngineStartedState>(),
        isA<ClientDisconnectedState>(),
        isA<EngineStoppedState>(),
      ],
      verify: (_) {
        verify(() => mockRepo.start(options: any(named: 'options'))).called(1);
      },
    );

    blocTest<EngineControlBloc, EngineControlState>(
      'emits EngineServerCreatedState',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(EngineControlEventStart(
          options: FakeEngineOptionsExternal(),
        ));
        await Future.delayed(const Duration(milliseconds: 50));

        final msg = EngineMessage()
          ..engineServerCreated = EngineServerCreated();
        streamController.add(EngineOutput(msg, null));
        await Future.delayed(const Duration(milliseconds: 50));

        await streamController.close();
        await Future.delayed(const Duration(milliseconds: 50));
      },
      expect: () => [
        isA<EngineStartingState>(),
        isA<EngineServerCreatedState>(),
        isA<EngineStoppedState>(),
      ],
    );

    blocTest<EngineControlBloc, EngineControlState>(
      'emits EngineStoppedState when repo.start throws',
      build: () {
        final bloc = buildBloc();
        when(() => mockRepo.start(options: any(named: 'options')))
            .thenThrow(Exception('start failed'));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(EngineControlEventStart(
          options: FakeEngineOptionsExternal(),
        ));
        await Future.delayed(const Duration(milliseconds: 50));
      },
      expect: () => [isA<EngineStoppedState>()],
    );

    blocTest<EngineControlBloc, EngineControlState>(
      'emits ClientConnectedState then ClientDisconnectedState',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(EngineControlEventStart(
          options: FakeEngineOptionsExternal(),
        ));
        await Future.delayed(const Duration(milliseconds: 50));

        final connectMsg = EngineMessage()
          ..clientConnected = (ClientConnected()..clientName = 'Test Client');
        streamController.add(EngineOutput(connectMsg, null));
        await Future.delayed(const Duration(milliseconds: 50));

        final disconnectMsg = EngineMessage()
          ..clientDisconnected = ClientDisconnected();
        streamController.add(EngineOutput(disconnectMsg, null));
        await Future.delayed(const Duration(milliseconds: 50));

        await streamController.close();
        await Future.delayed(const Duration(milliseconds: 50));
      },
      expect: () => [
        isA<EngineStartingState>(),
        isA<ClientConnectedState>()
            .having((s) => s.clientName, 'clientName', 'Test Client'),
        isA<ClientDisconnectedState>(),
        isA<EngineStoppedState>(),
      ],
    );

    blocTest<EngineControlBloc, EngineControlState>(
      'stop when already stopped is a no-op',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(EngineControlEventStop());
        await Future.delayed(const Duration(milliseconds: 50));
      },
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockRepo.stop());
      },
    );

    group('device events', () {
      blocTest<EngineControlBloc, EngineControlState>(
        'emits DeviceConnectedState on device connected message',
        build: buildBloc,
        act: (bloc) async {
          bloc.add(EngineControlEventStart(
            options: FakeEngineOptionsExternal(),
          ));
          await Future.delayed(const Duration(milliseconds: 50));

          final msg = EngineMessage()
            ..deviceConnected = DeviceConnected(
              name: 'Test Device',
              index: 0,
              identifier: const SerializableUserConfigDeviceIdentifier(
                'test-addr',
                'lovense',
                null,
              ),
            );
          streamController.add(EngineOutput(msg, null));
          await Future.delayed(const Duration(milliseconds: 50));

          await streamController.close();
          await Future.delayed(const Duration(milliseconds: 50));
        },
        expect: () => [
          isA<EngineStartingState>(),
          isA<DeviceConnectedState>()
              .having((s) => s.name, 'name', 'Test Device')
              .having((s) => s.index, 'index', 0),
          isA<EngineStoppedState>(),
        ],
      );

      blocTest<EngineControlBloc, EngineControlState>(
        'emits DeviceDisconnectedState after device disconnected',
        build: buildBloc,
        act: (bloc) async {
          bloc.add(EngineControlEventStart(
            options: FakeEngineOptionsExternal(),
          ));
          await Future.delayed(const Duration(milliseconds: 50));

          final connectMsg = EngineMessage()
            ..deviceConnected = DeviceConnected(
              name: 'Test Device',
              index: 0,
              identifier: const SerializableUserConfigDeviceIdentifier(
                'test-addr',
                'lovense',
                null,
              ),
            );
          streamController.add(EngineOutput(connectMsg, null));
          await Future.delayed(const Duration(milliseconds: 50));

          final disconnectMsg = EngineMessage()
            ..deviceDisconnected = (DeviceDisconnected()..index = 0);
          streamController.add(EngineOutput(disconnectMsg, null));
          await Future.delayed(const Duration(milliseconds: 50));

          await streamController.close();
          await Future.delayed(const Duration(milliseconds: 50));
        },
        expect: () => [
          isA<EngineStartingState>(),
          isA<DeviceConnectedState>(),
          isA<DeviceDisconnectedState>()
              .having((s) => s.index, 'index', 0),
          isA<EngineStoppedState>(),
        ],
      );
    });
  });
}
