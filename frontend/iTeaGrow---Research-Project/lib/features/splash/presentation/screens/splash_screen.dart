import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../features/auth/data/providers/auth_provider.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/services/local_auth_service.dart' show sharedPreferencesProvider;
import 'package:iteagrow/l10n/app_localizations.dart';

/// Premium Get Started / Onboarding Screen
/// First-time users see the full onboarding with "Get Started" button.
/// Returning authenticated users auto-skip to their dashboard.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;
  bool _showOnboarding = false;
  bool _isChecking = true;

  static const _onboardingKey = 'has_seen_onboarding';

  @override
  void initState() {
    super.initState();
    // Small delay so the image loads before we decide what to show
    Future.delayed(const Duration(milliseconds: 800), _checkStateAndRoute);
  }

  Future<void> _checkStateAndRoute() async {
    if (!mounted || _navigated) return;

    final authState = ref.read(authStateProvider);

    // Wait for auth to finish loading
    if (authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading) {
      Future.delayed(const Duration(milliseconds: 500), _checkStateAndRoute);
      return;
    }

    // If authenticated, go straight to dashboard
    if (authState.isAuthenticated && authState.user != null) {
      _navigated = true;
      _navigateToDashboard(authState.user!.role);
      return;
    }

    // Not authenticated — check if user has seen onboarding before
    final prefs = ref.read(sharedPreferencesProvider);
    final hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;

    if (hasSeenOnboarding) {
      // Returning user who's logged out — go to login
      _navigated = true;
      if (mounted) context.go('/login');
    } else {
      // First-time user — show the onboarding screen
      if (mounted) {
        setState(() {
          _showOnboarding = true;
          _isChecking = false;
        });
      }
    }
  }

  void _navigateToDashboard(UserRole role) {
    switch (role) {
      case UserRole.admin:
        context.go('/dashboard/admin');
      case UserRole.manager:
        context.go('/dashboard/manager');
      case UserRole.farmer:
        context.go('/dashboard/farmer');
    }
  }

  Future<void> _onGetStarted() async {
    // Mark onboarding as seen
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_onboardingKey, true);

    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen background image
          Image.asset(
            'assets/images/tea-field.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Dark gradient overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.50),
                  Colors.black.withOpacity(0.10),
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.65),
                ],
                stops: const [0.0, 0.3, 0.5, 1.0],
              ),
            ),
          ),

          // Content
          if (_isChecking && !_showOnboarding)
            // Brief loading state while checking auth
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else if (_showOnboarding)
            _buildOnboardingContent(context),
        ],
      ),
    );
  }

  Widget _buildOnboardingContent(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TeaSpacing.lg),
        child: Column(
          children: [
            const Spacer(flex: 3),

            // Animated leaf icon with glow
            _buildLeafIcon()
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: TeaSpacing.lg),

            // App name
            Text(
              'iTeaGrow',
              style: TeaTypography.displayLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 600.ms),

            const SizedBox(height: TeaSpacing.smd),

            // Subtitle
            Text(
              AppLocalizations.of(context)!.splash_subtitle,
              textAlign: TextAlign.center,
              style: TeaTypography.titleMedium.copyWith(
                color: Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
                height: 1.4,
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 600.ms),

            const Spacer(flex: 4),

            // Get Started button
            _buildGetStartedButton()
                .animate()
                .fadeIn(delay: 700.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0, delay: 700.ms, duration: 500.ms)
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1, 1),
                  delay: 700.ms,
                  duration: 500.ms,
                ),

            const SizedBox(height: TeaSpacing.md),

            // Version text
            Text(
              AppLocalizations.of(context)!.splash_version,
              style: TeaTypography.labelSmall.copyWith(
                color: Colors.white.withOpacity(0.38),
              ),
            ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),

            SizedBox(height: bottomPadding > 0 ? TeaSpacing.md : TeaSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildLeafIcon() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.10),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: TeaColors.freshLeaf.withOpacity(0.25),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        Icons.eco,
        size: 42,
        color: Colors.white,
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [TeaColors.freshLeaf, TeaColors.matureLeaf],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: TeaColors.freshLeaf.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onGetStarted,
            borderRadius: BorderRadius.circular(28),
            splashColor: Colors.white.withOpacity(0.2),
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.landing_get_started,
                style: TeaTypography.buttonLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
