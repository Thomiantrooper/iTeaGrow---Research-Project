import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iteagrow/core/theme/app_theme.dart';
import 'package:iteagrow/features/auth/presentation/providers/auth_provider.dart';
import 'package:iteagrow/features/public/presentation/landing/landing_page.dart';
import 'package:iteagrow/features/leaf_maturity/presentation/screens/leaf_maturity_screen.dart';
import 'package:iteagrow/features/disease_detection/presentation/screens/disease_detection_screen.dart';
import 'package:iteagrow/features/soil_fertilization/presentation/screens/soil_fertilization_screen.dart';
import 'package:iteagrow/features/powder_grading/presentation/screens/powder_grading_screen.dart';

class FarmerDashboard extends ConsumerWidget {
  const FarmerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // 10% Tertiary Content (AppBar + Drawer access usually, here simplified to AppBar actions)
      appBar: AppBar(
        title: const Text('iTeaGrow'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('Farmer Name'),
              accountEmail: Text('farmer@iteagrow.com'),
              currentAccountPicture: CircleAvatar(child: Icon(Icons.person)),
              decoration: BoxDecoration(color: AppTheme.primaryGreen),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
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
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 70% Primary Action Area (Scrollable)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Primary Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Primary Action 1: Leaf Maturity Analysis (Hero Card - Fixed convenient height)
                  SizedBox(
                    height: 220, // Large touch target but not screen-dependent
                    child: Card(
                      elevation: 4,
                      color: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LeafMaturityScreen()),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.eco, color: Colors.white, size: 64),
                            SizedBox(height: 12),
                            Text(
                              'Leaf Maturity',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Scan & Analyze Tea Leaves',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Secondary Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 140, // Consistent height for secondary cards
                          child: _buildActionCard(
                            context,
                            'Disease Check',
                            Icons.health_and_safety,
                            AppTheme.statusCritical,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const DiseaseDetectionScreen()),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 140,
                          child: _buildActionCard(
                            context,
                            'Fertilizer',
                            Icons.eco,
                            Colors.brown,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SoilFertilizationScreen()),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 140,
                          child: _buildActionCard(
                            context,
                            'Grading',
                            Icons.grade,
                            Colors.orange,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PowderGradingScreen(
                                          showMarketData: false)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Extra padding for bottom scrolling
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
