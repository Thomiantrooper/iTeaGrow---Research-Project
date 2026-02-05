import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/prediction_request_model.dart';
import '../../domain/entities/yield_prediction_result.dart';

class YieldResultsScreen extends StatelessWidget {
  final YieldPredictionResult result;
  final PredictionRequestModel? predictionRequest;

  const YieldResultsScreen({
    super.key,
    required this.result,
    this.predictionRequest,
  });

  @override
  Widget build(BuildContext context) {
    // Get colors from theme
    final primaryColor = Theme.of(context).primaryColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _generateAndSharePdf(context, result),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            _buildSummaryCard(context),
            const SizedBox(height: 24),

            // Yield Chart
            if (result.dailyPredictions.isNotEmpty) ...[
              const Text(
                'Yield Forecast',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: _buildYieldChart(primaryColor, onSurface),
              ),
              const SizedBox(height: 24),
            ],

            // Daily Breakdown
            const Text(
              'Daily Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: result.dailyPredictions.length,
              itemBuilder: (context, index) {
                final prediction = result.dailyPredictions[index];

                // Find max yield to highlight
                double maxYield = 0;
                for (var p in result.dailyPredictions) {
                  if (p.predictedYieldKg > maxYield)
                    maxYield = p.predictedYieldKg;
                }
                final isHighest = prediction.predictedYieldKg == maxYield;

                return Padding(
                  padding: EdgeInsets.only(
                      bottom:
                          index == result.dailyPredictions.length - 1 ? 0 : 12),
                  child: _buildDailyCard(context, prediction, isHighest),
                );
              },
            ),

            const SizedBox(height: 32),

            // Advanced Analytics Section
            ExpansionTile(
              title: const Text(
                'Advanced Analysis',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Tap to show detailed charts'),
              children: [
                const SizedBox(height: 16),

                // Chart 1: Yield Forecast (Bar + Temp Line)
                _buildSectionTitle('Yield Forecast vs Temperature'),
                SizedBox(
                  height: 300,
                  child: _buildYieldTempChart(primaryColor),
                ),
                const SizedBox(height: 32),

                // Chart 2: Weather (Yield Line + Rain Bar)
                _buildSectionTitle('Rainfall Impact on Yield'),
                SizedBox(
                  height: 300,
                  child: _buildYieldRainChart(primaryColor),
                ),
                const SizedBox(height: 32),

                // Chart 3: Efficiency
                _buildSectionTitle('Efficiency Analysis'),
                SizedBox(
                  height: 250,
                  child: _buildEfficiencyChart(primaryColor),
                ),
                const SizedBox(height: 32),

                const SizedBox(height: 24),
              ],
            ),

            if (result.summary.weatherSource != null) ...[
              const SizedBox(height: 24),
              Text(
                'Weather Source: ${result.summary.weatherSource}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Chart 1: Combo (Yield Bar + Temp Line)
  Widget _buildYieldTempChart(Color primary) {
    // Scales
    double maxYield = 0;
    double maxTemp = 0;
    for (var p in result.dailyPredictions) {
      if (p.predictedYieldKg > maxYield) maxYield = p.predictedYieldKg;
      if (p.weather.tempMax > maxTemp) maxTemp = p.weather.tempMax;
    }
    maxYield = (maxYield * 1.2).ceilToDouble();
    maxTemp = (maxTemp * 1.5).ceilToDouble(); // More headroom for line

    return Stack(
      children: [
        // Bottom: Yield Bar Chart (Left Axis)
        BarChart(
          BarChartData(
            alignment: BarChartAlignment
                .spaceAround, // Distribute evenly to fill width
            maxY: maxYield,
            minY: 0,
            barGroups: result.dailyPredictions.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.predictedYieldKg,
                    color: Colors.green.withOpacity(0.7),
                    width: 16,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30, // FIXED: Explicit size
                  getTitlesWidget: (value, meta) {
                    int idx = value.toInt();
                    if (idx >= 0 && idx < result.dailyPredictions.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${result.dailyPredictions[idx].date.day}/${result.dailyPredictions[idx].date.month}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40, // FIXED: Match LineChart's left spacer
                    interval: maxYield / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == 0)
                        return const Text('0',
                            style: TextStyle(color: Colors.grey, fontSize: 10));
                      return Text('${value.toInt()}',
                          style: const TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold));
                    }),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60, // FIXED: Match LineChart's right titles
                    getTitlesWidget: (v, m) => const Text('')), // Spacer
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barTouchData:
                BarTouchData(enabled: false), // Disable bottom chart touch
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        ),

        // Top: Temp Line Chart (Right Axis simulated)
        LineChart(
          LineChartData(
            minY: 0,
            maxY: maxYield, // Use SAME Y scale as BarChart for alignment
            minX: -0.5, // Standard padding for spaceAround
            maxX: result.dailyPredictions.length -
                0.5, // Standard padding for spaceAround
            lineBarsData: [
              LineChartBarData(
                spots: result.dailyPredictions.asMap().entries.map((e) {
                  // Normalize: TempValue * (MaxYield / MaxTemp)
                  double normalizedY =
                      e.value.weather.avgTemp * (maxYield / maxTemp);
                  return FlSpot(e.key.toDouble(), normalizedY);
                }).toList(),
                color: Colors.amber.shade700, // Changed from pink to Amber
                barWidth: 3,
                isCurved: true,
                dotData: const FlDotData(show: true),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final index = barSpot.x.toInt();
                    if (index < 0 || index >= result.dailyPredictions.length)
                      return null;

                    final data = result.dailyPredictions[index];
                    // De-normalize temp
                    double ratio = maxYield / maxTemp;
                    double temp = barSpot.y / ratio;

                    return LineTooltipItem(
                      'Yield: ${data.predictedYieldKg.toStringAsFixed(2)} kg\nTemp: ${temp.toStringAsFixed(2)}°C',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40, // FIXED: Match BarChart
                    getTitlesWidget: (v, m) => const Text('')), // Spacer
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60, // FIXED: Match BarChart spacer
                  interval: maxYield / 4, // Sync intervals
                  getTitlesWidget: (value, meta) {
                    // Un-normalize value to show real Temp
                    double ratio = maxYield / maxTemp;
                    double temp = value / ratio;
                    if (temp < 0) return const Text('');
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      angle: -0.5, // Angle the text
                      child: Text(
                        '${temp.toStringAsFixed(2)}°C',
                        style: TextStyle(
                          color: Colors.amber.shade800, // Match line color
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize:
                      30, // FIXED: Match BarChart bottom height to align plot area
                  getTitlesWidget: (v, m) => const Text(''), // Invisible spacer
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        ),
      ],
    );
  }

  // Chart 2: Combo (Yield Line + Rain Bar)
  Widget _buildYieldRainChart(Color primary) {
    // Scales
    double maxYield = 0;
    double maxRain = 0.1; // avoid div by zero
    for (var p in result.dailyPredictions) {
      if (p.predictedYieldKg > maxYield) maxYield = p.predictedYieldKg;
      if (p.weather.rainfall > maxRain) maxRain = p.weather.rainfall;
    }
    maxYield = (maxYield * 1.2).ceilToDouble();
    maxRain = (maxRain * 1.5).ceilToDouble();

    return Stack(
      children: [
        // Bottom: Rain Bar Chart (Right Axis logic via Normalization)
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround, // Distribute evenly
            maxY: maxYield, // Using Yield scale as base
            minY: 0,
            barGroups: result.dailyPredictions.asMap().entries.map((e) {
              // Normalize Rain to Yield Scale
              double normalizedRain =
                  e.value.weather.rainfall * (maxYield / maxRain);
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: normalizedRain,
                    color: Colors.blue.withOpacity(0.4),
                    width: 16,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30, // Explicit size
                  getTitlesWidget: (value, meta) {
                    int idx = value.toInt();
                    if (idx >= 0 && idx < result.dailyPredictions.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${result.dailyPredictions[idx].date.day}/${result.dailyPredictions[idx].date.month}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40, // FIXED: Explicitly set
                      getTitlesWidget: (v, m) => const Text(''))), // Spacer
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60, // FIXED: Set to 60
                  interval: maxYield / 4,
                  getTitlesWidget: (value, meta) {
                    double realRain = value / (maxYield / maxRain);
                    if (realRain < 0) return const Text('');
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      angle: -0.5, // Angle the text
                      child: Text(
                        '${realRain.toStringAsFixed(2)}mm',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barTouchData:
                BarTouchData(enabled: false), // Disable bottom chart touch
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        ),

        // Top: Yield Line Chart (Left Axis)
        LineChart(
          LineChartData(
            minY: 0,
            maxY: maxYield,
            minX: -0.5, // Standard padding for spaceAround
            maxX: result.dailyPredictions.length -
                0.5, // Standard padding for spaceAround
            lineBarsData: [
              LineChartBarData(
                spots: result.dailyPredictions.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.predictedYieldKg);
                }).toList(),
                color: Colors.green,
                barWidth: 3,
                isCurved: true,
                dotData: const FlDotData(show: true),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.green.withOpacity(0.8),
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final index = barSpot.x.toInt();
                    if (index < 0 || index >= result.dailyPredictions.length)
                      return null;

                    final data = result.dailyPredictions[index];
                    final rain = data.weather.rainfall;

                    return LineTooltipItem(
                      'Yield: ${data.predictedYieldKg.toStringAsFixed(2)} kg\nRain: ${rain.toStringAsFixed(2)} mm',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40, // FIXED: Match
                    interval: maxYield / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('0');
                      return Text('${value.toInt()}',
                          style: const TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold));
                    }),
              ),
              rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60, // FIXED: Match BarChart's 60
                      getTitlesWidget: (v, m) => const Text(''))), // Spacer
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize:
                      30, // FIXED: Match BarChart bottom height to align plot area
                  getTitlesWidget: (v, m) => const Text(''), // Invisible spacer
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        ),
      ],
    );
  }

  Widget _buildEfficiencyChart(Color primary) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 4.0, // efficiency is usually small log value
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                if (idx >= 0 && idx < result.dailyPredictions.length) {
                  return Text('${result.dailyPredictions[idx].date.day}');
                }
                return const Text('');
              },
            ),
          ),
        ),
        barGroups: result.dailyPredictions.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.logEfficiency,
                color: Colors.blue.withOpacity(0.6),
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Log Eff: ${rod.toY.toStringAsFixed(2)}',
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    // Find best harvest day
    DailyPrediction? bestDay;
    double maxYield = -1;
    for (var p in result.dailyPredictions) {
      if (p.predictedYieldKg > maxYield) {
        maxYield = p.predictedYieldKg;
        bestDay = p;
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Predicted Yield'),
                    const SizedBox(height: 8),
                    Text(
                      '${result.summary.totalPredictedYield.toStringAsFixed(2)} kg',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  context,
                  'Avg. Daily',
                  '${result.summary.averageDailyYield.toStringAsFixed(2)} kg',
                  icon: Icons.trending_up,
                ),
                if (bestDay != null)
                  _buildSummaryItem(
                    context,
                    'Best Harvest Day',
                    '${bestDay.date.day}/${bestDay.date.month} (${bestDay.predictedYieldKg.toStringAsFixed(2)} kg)',
                    icon: null, // Remove star icon
                    valueColor: Colors.amber.shade800,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYieldChart(Color primaryColor, Color onSurface) {
    // Generate sports for chart
    final spots = result.dailyPredictions.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.predictedYieldKg);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 200,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Ensure we only show valid integer indices
                if (value % 1 != 0) return const Text('');

                int idx = value.toInt();
                if (idx >= 0 && idx < result.dailyPredictions.length) {
                  final date = result.dailyPredictions[idx].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                        fontSize: 12, // Increased size
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                // Show clear rounded values
                if (value == 0) return const Text('0');
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
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
        borderData: FlBorderData(show: false),
        // Use exact range to prevent label duplication
        minX: 0,
        maxX: (result.dailyPredictions.length - 1).toDouble(),
        // Add vertical padding to Y axis so points aren't cut off
        minY: 0,
        // Calculate max Y dynamically + buffer? (FlChart does auto mostly, but let's be safe if needed)
        // Leaving it auto for now, usually works well unless 0.

        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35, // moderate smoothing
            preventCurveOverShooting: true, // cleaner curve
            color: primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.3),
                  primaryColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '${barSpot.y.toStringAsFixed(2)} kg',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCard(
      BuildContext context, DailyPrediction prediction, bool isHighestYield) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isHighestYield ? Colors.amber.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighestYield
            ? Border.all(color: Colors.amber.shade700, width: 2)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isHighestYield) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Highest Yield',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(prediction.date),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prediction',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isHighestYield
                        ? Colors.amber.shade100
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${prediction.predictedYieldKg.toStringAsFixed(2)} kg',
                    style: TextStyle(
                      color: isHighestYield
                          ? Colors.amber.shade900
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildWeatherItem(
                    Icons.thermostat,
                    'Temp',
                    (prediction.weather.tempMin - prediction.weather.tempMax)
                                .abs() <
                            0.1
                        ? '${prediction.weather.tempMin.toStringAsFixed(2)}°C'
                        : '${prediction.weather.tempMin.toStringAsFixed(2)}-${prediction.weather.tempMax.toStringAsFixed(2)}°C',
                    Colors.orange,
                  ),
                  _buildVerticalDivider(),
                  _buildWeatherItem(
                    Icons.water_drop,
                    'Humidity',
                    '${prediction.weather.humidity.toStringAsFixed(2)}%',
                    Colors.blue,
                  ),
                  _buildVerticalDivider(),
                  _buildWeatherItem(
                    Icons.cloud,
                    'Rain',
                    '${prediction.weather.rainfall.toStringAsFixed(2)} mm',
                    Colors.indigo,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildWeatherItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1) {
      return 'Tomorrow';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _generateAndSharePdf(
      BuildContext context, YieldPredictionResult result) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // 1. Define Brand Color (TeaColors.freshLeaf = 0xFF4A7C59)
    final teaGreen = PdfColor.fromInt(0xFF4A7C59);
    final lightGreen = PdfColor.fromInt(0xFFE8F0E9); // Mist green background

    // 2. Find Best Harvest Day(s)
    double maxYield = -1;
    DateTime? bestDate;
    for (var p in result.dailyPredictions) {
      if (p.predictedYieldKg > maxYield) {
        maxYield = p.predictedYieldKg;
        bestDate = p.date;
      }
    }
    String bestDayStr = 'N/A';
    if (bestDate != null) {
      bestDayStr =
          '${bestDate.day}/${bestDate.month}/${bestDate.year} (${maxYield.toStringAsFixed(2)} kg)';
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Yield Prediction Report',
                  style: pw.TextStyle(
                      font: fontBold, fontSize: 24, color: teaGreen)),
              pw.PdfLogo(),
            ],
          ),
        ),
        footer: (context) => pw.Footer(
          leading: pw.Text('iTeaGrow - Smart Tea Management',
              style: pw.TextStyle(font: font, fontSize: 10, color: teaGreen)),
          trailing: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey)),
        ),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Text('Generated on: ${DateTime.now().toString().split('.')[0]}',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 20),

          // Summary Section
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: teaGreen, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              color: lightGreen, // Light background
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Executive Summary',
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 16, color: teaGreen)),
                pw.Divider(color: teaGreen),
                _buildPdfSummaryRow(
                    'Total Predicted Yield',
                    '${result.summary.totalPredictedYield.toStringAsFixed(2)} kg',
                    font,
                    fontBold),
                _buildPdfSummaryRow(
                    'Average Daily Yield',
                    '${result.summary.averageDailyYield.toStringAsFixed(2)} kg',
                    font,
                    fontBold),
                _buildPdfSummaryRow('Highest Yield Day', bestDayStr, font,
                    fontBold, // Highlighted
                    valueColor: teaGreen),
                if (result.summary.weatherSource != null)
                  _buildPdfSummaryRow('Weather Source',
                      '${result.summary.weatherSource}', font, fontBold),
              ],
            ),
          ),
          // Input Parameters Section (New)
          if (predictionRequest != null) ...[
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Input Parameters',
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 14, color: teaGreen)),
                  pw.Divider(color: PdfColors.grey300),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildPdfSummaryRow('Division',
                                predictionRequest!.divisionId, font, fontBold),
                            _buildPdfSummaryRow(
                                'Labor Total',
                                predictionRequest!.laborTotal.toString(),
                                font,
                                fontBold),
                            _buildPdfSummaryRow(
                                'Field Size',
                                '${predictionRequest!.fieldSizeHa} ha',
                                font,
                                fontBold),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildPdfSummaryRow(
                                'Crop Harvested',
                                '${predictionRequest!.cropHarvestedKg} kg',
                                font,
                                fontBold),
                            _buildPdfSummaryRow(
                                'Grades (G/C/D)',
                                '${predictionRequest!.gPct}% / ${predictionRequest!.cPct}% / ${predictionRequest!.dPct}%',
                                font,
                                fontBold),
                            _buildPdfSummaryRow(
                                'Prediction Days',
                                '${predictionRequest!.predictionDays} days',
                                font,
                                fontBold),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 24),

          // Table Section
          pw.Text('Daily Forecast Breakdown',
              style:
                  pw.TextStyle(font: fontBold, fontSize: 18, color: teaGreen)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(
                font: fontBold, color: PdfColors.white, fontSize: 11),
            cellStyle: pw.TextStyle(font: font, fontSize: 10),
            headerDecoration: pw.BoxDecoration(color: teaGreen),
            rowDecoration: const pw.BoxDecoration(
                border:
                    pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            headers: ['Date', 'Yield (kg)', 'Rain (mm)', 'Temp (°C)'],
            data: result.dailyPredictions.map((p) {
              // Format temp to match screen logic
              String tempStr = (p.weather.tempMin - p.weather.tempMax).abs() <
                      0.1
                  ? p.weather.tempMin.toStringAsFixed(1)
                  : '${p.weather.tempMin.toStringAsFixed(1)} - ${p.weather.tempMax.toStringAsFixed(1)}';

              return [
                '${p.date.day}/${p.date.month}/${p.date.year}',
                p.predictedYieldKg.toStringAsFixed(2),
                p.weather.rainfall.toStringAsFixed(2),
                tempStr,
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
        bytes: await doc.save(), filename: 'yield_prediction_report.pdf');
  }

  pw.Widget _buildPdfSummaryRow(
      String label, String value, pw.Font font, pw.Font fontBold,
      {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font)),
          pw.Text(value,
              style: pw.TextStyle(
                  font: fontBold, color: valueColor ?? PdfColors.black)),
        ],
      ),
    );
  }
}
