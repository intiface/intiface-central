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
        final bufferSize = ObservationCubit.bufferSize;
        final spots = <FlSpot>[];
        final step = 10.0 / (bufferSize - 1);
        for (var i = 0; i < state.values.length; i++) {
          spots.add(FlSpot(-i * step, state.values[i]));
        }

        final lineColor = Theme.of(context).colorScheme.primary;

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
              ),
            ),
          ],
        );
      },
    );
  }
}
