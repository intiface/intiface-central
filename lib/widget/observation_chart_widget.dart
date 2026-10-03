import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/bloc/device/observation_cubit.dart';

class ObservationChartWidget extends StatelessWidget {
  final ObservationCubit _observationCubit;

  const ObservationChartWidget({
    super.key,
    required ObservationCubit observationCubit,
  }) : _observationCubit = observationCubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ObservationCubit, ObservationState>(
      bloc: _observationCubit,
      builder: (context, state) {
        final theme = Theme.of(context);
        final lineColor = theme.colorScheme.primary;
        final gridColor = theme.dividerColor.withValues(alpha: 0.25);
        final labelStyle = theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 9,
        );
        final spots = state.samples
            .map(
              (sample) =>
                  FlSpot(state.secondsFromWindowEnd(sample), sample.value),
            )
            .toList(growable: false);
        final latestValue = state.currentValue;
        final minY = _observationCubit.minValue;

        return Semantics(
          label:
              'Device output observation ${_observationCubit.deviceIndex}:${_observationCubit.featureIndex}',
          value: '${(latestValue * 100).round()} percent',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: SizedBox(
              height: 112,
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
                      isStepLineChart: false,
                      color: lineColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        checkToShowDot: (spot, _) =>
                            spots.isNotEmpty && spot == spots.last,
                        getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                          radius: 3,
                          color: lineColor,
                          strokeWidth: 1.5,
                          strokeColor: theme.colorScheme.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        cutOffY: 0,
                        applyCutOffY: minY < 0,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            lineColor.withValues(alpha: 0.18),
                            lineColor.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                      aboveBarData: BarAreaData(
                        show: minY < 0,
                        cutOffY: 0,
                        applyCutOffY: true,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            lineColor.withValues(alpha: 0.18),
                            lineColor.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 0.5,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(
                            '${(value * 100).round()}%',
                            style: labelStyle,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 20,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(
                            value == 0 ? 'now' : '${value.round()}s',
                            style: labelStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 0.25,
                    verticalInterval: 2,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: gridColor, strokeWidth: 0.5),
                    getDrawingVerticalLine: (_) =>
                        FlLine(color: gridColor, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: gridColor, width: 0.5),
                  ),
                  lineTouchData: const LineTouchData(enabled: false),
                ),
                duration: Duration.zero,
              ),
            ),
          ),
        );
      },
    );
  }
}
