import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device/observation_cubit.dart';

class CompactObservationWidget extends StatelessWidget {
  final List<ObservationCubit> observations;

  const CompactObservationWidget({super.key, required this.observations});

  @override
  Widget build(BuildContext context) {
    if (observations.isEmpty) return const SizedBox.shrink();

    // All ObservationCubits tick at 100ms, so building on the first cubit's
    // state changes is sufficient — we read current state from all cubits
    // during each build.
    return BlocBuilder<ObservationCubit, ObservationState>(
      bloc: observations.first,
      builder: (context, _) {
        final bufferSize = ObservationCubit.bufferSize;
        final envelope = List<double>.filled(bufferSize, 0.0);
        for (var obs in observations) {
          final values = obs.state.values;
          for (var i = 0; i < min(bufferSize, values.length); i++) {
            envelope[i] = max(envelope[i], values[i]);
          }
        }

        final spots = <FlSpot>[];
        final step = 10.0 / (bufferSize - 1);
        for (var i = 0; i < bufferSize; i++) {
          spots.add(FlSpot(-i * step, envelope[i]));
        }

        final lineColor = Theme.of(context).colorScheme.primary;

        return SizedBox(
          height: 20,
          child: LineChart(
            LineChartData(
              minX: -10,
              maxX: 0,
              minY: 0,
              maxY: 1.0,
              clipData: const FlClipData.all(),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: lineColor.withValues(alpha: 0.7),
                  barWidth: 1,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
            ),
          ),
        );
      },
    );
  }
}
