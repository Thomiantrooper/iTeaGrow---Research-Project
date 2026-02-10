import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/analytics_provider.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(analyticsProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(analyticsProvider.notifier).loadAll(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${state.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(analyticsProvider.notifier).loadAll(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(analyticsProvider.notifier).loadAll();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(state),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Disease Distribution'),
                        const SizedBox(height: 16),
                        _buildPieChart(state),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Disease Trends'),
                        const SizedBox(height: 16),
                        _buildLineChart(state),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Monthly Scans'),
                        const SizedBox(height: 16),
                        _buildBarChart(state),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Recovery Tracking'),
                        const SizedBox(height: 16),
                        _buildRecoverySection(state),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Top Scanners'),
                        const SizedBox(height: 16),
                        _buildTopScannersSection(state),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSummaryCards(AnalyticsState state) {
    final overview = state.overview;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _SummaryCard(
          title: 'Total Scans',
          value: '${overview?['total_scans'] ?? 0}',
          icon: Icons.document_scanner,
          color: Colors.blue,
        ),
        _SummaryCard(
          title: 'Total Users',
          value: '${overview?['total_users'] ?? 0}',
          icon: Icons.people,
          color: Colors.purple,
        ),
        _SummaryCard(
          title: 'Health Rate',
          value:
              '${((overview?['health_rate'] ?? 0) as num).toStringAsFixed(1)}%',
          icon: Icons.health_and_safety,
          color: AppTheme.statusGood,
        ),
        _SummaryCard(
          title: 'Active Devices',
          value: '${overview?['total_devices'] ?? 0}',
          icon: Icons.sensors,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildPieChart(AnalyticsState state) {
    final distribution = state.diseaseDistribution;
    if (distribution == null || distribution.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No disease distribution data available')),
        ),
      );
    }

    final List<Map<String, dynamic>> items =
        List<Map<String, dynamic>>.from(distribution);

    final colors = [
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.blue,
      Colors.purple,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final count = (item['count'] ?? 0) as num;
                    final percentage = (item['percentage'] ?? 0) as num;
                    return PieChartSectionData(
                      value: count.toDouble(),
                      title: '${percentage.toStringAsFixed(1)}%',
                      color: colors[i % colors.length],
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item['disease_name'] ?? 'Unknown'} (${item['count'] ?? 0})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(AnalyticsState state) {
    final trends = state.diseaseTrends;
    if (trends == null || trends.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No trend data available')),
        ),
      );
    }

    final List<Map<String, dynamic>> trendItems =
        List<Map<String, dynamic>>.from(trends);

    final spots = trendItems.asMap().entries.map((entry) {
      final total = (entry.value['total'] ?? 0) as num;
      return FlSpot(entry.key.toDouble(), total.toDouble());
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < trendItems.length) {
                        final period =
                            trendItems[idx]['period']?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            period.length > 5
                                ? period.substring(period.length - 5)
                                : period,
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
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.primaryGreen,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(AnalyticsState state) {
    final yearly = state.yearlyAnalysis;
    final monthlyData = yearly?['monthly_data'] as List?;
    if (yearly == null || monthlyData == null || monthlyData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No yearly data available')),
        ),
      );
    }

    final List<Map<String, dynamic>> months =
        List<Map<String, dynamic>>.from(monthlyData);
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < months.length) {
                        final month = (months[idx]['month'] ?? 1) as num;
                        final mIdx = month.toInt() - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            mIdx >= 0 && mIdx < 12 ? monthNames[mIdx] : '',
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
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: months.asMap().entries.map((entry) {
                final total = (entry.value['total'] ?? 0) as num;
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: total.toDouble(),
                      color: AppTheme.primaryGreen,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecoverySection(AnalyticsState state) {
    final recovery = state.recoveryTracking;
    if (recovery == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No recovery data available')),
        ),
      );
    }

    final recovered = recovery['recovered'] ?? 0;
    final improving = recovery['improving'] ?? 0;
    final stillInfected = recovery['still_infected'] ?? 0;
    final total = recovery['total_tracked_users'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('$total Plants Tracked',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _RecoveryIndicator(
                    label: 'Recovered',
                    value: recovered,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _RecoveryIndicator(
                    label: 'Improving',
                    value: improving,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _RecoveryIndicator(
                    label: 'Infected',
                    value: stillInfected,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopScannersSection(AnalyticsState state) {
    final userStats = state.userStats;
    if (userStats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No user stats available')),
        ),
      );
    }

    final topScanners =
        List<Map<String, dynamic>>.from(userStats['top_scanners'] ?? []);

    if (topScanners.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No scanner data')),
        ),
      );
    }

    return Card(
      child: Column(
        children: topScanners.asMap().entries.map((entry) {
          final scanner = entry.value;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
              child: Text(
                '${entry.key + 1}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen),
              ),
            ),
            title: Text(scanner['username'] ?? 'Unknown'),
            trailing: Text(
              '${scanner['scan_count'] ?? 0} scans',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryIndicator extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;

  const _RecoveryIndicator({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}
