import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';

/// Help Center Screen
class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<FAQCategory> _categories = [
    FAQCategory(
      title: 'Getting Started',
      icon: Icons.rocket_launch_outlined,
      faqs: [
        FAQ(
          question: 'How do I scan a leaf for disease detection?',
          answer: 'Navigate to the Disease Detection screen from the dashboard or quick actions. Tap the camera button to take a photo of the leaf, or select an existing image from your gallery. The AI will analyze the image and provide results within seconds.',
        ),
        FAQ(
          question: 'How do I connect my IoT sensors?',
          answer: 'Go to Settings > IoT Devices or tap the IoT quick action. Make sure Bluetooth is enabled on your device. The app will automatically detect nearby compatible sensors. Tap on the sensor to pair and calibrate.',
        ),
        FAQ(
          question: 'What is the Growth Monitoring feature?',
          answer: 'Growth Monitoring tracks the health and development of your tea plants across different blocks. It uses AI to analyze plant images and environmental data to provide insights on growth stages and recommendations.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Disease Detection',
      icon: Icons.local_hospital_outlined,
      faqs: [
        FAQ(
          question: 'What diseases can the app detect?',
          answer: 'The app can detect common tea plant diseases including Blister Blight, Brown Blight, Algal Leaf Spot, Red Rust, and Gray Blight. Our AI model is continuously updated to improve accuracy and add new disease types.',
        ),
        FAQ(
          question: 'How accurate is the disease detection?',
          answer: 'Our AI model achieves over 95% accuracy on common tea diseases. For best results, ensure good lighting and capture clear, focused images of the affected leaves.',
        ),
        FAQ(
          question: 'Can I view my scan history?',
          answer: 'Yes! Your scan history is saved automatically. Go to Disease Detection > History to view past scans, track disease trends, and monitor treatment effectiveness.',
        ),
      ],
    ),
    FAQCategory(
      title: 'IoT & Sensors',
      icon: Icons.sensors_outlined,
      faqs: [
        FAQ(
          question: 'Which IoT sensors are compatible?',
          answer: 'The app supports various soil moisture sensors, temperature/humidity sensors, and air quality monitors. Check our compatibility list in Settings > IoT Devices > Compatible Devices.',
        ),
        FAQ(
          question: 'How often do sensors sync data?',
          answer: 'Sensors sync data every 5 minutes by default. You can adjust this in Settings > IoT Devices > Sync Frequency. More frequent syncing may reduce battery life.',
        ),
        FAQ(
          question: 'What do I do if a sensor disconnects?',
          answer: 'Try these steps: 1) Check sensor battery level, 2) Ensure you\'re within Bluetooth range, 3) Toggle Bluetooth off/on, 4) Remove and re-pair the sensor from the IoT Devices screen.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Account & Settings',
      icon: Icons.settings_outlined,
      faqs: [
        FAQ(
          question: 'How do I change my password?',
          answer: 'Go to Settings > Account > Change Password. Enter your current password, then create a new password that\'s at least 8 characters with a mix of letters and numbers.',
        ),
        FAQ(
          question: 'Can I use the app offline?',
          answer: 'Yes! Core features like viewing your dashboard, accessing scan history, and monitoring cached sensor data work offline. Disease detection requires an internet connection for AI processing.',
        ),
        FAQ(
          question: 'How do I export my data?',
          answer: 'Go to Settings > App Settings > Export Data. You can export plantation data, scan history, and sensor readings in CSV or PDF format.',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        backgroundColor: TeaColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TeaColors.nearBlack),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Help Center',
          style: TeaTypography.titleLarge.copyWith(color: TeaColors.nearBlack),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Header
            Container(
              color: TeaColors.white,
              padding: TeaSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can we help you?',
                    style: TeaTypography.headlineSmall,
                  ),
                  const SizedBox(height: TeaSpacing.md),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for help...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: TeaColors.mistGreen,
                      border: OutlineInputBorder(
                        borderRadius: TeaRadius.radiusMd,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ],
              ),
            ),

            // Quick Actions
            Padding(
              padding: TeaSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: TeaSpacing.md),
                  Text(
                    'Quick Actions',
                    style: TeaTypography.titleMedium,
                  ),
                  const SizedBox(height: TeaSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.chat_outlined,
                          label: 'Chat Support',
                          onTap: () => context.push('/chatbot'),
                        ),
                      ),
                      const SizedBox(width: TeaSpacing.sm),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.email_outlined,
                          label: 'Email Us',
                          onTap: () {
                            TeaSnackbar.info(context, 'Email: support@iteagrow.com');
                          },
                        ),
                      ),
                      const SizedBox(width: TeaSpacing.sm),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.video_library_outlined,
                          label: 'Tutorials',
                          onTap: () {
                            TeaSnackbar.info(context, 'Video tutorials coming soon!');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // FAQ Categories
            Padding(
              padding: TeaSpacing.screenPaddingHorizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: TeaSpacing.lg),
                  Text(
                    'Frequently Asked Questions',
                    style: TeaTypography.titleMedium,
                  ),
                  const SizedBox(height: TeaSpacing.sm),
                  ..._buildFilteredCategories(),
                  const SizedBox(height: TeaSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TeaCard.elevated(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: TeaSpacing.sm,
        vertical: TeaSpacing.md,
      ),
      child: Column(
        children: [
          Icon(icon, color: TeaColors.freshLeaf, size: 28),
          const SizedBox(height: TeaSpacing.xs),
          Text(
            label,
            style: TeaTypography.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilteredCategories() {
    List<Widget> widgets = [];

    for (int i = 0; i < _categories.length; i++) {
      final category = _categories[i];
      final filteredFaqs = _searchQuery.isEmpty
          ? category.faqs
          : category.faqs.where((faq) =>
              faq.question.toLowerCase().contains(_searchQuery) ||
              faq.answer.toLowerCase().contains(_searchQuery),).toList();

      if (filteredFaqs.isEmpty && _searchQuery.isNotEmpty) continue;

      widgets.add(
        _buildCategorySection(category, filteredFaqs, i)
            .animate()
            .fadeIn(duration: 300.ms, delay: (i * 100).ms)
            .slideY(begin: 0.1, end: 0),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(TeaSpacing.xl),
            child: Column(
              children: [
                const Icon(Icons.search_off, size: 48, color: TeaColors.mediumGray),
                const SizedBox(height: TeaSpacing.md),
                Text(
                  'No results found',
                  style: TeaTypography.titleMedium.copyWith(
                    color: TeaColors.darkGray,
                  ),
                ),
                Text(
                  'Try different keywords',
                  style: TeaTypography.bodySmall.copyWith(
                    color: TeaColors.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildCategorySection(FAQCategory category, List<FAQ> faqs, int index) {
    return TeaCard.elevated(
      margin: const EdgeInsets.only(bottom: TeaSpacing.md),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(TeaSpacing.sm),
          decoration: BoxDecoration(
            color: TeaColors.freshLeaf.withOpacity(0.1),
            borderRadius: TeaRadius.radiusSm,
          ),
          child: Icon(category.icon, color: TeaColors.freshLeaf),
        ),
        title: Text(
          category.title,
          style: TeaTypography.titleSmall,
        ),
        subtitle: Text(
          '${faqs.length} articles',
          style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray),
        ),
        children: faqs.map((faq) => _buildFAQItem(faq)).toList(),
      ),
    );
  }

  Widget _buildFAQItem(FAQ faq) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: TeaSpacing.md),
      title: Text(
        faq.question,
        style: TeaTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TeaSpacing.md,
            0,
            TeaSpacing.md,
            TeaSpacing.md,
          ),
          child: Text(
            faq.answer,
            style: TeaTypography.bodySmall.copyWith(
              color: TeaColors.darkGray,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class FAQCategory {
  final String title;
  final IconData icon;
  final List<FAQ> faqs;

  FAQCategory({
    required this.title,
    required this.icon,
    required this.faqs,
  });
}

class FAQ {
  final String question;
  final String answer;

  FAQ({required this.question, required this.answer});
}
