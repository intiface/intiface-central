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
  testWidgets('full chart uses timestamp spots without an implicit tween', (
    tester,
  ) async {
    final fixture = _ChartFixture();
    addTearDown(fixture.close);

    await tester.pumpWidget(
      _app(ObservationChartWidget(observationCubit: fixture.cubit)),
    );

    var chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.duration, Duration.zero);
    expect(chart.data.titlesData.show, isTrue);
    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .any(
            (widget) =>
                widget.properties.label == 'Device output observation 1:2',
          ),
      isTrue,
    );

    final initialSample = fixture.cubit.state.samples.last;
    fixture.harness.advance(const Duration(seconds: 1));
    await tester.pump();

    chart = tester.widget<LineChart>(find.byType(LineChart));
    final spots = chart.data.lineBarsData.single.spots;
    expect(
      spots.map((spot) => spot.x),
      orderedEquals(spots.map((spot) => spot.x).toList()..sort()),
    );
    expect(
      spots.firstWhere((spot) => spot.y == initialSample.value && spot.x == -1),
      isNotNull,
    );
  });

  testWidgets('compact chart keeps timestamp order and disables tweening', (
    tester,
  ) async {
    final fixture = _ChartFixture();
    addTearDown(fixture.close);
    final cubit = fixture.cubit;

    fixture.observations.add(
      DeviceOutputObservation()
        ..deviceIndex = 1
        ..featureIndex = 2
        ..value = 100,
    );
    fixture.harness.advance(ObservationCubit.presentationInterval);

    await tester.pumpWidget(
      _app(CompactObservationWidget(label: 'L0', observation: cubit)),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final spots = chart.data.lineBarsData.single.spots;
    expect(chart.duration, Duration.zero);
    expect(spots.last.y, 1);
    for (var i = 1; i < spots.length; i++) {
      expect(spots[i].x, greaterThanOrEqualTo(spots[i - 1].x));
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
