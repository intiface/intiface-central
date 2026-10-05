import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intiface_central/bloc/device/observation_cubit.dart';
import 'package:intiface_central/bloc/engine/engine_messages.dart';
import 'package:intiface_central/widget/compact_observation_widget.dart';
import 'package:intiface_central/widget/observation_chart_widget.dart';

import '../helpers/observation_fixtures.dart';

void main() {
  testWidgets('both charts disable fl_chart tweening', (tester) async {
    final fixture = _ChartFixture();
    addTearDown(fixture.close);

    await tester.pumpWidget(
      _app(
        Column(
          children: [
            ObservationChartWidget(observationCubit: fixture.cubit),
            CompactObservationWidget(label: 'L0', observation: fixture.cubit),
          ],
        ),
      ),
    );

    final charts = tester.widgetList<LineChart>(find.byType(LineChart));
    expect(charts, hasLength(2));
    for (final chart in charts) {
      expect(chart.duration, Duration.zero);
    }
  });

  testWidgets('charts extend below zero for signed step ranges', (
    tester,
  ) async {
    final fixture = _ChartFixture(minSteps: -100);
    addTearDown(fixture.close);

    await tester.pumpWidget(
      _app(
        Column(
          children: [
            ObservationChartWidget(observationCubit: fixture.cubit),
            CompactObservationWidget(label: 'R0', observation: fixture.cubit),
          ],
        ),
      ),
    );

    final charts = tester.widgetList<LineChart>(find.byType(LineChart));
    expect(charts, hasLength(2));
    for (final chart in charts) {
      expect(chart.data.minY, -1);
      expect(chart.data.lineBarsData.single.aboveBarData.show, isTrue);
    }
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 500, child: child)),
  );
}

class _ChartFixture {
  final int minSteps;
  final observations = StreamController<DeviceOutputObservation>.broadcast(
    sync: true,
  );
  final harness = ObservationHarness();
  late final ObservationCubit cubit = ObservationCubit(
    deviceIndex: 1,
    featureIndex: 2,
    minSteps: minSteps,
    maxSteps: 100,
    observationStream: observations.stream,
    clock: harness.readClock,
    timerFactory: harness.createTimer,
  );

  _ChartFixture({this.minSteps = 0});

  Future<void> close() async {
    await cubit.close();
    await observations.close();
  }
}
