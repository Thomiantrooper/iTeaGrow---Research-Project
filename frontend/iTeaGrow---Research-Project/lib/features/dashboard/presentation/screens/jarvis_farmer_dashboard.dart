import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/jarvis_theme.dart';
import '../../../../core/widgets/floating_tea_leaf.dart';
import '../../../../core/widgets/hologram_card.dart';
import '../../../../core/widgets/jarvis_assistant.dart';
import '../../../../core/services/ai_assistant_service.dart';
import '../../../../core/services/voice_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../disease_detection/presentation/screens/enhanced_disease_detection_screen.dart';
import '../../../leaf_maturity/presentation/screens/leaf_maturity_screen.dart';
import '../../../soil_fertilization/presentation/screens/soil_fertilization_screen.dart';
import '../../../powder_grading/presentation/screens/powder_grading_screen.dart';
import '../../../public/presentation/landing/landing_page.dart';
import '../../presentation/widgets/weather_risk_card.dart';
import '../../../iot_connectivity/presentation/widgets/esp32_sensor_card.dart';
import '../../../iot_connectivity/presentation/screens/iot_devices_screen.dart';

class JarvisFarmerDashboard extends ConsumerStatefulWidget {
  const JarvisFarmerDashboard({super.key});

  @override
  ConsumerState<JarvisFarmerDashboard> createState() =>
      _JarvisFarmerDashboardState();
}

class _JarvisFarmerDashboardState extends ConsumerState<JarvisFarmerDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showAssistant = false;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleAssistant() {
    setState(() {
      _showAssistant = !_showAssistant;
    });
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceServiceProvider);
    final assistantState = ref.watch(aiAssistantProvider);

    return Scaffold(
      backgroundColor: JarvisTheme.mistWhite,
      body: Stack(
        children: [
          // Background floating leaves
          const FloatingLeavesBackground(leafCount: 5),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar
                  _buildAppBar(context),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(JarvisTheme.spacingMd),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Greeting section
                        _buildGreetingSection(),
                        const SizedBox(height: JarvisTheme.spacingLg),

                        // Weather & Risk Alert
                        const WeatherRiskCard(),
                        const SizedBox(height: JarvisTheme.spacingLg),

                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Crop Insights',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: JarvisTheme.textPrimary,
                            ),
                          ),
                        ),
                        _buildPrimaryAction(context),
                        const SizedBox(height: JarvisTheme.spacingLg),

                        // Quick Actions Grid
                        _buildQuickActionsGrid(context),
                        const SizedBox(height: JarvisTheme.spacingLg),

                        // Environmental Metrics
                        _buildEnvironmentalMetrics(),
                        const SizedBox(height: JarvisTheme.spacingXxl),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // AI Assistant Panel
          if (_showAssistant) _buildAssistantPanel(assistantState, voiceState),

          // Jarvis FAB
          Positioned(
            right: JarvisTheme.spacingMd,
            bottom: JarvisTheme.spacingMd,
            child: GestureDetector(
              onTap: _toggleAssistant,
              onLongPress: () {
                // Start voice input
                ref.read(voiceServiceProvider.notifier).startListening();
              },
              child: JarvisAssistant(
                size: 60,
                isListening: voiceState.state == VoiceState.listening,
                isSpeaking: voiceState.state == VoiceState.speaking,
                isProcessing: assistantState.isProcessing,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                JarvisTheme.teaGreen,
                JarvisTheme.teaGreenDark,
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(JarvisTheme.radiusXl),
            ),
            boxShadow: JarvisTheme.cardShadow,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'iTeaGrow',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => _showDrawer(context),
        ),
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.white),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: JarvisTheme.warning,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            // Show notifications
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGreetingSection() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay_outlined;
    }

    return HologramCard(
      enableGlow: false,
      enable3DEffect: false,
      padding: const EdgeInsets.all(JarvisTheme.spacingLg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: JarvisTheme.primaryGradient,
              borderRadius: BorderRadius.circular(JarvisTheme.radiusMd),
            ),
            child: Icon(greetingIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: JarvisTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 14,
                    color: JarvisTheme.textMuted,
                  ),
                ),
                const Text(
                  'Farmer',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: JarvisTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Language selector
          PopupMenuButton<VoiceLanguage>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: JarvisTheme.mistGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.language,
                color: JarvisTheme.teaGreen,
                size: 20,
              ),
            ),
            onSelected: (language) {
              ref.read(voiceServiceProvider.notifier).setLanguage(language);
              ref.read(aiAssistantProvider.notifier).setLanguage(language);
            },
            itemBuilder: (context) => VoiceLanguage.values.map((lang) {
              return PopupMenuItem(
                value: lang,
                child: Text(lang.name),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(BuildContext context) {
    return HologramCard(
      enableGlow: true,
      glowColor: JarvisTheme.teaGreen,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeafMaturityScreen()),
        );
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: JarvisTheme.primaryGradient,
          borderRadius: BorderRadius.circular(JarvisTheme.radiusLg),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -20,
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
              padding: const EdgeInsets.all(JarvisTheme.spacingLg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'MATURITY ANALYSIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Leaf Maturity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Check leaf quality and maturity',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.center_focus_strong,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      _QuickAction(
        title: 'Disease Check',
        subtitle: 'Scan for diseases',
        icon: Icons.bug_report_outlined,
        color: JarvisTheme.critical,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const EnhancedDiseaseDetectionScreen()),
        ),
      ),
      _QuickAction(
        title: 'Fertilizer',
        subtitle: 'Get recommendations',
        icon: Icons.eco_outlined,
        color: JarvisTheme.earthyBrown,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SoilFertilizationScreen()),
        ),
      ),
      _QuickAction(
        title: 'Grading',
        subtitle: 'Check quality',
        icon: Icons.grade_outlined,
        color: JarvisTheme.softGoldDark,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PowderGradingScreen(showMarketData: false),
          ),
        ),
      ),
      _QuickAction(
        title: 'IoT Sensors',
        subtitle: 'View readings',
        icon: Icons.sensors_outlined,
        color: JarvisTheme.info,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IoTDevicesScreen()),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: JarvisTheme.textPrimary,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: JarvisTheme.spacingMd,
            crossAxisSpacing: JarvisTheme.spacingMd,
            childAspectRatio: 1.4,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return HologramCard(
              enableGlow: true,
              glowColor: action.color,
              onTap: action.onTap,
              padding: const EdgeInsets.all(JarvisTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: action.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(action.icon, color: action.color, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: JarvisTheme.textPrimary,
                        ),
                      ),
                      Text(
                        action.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: JarvisTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnvironmentalMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Environmental Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: JarvisTheme.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IoTDevicesScreen()),
                  );
                },
                icon: const Icon(Icons.sensors, size: 16),
                label: const Text('Manage'),
                style: TextButton.styleFrom(
                  foregroundColor: JarvisTheme.teaGreen,
                ),
              ),
            ],
          ),
        ),
        // ESP32 Live Sensor Card
        ESP32SensorCard(
          showConnectionStatus: true,
          showAirQuality: true,
          showDiseaseRisk: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IoTDevicesScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAssistantPanel(
    AssistantState assistantState,
    VoiceServiceState voiceState,
  ) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _toggleAssistant,
        child: Container(
          color: Colors.black54,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping panel
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                margin: const EdgeInsets.all(JarvisTheme.spacingMd),
                decoration: BoxDecoration(
                  color: JarvisTheme.mistWhite,
                  borderRadius: BorderRadius.circular(JarvisTheme.radiusXl),
                  boxShadow: JarvisTheme.elevatedShadow,
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(JarvisTheme.spacingMd),
                      decoration: const BoxDecoration(
                        gradient: JarvisTheme.primaryGradient,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(JarvisTheme.radiusXl),
                        ),
                      ),
                      child: Row(
                        children: [
                          JarvisAssistant(
                            size: 40,
                            isProcessing: assistantState.isProcessing,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tea Assistant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Ask me anything about tea cultivation',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: _toggleAssistant,
                          ),
                        ],
                      ),
                    ),

                    // Messages
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(JarvisTheme.spacingMd),
                        itemCount: assistantState.messages.length +
                            (assistantState.isProcessing ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= assistantState.messages.length) {
                            return const JarvisMessageBubble(
                              message: '',
                              isLoading: true,
                            );
                          }
                          final message = assistantState.messages[index];
                          return JarvisMessageBubble(
                            message: message.text,
                            isFromAssistant: message.isFromAssistant,
                            timestamp: message.timestamp,
                          );
                        },
                      ),
                    ),

                    // Input
                    Container(
                      padding: const EdgeInsets.all(JarvisTheme.spacingMd),
                      decoration: const BoxDecoration(
                        color: JarvisTheme.mistGray,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(JarvisTheme.radiusXl),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              voiceState.state == VoiceState.listening
                                  ? Icons.mic
                                  : Icons.mic_none,
                              color: voiceState.state == VoiceState.listening
                                  ? JarvisTheme.hologramCyan
                                  : JarvisTheme.teaGreen,
                            ),
                            onPressed: () {
                              if (voiceState.state == VoiceState.listening) {
                                ref
                                    .read(voiceServiceProvider.notifier)
                                    .stopListening();
                              } else {
                                ref
                                    .read(voiceServiceProvider.notifier)
                                    .startListening();
                              }
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type your question...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (text) {
                                if (text.isNotEmpty) {
                                  ref
                                      .read(aiAssistantProvider.notifier)
                                      .processMessage(text);
                                  _messageController.clear();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send,
                                color: JarvisTheme.teaGreen),
                            onPressed: () {
                              final text = _messageController.text;
                              if (text.isNotEmpty) {
                                ref
                                    .read(aiAssistantProvider.notifier)
                                    .processMessage(text);
                                _messageController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: JarvisTheme.mistWhite,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(JarvisTheme.radiusXl),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: JarvisTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // User header
            Container(
              padding: const EdgeInsets.all(JarvisTheme.spacingLg),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      gradient: JarvisTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: JarvisTheme.spacingMd),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Farmer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'farmer@iteagrow.com',
                          style: TextStyle(
                            color: JarvisTheme.textMuted,
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
                  color: JarvisTheme.teaGreen),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history_outlined,
                  color: JarvisTheme.teaGreen),
              title: const Text('Scan History'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined,
                  color: JarvisTheme.teaGreen),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading:
                  const Icon(Icons.help_outline, color: JarvisTheme.teaGreen),
              title: const Text('Help & Support'),
              onTap: () {},
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: JarvisTheme.critical),
              title: const Text('Logout',
                  style: TextStyle(color: JarvisTheme.critical)),
              onTap: () {
                ref.read(currentUserProvider.notifier).state = null;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: JarvisTheme.spacingLg),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
