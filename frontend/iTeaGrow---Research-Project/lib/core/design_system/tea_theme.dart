import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tea_colors.dart';
import 'tea_typography.dart';
import 'tea_spacing.dart';
import 'tea_radius.dart';

/// Tea Plantation Theme
/// Premium, nature-inspired Material 3 theme
class TeaTheme {
  TeaTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: TeaColors.freshLeaf,
        onPrimary: TeaColors.white,
        primaryContainer: TeaColors.leafPale,
        onPrimaryContainer: TeaColors.matureLeaf,
        secondary: TeaColors.goldenSunlight,
        onSecondary: TeaColors.nearBlack,
        secondaryContainer: TeaColors.dawnPeach,
        onSecondaryContainer: TeaColors.richSoil,
        tertiary: TeaColors.richSoil,
        onTertiary: TeaColors.white,
        tertiaryContainer: TeaColors.clayPot,
        surface: TeaColors.white,
        onSurface: TeaColors.nearBlack,
        surfaceContainerHighest: TeaColors.mistGreen,
        error: TeaColors.alertRust,
        onError: TeaColors.white,
        outline: TeaColors.lightGray,
        outlineVariant: TeaColors.mediumGray,
      ),

      // Scaffold
      scaffoldBackgroundColor: TeaColors.mistGreen,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: TeaColors.white,
        foregroundColor: TeaColors.nearBlack,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        titleTextStyle: TeaTypography.titleLarge,
        iconTheme: const IconThemeData(color: TeaColors.nearBlack),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.bottomLg,
        ),
        shadowColor: TeaColors.shadowVale,
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: TeaColors.white,
        elevation: 0,
        shadowColor: TeaColors.shadowVale,
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.radiusLg,
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TeaColors.freshLeaf,
          foregroundColor: TeaColors.white,
          disabledBackgroundColor: TeaColors.lightGray,
          disabledForegroundColor: TeaColors.darkGray,
          elevation: 0,
          shadowColor: TeaColors.freshLeaf.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(
            horizontal: TeaSpacing.lg,
            vertical: TeaSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: TeaRadius.radiusMd,
          ),
          textStyle: TeaTypography.buttonMedium,
          minimumSize: const Size(88, 48),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TeaColors.freshLeaf,
          disabledForegroundColor: TeaColors.mediumGray,
          side: const BorderSide(color: TeaColors.freshLeaf, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: TeaSpacing.lg,
            vertical: TeaSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: TeaRadius.radiusMd,
          ),
          textStyle: TeaTypography.buttonMedium.copyWith(
            color: TeaColors.freshLeaf,
          ),
          minimumSize: const Size(88, 48),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TeaColors.freshLeaf,
          disabledForegroundColor: TeaColors.mediumGray,
          padding: const EdgeInsets.symmetric(
            horizontal: TeaSpacing.md,
            vertical: TeaSpacing.sm,
          ),
          textStyle: TeaTypography.buttonMedium.copyWith(
            color: TeaColors.freshLeaf,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: TeaRadius.radiusSm,
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: TeaColors.freshLeaf,
        foregroundColor: TeaColors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.radiusLg,
        ),
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: TeaSpacing.lg,
          vertical: TeaSpacing.md,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TeaColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TeaSpacing.md,
          vertical: TeaSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: const BorderSide(color: TeaColors.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: const BorderSide(color: TeaColors.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: const BorderSide(color: TeaColors.freshLeaf, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: const BorderSide(color: TeaColors.alertRust),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: const BorderSide(color: TeaColors.alertRust, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: const BorderSide(color: TeaColors.lightGray),
        ),
        labelStyle: TeaTypography.labelLarge.copyWith(
          color: TeaColors.darkGray,
        ),
        hintStyle: TeaTypography.bodyMedium.copyWith(
          color: TeaColors.mediumGray,
        ),
        errorStyle: TeaTypography.labelSmall.copyWith(
          color: TeaColors.alertRust,
        ),
        helperStyle: TeaTypography.labelSmall.copyWith(
          color: TeaColors.darkGray,
        ),
        prefixIconColor: TeaColors.darkGray,
        suffixIconColor: TeaColors.darkGray,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: TeaColors.white,
        selectedItemColor: TeaColors.freshLeaf,
        unselectedItemColor: TeaColors.mediumGray,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: TeaColors.white,
        indicatorColor: TeaColors.leafPale,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TeaTypography.labelSmall.copyWith(
              color: TeaColors.freshLeaf,
              fontWeight: FontWeight.w600,
            );
          }
          return TeaTypography.labelSmall.copyWith(
            color: TeaColors.darkGray,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: TeaColors.freshLeaf,
              size: 24,
            );
          }
          return const IconThemeData(
            color: TeaColors.darkGray,
            size: 24,
          );
        }),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: TeaColors.leafPale,
        selectedColor: TeaColors.freshLeaf,
        disabledColor: TeaColors.lightGray,
        labelStyle: TeaTypography.labelMedium,
        secondaryLabelStyle: TeaTypography.labelMedium.copyWith(
          color: TeaColors.white,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: TeaSpacing.sm,
          vertical: TeaSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.radiusRound,
        ),
        side: BorderSide.none,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: TeaColors.lightGray,
        thickness: 1,
        space: TeaSpacing.md,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: TeaColors.freshLeaf,
        linearTrackColor: TeaColors.leafPale,
        circularTrackColor: TeaColors.leafPale,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TeaColors.nearBlack,
        contentTextStyle: TeaTypography.bodyMedium.copyWith(
          color: TeaColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.radiusMd,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        actionTextColor: TeaColors.goldenSunlight,
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: TeaColors.white,
        elevation: 8,
        shadowColor: TeaColors.shadowVale,
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.radiusXl,
        ),
        titleTextStyle: TeaTypography.headlineSmall,
        contentTextStyle: TeaTypography.bodyMedium,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: TeaColors.white,
        elevation: 8,
        shadowColor: TeaColors.shadowVale,
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.topXxl,
        ),
        modalBackgroundColor: TeaColors.white,
        modalElevation: 8,
        dragHandleColor: TeaColors.mediumGray,
        dragHandleSize: const Size(40, 4),
      ),

      // Drawer Theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: TeaColors.white,
        elevation: 16,
        shadowColor: TeaColors.shadowVale,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(TeaRadius.xl),
          ),
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarTheme(
        labelColor: TeaColors.freshLeaf,
        unselectedLabelColor: TeaColors.darkGray,
        labelStyle: TeaTypography.labelLarge,
        unselectedLabelStyle: TeaTypography.labelLarge,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: TeaColors.freshLeaf,
            width: 3,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: TeaColors.freshLeaf,
        inactiveTrackColor: TeaColors.leafPale,
        thumbColor: TeaColors.freshLeaf,
        overlayColor: TeaColors.freshLeaf.withOpacity(0.12),
        valueIndicatorColor: TeaColors.freshLeaf,
        valueIndicatorTextStyle: TeaTypography.labelMedium.copyWith(
          color: TeaColors.white,
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TeaColors.freshLeaf;
          }
          return TeaColors.mediumGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TeaColors.leafPale;
          }
          return TeaColors.lightGray;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TeaColors.freshLeaf;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(TeaColors.white),
        side: const BorderSide(color: TeaColors.mediumGray, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.radiusXs,
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TeaColors.freshLeaf;
          }
          return TeaColors.mediumGray;
        }),
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: TeaColors.nearBlack,
          borderRadius: TeaRadius.radiusSm,
        ),
        textStyle: TeaTypography.labelSmall.copyWith(
          color: TeaColors.white,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: TeaSpacing.sm,
          vertical: TeaSpacing.xs,
        ),
      ),

      // Date Picker Theme
      datePickerTheme: DatePickerThemeData(
        backgroundColor: TeaColors.white,
        headerBackgroundColor: TeaColors.freshLeaf,
        headerForegroundColor: TeaColors.white,
        dayStyle: TeaTypography.bodyMedium,
        yearStyle: TeaTypography.bodyMedium,
        weekdayStyle: TeaTypography.labelSmall,
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.radiusXl,
        ),
      ),

      // Time Picker Theme
      timePickerTheme: TimePickerThemeData(
        backgroundColor: TeaColors.white,
        hourMinuteColor: TeaColors.leafPale,
        hourMinuteTextColor: TeaColors.nearBlack,
        dialBackgroundColor: TeaColors.leafPale,
        dialHandColor: TeaColors.freshLeaf,
        dialTextColor: TeaColors.nearBlack,
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.radiusXl,
        ),
      ),

      // Typography
      textTheme: TeaTypography.textTheme,
      fontFamily: TeaTypography.primaryFont,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: TeaColors.leafLight,
        onPrimary: TeaColors.darkBackground,
        primaryContainer: TeaColors.matureLeaf,
        onPrimaryContainer: TeaColors.leafPale,
        secondary: TeaColors.goldenSunlight,
        onSecondary: TeaColors.darkBackground,
        secondaryContainer: TeaColors.richSoil,
        onSecondaryContainer: TeaColors.dawnPeach,
        tertiary: TeaColors.clayPot,
        onTertiary: TeaColors.white,
        surface: TeaColors.darkSurface,
        onSurface: TeaColors.white,
        surfaceContainerHighest: TeaColors.darkCard,
        error: TeaColors.alertRust,
        onError: TeaColors.white,
        outline: TeaColors.darkBorder,
        outlineVariant: TeaColors.darkGray,
      ),

      // Scaffold
      scaffoldBackgroundColor: TeaColors.darkBackground,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: TeaColors.darkSurface,
        foregroundColor: TeaColors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        titleTextStyle: TeaTypography.titleLarge.copyWith(
          color: TeaColors.white,
        ),
        iconTheme: const IconThemeData(color: TeaColors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.bottomLg,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: TeaColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.radiusLg,
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TeaColors.leafLight,
          foregroundColor: TeaColors.darkBackground,
          disabledBackgroundColor: TeaColors.darkBorder,
          disabledForegroundColor: TeaColors.darkGray,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: TeaSpacing.lg,
            vertical: TeaSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: TeaRadius.radiusMd,
          ),
          textStyle: TeaTypography.buttonMedium,
          minimumSize: const Size(88, 48),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TeaColors.leafLight,
          side: const BorderSide(color: TeaColors.leafLight, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: TeaSpacing.lg,
            vertical: TeaSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: TeaRadius.radiusMd,
          ),
          minimumSize: const Size(88, 48),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TeaColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TeaSpacing.md,
          vertical: TeaSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: const BorderSide(color: TeaColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: const BorderSide(color: TeaColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: const BorderSide(color: TeaColors.leafLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: TeaRadius.radiusMd,
          borderSide: const BorderSide(color: TeaColors.alertRust),
        ),
        labelStyle: TeaTypography.labelLarge.copyWith(
          color: TeaColors.mediumGray,
        ),
        hintStyle: TeaTypography.bodyMedium.copyWith(
          color: TeaColors.darkGray,
        ),
        errorStyle: TeaTypography.labelSmall.copyWith(
          color: TeaColors.alertRust,
        ),
        prefixIconColor: TeaColors.mediumGray,
        suffixIconColor: TeaColors.mediumGray,
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: TeaColors.darkSurface,
        indicatorColor: TeaColors.matureLeaf,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TeaTypography.labelSmall.copyWith(
              color: TeaColors.leafLight,
              fontWeight: FontWeight.w600,
            );
          }
          return TeaTypography.labelSmall.copyWith(
            color: TeaColors.mediumGray,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: TeaColors.leafLight,
              size: 24,
            );
          }
          return const IconThemeData(
            color: TeaColors.mediumGray,
            size: 24,
          );
        }),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: TeaColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.topXxl,
        ),
        modalBackgroundColor: TeaColors.darkSurface,
        dragHandleColor: TeaColors.darkBorder,
        dragHandleSize: const Size(40, 4),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: TeaColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.radiusXl,
        ),
        titleTextStyle: TeaTypography.headlineSmall.copyWith(
          color: TeaColors.white,
        ),
        contentTextStyle: TeaTypography.bodyMedium.copyWith(
          color: TeaColors.white,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TeaColors.darkCard,
        contentTextStyle: TeaTypography.bodyMedium.copyWith(
          color: TeaColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.radiusMd,
        ),
        behavior: SnackBarBehavior.floating,
        actionTextColor: TeaColors.goldenSunlight,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: TeaColors.darkBorder,
        thickness: 1,
        space: TeaSpacing.md,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: TeaColors.leafLight,
        linearTrackColor: TeaColors.darkBorder,
        circularTrackColor: TeaColors.darkBorder,
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge:
            TeaTypography.displayLarge.copyWith(color: TeaColors.white),
        displayMedium:
            TeaTypography.displayMedium.copyWith(color: TeaColors.white),
        displaySmall:
            TeaTypography.displaySmall.copyWith(color: TeaColors.white),
        headlineLarge:
            TeaTypography.headlineLarge.copyWith(color: TeaColors.white),
        headlineMedium:
            TeaTypography.headlineMedium.copyWith(color: TeaColors.white),
        headlineSmall:
            TeaTypography.headlineSmall.copyWith(color: TeaColors.white),
        titleLarge: TeaTypography.titleLarge.copyWith(color: TeaColors.white),
        titleMedium: TeaTypography.titleMedium.copyWith(color: TeaColors.white),
        titleSmall: TeaTypography.titleSmall.copyWith(color: TeaColors.white),
        bodyLarge: TeaTypography.bodyLarge.copyWith(color: TeaColors.white),
        bodyMedium: TeaTypography.bodyMedium.copyWith(color: TeaColors.white),
        bodySmall:
            TeaTypography.bodySmall.copyWith(color: TeaColors.mediumGray),
        labelLarge: TeaTypography.labelLarge.copyWith(color: TeaColors.white),
        labelMedium:
            TeaTypography.labelMedium.copyWith(color: TeaColors.mediumGray),
        labelSmall:
            TeaTypography.labelSmall.copyWith(color: TeaColors.mediumGray),
      ),
      fontFamily: TeaTypography.primaryFont,
    );
  }
}
