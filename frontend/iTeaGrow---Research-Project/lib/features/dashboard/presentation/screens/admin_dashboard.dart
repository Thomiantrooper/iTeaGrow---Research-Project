import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iteagrow/core/theme/app_theme.dart';
import 'package:iteagrow/core/widgets/dashboard_card.dart';
import 'package:iteagrow/features/auth/presentation/providers/auth_provider.dart';
import 'package:iteagrow/features/public/presentation/landing/landing_page.dart';
import 'package:iteagrow/features/leaf_maturity/presentation/screens/leaf_maturity_screen.dart';
import 'package:iteagrow/features/disease_detection/presentation/screens/disease_detection_screen.dart';
import 'package:iteagrow/features/soil_fertilization/presentation/screens/soil_fertilization_screen.dart';
import 'package:iteagrow/features/yield_prediction/presentation/screens/what_if_simulation_screen.dart';
import 'package:iteagrow/features/dashboard/presentation/screens/analytics_screen.dart';
import 'package:iteagrow/features/powder_grading/presentation/screens/powder_grading_screen.dart';
import 'package:iteagrow/features/admin/presentation/screens/admin_placeholder_screens.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Administrator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(currentUserProvider.notifier).state = null;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LandingPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Text(
              'System Administrator',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Full system access and control',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            // Core Features
            Text(
              'Core Features',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                DashboardCard(
                  icon: Icons.eco,
                  title: 'Leaf Maturity',
                  subtitle: 'Species & Maturity',
                  color: AppTheme.primaryGreen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LeafMaturityScreen()),
                  ),
                ),
                DashboardCard(
                  icon: Icons.health_and_safety,
                  title: 'Disease Detection',
                  subtitle: 'With Live IoT',
                  color: AppTheme.statusWarning,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DiseaseDetectionScreen()),
                  ),
                ),
                DashboardCard(
                  icon: Icons.grass,
                  title: 'Soil & Fertilization',
                  subtitle: 'Live + TRI Planning',
                  color: Colors.brown,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SoilFertilizationScreen()),
                  ),
                ),
                DashboardCard(
                  icon: Icons.trending_up,
                  title: 'Yield Prediction',
                  subtitle: 'Independent Module',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WhatIfSimulationScreen()),
                  ),
                ),
                DashboardCard(
                  icon: Icons.grade,
                  title: 'Powder Grading',
                  subtitle: 'Market Analysis',
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PowderGradingScreen()),
                  ),
                ),
                DashboardCard(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  subtitle: 'Trends & Insights',
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // System Administration
            Text(
              'System Administration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                DashboardCard(
                  icon: Icons.people,
                  title: 'User Management',
                  subtitle: 'Roles & Access',
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                  ),
                ),
                DashboardCard(
                  icon: Icons.devices,
                  title: 'Device Management',
                  subtitle: 'IoT Configuration',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeviceManagementScreen()),
                  ),
                ),
                DashboardCard(
                  icon: Icons.settings,
                  title: 'System Config',
                  subtitle: 'Thresholds & Rules',
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SystemConfigScreen()),
                  ),
                ),
                DashboardCard(
                  icon: Icons.description,
                  title: 'Audit Logs',
                  subtitle: 'System Activity',
                  color: Colors.grey,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SystemLogsScreen()),
                  ),
                ),
                DashboardCard(
                  icon: Icons.sync,
                  title: 'Data Sync',
                  subtitle: 'Cloud Backup',
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DataSyncScreen()),
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
