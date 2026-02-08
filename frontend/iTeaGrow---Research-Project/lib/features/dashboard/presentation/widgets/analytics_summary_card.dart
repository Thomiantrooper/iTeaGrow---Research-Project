import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AnalyticsSummaryCard extends StatelessWidget {
  const AnalyticsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data - in real app, this would come from database analytics
    final metrics = [
      _MetricData(
        label: 'Avg Yield Prediction',
        value: '2.8 kg',
        trend: 12.5,
        icon: Icons.trending_up,
      ),
      _MetricData(
        label: 'Good Leaf %',
        value: '78%',
        trend: 5.2,
        icon: Icons.eco,
      ),
      _MetricData(
        label: 'Powder Grade',
        value: 'A+',
        trend: 0,
        icon: Icons.grade,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: metrics.map((metric) {
                return _MetricItem(metric: metric);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final _MetricData metric;

  const _MetricItem({required this.metric});

  @override
  Widget build(BuildContext context) {
    final trendColor = metric.trend > 0
        ? AppTheme.statusGood
        : metric.trend < 0
            ? AppTheme.statusCritical
            : AppTheme.textSecondary;

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            metric.icon,
            color: AppTheme.primaryGreen,
            size: 24,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          metric.value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          metric.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        if (metric.trend != 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                metric.trend > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: trendColor,
              ),
              Text(
                '${metric.trend.abs()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final double trend;
  final IconData icon;

  _MetricData({
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
  });
}
