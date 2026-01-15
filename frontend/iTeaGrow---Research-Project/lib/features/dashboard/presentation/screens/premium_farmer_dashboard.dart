import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/animations/tea_animations.dart';
import '../../../auth/data/providers/auth_provider_simple.dart';

/// Premium Farmer Dashboard with 3D hero and modern UI
class PremiumFarmerDashboard extends ConsumerStatefulWidget {
  const PremiumFarmerDashboard({super.key});

  @override
  ConsumerState<PremiumFarmerDashboard> createState() =>
      _PremiumFarmerDashboardState();
}

class _PremiumFarmerDashboardState extends ConsumerState<PremiumFarmerDashboard>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    final user = ref.watch(authStateSimpleProvider);
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      body: Stack(
        children: [
          // Background decoration
          const FloatingLeavesBackground(
            leafCount: 5,
            opacity: 0.08,
            child: SizedBox.expand(),
          ),

          // Main content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar
              _buildSliverAppBar(user?.fullName ?? 'User', greeting),

              // Content
              SliverPadding(
                padding: TeaSpacing.screenPaddingHorizontal,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: TeaSpacing.md),

                    // Hero Card with 3D-like visualization
                    _buildHeroCard(),

                    const SizedBox(height: TeaSpacing.lg),

                    // Metrics Row
                    _buildMetricsRow(),

                    const SizedBox(height: TeaSpacing.lg),

                    // Alerts Section
                    _buildAlertsSection(),

                    const SizedBox(height: TeaSpacing.lg),

                    // Quick Actions
                    _buildQuickActions(),

                    const SizedBox(height: TeaSpacing.lg),

                    // Recent Activity
                    _buildRecentActivity(),

                    const SizedBox(height: TeaSpacing.xxl),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSliverAppBar(String userName, String greeting) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: _isScrolled ? 2 : 0,
      backgroundColor: _isScrolled ? TeaColors.white : Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(
            TeaSpacing.md,
            0,
            TeaSpacing.md,
            TeaSpacing.md,
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: TeaTypography.bodyMedium.copyWith(
                    color: TeaColors.darkGray,
                  ),
                ),
                Text(
                  userName,
                  style: TeaTypography.headlineMedium.copyWith(
                    color: TeaColors.matureLeaf,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Notifications
        TeaIconButton(
          icon: Icons.notifications_outlined,
          onPressed: () {
            TeaSnackbar.info(context, 'Notifications coming soon!');
          },
          hasBadge: true,
          badgeText: '3',
          tooltip: 'Notifications',
        ),
        // Profile
        Padding(
          padding: const EdgeInsets.only(right: TeaSpacing.sm),
          child: GestureDetector(
            onTap: () => _showProfileMenu(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TeaColors.freshLeaf,
                shape: BoxShape.circle,
                boxShadow: TeaShadows.buttonShadow,
              ),
              child: const Icon(
                Icons.person,
                color: TeaColors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return TeaCard.elevated(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // 3D Visualization area (placeholder for actual 3D model)
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  TeaColors.leafPale,
                  TeaColors.freshLeaf.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(TeaRadius.lg),
              ),
            ),
            child: Stack(
              children: [
                // Placeholder for 3D model - will be replaced with actual Tea3DViewer
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BreathingAnimation(
                        child: Container(
                          padding: const EdgeInsets.all(TeaSpacing.lg),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: TeaColors.white.withOpacity(0.8),
                            boxShadow: TeaShadows.glowPrimary,
                          ),
                          child: const Icon(
                            Icons.eco,
                            size: 64,
                            color: TeaColors.freshLeaf,
                          ),
                        ),
                      ),
                      const SizedBox(height: TeaSpacing.sm),
                      Text(
                        '3D Tea Bush Preview',
                        style: TeaTypography.labelMedium.copyWith(
                          color: TeaColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                ),

                // Health indicator overlay
                Positioned(
                  top: TeaSpacing.md,
                  right: TeaSpacing.md,
                  child: TeaStatusBadge.healthy(label: 'Good Health'),
                ),
              ],
            ),
          ),

          // Stats section
          Padding(
            padding: TeaSpacing.cardPaddingMd,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plantation Overview',
                          style: TeaTypography.titleMedium,
                        ),
                        Text(
                          'Uva Highland Estate',
                          style: TeaTypography.bodySmall.copyWith(
                            color: TeaColors.darkGray,
                          ),
                        ),
                      ],
                    ),
                    TeaButton.outlined(
                      label: 'View Map',
                      icon: Icons.map_outlined,
                      size: TeaButtonSize.small,
                      onPressed: () {
                        TeaSnackbar.info(context, 'Plantation map coming soon!');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: TeaSpacing.md),
                TeaProgressBar(
                  value: 0.87,
                  label: 'Overall Health Score',
                  color: TeaColors.healthyGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildMetricsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeaSectionHeader(
          title: 'Today\'s Snapshot',
          icon: Icons.insights,
        ),
        const SizedBox(height: TeaSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TeaMetricCard(
                label: 'Temperature',
                value: '24',
                unit: '°C',
                icon: Icons.thermostat_outlined,
                iconColor: TeaColors.warningAmber,
                trend: '+2°',
                isPositiveTrend: null,
              ),
            ),
            const SizedBox(width: TeaSpacing.smd),
            Expanded(
              child: TeaMetricCard(
                label: 'Humidity',
                value: '78',
                unit: '%',
                icon: Icons.water_drop_outlined,
                iconColor: TeaColors.infoSky,
                trend: '+5%',
                isPositiveTrend: true,
              ),
            ),
            const SizedBox(width: TeaSpacing.smd),
            Expanded(
              child: TeaMetricCard(
                label: 'Air Quality',
                value: 'Good',
                icon: Icons.air_outlined,
                iconColor: TeaColors.healthyGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeaSectionHeader(
          title: 'Alerts',
          icon: Icons.warning_amber_outlined,
          actionLabel: 'See all',
          onAction: () {
            TeaSnackbar.info(context, 'All alerts coming soon!');
          },
        ),
        const SizedBox(height: TeaSpacing.sm),
        TeaAlertCard.warning(
          title: 'Block A3: High disease risk',
          message: 'Blister blight conditions detected. Tap to investigate.',
          onTap: () => context.push('/disease-detection'),
        ),
        const SizedBox(height: TeaSpacing.sm),
        TeaAlertCard.info(
          title: 'Harvest reminder',
          message: 'Block B2 leaves are ready for harvest (P+2 stage)',
          onTap: () {
            TeaSnackbar.info(context, 'Harvest tracking coming soon!');
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeaSectionHeader(
          title: 'Quick Actions',
          icon: Icons.flash_on_outlined,
        ),
        const SizedBox(height: TeaSpacing.sm),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: TeaSpacing.smd,
          crossAxisSpacing: TeaSpacing.smd,
          childAspectRatio: 1,
          children: [
            _buildQuickActionItem(
              icon: Icons.camera_alt_outlined,
              label: 'Scan Leaf',
              color: TeaColors.freshLeaf,
              onTap: () => context.push('/disease-detection'),
            ),
            _buildQuickActionItem(
              icon: Icons.grass_outlined,
              label: 'Growth',
              color: TeaColors.leafLight,
              onTap: () {
                TeaSnackbar.info(context, 'Growth monitoring coming soon!');
              },
            ),
            _buildQuickActionItem(
              icon: Icons.inventory_2_outlined,
              label: 'Harvest',
              color: TeaColors.goldenSunlight,
              onTap: () {
                TeaSnackbar.info(context, 'Harvest tracking coming soon!');
              },
            ),
            _buildQuickActionItem(
              icon: Icons.science_outlined,
              label: 'Soil Test',
              color: TeaColors.richSoil,
              onTap: () => context.push('/soil-fertilization'),
            ),
            _buildQuickActionItem(
              icon: Icons.grade_outlined,
              label: 'Quality',
              color: TeaColors.warmAmber,
              onTap: () => context.push('/powder-grading'),
            ),
            _buildQuickActionItem(
              icon: Icons.cloud_outlined,
              label: 'Weather',
              color: TeaColors.infoSky,
              onTap: () {
                TeaSnackbar.info(context, 'Weather forecast coming soon!');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TeaCard.elevated(
      onTap: onTap,
      padding: TeaSpacing.cardPaddingSm,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(TeaSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: TeaRadius.radiusSm,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: TeaSpacing.sm),
          Text(
            label,
            style: TeaTypography.labelMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeaSectionHeader(
          title: 'Recent Activity',
          icon: Icons.history,
          actionLabel: 'View all',
          onAction: () {
            TeaSnackbar.info(context, 'Activity history coming soon!');
          },
        ),
        const SizedBox(height: TeaSpacing.sm),
        TeaCard.elevated(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildActivityItem(
                icon: Icons.camera_alt_outlined,
                title: 'Leaf scan completed',
                subtitle: 'Block A2 - Healthy detected',
                time: '2 hours ago',
                color: TeaColors.healthyGreen,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                icon: Icons.inventory_2_outlined,
                title: 'Harvest recorded',
                subtitle: '245 kg from Block B1',
                time: '5 hours ago',
                color: TeaColors.goldenSunlight,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                icon: Icons.science_outlined,
                title: 'Soil analysis',
                subtitle: 'NPK levels optimal',
                time: 'Yesterday',
                color: TeaColors.richSoil,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: TeaSpacing.cardPaddingMd,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TeaSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: TeaRadius.radiusSm,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: TeaSpacing.smd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TeaTypography.titleSmall),
                Text(
                  subtitle,
                  style: TeaTypography.bodySmall.copyWith(
                    color: TeaColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TeaTypography.labelSmall.copyWith(
              color: TeaColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: TeaColors.white,
        boxShadow: [
          BoxShadow(
            color: TeaColors.shadowVale,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TeaSpacing.md,
            vertical: TeaSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.eco_outlined,
                activeIcon: Icons.eco,
                label: 'Plants',
                isActive: false,
                onTap: () {
                  TeaSnackbar.info(context, 'Plants section coming soon!');
                },
              ),
              _buildNavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: 'Reports',
                isActive: false,
                onTap: () {
                  TeaSnackbar.info(context, 'Reports coming soon!');
                },
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isActive: false,
                onTap: () => _showProfileMenu(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: TeaSpacing.md,
          vertical: TeaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive ? TeaColors.leafPale : Colors.transparent,
          borderRadius: TeaRadius.radiusRound,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? TeaColors.freshLeaf : TeaColors.darkGray,
              size: 24,
            ),
            const SizedBox(height: TeaSpacing.xxs),
            Text(
              label,
              style: TeaTypography.labelSmall.copyWith(
                color: isActive ? TeaColors.freshLeaf : TeaColors.darkGray,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: TeaColors.white,
          borderRadius: TeaRadius.topXxl,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: TeaSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TeaColors.mediumGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: TeaSpacing.lg),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  TeaSnackbar.info(context, 'Settings coming soon!');
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () {
                  Navigator.pop(context);
                  TeaSnackbar.info(context, 'Help coming soon!');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: TeaColors.alertRust,
                ),
                title: Text(
                  'Log Out',
                  style: TextStyle(color: TeaColors.alertRust),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authStateSimpleProvider.notifier).logout();
                  context.go('/login');
                },
              ),
              const SizedBox(height: TeaSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
