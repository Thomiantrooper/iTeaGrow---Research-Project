import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../providers/analytics_provider.dart';
import '../../../settings/presentation/screens/premium_settings_screen.dart';
import '../../../tour/presentation/providers/tour_provider.dart';
import '../../../tour/presentation/widgets/tour_overlay.dart';

class ManagerDashboard extends ConsumerStatefulWidget {
  const ManagerDashboard({super.key});

  @override
  ConsumerState<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends ConsumerState<ManagerDashboard> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // GlobalKeys for tour highlighting
  final _welcomeCardKey = GlobalKey();
  final _fieldToolsKey = GlobalKey();
  final _analyticsToolsKey = GlobalKey();
  final _marketToolsKey = GlobalKey();
  final _bottomNavKey = GlobalKey();
  bool _tourChecked = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      ref.read(analyticsProvider.notifier).loadOverview();
      ref.read(analyticsProvider.notifier).loadUserStats();
    });
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TeaTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TeaTypography.labelSmall.copyWith(
                      color: TeaColors.darkGray,
                    ),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: TeaColors.mediumGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      body: Stack(
        children: [
          const FloatingLeavesBackground(
            leafCount: 4,
            opacity: 0.05,
            child: SizedBox.expand(),
          ),

          // Tour auto-start check
          Builder(builder: (context) {
            if (!_tourChecked) {
              _tourChecked = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final tourNotifier =
                    ref.read(managerTourProvider.notifier);
                if (tourNotifier.shouldAutoStart) {
                  tourNotifier.startManagerTour(
                    welcomeCardKey: _welcomeCardKey,
                    fieldToolsKey: _fieldToolsKey,
                    analyticsToolsKey: _analyticsToolsKey,
                    marketToolsKey: _marketToolsKey,
                    bottomNavKey: _bottomNavKey,
                  );
                }
              });
            }
            return const SizedBox.shrink();
          }),

          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(user?.fullName ?? l10n.dashboard_manager_role),
              SliverPadding(
                padding: TeaSpacing.screenPaddingHorizontal,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    KeyedSubtree(
                      key: _welcomeCardKey,
                      child: _buildWelcomeCard(),
                    ),
                    const SizedBox(height: TeaSpacing.lg),
                    _buildManagementTools(),
                    const SizedBox(height: TeaSpacing.xxl),
                  ]),
                ),
              ),
            ],
          ),

          // Tour overlay
          Consumer(builder: (context, ref, _) {
            final tourState = ref.watch(managerTourProvider);
            if (!tourState.isActive) return const SizedBox.shrink();
            return TourOverlay(tourProviderOverride: managerTourProvider);
          }),
        ],
      ),
      bottomNavigationBar: KeyedSubtree(
        key: _bottomNavKey,
        child: TeaBottomNavBar(
        currentIndex: 0,
        items: [
          TeaNavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: l10n.dashboard_home),
          TeaNavItem(
              icon: Icons.map_outlined, activeIcon: Icons.map, label: l10n.dashboard_map),
          TeaNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: l10n.dashboard_profile),
        ],
        onTap: (index) {
          switch (index) {
            case 1:
              context.push('/map');
            case 2:
              context.push('/profile');
          }
        },
      ),
      ),
    );
  }

  Widget _buildSliverAppBar(String userName) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: _isScrolled ? 2 : 0,
      backgroundColor: _isScrolled ? TeaColors.white : Colors.transparent,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: _isScrolled ? TeaColors.matureLeaf : TeaColors.matureLeaf,
          ),
          onPressed: () => _showDrawer(context, userName),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(
              TeaSpacing.md, 0, TeaSpacing.md, TeaSpacing.md),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.dashboard_manager_estate_label,
                  style: TeaTypography.bodyMedium
                      .copyWith(color: TeaColors.darkGray),
                ),
                Text(
                  userName,
                  style: TeaTypography.headlineMedium
                      .copyWith(color: TeaColors.matureLeaf),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TeaIconButton(
          icon: Icons.refresh,
          onPressed: () {
            ref.read(analyticsProvider.notifier).loadOverview();
            ref.read(analyticsProvider.notifier).loadUserStats();
          },
          tooltip: 'Refresh',
        ),
        const SizedBox(width: TeaSpacing.sm),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background image with zoom effect
            Positioned.fill(
              child: Transform.scale(
                scale: 1.25,
                child: Image.asset(
                  'assets/images/tea-field.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Dark overlay for text readability
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.dashboard_manager_welcome,
                    style: TeaTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.dashboard_manager_subtitle,
                    style: TeaTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.insights_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.dashboard_system_online,
                          style: TeaTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildManagementTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyedSubtree(
          key: _fieldToolsKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TeaSectionHeader(
                title: AppLocalizations.of(context)!.dashboard_section_field,
                icon: Icons.energy_savings_leaf_outlined,
              ),
              const SizedBox(height: TeaSpacing.smd),
              // Two-column rows (matches premium dashboard spacing)
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: AppLocalizations.of(context)!.dashboard_leaf_maturity,
                      subtitle: AppLocalizations.of(context)!.dashboard_leaf_maturity_sub,
                      icon: Icons.center_focus_strong,
                      gradient: [TeaColors.freshLeaf, TeaColors.matureLeaf.withOpacity(0.8)],
                      onTap: () => context.push('/leaf-maturity'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      title: AppLocalizations.of(context)!.dashboard_soil_test,
                      subtitle: AppLocalizations.of(context)!.dashboard_soil_test_sub,
                      icon: Icons.science_outlined,
                      gradient: [TeaColors.richSoil, const Color(0xFF8D6E63)],
                      onTap: () => context.push('/soil-fertilization'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: AppLocalizations.of(context)!.dashboard_iot_sensors,
                      subtitle: AppLocalizations.of(context)!.dashboard_iot_sensors_sub,
                      icon: Icons.sensors,
                      gradient: [TeaColors.infoSky, const Color(0xFF42A5F5)],
                      onTap: () => context.push('/iot-devices'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: TeaSpacing.lg),
        KeyedSubtree(
          key: _analyticsToolsKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TeaSectionHeader(
                title: AppLocalizations.of(context)!.dashboard_section_analytics,
                icon: Icons.health_and_safety_outlined,
              ),
              const SizedBox(height: TeaSpacing.smd),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: AppLocalizations.of(context)!.dashboard_disease_scan,
                      subtitle: AppLocalizations.of(context)!.dashboard_disease_plant_sub,
                      icon: Icons.bug_report_outlined,
                      gradient: [TeaColors.alertRust, const Color(0xFFEF5350)],
                      onTap: () => context.push('/disease-detection'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      title: AppLocalizations.of(context)!.dashboard_quality,
                      subtitle: AppLocalizations.of(context)!.dashboard_quality_sub,
                      icon: Icons.grade_outlined,
                      gradient: [TeaColors.warmAmber, TeaColors.goldenSunlight],
                      onTap: () => context.push('/powder-grading'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: AppLocalizations.of(context)!.dashboard_yield_predict,
                      subtitle: AppLocalizations.of(context)!.dashboard_yield_predict_sub,
                      icon: Icons.grass_outlined,
                      gradient: [TeaColors.leafLight, TeaColors.freshLeaf],
                      onTap: () => context.push('/yield-prediction'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: TeaSpacing.lg),
        KeyedSubtree(
          key: _marketToolsKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TeaSectionHeader(
                title: AppLocalizations.of(context)!.dashboard_section_market,
                icon: Icons.admin_panel_settings_outlined,
              ),
              const SizedBox(height: TeaSpacing.smd),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: AppLocalizations.of(context)!.dashboard_market_prices,
                      subtitle: AppLocalizations.of(context)!.dashboard_market_prices_sub,
                      icon: Icons.currency_exchange,
                      gradient: [TeaColors.matureLeaf, TeaColors.freshLeaf],
                      onTap: () => context.push('/market-analysis'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      title: AppLocalizations.of(context)!.dashboard_market_admin,
                      subtitle: AppLocalizations.of(context)!.dashboard_market_admin_sub,
                      icon: Icons.admin_panel_settings,
                      gradient: [TeaColors.warningAmber, TeaColors.goldenSunlight],
                      onTap: () => context.push('/market-admin'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  void _showDrawer(BuildContext context, String userName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: TeaColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: TeaColors.darkGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // User header
            Container(
              padding: const EdgeInsets.all(TeaSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: TeaColors.freshLeaf.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(userName),
                        style: TeaTypography.titleLarge.copyWith(
                          color: TeaColors.matureLeaf,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: TeaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TeaTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.dashboard_manager_role,
                          style: TeaTypography.bodySmall.copyWith(
                            color: TeaColors.darkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Menu items
            ListTile(
              leading: const Icon(Icons.dashboard_outlined,
                  color: TeaColors.matureLeaf),
              title: Text(AppLocalizations.of(context)!.dashboard_drawer_dashboard),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined,
                  color: TeaColors.matureLeaf),
              title: Text(AppLocalizations.of(context)!.nav_settings),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PremiumSettingsScreen(
                            allowBiometricAndPin: false,
                          )),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: TeaColors.matureLeaf),
              title: Text(AppLocalizations.of(context)!.dashboard_drawer_help),
              onTap: () {
                Navigator.pop(context);
                context.push('/help-center');
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: TeaColors.matureLeaf),
              title: Text(AppLocalizations.of(context)!.tour_retake),
              onTap: () {
                Navigator.pop(context);
                ref.read(managerTourProvider.notifier).resetTour();
                setState(() => _tourChecked = false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: TeaColors.alertRust),
              title: Text(
                AppLocalizations.of(context)!.dashboard_drawer_logout,
                style: const TextStyle(color: TeaColors.alertRust),
              ),
              onTap: () {
                ref.read(authStateProvider.notifier).logout();
              },
            ),
            const SizedBox(height: TeaSpacing.md),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
