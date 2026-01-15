import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tea_colors.dart';

/// Tea Plantation Typography System
/// Elegant, readable, professional
class TeaTypography {
  TeaTypography._();

  // ═══════════════════════════════════════════════════════════════════════════
  // FONT FAMILIES
  // ═══════════════════════════════════════════════════════════════════════════

  static String get primaryFont => GoogleFonts.poppins().fontFamily!;
  static String get displayFont => GoogleFonts.playfairDisplay().fontFamily!;
  static String get monoFont => GoogleFonts.jetBrainsMono().fontFamily!;

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPLAY STYLES (Hero numbers, key metrics)
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    color: TeaColors.nearBlack,
    height: 1.1,
  );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: TeaColors.nearBlack,
    height: 1.2,
  );

  static TextStyle get displaySmall => GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    color: TeaColors.nearBlack,
    height: 1.2,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADLINE STYLES (Section titles)
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get headlineLarge => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: TeaColors.nearBlack,
    height: 1.3,
  );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    color: TeaColors.nearBlack,
    height: 1.3,
  );

  static TextStyle get headlineSmall => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: TeaColors.nearBlack,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TITLE STYLES (Card titles, list items)
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get titleLarge => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: TeaColors.nearBlack,
    height: 1.4,
  );

  static TextStyle get titleMedium => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: TeaColors.nearBlack,
    height: 1.4,
  );

  static TextStyle get titleSmall => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: TeaColors.nearBlack,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BODY STYLES (General content)
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    color: TeaColors.nearBlack,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: TeaColors.nearBlack,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: TeaColors.darkGray,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // LABEL STYLES (Form labels, captions, chips)
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get labelLarge => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: TeaColors.nearBlack,
    height: 1.4,
  );

  static TextStyle get labelMedium => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: TeaColors.darkGray,
    height: 1.4,
  );

  static TextStyle get labelSmall => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: TeaColors.darkGray,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA STYLES (Sensor readings, codes, numbers)
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get dataLarge => GoogleFonts.jetBrainsMono(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: TeaColors.nearBlack,
    height: 1.2,
  );

  static TextStyle get dataMedium => GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: TeaColors.nearBlack,
    height: 1.3,
  );

  static TextStyle get dataSmall => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: TeaColors.darkGray,
    height: 1.3,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BUTTON STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get buttonLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: TeaColors.white,
    height: 1.4,
  );

  static TextStyle get buttonMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: TeaColors.white,
    height: 1.4,
  );

  static TextStyle get buttonSmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: TeaColors.white,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SPECIAL STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  /// For metric values on dashboard
  static TextStyle get metricValue => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: TeaColors.freshLeaf,
    height: 1.1,
  );

  /// For metric labels
  static TextStyle get metricLabel => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: TeaColors.darkGray,
    height: 1.4,
  );

  /// For alert messages
  static TextStyle get alertText => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: TeaColors.alertRust,
    height: 1.4,
  );

  /// For success messages
  static TextStyle get successText => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: TeaColors.healthyGreen,
    height: 1.4,
  );

  /// For hints and helper text
  static TextStyle get hint => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: TeaColors.mediumGray,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Apply color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply weight to any text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Generate Material TextTheme
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
