import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device/observation_cubit.dart';

class ObservationChartWidget extends StatelessWidget {
  final ObservationCubit _observationCubit;

  const ObservationChartWidget(
      {super.key, required ObservationCubit observationCubit})
      : _observationCubit = observationCubit;

  @override
  Widget build(BuildContext context) {
    final lineColor = Theme.of(context).colorScheme.primary;

    return BlocBuilder<ObservationCubit, ObservationState>(
      bloc: _observationCubit,
      builder: (context, state) {
        final spots = <FlSpot>[];
        final step = 10.0 / (state.values.length - 1);
        for (var i = 0; i < state.values.length; i++) {
          spots.add(FlSpot(-i * step, state.values[i]));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SizedBox(
            height: 60,
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
                    isStepLineChart: false,
                    color: lineColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withValues(alpha: 0.15),
                    ),
                  ),
                ],
                titlesData: const FlTitlesData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                lineTouchData: const LineTouchData(enabled: false),
              ),
            ),
          ),
        );
      },
    );
  }
}
