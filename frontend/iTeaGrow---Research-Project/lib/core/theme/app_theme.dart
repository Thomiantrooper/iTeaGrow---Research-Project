import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette - Tea Plantation Theme
  static const Color primaryGreen = Color(0xFF2E7D32); // Deep green
  static const Color primaryGreenDark = Color(0xFF1B5E20);
  static const Color primaryGreenLight = Color(0xFF4CAF50);
  
  static const Color accentAmber = Color(0xFFF9A825); // User-specified Amber
  static const Color accentAmberLight = Color(0xFFFFA726);
  
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Status Colors
  static const Color statusGood = Color(0xFF4CAF50); // Green
  static const Color statusWarning = Color(0xFFFFA726); // Amber
  static const Color statusCritical = Color(0xFFEF5350); // Red
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: accentAmber,
        surface: surfaceLight,
        error: statusCritical,
        onPrimary: textOnPrimary,
        onSecondary: textOnPrimary,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: textOnPrimary,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
  
  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreenLight,
        secondary: accentAmberLight,
        surface: surfaceDark,
        error: statusCritical,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textOnPrimary,
      ),
      scaffoldBackgroundColor: backgroundDark,
    );
  }
  
  // Spacing Constants
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  
  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  
  // Touch Target Size
  static const double minTouchTarget = 48.0;
}
