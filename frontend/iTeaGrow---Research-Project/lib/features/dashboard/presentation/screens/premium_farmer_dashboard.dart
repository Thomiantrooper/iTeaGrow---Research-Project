import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/widgets/jarvis_assistant.dart';
import '../../../../core/animations/tea_animations.dart';
import '../../../../core/providers/global_iot_provider.dart';
import '../../../../core/providers/iot_live_provider.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../providers/dashboard_kpi_provider.dart';
import '../providers/activity_feed_provider.dart';
import '../providers/alerts_provider.dart';
import '../../../tour/presentation/providers/tour_provider.dart';
import '../../../tour/presentation/widgets/tour_overlay.dart';
import '../../../../core/widgets/inputs/tea_search_bar.dart';
import '../../../../core/widgets/inputs/tea_category_chips.dart';
import '../../../../core/widgets/cards/tea_recommendation_row.dart';

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

  // GlobalKeys for tour highlighting
  final _heroCardKey = GlobalKey();
  final _metricsKey = GlobalKey();
  final _quickActionsKey = GlobalKey();
  final _alertsKey = GlobalKey();
  bool _tourChecked = false;
  int _selectedCategoryIndex = 0;

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
    final iotState = ref.watch(globalIoTProvider);
    final mqttState = ref.watch(iotLiveProvider);
    final kpiState = ref.watch(dashboardKpiProvider);
    final activityState = ref.watch(activityFeedProvider);
    final alertsState = ref.watch(alertsProvider);
    final user = authState.user;
    final greeting = _getGreeting();

    // Debug: Log every rebuild
    debugPrint(
        '[Dashboard] BUILD called - MQTT devices: ${mqttState.devices.length}, loading: ${mqttState.isLoading}, lastRefresh: ${mqttState.lastRefreshed}');
    if (mqttState.devices.isNotEmpty) {
      final device = mqttState.devices.values.first;
      debugPrint(
          '[Dashboard] BUILD - First device: T=${device.temperature}°C H=${device.humidity}%');
    }

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

          // Tour overlay (renders on top when active)
          // Trigger auto-start check after first frame
          Builder(builder: (context) {
            if (!_tourChecked) {
              _tourChecked = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final tourNotifier = ref.read(tourProvider.notifier);
                if (tourNotifier.shouldAutoStart) {
                  tourNotifier.startTour(
                    heroCardKey: _heroCardKey,
                    metricsKey: _metricsKey,
                    quickActionsKey: _quickActionsKey,
                    alertsKey: _alertsKey,
                  );
                }
              });
            }
            return const SizedBox.shrink();
          }),

          // Main content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar
              _buildSliverAppBar(user?.fullName ?? 'User', greeting, alertsState),

              // Content
              SliverPadding(
                padding: TeaSpacing.screenPaddingHorizontal,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: TeaSpacing.md),

                    // Search Bar
                    TeaSearchBar(
                      hintText: 'Search blocks, diseases, reports...',
                      showFilterIcon: true,
                      readOnly: true,
                      onTap: () => context.push('/chatbot'),
                      onFilterTap: () => context.push('/notifications'),
                    ),

                    const SizedBox(height: TeaSpacing.md),

                    // Category Chips
                    TeaCategoryChips(
                      categories: const [
                        TeaCategoryItem(label: 'Overview', icon: Icons.dashboard_outlined, iconColor: TeaColors.freshLeaf),
                        TeaCategoryItem(label: 'Diseases', icon: Icons.bug_report_outlined, iconColor: TeaColors.alertRust),
                        TeaCategoryItem(label: 'Harvest', icon: Icons.grass_outlined, iconColor: TeaColors.goldenSunlight),
                        TeaCategoryItem(label: 'IoT', icon: Icons.sensors, iconColor: TeaColors.infoSky),
                        TeaCategoryItem(label: 'Market', icon: Icons.trending_up, iconColor: TeaColors.warmAmber),
                      ],
                      selectedIndex: _selectedCategoryIndex,
                      onSelected: (index) {
                        setState(() => _selectedCategoryIndex = index);
                        // Navigate based on category
                        switch (index) {
                          case 1: context.push('/disease-detection');
                          case 2: context.push('/plants');
                          case 3: context.push('/iot-devices');
                          case 4: context.push('/market-analysis');
                        }
                      },
                    ),

                    const SizedBox(height: TeaSpacing.lg),

                    // Hero Card with 3D-like visualization
                    KeyedSubtree(
                      key: _heroCardKey,
                      child: _buildHeroCard(kpiState),
                    ),

                    const SizedBox(height: TeaSpacing.lg),

                    // Metrics Row
                    KeyedSubtree(
                      key: _metricsKey,
                      child: _buildMetricsRow(iotState, mqttState),
                    ),

                    const SizedBox(height: TeaSpacing.lg),

                    // Alerts Section
                    KeyedSubtree(
                      key: _alertsKey,
                      child: _buildAlertsSection(alertsState),
                    ),

                    const SizedBox(height: TeaSpacing.lg),

                    // Quick Actions (Unified Premium Grid)
                    KeyedSubtree(
                      key: _quickActionsKey,
                      child: _buildQuickActions(),
                    ),

                    const SizedBox(height: TeaSpacing.lg),

                    // Recommended Actions
                    TeaRecommendationRow(
                      sectionTitle: 'Recommended',
                      items: [
                        TeaRecommendationItem(
                          title: 'Scan Leaves',
                          subtitle: 'Disease check',
                          icon: Icons.camera_alt_outlined,
                          gradientColors: [Colors.red.shade600, Colors.red.shade400],
                          badge: 'AI',
                          onTap: () => context.push('/disease-detection'),
                        ),
                        TeaRecommendationItem(
                          title: 'Soil Health',
                          subtitle: 'NPK analysis',
                          icon: Icons.science_outlined,
                          gradientColors: [TeaColors.richSoil, TeaColors.clayPot],
                          onTap: () => context.push('/soil-fertilization'),
                        ),
                        TeaRecommendationItem(
                          title: 'Yield Forecast',
                          subtitle: 'Predict harvest',
                          icon: Icons.analytics_outlined,
                          gradientColors: [TeaColors.infoSky, Colors.blue.shade400],
                          onTap: () => context.push('/yield-prediction'),
                        ),
                        TeaRecommendationItem(
                          title: 'Market Price',
                          subtitle: 'Tea value',
                          icon: Icons.trending_up,
                          gradientColors: [TeaColors.warmAmber, TeaColors.goldenSunlight],
                          badge: 'LIVE',
                          onTap: () => context.push('/market-analysis'),
                        ),
                      ],
                    ),

                    const SizedBox(height: TeaSpacing.lg),

                    // Recent Activity
                    _buildRecentActivity(activityState),

                    const SizedBox(height: TeaSpacing.xxl),
                  ]),
                ),
              ),
            ],
          ),

          // Tour overlay - renders on top of all content when active
          Consumer(builder: (context, ref, _) {
            final tourState = ref.watch(tourProvider);
            if (!tourState.isActive) return const SizedBox.shrink();
            return const TourOverlay();
          }),
        ],
      ),
      bottomNavigationBar: TeaBottomNavBar(
        currentIndex: 0,
        items: const [
          TeaNavItem(
              icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
          TeaNavItem(
              icon: Icons.eco_outlined, activeIcon: Icons.eco, label: 'Plants'),
          TeaNavItem(
              icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Map'),
          TeaNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile'),
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

  Widget _buildSliverAppBar(String userName, String greeting, AlertsState alertsState) {
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
          hasBadge: alertsState.alertCount > 0,
          badgeText: '${alertsState.alertCount}',
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

  Widget _buildHeroCard(DashboardKpiState kpiState) {
    if (kpiState.isLoading && !kpiState.hasData) {
      return const TeaSkeletonHeroCard();
    }
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
                          TeaColors.matureLeaf.withValues(alpha: 0.15),
                          TeaColors.freshLeaf.withValues(alpha: 0.25),
                          TeaColors.leafLight.withValues(alpha: 0.2),
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
                      color: TeaColors.freshLeaf.withValues(alpha: 0.1),
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
                      color: TeaColors.goldenSunlight.withValues(alpha: 0.08),
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
                                          TeaColors.freshLeaf.withValues(alpha: 0.2),
                                          TeaColors.freshLeaf.withValues(alpha: 0.05),
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
                                              .withValues(alpha: 0.3),
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
                            color: TeaColors.white.withValues(alpha: 0.7),
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
                                  'Active Blocks',
                                  kpiState.hasData ? '${kpiState.activeBlocks}' : '--',
                                  TeaColors.freshLeaf),
                              _buildMiniStat(
                                  'Healthy Plants',
                                  kpiState.hasData ? '${kpiState.healthPercent.toStringAsFixed(0)}%' : '--%',
                                  TeaColors.healthyGreen),
                              _buildMiniStat(
                                  'Harvest Ready',
                                  kpiState.hasData ? '${kpiState.harvestReadyBlocks} Blocks' : '-- Blocks',
                                  TeaColors.goldenSunlight),
                              _buildMiniStat(
                                  'Alerts',
                                  kpiState.hasData ? '${kpiState.alertCount}' : '--',
                                  TeaColors.warningAmber),
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
                  child: TeaStatusBadge.healthy(
                    label: kpiState.hasData ? kpiState.healthStatusLabel : 'Loading...',
                  ),
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
                          kpiState.hasData ? kpiState.estateName : 'Loading...',
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
                TeaProgressBar(
                  value: kpiState.hasData ? kpiState.healthPercent / 100 : 0,
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
              color: color.withValues(alpha: 0.1),
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

  Widget _buildMetricsRow(dynamic iotState, dynamic mqttState) {
    final mqttDevice =
        mqttState.deviceList.isNotEmpty ? mqttState.deviceList.first : null;
    final hasMqtt = mqttDevice != null && mqttDevice.hasData;
    final hasLiveData = hasMqtt || iotState.hasData;

    // Debug: Print values to console
    if (hasMqtt) {
      debugPrint(
          '[Dashboard] MQTT Device: T=${mqttDevice.temperature}°C H=${mqttDevice.humidity}% AQ=${mqttDevice.airQuality} TS=${mqttDevice.timestamp}');
    }

    // Temperature: MQTT first, then globalIoT, then placeholder
    final temperature = hasMqtt && mqttDevice.temperature != null
        ? mqttDevice.temperature!.toStringAsFixed(1)
        : iotState.hasData
            ? iotState.temperature.toStringAsFixed(1)
            : '--';

    // Humidity: MQTT first, then globalIoT, then placeholder (show exact decimal value)
    final humidity = hasMqtt && mqttDevice.humidity != null
        ? mqttDevice.humidity!.toString()
        : iotState.hasData
            ? iotState.humidity.toString()
            : '--';

    // Air quality: MQTT first (ppm → label), then globalIoT, then placeholder
    final double aqValue = hasMqtt && mqttDevice.airQuality != null
        ? mqttDevice.airQuality!
        : iotState.hasData
            ? iotState.airQuality.toDouble()
            : -1;
    final airQuality =
        aqValue >= 0 ? _getAirQualityLabel(aqValue.toInt()) : '--';
    final airQualityColor = aqValue >= 0
        ? _getAirQualityColor(aqValue.toInt())
        : TeaColors.darkGray;

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
              if (hasLiveData) ...[
                if (hasMqtt && mqttDevice.timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(right: TeaSpacing.sm),
                    child: Text(
                      '${DateTime.now().difference(mqttDevice.timestamp!).inSeconds}s ago',
                      style: TeaTypography.labelSmall.copyWith(
                        color: DateTime.now()
                                    .difference(mqttDevice.timestamp!)
                                    .inMinutes >
                                2
                            ? TeaColors.warningAmber
                            : TeaColors.darkGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (mqttState.lastRefreshed != null)
                  Padding(
                    padding: const EdgeInsets.only(right: TeaSpacing.sm),
                    child: Text(
                      'Ref: ${DateTime.now().difference(mqttState.lastRefreshed!).inSeconds}s',
                      style: TeaTypography.labelSmall.copyWith(
                        color: TeaColors.darkGray.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                InkWell(
                  onTap: () {
                    debugPrint('[Dashboard] Manual refresh triggered');
                    ref.read(iotLiveProvider.notifier).refresh();
                  },
                  borderRadius: TeaRadius.radiusSm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TeaSpacing.sm,
                      vertical: TeaSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: TeaColors.healthyGreen.withValues(alpha: 0.1),
                      borderRadius: TeaRadius.radiusSm,
                      border: Border.all(
                        color: TeaColors.healthyGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (mqttState.isLoading)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: TeaColors.healthyGreen,
                            ),
                          )
                        else ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: TeaColors.healthyGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.refresh,
                            size: 12,
                            color: TeaColors.healthyGreen,
                          ),
                        ],
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
                ),
              ],
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

  Widget _buildAlertsSection(AlertsState alertsState) {
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
        if (alertsState.isLoading && !alertsState.hasData)
          const TeaSkeletonAlertList()
        else if (alertsState.alerts.isEmpty)
          TeaCard.outlined(
            child: Padding(
              padding: TeaSpacing.cardPaddingMd,
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: TeaColors.healthyGreen, size: 20),
                  const SizedBox(width: TeaSpacing.sm),
                  Text(
                    'No active alerts',
                    style: TeaTypography.bodyMedium.copyWith(
                      color: TeaColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...alertsState.alerts.map((alert) {
            if (alert.isError) {
              return Padding(
                padding: const EdgeInsets.only(bottom: TeaSpacing.sm),
                child: TeaAlertCard.error(
                  title: alert.title,
                  message: alert.message,
                  onTap: () => context.push(alert.routePath ?? '/notifications'),
                ),
              );
            } else if (alert.isWarning) {
              return Padding(
                padding: const EdgeInsets.only(bottom: TeaSpacing.sm),
                child: TeaAlertCard.warning(
                  title: alert.title,
                  message: alert.message,
                  onTap: () => context.push(alert.routePath ?? '/notifications'),
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: TeaSpacing.sm),
                child: TeaAlertCard.info(
                  title: alert.title,
                  message: alert.message,
                  onTap: () => context.push(alert.routePath ?? '/notifications'),
                ),
              );
            }
          }),
        if (alertsState.error != null && !alertsState.hasData)
          Center(
            child: TextButton.icon(
              onPressed: () => ref.read(alertsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
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
                TeaColors.matureLeaf.withValues(alpha: 0.8),
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

  Widget _buildRecentActivity(ActivityFeedState activityState) {
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
        if (activityState.isLoading && !activityState.hasData)
          const TeaSkeletonActivityList()
        else if (activityState.activities.isEmpty)
          TeaCard.outlined(
            child: Padding(
              padding: TeaSpacing.cardPaddingMd,
              child: Row(
                children: [
                  Icon(Icons.inbox_outlined,
                      color: TeaColors.mediumGray, size: 20),
                  const SizedBox(width: TeaSpacing.sm),
                  Text(
                    'No recent activity',
                    style: TeaTypography.bodyMedium.copyWith(
                      color: TeaColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          TeaCard.elevated(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < activityState.activities.length && i < 5; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _buildActivityItem(
                    icon: _getActivityIcon(activityState.activities[i].iconType),
                    title: activityState.activities[i].title,
                    subtitle: activityState.activities[i].subtitle,
                    time: activityState.activities[i].timeAgo,
                    color: _getActivityColor(activityState.activities[i].iconType),
                  ),
                ],
              ],
            ),
          ),
        if (activityState.error != null && !activityState.hasData)
          Center(
            child: TextButton.icon(
              onPressed: () => ref.read(activityFeedProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ),
      ],
    );
  }

  IconData _getActivityIcon(IconType type) {
    switch (type) {
      case IconType.scan:
        return Icons.camera_alt_outlined;
      case IconType.harvest:
        return Icons.inventory_2_outlined;
      case IconType.soil:
        return Icons.science_outlined;
      case IconType.alert:
        return Icons.warning_amber_outlined;
      case IconType.report:
        return Icons.description_outlined;
    }
  }

  Color _getActivityColor(IconType type) {
    switch (type) {
      case IconType.scan:
        return TeaColors.healthyGreen;
      case IconType.harvest:
        return TeaColors.goldenSunlight;
      case IconType.soil:
        return TeaColors.richSoil;
      case IconType.alert:
        return TeaColors.warningAmber;
      case IconType.report:
        return TeaColors.infoSky;
    }
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
              color: color.withValues(alpha: 0.1),
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
