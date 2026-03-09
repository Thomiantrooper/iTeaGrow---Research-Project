import 'package:flutter/material.dart';

/// Sections of the app that the tour covers
enum TourSection {
  // Farmer dashboard
  welcome,
  overviewCard,
  searchBar,
  quickActions,
  diseaseDetection,
  navigation,
  chatAssistant,
  finish,

  // Manager dashboard
  managerWelcome,
  managerOverview,
  managerFieldOps,
  managerAnalytics,
  managerMarket,
  managerNavigation,
  managerMenu,
  managerFinish,
}

/// A single step in the guided tour
class TourStep {
  final TourSection section;
  final String title;
  final String message;
  final GlobalKey? targetKey;
  final String? routePath;
  final Alignment bubbleAlignment;
  final IconData icon;

  const TourStep({
    required this.section,
    required this.title,
    required this.message,
    this.targetKey,
    this.routePath,
    this.bubbleAlignment = Alignment.topLeft,
    this.icon = Icons.smart_toy_outlined,
  });
}

/// Predefined tour steps for the application
class TourSteps {
  TourSteps._();

  static List<TourStep> buildSteps({
    GlobalKey? heroCardKey,
    GlobalKey? searchBarKey,
    GlobalKey? quickActionsKey,
    GlobalKey? bottomNavKey,
    GlobalKey? chatFabKey,
  }) {
    return [
      TourStep(
        section: TourSection.welcome,
        title: 'Welcome to iTeaGrow!',
        message:
            'Hi there! I\'m TeaBot, your plantation assistant. Let me show you around so you can get the most from your tea estate!',
        icon: Icons.waving_hand,
      ),
      TourStep(
        section: TourSection.overviewCard,
        title: 'Plantation Overview',
        message:
            'This is your command center. It confirms the system is online and gives you an at-a-glance summary of your tea estate status.',
        targetKey: heroCardKey,
        icon: Icons.dashboard_outlined,
      ),
      TourStep(
        section: TourSection.searchBar,
        title: 'Quick Search',
        message:
            'Tap the search bar to instantly find any feature, screen, or tool — disease detection, soil analysis, maps, settings, and more.',
        targetKey: searchBarKey,
        icon: Icons.search_rounded,
      ),
      TourStep(
        section: TourSection.quickActions,
        title: 'Your AI Toolkit',
        message:
            'Six AI-powered tools at your fingertips: Disease Detection, Leaf Maturity, Soil Analysis, IoT Sensors, Powder Grading, and Yield Forecasting.',
        targetKey: quickActionsKey,
        icon: Icons.auto_awesome,
      ),
      TourStep(
        section: TourSection.diseaseDetection,
        title: 'Disease Detection',
        message:
            'Scan any tea leaf with your camera. The AI identifies diseases, rates severity, and gives treatment recommendations — even when offline.',
        icon: Icons.document_scanner_outlined,
      ),
      TourStep(
        section: TourSection.navigation,
        title: 'Navigate the App',
        message:
            'The bottom bar keeps you moving: Home for the dashboard, Map for your plantation\'s soil health and zone analysis, and Profile for your account.',
        targetKey: bottomNavKey,
        icon: Icons.navigation_outlined,
      ),
      TourStep(
        section: TourSection.chatAssistant,
        title: 'Your Personal TeaBot',
        message:
            'I\'m always here! Tap this button anytime to ask about crop health, diseases, yield estimates, weather impacts, or anything tea-related.',
        targetKey: chatFabKey,
        icon: Icons.chat_bubble_outlined,
      ),
      TourStep(
        section: TourSection.finish,
        title: 'You\'re All Set!',
        message:
            'That\'s the tour! You can restart it anytime from the Profile menu. Happy tea growing!',
        icon: Icons.celebration_outlined,
      ),
    ];
  }

  static List<TourStep> buildManagerSteps({
    GlobalKey? welcomeCardKey,
    GlobalKey? fieldToolsKey,
    GlobalKey? analyticsToolsKey,
    GlobalKey? marketToolsKey,
    GlobalKey? bottomNavKey,
  }) {
    return [
      const TourStep(
        section: TourSection.managerWelcome,
        title: 'Welcome, Estate Manager!',
        message:
            'Hi! I\'m TeaBot. This is your management dashboard — built for overseeing your entire tea estate operation.',
        icon: Icons.waving_hand,
      ),
      TourStep(
        section: TourSection.managerOverview,
        title: 'Estate Overview',
        message:
            'Your estate status at a glance. This card confirms the system is online and shows key estate information for quick decisions.',
        targetKey: welcomeCardKey,
        icon: Icons.landscape_outlined,
      ),
      TourStep(
        section: TourSection.managerFieldOps,
        title: 'Field Operations',
        message:
            'Three core field tools: Leaf Maturity scanning, Soil & Fertilization analysis, and live IoT Sensor monitoring across your estate.',
        targetKey: fieldToolsKey,
        icon: Icons.agriculture_outlined,
      ),
      TourStep(
        section: TourSection.managerAnalytics,
        title: 'AI Analytics',
        message:
            'AI-powered insights: Disease Detection for tea leaves, Powder Quality Grading, and Yield Prediction to plan your harvests.',
        targetKey: analyticsToolsKey,
        icon: Icons.auto_awesome,
      ),
      TourStep(
        section: TourSection.managerMarket,
        title: 'Market & Admin',
        message:
            'Track live tea market prices and manage market data as an administrator — all from one place.',
        targetKey: marketToolsKey,
        icon: Icons.currency_exchange,
      ),
      TourStep(
        section: TourSection.managerNavigation,
        title: 'Navigate the App',
        message:
            'The bottom bar takes you Home, to the Map for soil health and zone analysis, and to your Profile.',
        targetKey: bottomNavKey,
        icon: Icons.navigation_outlined,
      ),
      const TourStep(
        section: TourSection.managerMenu,
        title: 'Quick Menu',
        message:
            'Tap the menu icon (top-left) anytime to access Settings, Help, and to log out.',
        icon: Icons.menu_rounded,
      ),
      const TourStep(
        section: TourSection.managerFinish,
        title: 'You\'re All Set!',
        message:
            'That\'s the tour! You can restart it anytime from the menu. Happy managing!',
        icon: Icons.celebration_outlined,
      ),
    ];
  }
}
