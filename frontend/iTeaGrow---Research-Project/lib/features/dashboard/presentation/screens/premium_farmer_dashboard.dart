import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/providers/global_iot_provider.dart';
import '../../../../core/providers/iot_live_provider.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../providers/dashboard_kpi_provider.dart';
import '../providers/activity_feed_provider.dart';
import '../providers/alerts_provider.dart';
import '../../../tour/presentation/providers/tour_provider.dart';
import '../../../tour/presentation/widgets/tour_overlay.dart';

/// Premium Farmer Dashboard - Modern minimal aesthetic
class PremiumFarmerDashboard extends ConsumerStatefulWidget {
  const PremiumFarmerDashboard({super.key});

  @override
  ConsumerState<PremiumFarmerDashboard> createState() =>
      _PremiumFarmerDashboardState();
}

class _PremiumFarmerDashboardState
    extends ConsumerState<PremiumFarmerDashboard> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // GlobalKeys for tour highlighting
  final _heroCardKey = GlobalKey();
  final _metricsKey = GlobalKey();
  final _quickActionsKey = GlobalKey();
  final _alertsKey = GlobalKey();
  bool _tourChecked = false;

  // Search
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 50;
    if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
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
    final user = authState.user;
    final greeting = _getGreeting();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F7),
      body: Stack(
        children: [
          // Soft background shapes
          _buildBackgroundShapes(screenWidth),

          // Tour auto-start check
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
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(
                  user?.fullName ?? 'Farmer', greeting),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),

                    // Global Search Bar
                    _buildSearchBar(),
                    const SizedBox(height: 16),

                    // Live Metrics
                    KeyedSubtree(
                      key: _metricsKey,
                      child: _buildLiveMetrics(iotState, mqttState),
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    KeyedSubtree(
                      key: _quickActionsKey,
                      child: _buildQuickActions(),
                    ),

                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),

          // Tour overlay
          Consumer(builder: (context, ref, _) {
            final tourState = ref.watch(tourProvider);
            if (!tourState.isActive) return const SizedBox.shrink();
            return const TourOverlay();
          }),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildChatFab(),
    );
  }

  // ─── Search ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        setState(() => _isSearchOpen = true);
        _showSearchOverlay();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            const Icon(Icons.search_rounded, color: TeaColors.mediumGray, size: 22),
            const SizedBox(width: 12),
            Text(
              'Search features, pages, tools...',
              style: TeaTypography.bodyMedium.copyWith(
                color: TeaColors.mediumGray,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TeaColors.freshLeaf.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '/',
                style: TeaTypography.labelSmall.copyWith(
                  color: TeaColors.freshLeaf,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  void _showSearchOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DashboardSearchOverlay(
        onSelect: (route) {
          Navigator.pop(ctx);
          context.push(route);
        },
      ),
    ).whenComplete(() {
      setState(() => _isSearchOpen = false);
    });
  }

  // ─── Background Shapes ─────────────────────────────────────────────────

  Widget _buildBackgroundShapes(double screenWidth) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  TeaColors.freshLeaf.withOpacity(0.08),
                  TeaColors.freshLeaf.withOpacity(0.02),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 300,
          left: -100,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  TeaColors.goldenSunlight.withOpacity(0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          right: -50,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  TeaColors.infoSky.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(
      String userName, String greeting) {
    return SliverAppBar(
      expandedHeight: 110,
      floating: true,
      pinned: true,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor:
          _isScrolled ? Colors.white.withOpacity(0.95) : Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TeaTypography.bodySmall.copyWith(
                    color: TeaColors.darkGray,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: TeaTypography.headlineMedium.copyWith(
                    color: TeaColors.matureLeaf,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Profile avatar
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: _showProfileMenu,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [TeaColors.freshLeaf, TeaColors.matureLeaf],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: TeaColors.freshLeaf.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: TeaColors.nearBlack, size: 20),
            if (badge != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: TeaColors.alertRust,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Welcome Hero ──────────────────────────────────────────────────────

  Widget _buildWelcomeHero(DashboardKpiState kpiState) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D7C50), Color(0xFF2A5A38)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TeaColors.matureLeaf.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative shapes
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Health score ring
                    _buildHealthRing(kpiState),
                    const SizedBox(width: 20),
                    // Estate info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plantation Overview',
                            style: TeaTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            kpiState.hasData
                                ? kpiState.estateName
                                : 'Connecting...',
                            style: TeaTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kpiState.hasData
                                        ? TeaColors.healthyGreen
                                        : TeaColors.warningAmber,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  kpiState.hasData
                                      ? kpiState.healthStatusLabel
                                      : 'Loading...',
                                  style: TeaTypography.labelSmall.copyWith(
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
                const SizedBox(height: 20),
                // KPI row
                Row(
                  children: [
                    _buildHeroKpi(
                      label: 'Blocks',
                      value: kpiState.hasData
                          ? '${kpiState.activeBlocks}'
                          : '--',
                      icon: Icons.grid_view_rounded,
                    ),
                    _buildHeroDivider(),
                    _buildHeroKpi(
                      label: 'Harvest',
                      value: kpiState.hasData
                          ? '${kpiState.harvestReadyBlocks}'
                          : '--',
                      icon: Icons.grass_rounded,
                    ),
                    _buildHeroDivider(),
                    _buildHeroKpi(
                      label: 'Alerts',
                      value: kpiState.hasData
                          ? '${kpiState.alertCount}'
                          : '--',
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildHealthRing(DashboardKpiState kpiState) {
    final healthPercent = kpiState.hasData ? kpiState.healthPercent : 0.0;
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: healthPercent / 100,
              strokeWidth: 6,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                kpiState.hasData
                    ? '${healthPercent.toStringAsFixed(0)}%'
                    : '--',
                style: TeaTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              Text(
                'Health',
                style: TeaTypography.labelSmall.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroKpi({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.6), size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TeaTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TeaTypography.labelSmall.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.15),
    );
  }

  // ─── Live Metrics ──────────────────────────────────────────────────────

  Widget _buildLiveMetrics(dynamic iotState, dynamic mqttState) {
    final mqttDevice =
        mqttState.deviceList.isNotEmpty ? mqttState.deviceList.first : null;
    final hasMqtt = mqttDevice != null && mqttDevice.hasData;

    final temperature = hasMqtt && mqttDevice.temperature != null
        ? mqttDevice.temperature!.toStringAsFixed(1)
        : iotState.hasData
            ? iotState.temperature.toStringAsFixed(1)
            : '--';

    final humidity = hasMqtt && mqttDevice.humidity != null
        ? mqttDevice.humidity!.toString()
        : iotState.hasData
            ? iotState.humidity.toString()
            : '--';

    final double aqValue = hasMqtt && mqttDevice.airQuality != null
        ? mqttDevice.airQuality!
        : iotState.hasData
            ? iotState.airQuality.toDouble()
            : -1;
    final airQuality =
        aqValue >= 0 ? _getAirQualityLabel(aqValue.toInt()) : '--';
    final airQualityColor =
        aqValue >= 0 ? _getAirQualityColor(aqValue.toInt()) : TeaColors.darkGray;
    final hasLiveData = hasMqtt || iotState.hasData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text(
              'Live Environment',
              style: TeaTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (hasLiveData)
              GestureDetector(
                onTap: () => ref.read(iotLiveProvider.notifier).refresh(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TeaColors.healthyGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(width: 6),
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
        ),
        const SizedBox(height: 12),
        // Metric cards row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Temperature',
                value: temperature,
                unit: '°C',
                icon: Icons.thermostat_outlined,
                color: const Color(0xFFFF8A65),
                bgColor: const Color(0xFFFFF3E0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                label: 'Humidity',
                value: humidity,
                unit: '%',
                icon: Icons.water_drop_outlined,
                color: const Color(0xFF42A5F5),
                bgColor: const Color(0xFFE3F2FD),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                label: 'Air Quality',
                value: airQuality,
                unit: '',
                icon: Icons.air_outlined,
                color: airQualityColor,
                bgColor: airQualityColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TeaTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: TeaColors.nearBlack,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: TeaTypography.bodySmall.copyWith(
                      color: TeaColors.darkGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TeaTypography.labelSmall.copyWith(
              color: TeaColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Actions ─────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TeaTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        // Top row
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Disease Scan',
                subtitle: 'AI-powered detection',
                icon: Icons.document_scanner_outlined,
                gradient: const [Color(0xFFEF5350), Color(0xFFE57373)],
                onTap: () => context.push('/disease-detection'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Leaf Maturity',
                subtitle: 'Quality check',
                icon: Icons.eco_outlined,
                gradient: const [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                onTap: () => context.push('/leaf-maturity'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom row
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Soil Analysis',
                subtitle: 'NPK nutrients',
                icon: Icons.science_outlined,
                gradient: const [Color(0xFF8D6E63), Color(0xFFA1887F)],
                onTap: () => context.push('/soil-fertilization'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'IoT Sensors',
                subtitle: 'Real-time data',
                icon: Icons.sensors_rounded,
                gradient: const [Color(0xFF42A5F5), Color(0xFF64B5F6)],
                onTap: () => context.push('/iot-devices'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Extra row
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Powder Grading',
                subtitle: 'Quality grade',
                icon: Icons.grain_rounded,
                gradient: const [Color(0xFFFFB74D), Color(0xFFFFCC80)],
                onTap: () => context.push('/powder-grading'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Yield Forecast',
                subtitle: 'Predict harvest',
                icon: Icons.analytics_outlined,
                gradient: const [Color(0xFF7E57C2), Color(0xFF9575CD)],
                onTap: () => context.push('/yield-prediction'),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TeaTypography.labelSmall.copyWith(
                      color: TeaColors.darkGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  // ─── Alerts ────────────────────────────────────────────────────────────

  Widget _buildAlerts(AlertsState alertsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Alerts',
              style:
                  TeaTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Text(
                'See all',
                style: TeaTypography.labelMedium.copyWith(
                  color: TeaColors.freshLeaf,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (alertsState.isLoading && !alertsState.hasData)
          _buildAlertSkeleton()
        else if (alertsState.alerts.isEmpty)
          _buildEmptyState(
            icon: Icons.check_circle_outline_rounded,
            color: TeaColors.healthyGreen,
            message: 'All clear — no active alerts',
          )
        else
          ...alertsState.alerts.map((alert) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildAlertCard(alert),
              )),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  Widget _buildAlertCard(AlertData alert) {
    final Color color;
    final IconData icon;
    if (alert.isError) {
      color = TeaColors.alertRust;
      icon = Icons.error_outline_rounded;
    } else if (alert.isWarning) {
      color = TeaColors.warningAmber;
      icon = Icons.warning_amber_rounded;
    } else {
      color = TeaColors.infoSky;
      icon = Icons.info_outline_rounded;
    }

    return GestureDetector(
      onTap: () => context.push(alert.routePath ?? '/notifications'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TeaTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (alert.message.isNotEmpty)
                    Text(
                      alert.message,
                      style: TeaTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: TeaColors.mediumGray, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSkeleton() {
    return Column(
      children: List.generate(
        2,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Recent Activity ───────────────────────────────────────────────────

  Widget _buildRecentActivity(ActivityFeedState activityState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style:
                  TeaTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/activity-history'),
              child: Text(
                'View all',
                style: TeaTypography.labelMedium.copyWith(
                  color: TeaColors.freshLeaf,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activityState.isLoading && !activityState.hasData)
          _buildActivitySkeleton()
        else if (activityState.activities.isEmpty)
          _buildEmptyState(
            icon: Icons.inbox_outlined,
            color: TeaColors.mediumGray,
            message: 'No recent activity',
          )
        else
          Container(
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
            child: Column(
              children: [
                for (int i = 0;
                    i < activityState.activities.length && i < 5;
                    i++) ...[
                  if (i > 0)
                    Divider(
                        height: 1,
                        indent: 68,
                        color: Colors.grey.withOpacity(0.1)),
                  _buildActivityItem(activityState.activities[i]),
                ],
              ],
            ),
          ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }

  Widget _buildActivityItem(ActivityItem item) {
    final color = _getActivityColor(item.iconType);
    final icon = _getActivityIcon(item.iconType);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TeaTypography.titleSmall.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.subtitle.isNotEmpty)
                  Text(
                    item.subtitle,
                    style: TeaTypography.bodySmall.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            item.timeAgo,
            style: TeaTypography.labelSmall.copyWith(
              color: TeaColors.mediumGray,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySkeleton() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            message,
            style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Navigation ─────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', true, () {}),
              _buildNavItem(Icons.eco_rounded, 'Plants', false,
                  () => context.push('/plants')),
              _buildNavItem(Icons.map_rounded, 'Map', false,
                  () => context.push('/map')),
              _buildNavItem(Icons.person_rounded, 'Profile', false,
                  () => context.push('/profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? TeaColors.freshLeaf.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? TeaColors.freshLeaf : TeaColors.mediumGray,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? TeaColors.freshLeaf : TeaColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Chat FAB ──────────────────────────────────────────────────────────

  Widget _buildChatFab() {
    return GestureDetector(
      onTap: () => context.push('/chatbot'),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TeaColors.freshLeaf, TeaColors.matureLeaf],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: TeaColors.freshLeaf.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.chat_bubble_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 2000.ms,
          curve: Curves.easeInOut,
        );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  String _getAirQualityLabel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Fair';
    if (aqi <= 150) return 'Poor';
    if (aqi <= 200) return 'Bad';
    return 'Hazard';
  }

  Color _getAirQualityColor(int aqi) {
    if (aqi <= 50) return TeaColors.healthyGreen;
    if (aqi <= 100) return TeaColors.goldenSunlight;
    if (aqi <= 150) return TeaColors.warningAmber;
    if (aqi <= 200) return TeaColors.alertRust;
    return const Color(0xFF8E4585);
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              _buildMenuItem(Icons.person_outline_rounded, 'My Profile',
                  () => context.push('/profile')),
              _buildMenuItem(Icons.sensors_rounded, 'IoT Devices',
                  () => context.push('/iot-devices')),
              _buildMenuItem(Icons.history_rounded, 'Scan History',
                  () => context.push('/scan-history')),
              _buildMenuItem(Icons.description_outlined, 'Reports',
                  () => context.push('/reports')),
              _buildMenuItem(Icons.trending_up_rounded, 'Market Analysis',
                  () => context.push('/market-analysis')),
              _buildMenuItem(Icons.settings_outlined, 'Settings',
                  () => context.push('/settings')),
              _buildMenuItem(Icons.help_outline_rounded, 'Help & Support',
                  () => context.push('/help-center')),
              const Divider(height: 1),
              _buildMenuItem(Icons.logout_rounded, 'Log Out', () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              }, isDestructive: true),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? TeaColors.alertRust : TeaColors.nearBlack,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? TeaColors.alertRust : TeaColors.nearBlack,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

// ─── Search Data ──────────────────────────────────────────────────────────

class _SearchEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final List<String> keywords;

  const _SearchEntry(this.title, this.subtitle, this.icon, this.route, this.keywords);
}

const _allSearchEntries = <_SearchEntry>[
  _SearchEntry('Disease Detection', 'AI-powered leaf disease scan', Icons.document_scanner_outlined, '/disease-detection', ['disease', 'scan', 'leaf', 'blight', 'rust', 'detection', 'camera']),
  _SearchEntry('Leaf Maturity', 'Check tea leaf quality', Icons.eco_outlined, '/leaf-maturity', ['leaf', 'maturity', 'quality', 'growth']),
  _SearchEntry('Soil Analysis', 'NPK nutrient analysis', Icons.science_outlined, '/soil-fertilization', ['soil', 'fertilizer', 'npk', 'nutrient', 'analysis']),
  _SearchEntry('IoT Sensors', 'Real-time sensor data', Icons.sensors_rounded, '/iot-devices', ['iot', 'sensor', 'device', 'temperature', 'humidity', 'mqtt']),
  _SearchEntry('Powder Grading', 'Tea powder quality grade', Icons.grain_rounded, '/powder-grading', ['powder', 'grading', 'quality', 'grade', 'tea']),
  _SearchEntry('Yield Forecast', 'Predict harvest yield', Icons.analytics_outlined, '/yield-prediction', ['yield', 'forecast', 'predict', 'harvest']),
  _SearchEntry('Scan History', 'Past detection results', Icons.history_rounded, '/scan-history', ['history', 'scan', 'past', 'previous', 'results']),
  _SearchEntry('Reports', 'PDF reports and exports', Icons.description_outlined, '/reports', ['report', 'pdf', 'export', 'document']),
  _SearchEntry('Plants', 'Growth monitoring', Icons.eco_rounded, '/plants', ['plant', 'growth', 'monitor', 'block']),
  _SearchEntry('Plantation Map', 'Field map view', Icons.map_rounded, '/map', ['map', 'field', 'location', 'plantation']),
  _SearchEntry('Market Analysis', 'Tea market prices', Icons.trending_up_rounded, '/market-analysis', ['market', 'price', 'analysis', 'value']),
  _SearchEntry('Notifications', 'Alerts and updates', Icons.notifications_outlined, '/notifications', ['notification', 'alert', 'update']),
  _SearchEntry('Settings', 'App preferences', Icons.settings_outlined, '/settings', ['setting', 'preference', 'config']),
  _SearchEntry('Profile', 'Your account', Icons.person_outlined, '/profile', ['profile', 'account', 'user']),
  _SearchEntry('Help & Support', 'FAQ and contact', Icons.help_outline_rounded, '/help-center', ['help', 'support', 'faq', 'contact']),
  _SearchEntry('Activity History', 'Recent actions', Icons.access_time_rounded, '/activity-history', ['activity', 'history', 'recent', 'action']),
  _SearchEntry('Chatbot', 'AI assistant', Icons.chat_bubble_outlined, '/chatbot', ['chat', 'bot', 'assistant', 'ai', 'help']),
];

// ─── Search Overlay Widget ────────────────────────────────────────────────

class _DashboardSearchOverlay extends StatefulWidget {
  final void Function(String route) onSelect;

  const _DashboardSearchOverlay({required this.onSelect});

  @override
  State<_DashboardSearchOverlay> createState() =>
      _DashboardSearchOverlayState();
}

class _DashboardSearchOverlayState extends State<_DashboardSearchOverlay> {
  final _controller = TextEditingController();
  String _query = '';

  List<_SearchEntry> get _filtered {
    if (_query.isEmpty) return _allSearchEntries;
    final q = _query.toLowerCase();
    return _allSearchEntries.where((item) {
      if (item.title.toLowerCase().contains(q)) return true;
      if (item.subtitle.toLowerCase().contains(q)) return true;
      return item.keywords.any((k) => k.contains(q));
    }).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF6F9F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: TeaTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search features, pages, tools...',
                  hintStyle: TeaTypography.bodyMedium.copyWith(
                    color: TeaColors.mediumGray,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: TeaColors.mediumGray, size: 22),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _query.isEmpty
                    ? 'All features (${results.length})'
                    : '${results.length} result${results.length == 1 ? '' : 's'}',
                style: TeaTypography.labelSmall.copyWith(
                  color: TeaColors.darkGray,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Results list
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            color: TeaColors.mediumGray, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No results for "$_query"',
                          style: TeaTypography.bodyMedium.copyWith(
                            color: TeaColors.darkGray,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPad + 16),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return _buildSearchResultTile(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(_SearchEntry item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => widget.onSelect(item.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: TeaColors.freshLeaf.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, color: TeaColors.freshLeaf, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TeaTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: TeaTypography.labelSmall.copyWith(
                        color: TeaColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: TeaColors.mediumGray, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
