import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class AboutUsPageSimple extends StatelessWidget {
  const AboutUsPageSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About iTeaGrow'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco, size: 56, color: Colors.white),
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'iTeaGrow',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
            ),

            const SizedBox(height: 8),

            const Text(
              'AI-IoT Tea Monitoring System',
              style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 24),

            const Text(
              'iTeaGrow is a research project focused on developing an AI-IoT decision support system for tea cultivation in Sri Lanka. The system combines machine learning, IoT sensors, and mobile technology to help farmers optimize tea leaf quality, fertilization, and market value.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 32),

            Text(
              'Key Features',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            const _FeatureItem(icon: Icons.eco, title: 'AI-powered leaf maturity detection'),
            const _FeatureItem(icon: Icons.sensors, title: 'Real-time IoT sensor monitoring'),
            const _FeatureItem(icon: Icons.health_and_safety, title: 'Disease detection and prevention'),
            const _FeatureItem(icon: Icons.science, title: 'Smart fertilization recommendations'),
            const _FeatureItem(icon: Icons.grade, title: 'Tea powder quality grading'),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FeatureItem({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
