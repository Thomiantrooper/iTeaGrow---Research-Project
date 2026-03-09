import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iteagrow/core/design_system/design_system.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import '../../data/models/market_models.dart';

class GradeValueChart extends StatelessWidget {
  final Map<String, dynamic> latestPrices;
  final List<String> grades;

  const GradeValueChart({
    super.key,
    required this.latestPrices,
    required this.grades,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxPrice() * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: TeaColors.matureLeaf,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${grades[group.x]}\nRs. ${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < grades.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(grades[index],
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(value.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 9, color: TeaColors.darkGray)),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: grades.asMap().entries.map((entry) {
            final index = entry.key;
            final grade = entry.value;
            final price = (latestPrices[grade] as num?)?.toDouble() ?? 0.0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: price,
                  color: TeaColors.freshLeaf,
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _getMaxPrice() {
    double max = 0;
    for (var p in latestPrices.values) {
      if (p is num && p > max) max = p.toDouble();
    }
    return max == 0 ? 1000 : max;
  }
}

class MarketTrendChart extends StatelessWidget {
  final MarketPriceResponse res;
  final String selectedGrade;

  const MarketTrendChart({
    super.key,
    required this.res,
    required this.selectedGrade,
  });

  @override
  Widget build(BuildContext context) {
    final keys = res.marketPrices.keys.where((k) => k != 'default').toList()
      ..sort((a, b) => a.compareTo(b)); // Chronological

    if (keys.isEmpty)
      return Center(child: Text(AppLocalizations.of(context)!.chart_no_trend_data));

    final spots = <FlSpot>[];
    for (int i = 0; i < keys.length; i++) {
      final weekPrices = res.marketPrices[keys[i]];
      if (weekPrices != null && weekPrices.containsKey(selectedGrade)) {
        spots.add(FlSpot(
            i.toDouble(), (weekPrices[selectedGrade] as num).toDouble()));
      }
    }

    if (spots.isEmpty)
      return Center(child: Text(AppLocalizations.of(context)!.chart_no_trend_grade));

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final double range = maxY - minY;
    final double yInterval = range > 300 ? 100 : 50;

    // Provide more breathing room at the bottom to avoid overlap with X-axis
    final double chartMinY = (minY / yInterval).floor() * yInterval - yInterval;
    final double chartMaxY =
        (maxY / yInterval).ceil() * yInterval + (yInterval / 2);

    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (keys.length - 1).toDouble(),
          minY: chartMinY,
          maxY: chartMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: TeaColors.freshLeaf,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: TeaColors.freshLeaf.withOpacity(0.1),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  // Strictly only show at exact integer positions
                  if ((value - index).abs() > 0.05)
                    return const SizedBox.shrink();

                  if (index >= 0 && index < keys.length) {
                    final bool isFirst = index == 0;
                    final bool isLast = index == keys.length - 1;
                    final bool isMiddle =
                        keys.length > 2 && index == (keys.length / 2).floor();

                    if (isFirst || isLast || isMiddle) {
                      final dateStr = keys[index];
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8,
                        child: Text(
                          dateStr.length > 5 ? dateStr.substring(5) : dateStr,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: TeaColors.darkGray,
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 9,
                        color: TeaColors.darkGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: TeaColors.lightGray,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class QualityRadarChart extends StatelessWidget {
  final double color;
  final double aroma;
  final double age;

  const QualityRadarChart({
    super.key,
    required this.color,
    required this.aroma,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AspectRatio(
      aspectRatio: 1.3,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: TeaColors.freshLeaf.withOpacity(0.3),
              borderColor: TeaColors.freshLeaf,
              entryRadius: 3,
              dataEntries: [
                RadarEntry(value: (color * 100).clamp(5, 100)),
                RadarEntry(value: (aroma * 100).clamp(5, 100)),
                RadarEntry(value: (age * 100).clamp(5, 100)),
              ],
            ),
            // Benchmark premium line
            RadarDataSet(
              fillColor: TeaColors.goldenSunlight.withOpacity(0.05),
              borderColor: TeaColors.goldenSunlight.withOpacity(0.4),
              entryRadius: 0,
              dataEntries: [
                const RadarEntry(value: 80),
                const RadarEntry(value: 80),
                const RadarEntry(value: 80),
              ],
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData:
              const BorderSide(color: TeaColors.mediumGray, width: 1),
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: const TextStyle(
              color: TeaColors.nearBlack,
              fontSize: 12,
              fontWeight: FontWeight.bold),
          getTitle: (index, angle) {
            switch (index) {
              case 0:
                return RadarChartTitle(text: l10n.chart_radar_color);
              case 1:
                return RadarChartTitle(text: l10n.chart_radar_aroma);
              case 2:
                return RadarChartTitle(text: l10n.chart_radar_freshness);
              default:
                return const RadarChartTitle(text: '');
            }
          },
          tickCount: 5,
          radarShape: RadarShape.circle,
          ticksTextStyle:
              const TextStyle(color: Colors.transparent, fontSize: 0),
          gridBorderData: BorderSide(
              color: TeaColors.mediumGray.withOpacity(0.2), width: 1),
        ),
      ),
    );
  }
}

class RadarChartLegend extends StatelessWidget {
  const RadarChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(l10n.chart_your_batch, TeaColors.freshLeaf),
        const SizedBox(width: 24),
        _buildLegendItem(l10n.chart_premium_target, TeaColors.goldenSunlight),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: TeaColors.darkGray)),
      ],
    );
  }
}
