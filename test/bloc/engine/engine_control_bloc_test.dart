import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intiface_central/bloc/engine/engine_control_bloc.dart';
import 'package:intiface_central/bloc/engine/engine_repository.dart';

import '../../helpers/mocks.dart';

void main() {
  group('EngineControlBloc', () {
    late MockEngineRepository mockRepo;

    setUp(() {
      mockRepo = MockEngineRepository();
      when(() => mockRepo.messageStream)
          .thenAnswer((_) => const Stream.empty());
    });

    test('initial state is EngineStoppedState', () {
      final bloc = EngineControlBloc(mockRepo);
      expect(bloc.state, isA<EngineStoppedState>());
      bloc.close();
    });

    test('isRunning is false when stopped', () {
      final bloc = EngineControlBloc(mockRepo);
      expect(bloc.isRunning, isFalse);
      bloc.close();
    });

    test('devices list is initially empty', () {
      final bloc = EngineControlBloc(mockRepo);
      expect(bloc.devices, isEmpty);
      bloc.close();
    });
  });
}
