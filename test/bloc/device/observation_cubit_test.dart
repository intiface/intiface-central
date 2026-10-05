import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:intiface_central/bloc/device/observation_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_messages.dart';

import '../../helpers/observation_fixtures.dart';

void main() {
  group('ObservationCubit', () {
    test('samples the latest value at the presentation rate', () async {
      final observations = StreamController<DeviceOutputObservation>.broadcast(
        sync: true,
      );
      final harness = ObservationHarness();
      final cubit = _createCubit(observations, harness);
      addTearDown(() async {
        await cubit.close();
        await observations.close();
      });

      expect(harness.timerInterval, ObservationCubit.presentationInterval);

      observations.add(_observation(value: 50));
      harness.advance(const Duration(milliseconds: 500));

      expect(cubit.state.currentValue, closeTo(0.5, 0.0001));
      expect(
        cubit.state.samples.last.timestamp,
        const Duration(milliseconds: 500),
      );

      harness.advance(ObservationCubit.presentationInterval);
      expect(cubit.state.currentValue, closeTo(0.5, 0.0001));
    });

    test('keeps chronological timestamp history bounded', () async {
      final observations = StreamController<DeviceOutputObservation>.broadcast(
        sync: true,
      );
      final harness = ObservationHarness();
      final cubit = _createCubit(observations, harness);
      addTearDown(() async {
        await cubit.close();
        await observations.close();
      });

      for (var i = 0; i < 750; i++) {
        harness.advance(ObservationCubit.presentationInterval);
      }

      final samples = cubit.state.samples;
      expect(
        samples.length,
        lessThanOrEqualTo(ObservationCubit.maxHistorySamples),
      );
      for (var i = 1; i < samples.length; i++) {
        expect(samples[i].timestamp >= samples[i - 1].timestamp, isTrue);
      }
      expect(
        samples[1].timestamp,
        greaterThanOrEqualTo(
          cubit.state.windowEnd - ObservationCubit.historyWindow,
        ),
      );
    });

    test('keeps the full window when ticks run faster than nominal', () async {
      final observations = StreamController<DeviceOutputObservation>.broadcast(
        sync: true,
      );
      final harness = ObservationHarness();
      final cubit = _createCubit(observations, harness);
      addTearDown(() async {
        await cubit.close();
        await observations.close();
      });

      for (var i = 0; i < 1000; i++) {
        harness.advance(const Duration(milliseconds: 15));
      }

      expect(
        cubit.state.samples.first.timestamp,
        lessThanOrEqualTo(
          cubit.state.windowEnd - ObservationCubit.historyWindow,
        ),
      );
    });

    test('keeps the window-edge sample when the safety cap binds', () async {
      final observations = StreamController<DeviceOutputObservation>.broadcast(
        sync: true,
      );
      final harness = ObservationHarness();
      final cubit = _createCubit(observations, harness);
      addTearDown(() async {
        await cubit.close();
        await observations.close();
      });

      for (var i = 0; i < 2 * ObservationCubit.maxHistorySamples; i++) {
        harness.advance(const Duration(milliseconds: 5));
      }

      final samples = cubit.state.samples;
      expect(
        samples.length,
        lessThanOrEqualTo(ObservationCubit.maxHistorySamples),
      );
      expect(
        samples.first.timestamp,
        lessThanOrEqualTo(
          cubit.state.windowEnd - ObservationCubit.historyWindow,
        ),
      );
    });

    test(
      'timestamps move existing samples left as the window advances',
      () async {
        final observations =
            StreamController<DeviceOutputObservation>.broadcast(sync: true);
        final harness = ObservationHarness();
        final cubit = _createCubit(observations, harness);
        addTearDown(() async {
          await cubit.close();
          await observations.close();
        });

        final initialSample = cubit.state.samples.last;
        expect(cubit.state.secondsFromWindowEnd(initialSample), 0);

        harness.advance(const Duration(seconds: 1));

        expect(cubit.state.secondsFromWindowEnd(initialSample), -1);
      },
    );

    test('cancels its presentation timer on close', () async {
      final observations = StreamController<DeviceOutputObservation>.broadcast(
        sync: true,
      );
      final harness = ObservationHarness();
      final cubit = _createCubit(observations, harness);

      expect(harness.timer!.isActive, isTrue);
      await cubit.close();

      expect(harness.timer!.isActive, isFalse);
      await observations.close();
    });

    test('scales, clamps, and filters observations', () async {
      final observations = StreamController<DeviceOutputObservation>.broadcast(
        sync: true,
      );
      final harness = ObservationHarness();
      final cubit = _createCubit(observations, harness, maxSteps: 999);
      addTearDown(() async {
        await cubit.close();
        await observations.close();
      });

      observations.add(_observation(value: 499.5));
      harness.advance(ObservationCubit.presentationInterval);
      expect(cubit.state.currentValue, closeTo(0.5, 0.0001));

      observations.add(_observation(value: 100, featureIndex: 3));
      harness.advance(ObservationCubit.presentationInterval);
      expect(cubit.state.currentValue, closeTo(0.5, 0.0001));

      observations.add(_observation(value: 2000));
      harness.advance(ObservationCubit.presentationInterval);
      expect(cubit.state.currentValue, 1);
    });

    test('keeps negative values for signed step ranges', () async {
      final observations = StreamController<DeviceOutputObservation>.broadcast(
        sync: true,
      );
      final harness = ObservationHarness();
      final cubit = _createCubit(observations, harness, minSteps: -100);
      addTearDown(() async {
        await cubit.close();
        await observations.close();
      });

      expect(cubit.minValue, -1);

      observations.add(_observation(value: -50));
      harness.advance(ObservationCubit.presentationInterval);
      expect(cubit.state.currentValue, closeTo(-0.5, 0.0001));

      observations.add(_observation(value: -200));
      harness.advance(ObservationCubit.presentationInterval);
      expect(cubit.state.currentValue, -1);
    });
  });
}

ObservationCubit _createCubit(
  StreamController<DeviceOutputObservation> observations,
  ObservationHarness harness, {
  int minSteps = 0,
  int maxSteps = 100,
}) {
  return ObservationCubit(
    deviceIndex: 1,
    featureIndex: 2,
    minSteps: minSteps,
    maxSteps: maxSteps,
    observationStream: observations.stream,
    clock: harness.readClock,
    timerFactory: harness.createTimer,
  );
}

DeviceOutputObservation _observation({
  required double value,
  int featureIndex = 2,
}) {
  return DeviceOutputObservation()
    ..deviceIndex = 1
    ..featureIndex = featureIndex
    ..outputType = 'Position'
    ..value = value;
}
