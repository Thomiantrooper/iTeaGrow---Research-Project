import 'package:flutter/material.dart';

/// Sections of the app that the tour covers
enum TourSection {
  welcome,
  dashboardOverview,
  dataIngestion,
  processingPipeline,
  monitoring,
  reports,
  settings,
  userManagement,
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
    GlobalKey? metricsKey,
    GlobalKey? quickActionsKey,
    GlobalKey? alertsKey,
  }) {
    return [
      TourStep(
        section: TourSection.welcome,
        title: 'Welcome to iTeaGrow!',
        message:
            'Hi there! I\'m TeaBot, your plantation assistant. Let me show you around the app so you can get the most out of it!',
        icon: Icons.waving_hand,
      ),
      TourStep(
        section: TourSection.dashboardOverview,
        title: 'Your Dashboard',
        message:
            'This is your command center. You can see your estate health, active blocks, harvest status, and alerts at a glance.',
        targetKey: heroCardKey,
        icon: Icons.dashboard_outlined,
      ),
      TourStep(
        section: TourSection.dataIngestion,
        title: 'Live Sensor Data',
        message:
            'Real-time environmental data from your IoT sensors — temperature, humidity, and air quality — streams directly to your dashboard.',
        targetKey: metricsKey,
        icon: Icons.sensors,
      ),
      TourStep(
        section: TourSection.processingPipeline,
        title: 'AI-Powered Analysis',
        message:
            'Use our quick actions to scan leaves for diseases, check maturity stages, grade tea powder quality, and monitor plant growth — all powered by AI.',
        targetKey: quickActionsKey,
        icon: Icons.auto_awesome,
      ),
      TourStep(
        section: TourSection.monitoring,
        title: 'Smart Alerts',
        message:
            'Stay informed with real-time alerts about disease risks, harvest reminders, and environmental anomalies from your plantation.',
        targetKey: alertsKey,
        icon: Icons.notifications_active_outlined,
      ),
      TourStep(
        section: TourSection.reports,
        title: 'Reports & History',
        message:
            'Access detailed PDF reports of all your scans, track detection history, and export data for record-keeping.',
        routePath: '/reports',
        icon: Icons.description_outlined,
      ),
      TourStep(
        section: TourSection.settings,
        title: 'Settings & Preferences',
        message:
            'Customize your experience — language preferences, notification settings, IoT device management, and biometric security.',
        routePath: '/settings',
        icon: Icons.settings_outlined,
      ),
      TourStep(
        section: TourSection.userManagement,
        title: 'You\'re All Set!',
        message:
            'That\'s the tour! Tap the floating button anytime to chat with me for help. Happy tea growing!',
        icon: Icons.celebration_outlined,
      ),
    ];
  }
}
