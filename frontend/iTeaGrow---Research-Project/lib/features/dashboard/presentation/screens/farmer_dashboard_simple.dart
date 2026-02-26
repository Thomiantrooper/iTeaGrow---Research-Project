import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/iot_live_provider.dart';
import '../../../auth/data/providers/auth_provider_simple.dart';

class FarmerDashboardSimple extends ConsumerWidget {
  const FarmerDashboardSimple({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateSimpleProvider);
    final liveState = ref.watch(iotLiveProvider);
    final device = liveState.deviceList.isNotEmpty ? liveState.deviceList.first : null;
    final hasLive = device != null && device.hasData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
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
                      'Welcome, ${user?.fullName ?? "Farmer"}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                        SizedBox(width: 4),
                        Text('Talawakelle, Sri Lanka', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Quick Actions',
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
                  icon: Icons.camera_alt,
                  title: 'Capture Leaf',
                  color: AppTheme.primaryGreen,
                  onTap: () => context.push('/dashboard/farmer/scan'),
                ),
                _DashboardCard(
                  icon: Icons.health_and_safety,
                  title: 'Disease Detection',
                  color: AppTheme.statusWarning,
                  onTap: () => context.push('/dashboard/farmer/history'),
                ),
                _DashboardCard(
                  icon: Icons.description,
                  title: 'Reports',
                  color: AppTheme.accentAmber,
                  onTap: () => context.push('/dashboard/farmer/reports'),
                ),
                _DashboardCard(
                  icon: Icons.sensors,
                  title: 'IoT Devices',
                  color: Colors.blue,
                  onTap: () => context.push('/dashboard/farmer/devices'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Sensor Readings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            _SensorCard(
              title: 'Soil Moisture',
              value: hasLive && device.soilMoisture != null
                  ? '${device.soilMoisture!.toStringAsFixed(0)}%'
                  : '--',
              status: hasLive && device.soilMoisture != null
                  ? (device.soilMoisture! < 35 || device.soilMoisture! > 75 ? 'Warning' : 'Optimal')
                  : 'No data',
              statusColor: hasLive && device.soilMoisture != null
                  ? (device.soilMoisture! < 35 || device.soilMoisture! > 75
                      ? AppTheme.statusWarning
                      : AppTheme.statusGood)
                  : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            _SensorCard(
              title: 'Humidity',
              value: hasLive && device.humidity != null
                  ? '${device.humidity!.toStringAsFixed(0)}%'
                  : '--',
              status: hasLive && device.humidity != null
                  ? (device.humidity! < 55 || device.humidity! > 85 ? 'Warning' : 'Optimal')
                  : 'No data',
              statusColor: hasLive && device.humidity != null
                  ? (device.humidity! < 55 || device.humidity! > 85
                      ? AppTheme.statusWarning
                      : AppTheme.statusGood)
                  : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            _SensorCard(
              title: 'Temperature',
              value: hasLive && device.temperature != null
                  ? '${device.temperature!.toStringAsFixed(1)}°C'
                  : '--',
              status: hasLive && device.temperature != null
                  ? (device.temperature! < 18 || device.temperature! > 30 ? 'Warning' : 'Optimal')
                  : 'No data',
              statusColor: hasLive && device.temperature != null
                  ? (device.temperature! < 18 || device.temperature! > 30
                      ? AppTheme.statusWarning
                      : AppTheme.statusGood)
                  : AppTheme.textSecondary,
            ),

            const SizedBox(height: 24),

            Text(
              'Recent Alerts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            const _AlertCard(
              message: 'Fertilization recommended based on NPK levels',
              severity: 'Info',
              severityColor: Colors.blue,
            ),
            const SizedBox(height: 8),
            const _AlertCard(
              message: 'Optimal conditions for leaf harvesting',
              severity: 'Info',
              severityColor: Colors.blue,
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
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
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
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
                  Text(title, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String message;
  final String severity;
  final Color severityColor;

  const _AlertCard({
    required this.message,
    required this.severity,
    required this.severityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: severityColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    severity,
                    style: TextStyle(
                      fontSize: 12,
                      color: severityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
