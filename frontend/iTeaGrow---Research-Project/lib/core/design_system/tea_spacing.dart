import 'package:flutter/material.dart';

/// Tea Plantation Spacing System
/// Consistent spacing based on 8px grid
class TeaSpacing {
  TeaSpacing._();

  // ═══════════════════════════════════════════════════════════════════════════
  // BASE UNIT
  // ═══════════════════════════════════════════════════════════════════════════

  static const double unit = 8.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING VALUES
  // ═══════════════════════════════════════════════════════════════════════════

  /// 2px - Micro spacing
  static const double xxs = 2.0;

  /// 4px - Extra small spacing
  static const double xs = 4.0;

  /// 8px - Small spacing (1 unit)
  static const double sm = 8.0;

  /// 12px - Small-medium spacing
  static const double smd = 12.0;

  /// 16px - Medium spacing (2 units)
  static const double md = 16.0;

  /// 20px - Medium-large spacing
  static const double mld = 20.0;

  /// 24px - Large spacing (3 units)
  static const double lg = 24.0;

  /// 32px - Extra large spacing (4 units)
  static const double xl = 32.0;

  /// 40px - 2X large spacing (5 units)
  static const double xxl = 40.0;

  /// 48px - 3X large spacing (6 units)
  static const double xxxl = 48.0;

  /// 64px - Huge spacing (8 units)
  static const double huge = 64.0;

  /// 80px - Massive spacing (10 units)
  static const double massive = 80.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN PADDING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Standard screen horizontal padding
  static const double screenHorizontal = 16.0;

  /// Standard screen vertical padding
  static const double screenVertical = 24.0;

  /// Screen padding EdgeInsets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
    vertical: screenVertical,
  );

  /// Screen padding horizontal only
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // CARD PADDING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Small card padding
  static const EdgeInsets cardPaddingSm = EdgeInsets.all(sm);

  /// Medium card padding
  static const EdgeInsets cardPaddingMd = EdgeInsets.all(md);

  /// Large card padding
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(lg);

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPONENT SPACING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Space between icon and text
  static const double iconTextGap = 8.0;

  /// Space between list items
  static const double listItemGap = 12.0;

  /// Space between sections
  static const double sectionGap = 24.0;

  /// Space between cards in a grid
  static const double cardGap = 16.0;

  /// Space between form fields
  static const double formFieldGap = 16.0;

  /// Space between buttons
  static const double buttonGap = 12.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT MAX WIDTHS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Max width for mobile screens
  static const double mobileMaxWidth = 428.0;

  /// Max width for tablet screens
  static const double tabletMaxWidth = 834.0;

  /// Max width for desktop content
  static const double desktopMaxWidth = 1200.0;

  /// Max width for forms
  static const double formMaxWidth = 400.0;

  /// Max width for cards
  static const double cardMaxWidth = 360.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // SAFE AREA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bottom navigation bar height
  static const double bottomNavHeight = 80.0;

  /// App bar height
  static const double appBarHeight = 56.0;

  /// Floating action button margin
  static const double fabMargin = 16.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get EdgeInsets with all sides
  static EdgeInsets all(double value) => EdgeInsets.all(value);

  /// Get EdgeInsets with horizontal and vertical
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);

  /// Get EdgeInsets with only specific sides
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);

  /// Vertical spacer widget
  static SizedBox vertical(double height) => SizedBox(height: height);

  /// Horizontal spacer widget
  static SizedBox horizontal(double width) => SizedBox(width: width);

  /// Gap widgets for common sizes
  static const SizedBox gapXxs = SizedBox(height: xxs);
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl);

  /// Horizontal gap widgets
  static const SizedBox hGapXxs = SizedBox(width: xxs);
  static const SizedBox hGapXs = SizedBox(width: xs);
  static const SizedBox hGapSm = SizedBox(width: sm);
  static const SizedBox hGapMd = SizedBox(width: md);
  static const SizedBox hGapLg = SizedBox(width: lg);
  static const SizedBox hGapXl = SizedBox(width: xl);
}
