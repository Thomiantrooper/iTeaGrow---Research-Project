import 'package:flutter/material.dart';

/// Tea Plantation Border Radius System
/// Consistent, organic border radius values
class TeaRadius {
  TeaRadius._();

  // ═══════════════════════════════════════════════════════════════════════════
  // RADIUS VALUES
  // ═══════════════════════════════════════════════════════════════════════════

  /// No radius
  static const double none = 0.0;

  /// 4px - Extra small (chips, small buttons)
  static const double xs = 4.0;

  /// 8px - Small (input fields, small cards)
  static const double sm = 8.0;

  /// 12px - Medium (standard cards)
  static const double md = 12.0;

  /// 16px - Large (prominent cards)
  static const double lg = 16.0;

  /// 20px - Extra large (sheets, modals)
  static const double xl = 20.0;

  /// 24px - 2X large (large sheets)
  static const double xxl = 24.0;

  /// 32px - Huge (hero cards)
  static const double huge = 32.0;

  /// Fully rounded (pills, avatars)
  static const double round = 100.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS OBJECTS
  // ═══════════════════════════════════════════════════════════════════════════

  static BorderRadius get radiusNone => BorderRadius.zero;

  static BorderRadius get radiusXs => BorderRadius.circular(xs);

  static BorderRadius get radiusSm => BorderRadius.circular(sm);

  static BorderRadius get radiusMd => BorderRadius.circular(md);

  static BorderRadius get radiusLg => BorderRadius.circular(lg);

  static BorderRadius get radiusXl => BorderRadius.circular(xl);

  static BorderRadius get radiusXxl => BorderRadius.circular(xxl);

  static BorderRadius get radiusHuge => BorderRadius.circular(huge);

  static BorderRadius get radiusRound => BorderRadius.circular(round);

  // ═══════════════════════════════════════════════════════════════════════════
  // SPECIAL RADIUS (Organic, asymmetric for natural feel)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Organic asymmetric radius for a natural feel
  static BorderRadius get organic => const BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(14),
    bottomLeft: Radius.circular(14),
    bottomRight: Radius.circular(16),
  );

  /// Organic large radius
  static BorderRadius get organicLarge => const BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(20),
    bottomLeft: Radius.circular(20),
    bottomRight: Radius.circular(24),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP ONLY RADIUS (For bottom sheets, app bars)
  // ═══════════════════════════════════════════════════════════════════════════

  static BorderRadius get topSm => const BorderRadius.vertical(
    top: Radius.circular(sm),
  );

  static BorderRadius get topMd => const BorderRadius.vertical(
    top: Radius.circular(md),
  );

  static BorderRadius get topLg => const BorderRadius.vertical(
    top: Radius.circular(lg),
  );

  static BorderRadius get topXl => const BorderRadius.vertical(
    top: Radius.circular(xl),
  );

  static BorderRadius get topXxl => const BorderRadius.vertical(
    top: Radius.circular(xxl),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM ONLY RADIUS (For app bars with rounded bottom)
  // ═══════════════════════════════════════════════════════════════════════════

  static BorderRadius get bottomSm => const BorderRadius.vertical(
    bottom: Radius.circular(sm),
  );

  static BorderRadius get bottomMd => const BorderRadius.vertical(
    bottom: Radius.circular(md),
  );

  static BorderRadius get bottomLg => const BorderRadius.vertical(
    bottom: Radius.circular(lg),
  );

  static BorderRadius get bottomXl => const BorderRadius.vertical(
    bottom: Radius.circular(xl),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create custom circular BorderRadius
  static BorderRadius circular(double radius) => BorderRadius.circular(radius);

  /// Create custom BorderRadius with different values
  static BorderRadius only({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) => BorderRadius.only(
    topLeft: Radius.circular(topLeft),
    topRight: Radius.circular(topRight),
    bottomLeft: Radius.circular(bottomLeft),
    bottomRight: Radius.circular(bottomRight),
  );

  /// Get shape border for Material components
  static RoundedRectangleBorder shape(double radius) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
  );
}
