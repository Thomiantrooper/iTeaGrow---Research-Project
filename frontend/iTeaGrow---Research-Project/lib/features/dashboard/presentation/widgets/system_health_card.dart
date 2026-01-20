import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SystemHealthCard extends StatelessWidget {
  const SystemHealthCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data - in real app, this would come from system monitoring
    final healthMetrics = [
      _HealthMetric(
        label: 'Database',
        status: 'Healthy',
        isHealthy: true,
        icon: Icons.storage,
      ),
      _HealthMetric(
        label: 'IoT Devices',
        status: '3/4 Connected',
        isHealthy: true,
        icon: Icons.devices,
      ),
      _HealthMetric(
        label: 'Data Sync',
        status: 'Up to date',
        isHealthy: true,
        icon: Icons.sync,
      ),
      _HealthMetric(
        label: 'Storage',
        status: '2.3 GB / 10 GB',
        isHealthy: true,
        icon: Icons.sd_storage,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppTheme.statusGood,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      'All Systems Operational',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // Refresh system health
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...healthMetrics.map((metric) => _HealthRow(metric: metric)),
          ],
        ),
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final _HealthMetric metric;

  const _HealthRow({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: metric.isHealthy
                  ? AppTheme.statusGood.withOpacity(0.1)
                  : AppTheme.statusCritical.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              metric.icon,
              color: metric.isHealthy ? AppTheme.statusGood : AppTheme.statusCritical,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            metric.isHealthy ? Icons.check_circle : Icons.error,
            color: metric.isHealthy ? AppTheme.statusGood : AppTheme.statusCritical,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _HealthMetric {
  final String label;
  final String status;
  final bool isHealthy;
  final IconData icon;

  _HealthMetric({
    required this.label,
    required this.status,
    required this.isHealthy,
    required this.icon,
  });
}
