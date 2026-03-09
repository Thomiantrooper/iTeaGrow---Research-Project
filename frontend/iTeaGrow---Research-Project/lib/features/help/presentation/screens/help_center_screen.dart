import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/providers/auth_provider.dart';
import 'package:iteagrow/l10n/app_localizations.dart';

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
          question: 'What is iTeaGrow and what can it do for me?',
          answer:
              'iTeaGrow is a smart farming assistant designed specifically for tea plantation workers and managers. It helps you:\n\n• Detect diseases on tea leaves by simply taking a photo\n• Check if your tea leaves are ready to harvest\n• Grade your processed tea powder and estimate its market value\n• Monitor your plantation\'s temperature, humidity, and soil conditions in real time using connected sensors\n• Predict how much yield your plantation will produce\n\nYou do not need any technical knowledge to use this app — just point your camera at a leaf or powder, and the app does the rest.',
        ),
        FAQ(
          question: 'How do I log in or create an account?',
          answer:
              'Open the app and tap "Sign In" if you already have an account. Enter your registered email address and password, then tap "Login".\n\nIf you are new, tap "Create Account", fill in your name, email address, and a password of your choice (at least 8 characters), then tap "Register".\n\nIf you forget your password, tap "Forgot Password?" on the login screen and follow the instructions sent to your email.',
        ),
        FAQ(
          question: 'How do I navigate the app?',
          answer:
              'After logging in, you will see the Home Dashboard. From here you can:\n\n• Tap any feature card (Disease Detection, Leaf Maturity, etc.) to open that tool\n• Use the bottom navigation bar to quickly switch between Home, IoT monitoring, and Settings\n• Tap the "Quick Actions" buttons on the home screen for the most common tasks\n\nAll features are accessible from the main dashboard — you never need to go more than two taps deep.',
        ),
        FAQ(
          question: 'Does the app work without an internet connection?',
          answer:
              'Yes — the core AI features work fully offline. Disease detection, leaf maturity assessment, and tea powder grading all run directly on your phone without needing internet.\n\nSome features that do require internet:\n• Saving scan results to the cloud (they are queued and sync when you reconnect)\n• Market price lookups for the latest tea prices\n• Receiving app updates\n\nYour IoT sensor data is always visible on the dashboard even without internet, as long as your sensors are nearby.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Disease Detection',
      icon: Icons.local_hospital_outlined,
      faqs: [
        FAQ(
          question: 'How do I scan a leaf for disease?',
          answer:
              'Follow these simple steps:\n\n1. From the Home screen, tap "Disease Detection"\n2. Tap the camera icon to take a fresh photo, or tap the gallery icon to choose an existing photo\n3. Hold the phone steady, 20–30 cm away from the leaf, in good daylight or bright indoor light\n4. Make sure the leaf fills most of the frame — avoid capturing too much background\n5. Tap "Analyse" and wait a few seconds\n6. The app will show you the disease name, confidence level, severity, and what to do next\n\nTip: Natural daylight gives the best results. Avoid scanning in direct harsh sunlight or dark shadows.',
        ),
        FAQ(
          question: 'What diseases can the app detect?',
          answer:
              'The app can identify the following common tea plant diseases:\n\n• Blister Blight — Small, pale blisters on young leaves; very common in humid weather\n• Brown Blight — Brown patches spreading across the leaf; caused by fungal infection\n• Algal Leaf Spot — Circular grey-green patches caused by algae on the leaf surface\n• Red Rust — Reddish-brown powdery coating; caused by algae in wet conditions\n• Gray Blight — Grey dead patches at leaf tips or edges\n• Healthy — No disease found; your leaf is clean\n\nEach result comes with a detailed description and recommended treatment steps.',
        ),
        FAQ(
          question:
              'What do the confidence percentage and reliability label mean?',
          answer:
              'After scanning, you will see a "Confidence" percentage and a "Reliability" label:\n\n• 85–100% / Very High Reliability — The result is very dependable. Proceed with the recommended treatment.\n• 70–84% / High Reliability — A strong result. Apply treatment with normal care.\n• 50–69% / Moderate Reliability — The app is fairly sure but recommends re-scanning with a clearer photo.\n• Below 50% / Low Reliability — The result is uncertain. Please take another photo in better lighting before taking action.\n\nWhen confidence is low, the app will tell you to re-scan rather than showing you a misleading result.',
        ),
        FAQ(
          question: 'The app is rejecting my photo before scanning. Why?',
          answer:
              'The app checks your photo before analysing it to make sure it is actually a tea leaf. Common reasons for rejection:\n\n• "No leaf detected" — The image does not appear to be a tea leaf. Make sure the leaf is clearly visible and fills most of the frame.\n• "Image appears blurry" — Hold the phone steady and tap the screen on the leaf to focus before taking the photo.\n• "Image does not appear to contain a leaf" — You may have accidentally scanned a background surface, cloth, or object. Point the camera directly at the leaf.\n\nThis safety check exists so you only get results from real tea leaf images.',
        ),
        FAQ(
          question: 'Can I view my past scan results?',
          answer:
              'Yes. Tap the clock/history icon at the top-right of the Disease Detection screen to open your Scan History. You can:\n\n• See all past scans with date, disease detected, and confidence\n• Tap any entry to view the full result again\n• Track whether a disease is spreading over time\n• Delete individual entries if needed\n\nResults are saved automatically on your device and backed up to the cloud when you have internet.',
        ),
        FAQ(
          question: 'What should I do after a disease is detected?',
          answer:
              'The app provides specific advice for each disease under "Recommended Treatment" in the results screen. General steps:\n\n1. Note the disease name and severity shown\n2. Read the treatment recommendation carefully\n3. Isolate affected plants if severity is "High" to prevent spreading\n4. Apply the recommended fungicide or treatment\n5. Re-scan the same leaves after 7–10 days to monitor progress\n\nFor "Healthy" results, no action is needed — keep up your current care practices.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Leaf Maturity',
      icon: Icons.eco_outlined,
      faqs: [
        FAQ(
          question: 'What is Leaf Maturity and why does it matter?',
          answer:
              'Leaf Maturity tells you whether your tea leaves are at the right stage for harvesting. Picking leaves too early or too late affects the quality and taste of the final tea.\n\nThe app analyses the leaf\'s colour, texture, and visual features to classify it as:\n• Too Young — Not ready for picking yet\n• Ready to Pick — Optimal stage for harvesting\n• Mature / Over-mature — Past the best picking window\n\nKnowing this helps you maximise both yield quality and quantity.',
        ),
        FAQ(
          question: 'How do I assess leaf maturity?',
          answer:
              'Steps:\n\n1. Tap "Leaf Maturity" from the Home screen\n2. Take a clear photo of a leaf on the plant — a single leaf in focus works best\n3. Tap "Analyse"\n4. The app will display the maturity stage, a confidence percentage, and picking advice\n\nFor best results, photograph leaves in the upper canopy (the "flush") as these are the ones you would typically harvest.',
        ),
        FAQ(
          question: 'Can I scan a diseased or yellowed leaf for maturity?',
          answer:
              'You can try, but the app may flag the image for re-scanning if the leaf colour is too brown or damaged to assess maturity reliably. A very diseased leaf cannot give an accurate maturity reading — use Disease Detection for those leaves instead.\n\nMaturity assessment works best on leaves that are visibly green-to-slightly-brownish, which is the natural colour range of maturing tea leaves.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Tea Powder Grading',
      icon: Icons.grain_outlined,
      faqs: [
        FAQ(
          question: 'What is Tea Powder Grading?',
          answer:
              'After tea leaves are processed, the dried tea is sorted into different grades based on particle size and quality. Each grade has a different market value.\n\niTeaGrow can look at a photo of your processed tea powder and identify which grade it is:\n\n• BOP (Broken Orange Pekoe) — Coarser grade, premium quality\n• BOPF (Broken Orange Pekoe Fannings) — Fine grade, commonly used in tea bags\n• Dust — Very fine powder, strong flavour, widely used\n• Dust 1 — Slightly coarser than dust, good quality\n• Fanning 1 — Between BOPF and Dust, popular for commercial blends\n• Pekoe — Larger, full-leaf pieces, premium grade\n\nKnowing your grade helps you price your tea correctly at the auction or market.',
        ),
        FAQ(
          question: 'How do I scan tea powder for grading?',
          answer:
              'Steps:\n\n1. Tap "Powder Grading" from the Home screen\n2. Spread a small amount of your dry tea powder on a plain white or light-coloured plate or paper\n3. Take a clear, close-up photo of the powder — the powder should fill most of the frame\n4. Tap "Analyse"\n5. The result will show the grade, confidence level, and an explanation of what that grade means\n\nTips for a good scan:\n• Use natural daylight or a bright white light\n• Avoid shadows falling over the powder\n• Keep the camera still and close (15–25 cm away)\n• Do not scan wet or clumped powder — it must be dry',
        ),
        FAQ(
          question: 'What does the confidence score mean in grading?',
          answer:
              'The confidence score tells you how certain the app is about the grade it identified:\n\n• Above 70% — High confidence. The grade is very likely correct.\n• 50–70% — Moderate confidence. The result is a good estimate but consider re-scanning.\n• Below 50% — Low confidence. The powder may be mixed grades or the photo was unclear. Re-scan with a cleaner sample.\n\nIf the top two grades are very close in score, the app will show an "Ambiguous Result" banner to warn you that the powder could belong to either grade.',
        ),
        FAQ(
          question: 'Why is my powder photo being rejected?',
          answer:
              'The app checks that you are scanning actual tea powder before grading. Reasons for rejection:\n\n• "No tea powder detected" — Make sure the powder fills the frame and is dry. Dark surfaces, cloths, or non-powder objects will be rejected.\n• "Image appears blurry" — Hold the phone steady and get closer to the powder.\n• "Green content too high" — The app detected too much green, suggesting this may be an unprocessed leaf rather than processed powder.\n\nAlways scan powder on a plain, light background for best results.',
        ),
      ],
    ),
    FAQCategory(
      farmerVisible: false,
      title: 'Market Analysis',
      icon: Icons.show_chart_outlined,
      faqs: [
        FAQ(
          question: 'What is the Market Analysis feature?',
          answer:
              'Market Analysis combines your powder grade scan with current tea market prices to estimate how much your tea batch could sell for.\n\nIt shows you:\n• Estimated price range per kilogram for your grade\n• Total estimated value for your batch\n• Price comparison vs. other grades\n• Market trend indicator (whether prices are rising or falling)\n\nThis helps you decide whether to sell now or hold your stock, and gives you a fair benchmark when negotiating with buyers.',
        ),
        FAQ(
          question: 'How do I get a market value estimate?',
          answer:
              'Steps:\n\n1. Tap "Market Analysis" from the Home screen\n2. First, scan a photo of your tea powder — the app needs to identify the grade\n3. Once graded, enter your batch weight in kilograms\n4. Tap "Calculate Market Value"\n5. The app will show the estimated price range, total batch value, and market context\n\nFor the most up-to-date prices, make sure your phone is connected to the internet. The app will use cached prices if you are offline.',
        ),
        FAQ(
          question: 'Are the market prices accurate?',
          answer:
              'The prices shown are estimates based on recent Sri Lanka tea auction data and industry benchmarks. They are a helpful guide but may vary from the actual price you receive, which depends on:\n\n• Specific buyer and region\n• Exact moisture content and quality of your batch\n• Daily market fluctuations\n• Volume discounts or premiums\n\nAlways use these estimates as a reference, not as a guaranteed selling price.',
        ),
      ],
    ),
    FAQCategory(
      farmerVisible: false,
      title: 'Yield Prediction',
      icon: Icons.bar_chart_outlined,
      faqs: [
        FAQ(
          question: 'What is Yield Prediction?',
          answer:
              'Yield Prediction estimates how much tea (in kilograms) your plantation will produce in the coming harvest period based on information you provide about your land, workers, and growing conditions.\n\nThis helps you:\n• Plan your workforce and harvesting schedule\n• Estimate income before the harvest happens\n• Compare expected vs. actual yield over time\n• Identify which conditions lead to better yields',
        ),
        FAQ(
          question: 'How do I use Yield Prediction?',
          answer:
              'Steps:\n\n1. Tap "Yield Prediction" from the Home screen\n2. Fill in the form:\n   • Plantation area (in hectares or acres)\n   • Number of workers available for harvesting\n   • Number of tea bushes\n   • Season (Dry / Wet / Inter-monsoon)\n   • Average rainfall for the period\n   • Average temperature\n3. Tap "Predict Yield"\n4. The app will show the estimated yield in kilograms and a confidence range\n\nYou do not need exact numbers — reasonable estimates will give you a useful prediction.',
        ),
        FAQ(
          question:
              'My predicted yield seems too high or too low. What should I check?',
          answer:
              'If the prediction looks unexpected, check these inputs:\n\n• Workers per hectare: Typically 15–40 workers per hectare. If you entered too many or too few, the estimate will be skewed.\n• Crop load (kg/ha): Reasonable range is 200–2,500 kg per hectare per year. Very high numbers may trigger a warning.\n• Season: Dry season typically produces less than wet season — make sure you selected the right one.\n• Rainfall: Very high (>400mm) or very low (<20mm) values will show a warning, as these are extreme conditions.\n\nThe app shows advisory warnings if your inputs seem unusual — read them carefully before submitting.',
        ),
      ],
    ),
    FAQCategory(
      title: 'IoT Sensors & Live Monitoring',
      icon: Icons.sensors_outlined,
      faqs: [
        FAQ(
          question: 'What do the live sensor readings on the dashboard mean?',
          answer:
              'The dashboard shows real-time data from sensors installed in your plantation:\n\n• Temperature (°C) — Current air temperature at the sensor location. Ideal for tea: 18–28°C.\n• Humidity (%) — Moisture level in the air. High humidity (above 80%) increases disease risk.\n• Soil Moisture (%) — How wet the soil is. Tea generally needs 60–80% soil moisture.\n• Air Quality (ppm) — Air purity reading. High values may indicate smoke or chemical presence.\n• pH — Soil acidity level. Tea plants prefer slightly acidic soil (pH 4.5–6.0).\n\nColoured indicators (green/yellow/red) show whether each reading is in a safe, borderline, or concerning range.',
        ),
        FAQ(
          question:
              'What does "Live", "Stale", or "Offline" mean next to a sensor?',
          answer:
              '• Live (green dot) — The sensor is connected and sending fresh data right now.\n• Stale (yellow dot) — The sensor has not sent new data for more than 15 minutes. It may have a low battery or weak signal.\n• Offline (grey/red dot) — The sensor has not been heard from for a long time. Check power and connectivity.\n\nIf a sensor shows Stale or Offline, check that it is powered on and within range of your WiFi or network connection.',
        ),
        FAQ(
          question: 'What should I do if a sensor shows unusual readings?',
          answer:
              'If a reading seems wrong (for example, temperature showing 0°C or humidity at 0%):\n\n1. Check that the sensor is powered on and not covered or submerged\n2. Make sure the sensor is not in direct sunlight, which can cause false high temperature readings\n3. Wait 5–10 minutes and check if the value updates\n4. If still wrong, try restarting the sensor (power off and on)\n5. If the problem persists, the sensor may need recalibration or replacement\n\nAlways cross-check unusual readings with physical observation of your field before making decisions.',
        ),
        FAQ(
          question: 'How is the sensor data used by the app\'s AI features?',
          answer:
              'When you scan a leaf for disease detection, the app automatically reads the current temperature and humidity from your live sensors and includes them in the AI analysis. This makes the disease prediction more accurate because certain diseases are more likely in specific weather conditions.\n\nFor example, Blister Blight thrives in high humidity above 75% — if your sensor shows high humidity, the app factors this in when assessing risk.\n\nYou do not need to do anything extra — this happens automatically whenever sensors are connected.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Account & Settings',
      icon: Icons.manage_accounts_outlined,
      faqs: [
        FAQ(
          question: 'How do I change my name, email, or profile photo?',
          answer:
              'Go to the bottom navigation bar, tap "Settings", then tap your profile card at the top. From there you can:\n\n• Change your display name\n• Update your email address\n• Add or change your profile photo\n• Update your plantation name and location\n\nTap "Save Changes" after making edits.',
        ),
        FAQ(
          question: 'How do I change my password?',
          answer:
              'Steps:\n\n1. Open "Settings" from the bottom navigation bar\n2. Tap "Change Password"\n3. Enter your current password\n4. Enter your new password (at least 8 characters; use a mix of letters and numbers for security)\n5. Confirm the new password and tap "Update Password"\n\nIf you have forgotten your current password, log out and use "Forgot Password?" on the login screen instead.',
        ),
        FAQ(
          question: 'How do I turn notifications on or off?',
          answer:
              'Go to Settings > Notifications. You can separately enable or disable:\n\n• Disease alerts — Notified when a scan detects high-severity disease\n• Sensor alerts — Notified when a sensor reading goes into a dangerous range\n• Harvest reminders — Weekly digest of leaf maturity status\n• Market price updates — Daily tea auction price summary\n\nYou can also set quiet hours so you are not disturbed at night.',
        ),
        FAQ(
          question: 'How do I export or download my plantation data?',
          answer:
              'Go to Settings > Export Data. You can choose to export:\n\n• Scan history (disease detections and results)\n• Sensor readings (temperature, humidity, soil data over time)\n• Yield prediction history\n• Market analysis reports\n\nData is exported as a PDF report or CSV spreadsheet. Tap "Export" and the file will be saved to your phone\'s Downloads folder, or you can share it directly via WhatsApp, email, or any other app.',
        ),
        FAQ(
          question: 'How do I log out of the app?',
          answer:
              'Go to Settings and scroll to the bottom. Tap "Logout" and confirm. Your scan history and data remain saved — you can log back in at any time.\n\nNote: If you log out, you will need your email and password to log back in. Make sure you remember them before logging out.',
        ),
      ],
    ),
    FAQCategory(
      title: 'Troubleshooting',
      icon: Icons.build_outlined,
      faqs: [
        FAQ(
          question: 'The app is slow or crashing. What should I do?',
          answer:
              'Try these steps in order:\n\n1. Close the app completely and reopen it\n2. Restart your phone\n3. Check that your phone has enough free storage (at least 500 MB recommended)\n4. Update the app to the latest version via the Play Store or App Store\n5. If the problem continues, go to Settings > App Settings > Clear Cache\n\nIf none of these help, contact us at support@iteagrow.com with your phone model and a description of the problem.',
        ),
        FAQ(
          question:
              'My scan results look wrong. The app diagnosed a disease on a non-leaf image.',
          answer:
              'The app has built-in photo validation that should block non-leaf images before scanning. If an incorrect result appears, please:\n\n1. Make sure you are pointing the camera at a real tea leaf — not cloth, paper, electronic devices, or other objects\n2. Use natural daylight and avoid very dark or very bright scenes\n3. Hold the phone steady so the image is sharp\n4. If the problem persists, note the image type you used and contact us — we use this feedback to continuously improve the validation system.',
        ),
        FAQ(
          question:
              'The app says I have no internet but I do have WiFi. What should I try?',
          answer:
              '1. Toggle WiFi off and back on on your phone\n2. Check that your WiFi router is working (try another app that needs internet)\n3. Try switching to mobile data to see if the issue is router-specific\n4. Restart your phone\n5. Go to Settings > App Settings > Check Connection to test the server link\n\nAll AI scanning features work without internet — only cloud save, price data, and account sync need a connection.',
        ),
        FAQ(
          question: 'I forgot my password and cannot log in. What do I do?',
          answer:
              '1. On the login screen, tap "Forgot Password?"\n2. Enter the email address you used to register\n3. Open that email inbox (including Spam/Junk folder) — a password reset link will arrive within a few minutes\n4. Tap the link and follow the steps to set a new password\n5. Return to the app and log in with your new password\n\nIf you no longer have access to that email address, contact us at support@iteagrow.com and we will help you recover your account.',
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
          AppLocalizations.of(context)!.help_title,
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
                    AppLocalizations.of(context)!.help_header,
                    style: TeaTypography.headlineSmall,
                  ),
                  const SizedBox(height: TeaSpacing.md),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.help_search_hint,
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
                    AppLocalizations.of(context)!.help_quick_actions,
                    style: TeaTypography.titleMedium,
                  ),
                  const SizedBox(height: TeaSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 200,
                      child: _buildQuickAction(
                        icon: Icons.chat_outlined,
                        label: AppLocalizations.of(context)!.help_chat_support,
                        onTap: () => context.push('/chatbot'),
                      ),
                    ),
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
                    AppLocalizations.of(context)!.help_faq_section,
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
    final isManagerOrAbove =
        ref.read(authStateProvider).user?.role.canAccessAnalytics() ?? false;

    List<Widget> widgets = [];

    for (int i = 0; i < _categories.length; i++) {
      final category = _categories[i];

      // Hide manager-only categories from farmers
      if (!isManagerOrAbove && !category.farmerVisible) continue;

      final filteredFaqs = _searchQuery.isEmpty
          ? category.faqs
          : category.faqs
              .where(
                (faq) =>
                    faq.question.toLowerCase().contains(_searchQuery) ||
                    faq.answer.toLowerCase().contains(_searchQuery),
              )
              .toList();

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
                const Icon(Icons.search_off,
                    size: 48, color: TeaColors.mediumGray),
                const SizedBox(height: TeaSpacing.md),
                Text(
                  AppLocalizations.of(context)!.help_no_results,
                  style: TeaTypography.titleMedium.copyWith(
                    color: TeaColors.darkGray,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.help_no_results_hint,
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

  Widget _buildCategorySection(
      FAQCategory category, List<FAQ> faqs, int index) {
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
  /// Whether this category is visible to farmers.
  /// Manager/admin users always see all categories.
  final bool farmerVisible;
  final String title;
  final IconData icon;
  final List<FAQ> faqs;

  FAQCategory({
    this.farmerVisible = true,
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
