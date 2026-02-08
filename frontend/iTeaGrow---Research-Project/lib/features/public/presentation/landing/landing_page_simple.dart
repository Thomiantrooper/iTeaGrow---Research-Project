import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_selector.dart';

class SimpleLandingPage extends ConsumerWidget {
  const SimpleLandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Language Selector at the top
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40), // Spacer for alignment
                    const LanguageSelector(isVertical: false, buttonSize: 36),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 64,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  l10n?.landing_welcome ?? 'Welcome to iTeaGrow',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  l10n?.landing_description ?? 'AI-IoT System for Tea Leaf Monitoring, Fertilization, and Powder Grading',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/login'),
                    child: Text(l10n?.landing_get_started ?? 'Get Started'),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/about'),
                    child: Text(l10n?.landing_learn_more ?? 'Learn More'),
                  ),
                ),

                const SizedBox(height: 48),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickLinkCard(
                      icon: Icons.info_outline,
                      label: l10n?.nav_about ?? 'About Us',
                      onTap: () => context.push('/about'),
                    ),
                    _QuickLinkCard(
                      icon: Icons.contact_support_outlined,
                      label: l10n?.nav_contact ?? 'Contact Us',
                      onTap: () => context.push('/contact'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppTheme.primaryGreen),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
