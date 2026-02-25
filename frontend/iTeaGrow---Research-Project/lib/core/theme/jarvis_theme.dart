import 'package:flutter/material.dart';

/// Jarvis-Inspired Tea Plantation Theme
/// Calm, pleasant colors: tea-green, earthy brown, soft gold, mist white
class JarvisTheme {
  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY COLORS - Tea Plantation Palette
  // ═══════════════════════════════════════════════════════════════════════════

  // Tea Green - Primary brand color
  static const Color teaGreen = Color(0xFF3D8B40);
  static const Color teaGreenLight = Color(0xFF6ABF69);
  static const Color teaGreenDark = Color(0xFF1B5E20);
  static const Color teaGreenMuted = Color(0xFF81C784);

  // Earthy Brown - Secondary grounding color
  static const Color earthyBrown = Color(0xFF6D4C41);
  static const Color earthyBrownLight = Color(0xFF8D6E63);
  static const Color earthyBrownDark = Color(0xFF4E342E);

  // Soft Gold - Accent for highlights
  static const Color softGold = Color(0xFFD4A574);
  static const Color softGoldLight = Color(0xFFE8C9A0);
  static const Color softGoldDark = Color(0xFFB8860B);
  static const Color softGoldAccent = Color(0xFFFFC107);

  // Mist White - Background and surfaces
  static const Color mistWhite = Color(0xFFF8FAF8);
  static const Color mistWhitePure = Color(0xFFFFFFFF);
  static const Color mistGray = Color(0xFFECF0EC);

  // ═══════════════════════════════════════════════════════════════════════════
  // JARVIS UI COLORS - Futuristic Elements
  // ═══════════════════════════════════════════════════════════════════════════

  // Hologram effects
  static const Color hologramBlue = Color(0xFF00D4FF);
  static const Color hologramCyan = Color(0xFF00F5D4);
  static const Color hologramGreen = Color(0xFF00FF88);

  // Glow effects
  static const Color glowPrimary = Color(0xFF4CAF50);
  static const Color glowSecondary = Color(0xFF00BCD4);
  static const Color glowAccent = Color(0xFFFFD54F);

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  // Status colors
  static const Color healthy = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color critical = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Disease indicator colors
  static const Color diseaseNone = healthy;
  static const Color diseaseLow = Color(0xFFCDDC39);
  static const Color diseaseMedium = warning;
  static const Color diseaseHigh = critical;

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color textPrimary = Color(0xFF2E3A2F);
  static const Color textSecondary = Color(0xFF5F6B5F);
  static const Color textMuted = Color(0xFF8A948A);
  static const Color textOnDark = Color(0xFFF5F5F5);
  static const Color textOnPrimary = Colors.white;

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTS - 3D & Depth Effects
  // ═══════════════════════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teaGreen, teaGreenDark],
  );

  static const LinearGradient hologramGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [hologramCyan, hologramBlue, hologramGreen],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mistWhitePure, mistGray],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [softGoldLight, softGold, softGoldDark],
  );

  static const RadialGradient glowGradient = RadialGradient(
    colors: [
      Color(0x4000FF88),
      Color(0x2000D4FF),
      Colors.transparent,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADOWS - 3D Depth
  // ═══════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: teaGreenDark.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: teaGreenDark.withOpacity(0.15),
          blurRadius: 30,
          offset: const Offset(0, 15),
          spreadRadius: -5,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: hologramGreen.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: hologramCyan.withOpacity(0.2),
          blurRadius: 40,
          spreadRadius: 5,
        ),
      ];

  static List<BoxShadow> statusGlow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ];

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════════════

  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusRound = 100.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING
  // ═══════════════════════════════════════════════════════════════════════════

  static const double spacingXxs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATION DURATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animVerySlow = Duration(milliseconds: 800);

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: teaGreen,
        onPrimary: textOnPrimary,
        primaryContainer: teaGreenLight,
        onPrimaryContainer: teaGreenDark,
        secondary: softGold,
        onSecondary: textPrimary,
        secondaryContainer: softGoldLight,
        onSecondaryContainer: earthyBrownDark,
        tertiary: earthyBrown,
        onTertiary: textOnDark,
        tertiaryContainer: earthyBrownLight,
        surface: mistWhite,
        onSurface: textPrimary,
        surfaceContainerHighest: mistGray,
        error: critical,
        onError: textOnPrimary,
      ),

      // Scaffold
      scaffoldBackgroundColor: mistWhite,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: teaGreen,
        foregroundColor: textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textOnPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(radiusLg),
          ),
        ),
      ),

      // Cards
      cardTheme: CardTheme(
        color: mistWhitePure,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        margin: const EdgeInsets.all(spacingSm),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: teaGreen,
          foregroundColor: textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: teaGreen,
          side: const BorderSide(color: teaGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: teaGreen,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: spacingSm,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: teaGreen,
        foregroundColor: textOnPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mistGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: teaGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: critical, width: 1),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: mistWhitePure,
        selectedItemColor: teaGreen,
        unselectedItemColor: textMuted,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: mistGray,
        selectedColor: teaGreenLight,
        labelStyle: const TextStyle(color: textPrimary),
        secondaryLabelStyle: const TextStyle(color: textOnPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSm,
          vertical: spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusRound),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: teaGreenMuted.withOpacity(0.2),
        thickness: 1,
        space: spacingMd,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: teaGreen,
        linearTrackColor: mistGray,
        circularTrackColor: mistGray,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: earthyBrownDark,
        contentTextStyle: const TextStyle(color: textOnDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: mistWhitePure,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: mistWhitePure,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXl),
          ),
        ),
      ),

      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
      ),

      // Font Family
      fontFamily: 'Poppins',
    );
  }

  // Dark theme for night mode
  static ThemeData get darkTheme {
    const darkBg = Color(0xFF1A1F1A);
    const darkSurface = Color(0xFF252B25);
    const darkCard = Color(0xFF2D332D);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: teaGreenLight,
        onPrimary: darkBg,
        primaryContainer: teaGreenDark,
        onPrimaryContainer: teaGreenLight,
        secondary: softGold,
        onSecondary: darkBg,
        tertiary: earthyBrownLight,
        surface: darkSurface,
        onSurface: textOnDark,
        error: critical,
      ),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: textOnDark,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(radiusLg),
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      fontFamily: 'Poppins',
    );
  }
}
