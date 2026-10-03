import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device/observation_cubit.dart';

class CompactObservationWidget extends StatelessWidget {
  final String label;
  final ObservationCubit observation;

  const CompactObservationWidget({
    super.key,
    required this.label,
    required this.observation,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObservationCubit, ObservationState>(
      bloc: observation,
      builder: (context, state) {
        final spots = state.samples
            .map(
              (sample) =>
                  FlSpot(state.secondsFromWindowEnd(sample), sample.value),
            )
            .toList(growable: false);

        final lineColor = Theme.of(context).colorScheme.primary;
        final minY = observation.minValue;

        return Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 9,
                ),
                overflow: TextOverflow.clip,
                maxLines: 1,
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 16,
                child: LineChart(
                  LineChartData(
                    minX: -ObservationCubit.historyWindow.inSeconds.toDouble(),
                    maxX: 0,
                    minY: minY,
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
                          cutOffY: 0,
                          applyCutOffY: minY < 0,
                        ),
                        aboveBarData: BarAreaData(
                          show: minY < 0,
                          color: lineColor.withValues(alpha: 0.1),
                          cutOffY: 0,
                          applyCutOffY: true,
                        ),
                      ),
                    ],
                    titlesData: const FlTitlesData(show: false),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                  ),
                  duration: Duration.zero,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
