import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/widgets/jarvis_assistant.dart';
import '../../../../core/animations/tea_animations.dart';
import '../../../../core/providers/global_iot_provider.dart';
import '../../../auth/data/providers/auth_provider.dart';

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
  bool _isChatbotActive = false;

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
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
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

                    // Quick Actions (Unified Premium Grid)
                    _buildQuickActions(),

                    const SizedBox(height: TeaSpacing.lg),

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
      bottomNavigationBar: TeaBottomNavBar(
        currentIndex: 0,
        items: const [
          TeaNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
          TeaNavItem(icon: Icons.eco_outlined, activeIcon: Icons.eco, label: 'Plants'),
          TeaNavItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Map'),
          TeaNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 1:
              context.push('/plants');
            case 2:
              context.push('/map');
            case 3:
              context.push('/profile');
          }
        },
      ),
      floatingActionButton: JarvisFloatingButton(
        isActive: _isChatbotActive,
        onPressed: () {
          setState(() => _isChatbotActive = !_isChatbotActive);
          context.push('/chatbot');
        },
        onLongPress: () {
          TeaSnackbar.info(context, 'Hold to activate voice assistant');
        },
      ),
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
            context.push('/notifications');
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
          // Enhanced 3D Hero Visualization area
          Container(
            height: 220,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(TeaRadius.lg),
              ),
            ),
            child: Stack(
              children: [
                // Animated gradient background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          TeaColors.matureLeaf.withOpacity(0.15),
                          TeaColors.freshLeaf.withOpacity(0.25),
                          TeaColors.leafLight.withOpacity(0.2),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(TeaRadius.lg),
                      ),
                    ),
                  ),
                ),

                // Decorative circles (depth effect)
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TeaColors.freshLeaf.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TeaColors.goldenSunlight.withOpacity(0.08),
                    ),
                  ),
                ),

                // Main 3D-like hero content
                Padding(
                  padding: const EdgeInsets.all(TeaSpacing.md),
                  child: Row(
                    children: [
                      // Left side - 3D Plant visual
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BreathingAnimation(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer glow ring
                                  Container(
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          TeaColors.freshLeaf.withOpacity(0.2),
                                          TeaColors.freshLeaf.withOpacity(0.05),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Inner container with plant
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: TeaColors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: TeaColors.freshLeaf
                                              .withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: ShaderMask(
                                        shaderCallback: (bounds) =>
                                            const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            TeaColors.freshLeaf,
                                            TeaColors.matureLeaf,
                                          ],
                                        ).createShader(bounds),
                                        child: const Icon(
                                          Icons.eco,
                                          size: 56,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: TeaSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: TeaColors.healthyGreen,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '3D Model Ready',
                                  style: TeaTypography.labelSmall.copyWith(
                                    color: TeaColors.freshLeaf,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Right side - Quick stats
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(TeaSpacing.smd),
                          decoration: BoxDecoration(
                            color: TeaColors.white.withOpacity(0.7),
                            borderRadius: TeaRadius.radiusMd,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.landscape,
                                      size: 16, color: TeaColors.freshLeaf),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Estate Summary',
                                    style: TeaTypography.titleSmall.copyWith(
                                      color: TeaColors.matureLeaf,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: TeaSpacing.md),
                              _buildMiniStat(
                                  'Active Blocks', '12', TeaColors.freshLeaf),
                              _buildMiniStat('Healthy Plants', '87%',
                                  TeaColors.healthyGreen),
                              _buildMiniStat('Harvest Ready', '3 Blocks',
                                  TeaColors.goldenSunlight),
                              _buildMiniStat(
                                  'Alerts', '2', TeaColors.warningAmber),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Health indicator overlay
                Positioned(
                  top: TeaSpacing.sm,
                  right: TeaSpacing.sm,
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
                      onPressed: () => context.push('/map'),
                    ),
                  ],
                ),
                const SizedBox(height: TeaSpacing.md),
                const TeaProgressBar(
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

  Widget _buildMiniStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TeaTypography.labelSmall.copyWith(
              color: TeaColors.darkGray,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TeaTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final iotState = ref.watch(globalIoTProvider);
    final hasLiveData = iotState.hasData;

    // Get temperature value
    final temperature =
        hasLiveData ? iotState.temperature.toStringAsFixed(1) : '24';

    // Get humidity value
    final humidity = hasLiveData ? iotState.humidity.toStringAsFixed(0) : '78';

    // Get air quality label
    final airQuality =
        hasLiveData ? _getAirQualityLabel(iotState.airQuality) : 'Good';

    final airQualityColor = hasLiveData
        ? _getAirQualityColor(iotState.airQuality)
        : TeaColors.healthyGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom header row with live indicator
        Padding(
          padding: const EdgeInsets.symmetric(vertical: TeaSpacing.sm),
          child: Row(
            children: [
              const Icon(
                Icons.insights,
                size: 20,
                color: TeaColors.freshLeaf,
              ),
              const SizedBox(width: TeaSpacing.sm),
              Text(
                'Today\'s Snapshot',
                style: TeaTypography.titleMedium,
              ),
              const Spacer(),
              if (hasLiveData)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TeaSpacing.sm,
                    vertical: TeaSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: TeaColors.healthyGreen.withOpacity(0.1),
                    borderRadius: TeaRadius.radiusSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: TeaColors.healthyGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Live',
                        style: TeaTypography.labelSmall.copyWith(
                          color: TeaColors.healthyGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: TeaSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TeaMetricCard(
                label: 'Temperature',
                value: temperature,
                unit: '°C',
                icon: Icons.thermostat_outlined,
                iconColor: TeaColors.warningAmber,
                trend: hasLiveData ? null : '+2°',
                isPositiveTrend: null,
              ),
            ),
            const SizedBox(width: TeaSpacing.smd),
            Expanded(
              child: TeaMetricCard(
                label: 'Humidity',
                value: humidity,
                unit: '%',
                icon: Icons.water_drop_outlined,
                iconColor: TeaColors.infoSky,
                trend: hasLiveData ? null : '+5%',
                isPositiveTrend: hasLiveData ? null : true,
              ),
            ),
            const SizedBox(width: TeaSpacing.smd),
            Expanded(
              child: TeaMetricCard(
                label: 'Air Quality',
                value: airQuality,
                icon: Icons.air_outlined,
                iconColor: airQualityColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getAirQualityLabel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy';
    if (aqi <= 200) return 'Bad';
    return 'Hazardous';
  }

  Color _getAirQualityColor(int aqi) {
    if (aqi <= 50) return TeaColors.healthyGreen;
    if (aqi <= 100) return TeaColors.goldenSunlight;
    if (aqi <= 150) return TeaColors.warningAmber;
    if (aqi <= 200) return TeaColors.alertRust;
    return const Color(0xFF8E4585); // Purple for hazardous
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
            context.push('/notifications');
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
          onTap: () => context.push('/plants'),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TeaSectionHeader(
          title: 'Quick Actions',
          icon: Icons.flash_on_outlined,
        ),
        const SizedBox(height: TeaSpacing.smd),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: TeaSpacing.smd,
          crossAxisSpacing: TeaSpacing.smd,
          childAspectRatio: 1.2,
          children: [
            TeaImageCard(
              title: 'Leaf Maturity',
              subtitle: 'Check quality',
              tag: 'MATURITY',
              fallbackIcon: Icons.center_focus_strong,
              gradientColors: [
                TeaColors.freshLeaf,
                TeaColors.matureLeaf.withOpacity(0.8),
              ],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/leaf-maturity'),
            ),
            TeaImageCard(
              title: 'Disease Scan',
              subtitle: 'Plant health',
              tag: 'DIAGNOSIS',
              fallbackIcon: Icons.bug_report_outlined,
              gradientColors: [Colors.red.shade700, Colors.red.shade400],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/disease-detection'),
            ),
            TeaImageCard(
              title: 'Growth',
              subtitle: 'Block progress',
              tag: 'ANALYSIS',
              fallbackIcon: Icons.grass_outlined,
              gradientColors: [TeaColors.leafLight, TeaColors.freshLeaf],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/plants'),
            ),
            TeaImageCard(
              title: 'IoT Sensors',
              subtitle: 'Real-time data',
              tag: 'LIVE',
              fallbackIcon: Icons.sensors,
              gradientColors: [TeaColors.infoSky, Colors.blue.shade400],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/iot-devices'),
            ),
            TeaImageCard(
              title: 'Soil Test',
              subtitle: 'Nutrient check',
              tag: 'SOIL',
              fallbackIcon: Icons.science_outlined,
              gradientColors: [TeaColors.richSoil, Colors.brown.shade400],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/soil-fertilization'),
            ),
            TeaImageCard(
              title: 'Quality',
              subtitle: 'Powder grade',
              tag: 'GRADING',
              fallbackIcon: Icons.grade_outlined,
              gradientColors: [TeaColors.warmAmber, TeaColors.goldenSunlight],
              borderRadius: TeaRadius.radiusLg,
              onTap: () => context.push('/powder-grading'),
            ),
          ],
        ),
      ],
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
            context.push('/activity-history');
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
                leading: const Icon(Icons.person_outline),
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.sensors),
                title: const Text('IoT Devices'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/iot-devices');
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Scan History'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/scan-history');
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Reports'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/reports');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/help-center');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: TeaColors.alertRust,
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: TeaColors.alertRust),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
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
