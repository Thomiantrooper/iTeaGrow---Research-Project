import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/analytics_provider.dart';
import 'package:iteagrow/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      body: Stack(
        children: [
          const FloatingLeavesBackground(
            leafCount: 4,
            opacity: 0.05,
            child: SizedBox.expand(),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 80,
                floating: true,
                pinned: true,
                backgroundColor: TeaColors.white,
                title: Text(
                  l10n.analytics_title,
                  style: TeaTypography.headlineSmall.copyWith(color: TeaColors.matureLeaf),
                ),
                actions: [
                  TeaIconButton(
                    icon: Icons.refresh,
                    onPressed: () => ref.read(analyticsProvider.notifier).loadAll(),
                    tooltip: l10n.common_retry,
                  ),
                  const SizedBox(width: TeaSpacing.sm),
                ],
              ),
              if (state.isLoading && state.overview == null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: TeaColors.freshLeaf),
                        const SizedBox(height: TeaSpacing.md),
                        Text(l10n.analytics_loading, style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray)),
                      ],
                    ),
                  ),
                )
              else if (state.error != null && state.overview == null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: TeaColors.alertRust.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.error_outline, size: 32, color: TeaColors.alertRust),
                        ),
                        const SizedBox(height: TeaSpacing.md),
                        Text('Error: ${state.error}', style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray)),
                        const SizedBox(height: TeaSpacing.md),
                        TextButton.icon(
                          onPressed: () => ref.read(analyticsProvider.notifier).loadAll(),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(l10n.common_retry),
                          style: TextButton.styleFrom(foregroundColor: TeaColors.freshLeaf),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: TeaSpacing.screenPaddingHorizontal,
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: TeaSpacing.md),
                      _buildSummaryCards(state),
                      const SizedBox(height: TeaSpacing.lg),
                      _buildDiseaseDistributionSection(state),
                      const SizedBox(height: TeaSpacing.lg),
                      _buildTrendsSection(state),
                      const SizedBox(height: TeaSpacing.lg),
                      _buildMonthlyScansSection(state),
                      const SizedBox(height: TeaSpacing.lg),
                      _buildRecoverySection(state),
                      const SizedBox(height: TeaSpacing.lg),
                      _buildTopScannersSection(state),
                      const SizedBox(height: TeaSpacing.xxl),
                    ]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AnalyticsState state) {
    final overview = state.overview;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TeaMetricCard(
                label: AppLocalizations.of(context)!.analytics_total_scans,
                value: '${overview?['total_scans'] ?? 0}',
                icon: Icons.document_scanner_outlined,
                iconColor: TeaColors.infoSky,
              ),
            ),
            const SizedBox(width: TeaSpacing.smd),
            Expanded(
              child: TeaMetricCard(
                label: AppLocalizations.of(context)!.analytics_total_users,
                value: '${overview?['total_users'] ?? 0}',
                icon: Icons.people_outlined,
                iconColor: TeaColors.matureLeaf,
              ),
            ),
          ],
        ),
        const SizedBox(height: TeaSpacing.smd),
        Row(
          children: [
            Expanded(
              child: TeaMetricCard(
                label: AppLocalizations.of(context)!.analytics_health_rate,
                value: '${((overview?['health_rate'] ?? 0) as num).toStringAsFixed(1)}%',
                icon: Icons.health_and_safety_outlined,
                iconColor: TeaColors.healthyGreen,
              ),
            ),
            const SizedBox(width: TeaSpacing.smd),
            Expanded(
              child: TeaMetricCard(
                label: AppLocalizations.of(context)!.analytics_active_devices,
                value: '${overview?['total_devices'] ?? 0}',
                icon: Icons.sensors_outlined,
                iconColor: TeaColors.warmAmber,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDiseaseDistributionSection(AnalyticsState state) {
    final distribution = state.diseaseDistribution;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeaSectionHeader(title: AppLocalizations.of(context)!.analytics_disease_distribution, icon: Icons.pie_chart_outline),
        const SizedBox(height: TeaSpacing.smd),
        if (distribution == null || distribution.isEmpty)
          TeaCard.elevated(
            padding: const EdgeInsets.all(TeaSpacing.xl),
            child: Center(
              child: Text(AppLocalizations.of(context)!.analytics_no_distribution, style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray)),
            ),
          )
        else
          TeaCard.elevated(
            padding: const EdgeInsets.all(TeaSpacing.md),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: distribution.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final count = (item['count'] ?? 0) as num;
                        final percentage = (item['percentage'] ?? 0) as num;
                        return PieChartSectionData(
                          value: count.toDouble(),
                          title: '${percentage.toStringAsFixed(1)}%',
                          color: _chartColors[i % _chartColors.length],
                          radius: 80,
                          titleStyle: TeaTypography.labelSmall.copyWith(
                            color: TeaColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                    ),
                  ),
                ),
                const SizedBox(height: TeaSpacing.md),
                Wrap(
                  spacing: TeaSpacing.md,
                  runSpacing: TeaSpacing.sm,
                  children: distribution.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: _chartColors[i % _chartColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${item['disease_name'] ?? 'Unknown'} (${item['count'] ?? 0})',
                          style: TeaTypography.labelSmall,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTrendsSection(AnalyticsState state) {
    final trends = state.diseaseTrends;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeaSectionHeader(title: AppLocalizations.of(context)!.analytics_disease_trends, icon: Icons.trending_up),
        const SizedBox(height: TeaSpacing.smd),
        if (trends == null || trends.isEmpty)
          TeaCard.elevated(
            padding: const EdgeInsets.all(TeaSpacing.xl),
            child: Center(
              child: Text(AppLocalizations.of(context)!.analytics_no_trend, style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray)),
            ),
          )
        else
          TeaCard.elevated(
            padding: const EdgeInsets.all(TeaSpacing.md),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: TeaColors.lightGray,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < trends.length && idx % (trends.length > 10 ? 3 : 1) == 0) {
                            final period = trends[idx]['period']?.toString() ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                period.length > 5 ? period.substring(period.length - 5) : period,
                                style: TeaTypography.labelSmall.copyWith(fontSize: 9, color: TeaColors.darkGray),
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
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TeaTypography.labelSmall.copyWith(fontSize: 9, color: TeaColors.darkGray),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trends.asMap().entries.map((entry) {
                        final total = (entry.value['total'] ?? 0) as num;
                        return FlSpot(entry.key.toDouble(), total.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: TeaColors.freshLeaf,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 3,
                          color: TeaColors.freshLeaf,
                          strokeWidth: 1.5,
                          strokeColor: TeaColors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: TeaColors.freshLeaf.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMonthlyScansSection(AnalyticsState state) {
    final yearly = state.yearlyAnalysis;
    final monthlyData = yearly?['monthly_data'] as List?;
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeaSectionHeader(title: AppLocalizations.of(context)!.analytics_monthly_scans, icon: Icons.bar_chart_outlined),
        const SizedBox(height: TeaSpacing.smd),
        if (yearly == null || monthlyData == null || monthlyData.isEmpty)
          TeaCard.elevated(
            padding: const EdgeInsets.all(TeaSpacing.xl),
            child: Center(
              child: Text(AppLocalizations.of(context)!.analytics_no_yearly, style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray)),
            ),
          )
        else
          TeaCard.elevated(
            padding: const EdgeInsets.all(TeaSpacing.md),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: TeaColors.lightGray,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final months = List<Map<String, dynamic>>.from(monthlyData);
                          final idx = value.toInt();
                          if (idx >= 0 && idx < months.length) {
                            final month = (months[idx]['month'] ?? 1) as num;
                            final mIdx = month.toInt() - 1;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                mIdx >= 0 && mIdx < 12 ? monthNames[mIdx] : '',
                                style: TeaTypography.labelSmall.copyWith(fontSize: 9, color: TeaColors.darkGray),
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
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TeaTypography.labelSmall.copyWith(fontSize: 9, color: TeaColors.darkGray),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List<Map<String, dynamic>>.from(monthlyData).asMap().entries.map((entry) {
                    final total = (entry.value['total'] ?? 0) as num;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: total.toDouble(),
                          gradient: const LinearGradient(
                            colors: [TeaColors.freshLeaf, TeaColors.matureLeaf],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 14,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRecoverySection(AnalyticsState state) {
    final recovery = state.recoveryTracking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeaSectionHeader(title: AppLocalizations.of(context)!.analytics_recovery, icon: Icons.healing_outlined),
        const SizedBox(height: TeaSpacing.smd),
        if (recovery == null)
          TeaCard.elevated(
            padding: const EdgeInsets.all(TeaSpacing.xl),
            child: Center(
              child: Text(AppLocalizations.of(context)!.analytics_no_recovery, style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray)),
            ),
          )
        else
          TeaCard.elevated(
            padding: const EdgeInsets.all(TeaSpacing.lg),
            child: Column(
              children: [
                Text(
                  '${recovery['total_tracked_users'] ?? 0} ${AppLocalizations.of(context)!.analytics_plants_tracked}',
                  style: TeaTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: TeaSpacing.md),
                Row(
                  children: [
                    Expanded(child: _buildRecoveryIndicator(AppLocalizations.of(context)!.analytics_recovered, recovery['recovered'] ?? 0, TeaColors.healthyGreen)),
                    Expanded(child: _buildRecoveryIndicator(AppLocalizations.of(context)!.analytics_improving, recovery['improving'] ?? 0, TeaColors.warmAmber)),
                    Expanded(child: _buildRecoveryIndicator(AppLocalizations.of(context)!.analytics_infected, recovery['still_infected'] ?? 0, TeaColors.alertRust)),
                  ],
                ),
              ],
            ),
          ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRecoveryIndicator(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TeaTypography.headlineSmall.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: TeaSpacing.xs),
        Text(label, style: TeaTypography.labelSmall.copyWith(color: color)),
      ],
    );
  }

  Widget _buildTopScannersSection(AnalyticsState state) {
    final userStats = state.userStats;
    final topScanners = List<Map<String, dynamic>>.from(userStats?['top_scanners'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeaSectionHeader(title: AppLocalizations.of(context)!.analytics_top_scanners, icon: Icons.leaderboard_outlined),
        const SizedBox(height: TeaSpacing.smd),
        if (topScanners.isEmpty)
          TeaCard.elevated(
            padding: const EdgeInsets.all(TeaSpacing.xl),
            child: Center(
              child: Text(AppLocalizations.of(context)!.analytics_no_scanners, style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray)),
            ),
          )
        else
          TeaCard.elevated(
            padding: const EdgeInsets.symmetric(vertical: TeaSpacing.sm),
            child: Column(
              children: topScanners.asMap().entries.map((entry) {
                final scanner = entry.value;
                final rank = entry.key + 1;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: rank <= 3
                        ? [TeaColors.goldenSunlight, TeaColors.mediumGray, TeaColors.warmAmber][rank - 1].withOpacity(0.2)
                        : TeaColors.freshLeaf.withOpacity(0.1),
                    child: Text(
                      '$rank',
                      style: TeaTypography.labelMedium.copyWith(
                        color: rank <= 3
                            ? [TeaColors.goldenSunlight, TeaColors.darkGray, TeaColors.warmAmber][rank - 1]
                            : TeaColors.freshLeaf,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    scanner['full_name'] ?? scanner['username'] ?? 'Unknown',
                    style: TeaTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '@${scanner['username'] ?? ''}',
                    style: TeaTypography.labelSmall.copyWith(color: TeaColors.darkGray),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: TeaSpacing.sm, vertical: TeaSpacing.xs),
                    decoration: BoxDecoration(
                      color: TeaColors.freshLeaf.withOpacity(0.1),
                      borderRadius: TeaRadius.radiusRound,
                    ),
                    child: Text(
                      '${scanner['scan_count'] ?? 0} scans',
                      style: TeaTypography.labelSmall.copyWith(
                        color: TeaColors.matureLeaf,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  static const _chartColors = [
    TeaColors.healthyGreen,
    TeaColors.alertRust,
    TeaColors.warmAmber,
    TeaColors.infoSky,
    TeaColors.matureLeaf,
  ];
}
