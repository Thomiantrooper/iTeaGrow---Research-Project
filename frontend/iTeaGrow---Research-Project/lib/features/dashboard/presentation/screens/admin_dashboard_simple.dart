import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/providers/auth_provider.dart';

class AdminDashboardSimple extends ConsumerWidget {
  const AdminDashboardSimple({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
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
                      'Welcome, ${user?.fullName ?? "Administrator"}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text('System Administration', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'System Health',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            const Row(
              children: [
                Expanded(
                  child: _HealthCard(
                    title: 'Database',
                    status: 'Online',
                    statusColor: AppTheme.statusGood,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _HealthCard(
                    title: 'IoT Devices',
                    status: '12 Active',
                    statusColor: AppTheme.statusGood,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Row(
              children: [
                Expanded(
                  child: _HealthCard(
                    title: 'Data Sync',
                    status: 'Synced',
                    statusColor: AppTheme.statusGood,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _HealthCard(
                    title: 'ML Models',
                    status: 'Loaded',
                    statusColor: AppTheme.statusGood,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Administration Tools',
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
                _AdminCard(
                  icon: Icons.people,
                  title: 'User Management',
                  subtitle: 'Roles & Permissions',
                  color: Colors.blue,
                  onTap: () => context.push('/dashboard/admin/users'),
                ),
                _AdminCard(
                  icon: Icons.devices,
                  title: 'Device Management',
                  subtitle: 'IoT Configuration',
                  color: Colors.purple,
                  onTap: () => context.push('/dashboard/admin/devices'),
                ),
                _AdminCard(
                  icon: Icons.settings,
                  title: 'System Config',
                  subtitle: 'Thresholds & Rules',
                  color: Colors.orange,
                  onTap: () => context.push('/dashboard/admin/config'),
                ),
                _AdminCard(
                  icon: Icons.sync,
                  title: 'Data Sync',
                  subtitle: 'Cloud Backup',
                  color: Colors.teal,
                  onTap: () => context.push('/dashboard/admin/sync'),
                ),
                _AdminCard(
                  icon: Icons.description,
                  title: 'System Logs',
                  subtitle: 'Audit Trail',
                  color: Colors.grey,
                  onTap: () => context.push('/dashboard/admin/logs'),
                ),
                _AdminCard(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  subtitle: 'Dashboard & Charts',
                  color: AppTheme.primaryGreen,
                  onTap: () => context.push('/dashboard/admin/analytics'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            const _ActivityCard(
              icon: Icons.person_add,
              title: 'New user registered',
              subtitle: 'farmer_john - 2 hours ago',
            ),
            const SizedBox(height: 8),
            const _ActivityCard(
              icon: Icons.devices,
              title: 'IoT device connected',
              subtitle: 'Sensor-NPK-03 - 5 hours ago',
            ),
            const SizedBox(height: 8),
            const _ActivityCard(
              icon: Icons.sync,
              title: 'Data synchronized',
              subtitle: '1,245 records - 1 day ago',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
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

class _HealthCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;

  const _HealthCard({
    required this.title,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
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

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
