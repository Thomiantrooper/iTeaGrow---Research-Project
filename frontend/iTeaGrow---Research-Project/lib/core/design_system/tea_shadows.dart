import 'package:flutter/material.dart';
import 'tea_colors.dart';

/// Tea Plantation Shadow System
/// Depth and elevation through shadows
class TeaShadows {
  TeaShadows._();

  // ═══════════════════════════════════════════════════════════════════════════
  // ELEVATION LEVELS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ground level - no shadow
  static const double elevationGround = 0.0;

  /// Leaf level - slight elevation
  static const double elevationLeaf = 2.0;

  /// Branch level - medium elevation
  static const double elevationBranch = 4.0;

  /// Canopy level - high elevation (dialogs, sheets)
  static const double elevationCanopy = 8.0;

  /// Sky level - maximum elevation (floating elements)
  static const double elevationSky = 16.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // CARD SHADOWS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Subtle shadow for cards at rest
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: TeaColors.shadowVale,
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: TeaColors.shadowVale.withOpacity(0.5),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  /// Medium shadow for elevated cards
  static List<BoxShadow> get cardShadowMedium => [
    BoxShadow(
      color: TeaColors.shadowVale,
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: TeaColors.deepShadow,
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: -8,
    ),
  ];

  /// Strong shadow for highly elevated cards
  static List<BoxShadow> get cardShadowStrong => [
    BoxShadow(
      color: TeaColors.deepShadow,
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: TeaColors.deepShadow,
      blurRadius: 48,
      offset: const Offset(0, 20),
      spreadRadius: -8,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERACTIVE SHADOWS (For buttons, clickable elements)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Shadow for buttons at rest
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: TeaColors.freshLeaf.withOpacity(0.25),
      blurRadius: 8,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// Shadow for buttons on hover/press
  static List<BoxShadow> get buttonShadowActive => [
    BoxShadow(
      color: TeaColors.freshLeaf.withOpacity(0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  /// Shadow for buttons disabled
  static List<BoxShadow> get buttonShadowDisabled => [
    BoxShadow(
      color: TeaColors.shadowVale.withOpacity(0.5),
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // GLOW SHADOWS (For emphasis, status indicators)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Success glow
  static List<BoxShadow> get glowSuccess => [
    BoxShadow(
      color: TeaColors.healthyGreen.withOpacity(0.4),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  /// Warning glow
  static List<BoxShadow> get glowWarning => [
    BoxShadow(
      color: TeaColors.warningAmber.withOpacity(0.4),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  /// Error glow
  static List<BoxShadow> get glowError => [
    BoxShadow(
      color: TeaColors.alertRust.withOpacity(0.4),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  /// Info glow
  static List<BoxShadow> get glowInfo => [
    BoxShadow(
      color: TeaColors.infoSky.withOpacity(0.4),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  /// Primary glow (tea green)
  static List<BoxShadow> get glowPrimary => [
    BoxShadow(
      color: TeaColors.freshLeaf.withOpacity(0.4),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  /// Golden glow
  static List<BoxShadow> get glowGolden => [
    BoxShadow(
      color: TeaColors.goldenSunlight.withOpacity(0.4),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // INNER SHADOWS (For depth effects)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inner shadow for input fields
  static List<BoxShadow> get innerShadow => [
    const BoxShadow(
      color: Color(0x10000000),
      blurRadius: 4,
      offset: Offset(0, 2),
      spreadRadius: -2,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get glow shadow for a specific color
  static List<BoxShadow> glow(Color color, {double intensity = 0.4}) => [
    BoxShadow(
      color: color.withOpacity(intensity),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  /// Get colored card shadow
  static List<BoxShadow> coloredCard(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.15),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: color.withOpacity(0.1),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  /// Combine multiple shadows
  static List<BoxShadow> combine(List<List<BoxShadow>> shadows) {
    return shadows.expand((list) => list).toList();
  }

  /// No shadow
  static List<BoxShadow> get none => [];
}
