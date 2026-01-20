import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../features/auth/data/providers/auth_provider.dart';
import '../../../../core/enums/app_enums.dart';

/// Premium Splash Screen with animated tea leaf
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _leafController;
  late AnimationController _progressController;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _leafController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    // Start navigation check after minimum animation time
    Future.delayed(const Duration(milliseconds: 2500), _checkAuthAndNavigate);
  }

  void _checkAuthAndNavigate() {
    if (!mounted || _navigated) return;

    final authState = ref.read(authStateProvider);

    // Wait for auth to finish loading
    if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) {
      // Check again after a short delay
      Future.delayed(const Duration(milliseconds: 500), _checkAuthAndNavigate);
      return;
    }

    _navigated = true;

    if (authState.isAuthenticated && authState.user != null) {
      // Navigate to appropriate dashboard based on role
      switch (authState.user!.role) {
        case UserRole.admin:
          context.go('/dashboard/admin');
          break;
        case UserRole.manager:
          context.go('/dashboard/manager');
          break;
        case UserRole.farmer:
          context.go('/dashboard/farmer');
          break;
      }
    } else {
      // Navigate to login
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _leafController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              TeaColors.mistGreen,
              TeaColors.white,
              TeaColors.leafPale,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Animated Tea Leaf Icon
                _buildAnimatedLeaf(),

                const SizedBox(height: TeaSpacing.xl),

                // Logo Text
                _buildLogoText(),

                const SizedBox(height: TeaSpacing.sm),

                // Tagline
                _buildTagline(),

                const Spacer(flex: 2),

                // Progress Indicator
                _buildProgressIndicator(),

                const SizedBox(height: TeaSpacing.lg),

                // Version
                _buildVersion(),

                const SizedBox(height: TeaSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLeaf() {
    return AnimatedBuilder(
      animation: _leafController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _leafController.value * 2 * 3.14159,
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              TeaColors.freshLeaf.withOpacity(0.2),
              TeaColors.freshLeaf.withOpacity(0.05),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: TeaColors.freshLeaf.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: const Icon(
          Icons.eco,
          size: 64,
          color: TeaColors.freshLeaf,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildLogoText() {
    return Column(
      children: [
        Text(
          'iTeaGrow',
          style: TeaTypography.displayLarge.copyWith(
            color: TeaColors.matureLeaf,
            fontWeight: FontWeight.w700,
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildTagline() {
    return Text(
      'Nurture Every Leaf',
      style: TeaTypography.titleMedium.copyWith(
        color: TeaColors.darkGray,
        letterSpacing: 2,
        fontWeight: FontWeight.w400,
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 600.ms)
        .slideY(begin: 0.3, end: 0, delay: 600.ms, duration: 600.ms);
  }

  Widget _buildProgressIndicator() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progressController.value,
                  backgroundColor: TeaColors.lightGray,
                  valueColor: AlwaysStoppedAnimation(
                    TeaColors.freshLeaf,
                  ),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: TeaSpacing.sm),
            Text(
              'Loading...',
              style: TeaTypography.labelMedium.copyWith(
                color: TeaColors.darkGray,
              ),
            ),
          ],
        );
      },
    ).animate().fadeIn(delay: 900.ms, duration: 400.ms);
  }

  Widget _buildVersion() {
    return Text(
      'Version 1.0.0',
      style: TeaTypography.labelSmall.copyWith(
        color: TeaColors.mediumGray,
      ),
    ).animate().fadeIn(delay: 1200.ms, duration: 400.ms);
  }
}
