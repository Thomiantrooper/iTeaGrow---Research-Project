import 'package:flutter/material.dart';

/// Tea Plantation Color System
/// Nature-inspired, calm, professional palette
class TeaColors {
  TeaColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE GREENS (Tea Leaves)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary brand color - Fresh young tea leaves
  static const Color freshLeaf = Color(0xFF4A7C59);

  /// Secondary - Mature tea bushes
  static const Color matureLeaf = Color(0xFF2D5A3D);

  /// Background - Morning mist over plantation
  static const Color mistGreen = Color(0xFFE8F0E9);

  /// Dark mode primary
  static const Color deepForest = Color(0xFF1A3D2B);

  /// Light variant
  static const Color leafLight = Color(0xFF6B9B7A);

  /// Very light for backgrounds
  static const Color leafPale = Color(0xFFF0F5F1);

  // ═══════════════════════════════════════════════════════════════════════════
  // WARM ACCENTS (Sunlight & Earth)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Accent color - Morning sunlight through leaves
  static const Color goldenSunlight = Color(0xFFD4A574);

  /// Soft highlight - Dawn glow
  static const Color dawnPeach = Color(0xFFF5E6D3);

  /// Earthy brown - Rich soil
  static const Color richSoil = Color(0xFF5D4037);

  /// Ceramic accent - Clay pot
  static const Color clayPot = Color(0xFF8B6F5C);

  /// Warm amber
  static const Color warmAmber = Color(0xFFE6A855);

  // ═══════════════════════════════════════════════════════════════════════════
  // FUNCTIONAL COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Success / Healthy plants
  static const Color healthyGreen = Color(0xFF66BB6A);

  /// Warning states
  static const Color warningAmber = Color(0xFFFFB74D);

  /// Error / Disease alert
  static const Color alertRust = Color(0xFFE57373);

  /// Critical / Severe
  static const Color criticalRed = Color(0xFFD32F2F);

  /// Information
  static const Color infoSky = Color(0xFF64B5F6);

  /// Pending / Processing
  static const Color pendingBlue = Color(0xFF42A5F5);

  // ═══════════════════════════════════════════════════════════════════════════
  // NEUTRAL COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pure white
  static const Color white = Color(0xFFFFFFFF);

  /// Off-white surface
  static const Color surface = Color(0xFFFAFAFA);

  /// Light gray for disabled states
  static const Color lightGray = Color(0xFFE0E0E0);

  /// Medium gray for borders
  static const Color mediumGray = Color(0xFFBDBDBD);

  /// Dark gray for secondary text
  static const Color darkGray = Color(0xFF757575);

  /// Near black for primary text
  static const Color nearBlack = Color(0xFF212121);

  // ═══════════════════════════════════════════════════════════════════════════
  // ATMOSPHERIC EFFECTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Glass overlay effect
  static const Color morningMist = Color(0x40FFFFFF);

  /// Subtle glass tint
  static const Color dewDrop = Color(0x20FFFFFF);

  /// Soft shadow color
  static const Color shadowVale = Color(0x15000000);

  /// Darker shadow
  static const Color deepShadow = Color(0x25000000);

  // ═══════════════════════════════════════════════════════════════════════════
  // 3D RENDERING ACCENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// 3D leaf highlight
  static const Color leafHighlight = Color(0xFF7CB342);

  /// 3D leaf shadow
  static const Color leafShadow = Color(0xFF33691E);

  /// 3D ambient light
  static const Color ambientLight = Color(0xFFFFF8E1);

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK MODE COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color darkBackground = Color(0xFF121A14);
  static const Color darkSurface = Color(0xFF1E2820);
  static const Color darkCard = Color(0xFF263228);
  static const Color darkBorder = Color(0xFF3A4A3E);

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [freshLeaf, matureLeaf],
  );

  static const LinearGradient sunlightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [dawnPeach, goldenSunlight],
  );

  static const LinearGradient mistGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [mistGreen, white],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [white, surface],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [healthyGreen, Color(0xFF43A047)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningAmber, Color(0xFFFFA726)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [alertRust, criticalRed],
  );

  static const RadialGradient glowGradient = RadialGradient(
    colors: [
      Color(0x30FFD54F),
      Color(0x15FFD54F),
      Colors.transparent,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get status color based on health percentage
  static Color getHealthColor(double health) {
    if (health >= 80) return healthyGreen;
    if (health >= 60) return leafLight;
    if (health >= 40) return warningAmber;
    if (health >= 20) return alertRust;
    return criticalRed;
  }

  /// Get disease severity color
  static Color getDiseaseColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'none':
      case 'healthy':
        return healthyGreen;
      case 'low':
        return Color(0xFFCDDC39);
      case 'medium':
      case 'moderate':
        return warningAmber;
      case 'high':
      case 'severe':
        return alertRust;
      case 'critical':
        return criticalRed;
      default:
        return mediumGray;
    }
  }

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}
