import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/providers/auth_provider_simple.dart';

class ManagerDashboardSimple extends ConsumerWidget {
  const ManagerDashboardSimple({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateSimpleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authStateSimpleProvider.notifier).state = null;
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.fullName ?? "Manager"}!',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Analytics & Management Dashboard',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analytics Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Avg Yield',
                    value: '2,450 kg',
                    trend: '+12%',
                    trendUp: true,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Good Leaf %',
                    value: '78%',
                    trend: '+5%',
                    trendUp: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Management Tools',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _DashboardCard(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  subtitle: 'Dashboard & Charts',
                  color: AppTheme.primaryGreen,
                  onTap: () => context.push('/dashboard/manager/analytics'),
                ),
                _DashboardCard(
                  icon: Icons.health_and_safety,
                  title: 'Disease Detection',
                  subtitle: 'Scan & Detect',
                  color: AppTheme.statusWarning,
                  onTap: () => context.push('/dashboard/manager/disease'),
                ),
                _DashboardCard(
                  icon: Icons.description,
                  title: 'Reports',
                  subtitle: 'Generate PDF',
                  color: AppTheme.accentAmber,
                  onTap: () => context.push('/dashboard/manager/reports'),
                ),
                _DashboardCard(
                  icon: Icons.trending_up,
                  title: 'Trend Analysis',
                  subtitle: 'Historical Data',
                  color: Colors.purple,
                  onTap: () => context.push('/dashboard/manager/analytics'),
                ),
                _DashboardCard(
                  icon: Icons.camera_alt,
                  title: 'Leaf Maturity',
                  subtitle: '+ Yield Prediction',
                  color: Colors.green,
                  onTap: () => context.push('/dashboard/manager/disease'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Sensor Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const _SensorCard(
              title: 'NPK Levels',
              value: 'N:45 P:32 K:28',
              status: 'Balanced',
              statusColor: AppTheme.statusGood,
            ),
            const SizedBox(height: 8),
            const _SensorCard(
              title: 'Soil Moisture',
              value: '65%',
              status: 'Optimal',
              statusColor: AppTheme.statusGood,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool trendUp;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  trendUp ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color:
                      trendUp ? AppTheme.statusGood : AppTheme.statusCritical,
                ),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        trendUp ? AppTheme.statusGood : AppTheme.statusCritical,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;
  final Color statusColor;

  const _SensorCard({
    required this.title,
    required this.value,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
