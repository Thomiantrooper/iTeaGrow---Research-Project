import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/data/providers/auth_provider.dart';
import 'package:iteagrow/features/leaf_maturity/presentation/screens/leaf_maturity_screen.dart';
import 'package:iteagrow/features/disease_detection/presentation/screens/disease_detection_screen.dart';
import 'package:iteagrow/features/soil_fertilization/presentation/screens/soil_fertilization_screen.dart';
import 'package:iteagrow/features/yield_prediction/presentation/screens/yield_prediction_screen.dart';
import 'package:iteagrow/features/dashboard/presentation/screens/analytics_screen.dart';
import 'package:iteagrow/features/powder_grading/presentation/screens/powder_grading_screen.dart';

class ManagerDashboard extends ConsumerWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Estate Manager'),
              accountEmail: const Text('manager@iteagrow.com'),
              currentAccountPicture:
                  const CircleAvatar(child: Icon(Icons.admin_panel_settings)),
              decoration: BoxDecoration(color: Colors.purple.shade700),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context); // close drawer first
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 70% Primary Content: Advanced Features
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Strategic Planning',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade800,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Hero Row (Fixed Height)
                  SizedBox(
                    height: 180,
                    child: Row(
                      children: [
                        // Yield Prediction (Hero Card)
                        Expanded(
                          child: Card(
                            color: Colors.purple,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),),
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const YieldPredictionScreen(),),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.query_stats,
                                      color: Colors.white, size: 48,),
                                  SizedBox(height: 12),
                                  Text('Predict Yield',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,),),
                                  Text('Analysis & Reports',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12,),),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Powder Grading (Hero Card)
                        Expanded(
                          child: Card(
                            color: Colors.orange,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),),
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const PowderGradingScreen(),),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.grade,
                                      color: Colors.white, size: 48,),
                                  SizedBox(height: 12),
                                  Text('In-Depth Grading',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,),),
                                  Text('Quality Analysis',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12,),),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Tools',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade800,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary Tools Grid (Auto-calculated height)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _buildToolButton(
                          context,
                          'Full Analytics',
                          Icons.bar_chart,
                          Colors.teal,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AnalyticsScreen(),),),),
                      _buildToolButton(
                          context,
                          'Disease Reports',
                          Icons.bug_report,
                          Colors.red,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const DiseaseDetectionScreen(),),),),
                      _buildToolButton(
                          context,
                          'Soil Health',
                          Icons.terrain,
                          Colors.brown,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SoilFertilizationScreen(),),),),
                      _buildToolButton(
                          context,
                          'Leaf Maturity',
                          Icons.eco,
                          Colors.green,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const LeafMaturityScreen(),),),),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap,) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 20),
      label: Text(title,
          style: const TextStyle(fontSize: 12, color: Colors.black87),),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
