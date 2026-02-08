import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../design_system/design_system.dart';

/// Loading indicator styles
enum TeaLoadingStyle {
  circular,
  linear,
  dots,
  leaf,
}

/// Premium Loading Widget
class TeaLoading extends StatelessWidget {
  final TeaLoadingStyle style;
  final String? message;
  final double size;
  final Color? color;

  const TeaLoading({
    super.key,
    this.style = TeaLoadingStyle.circular,
    this.message,
    this.size = 40,
    this.color,
  });

  factory TeaLoading.circular({
    String? message,
    double size = 40,
    Color? color,
  }) {
    return TeaLoading(
      style: TeaLoadingStyle.circular,
      message: message,
      size: size,
      color: color,
    );
  }

  factory TeaLoading.dots({
    String? message,
    Color? color,
  }) {
    return TeaLoading(
      style: TeaLoadingStyle.dots,
      message: message,
      color: color,
    );
  }

  factory TeaLoading.leaf({
    String? message,
    double size = 60,
  }) {
    return TeaLoading(
      style: TeaLoadingStyle.leaf,
      message: message,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLoader(),
        if (message != null) ...[
          const SizedBox(height: TeaSpacing.md),
          Text(
            message!,
            style: TeaTypography.bodyMedium.copyWith(
              color: TeaColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildLoader() {
    switch (style) {
      case TeaLoadingStyle.circular:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(
              color ?? TeaColors.freshLeaf,
            ),
          ),
        );

      case TeaLoadingStyle.linear:
        return SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            minHeight: 4,
            backgroundColor: TeaColors.leafPale,
            valueColor: AlwaysStoppedAnimation(
              color ?? TeaColors.freshLeaf,
            ),
          ),
        );

      case TeaLoadingStyle.dots:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color ?? TeaColors.freshLeaf,
                shape: BoxShape.circle,
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(0.5, 0.5),
                  duration: 600.ms,
                  delay: Duration(milliseconds: index * 150),
                )
                .then()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                );
          }),
        );

      case TeaLoadingStyle.leaf:
        return SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.eco,
            size: size,
            color: color ?? TeaColors.freshLeaf,
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .rotate(
                begin: 0,
                end: 1,
                duration: 2000.ms,
                curve: Curves.easeInOut,
              )
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 1000.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.2, 1.2),
                end: const Offset(1, 1),
                duration: 1000.ms,
              ),
        );
    }
  }
}

/// Full screen loading overlay
class TeaLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;

  const TeaLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: backgroundColor ?? TeaColors.white.withOpacity(0.8),
              child: Center(
                child: TeaLoading.leaf(message: message),
              ),
            ),
          ).animate().fadeIn(duration: 200.ms),
      ],
    );
  }
}

/// Empty State Widget
class TeaEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TeaEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  factory TeaEmptyState.noData({
    String title = 'No data yet',
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return TeaEmptyState(
      title: title,
      message: message ?? 'Start by adding some data',
      icon: Icons.folder_open_outlined,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory TeaEmptyState.noResults({
    String title = 'No results found',
    String? message,
    VoidCallback? onClear,
  }) {
    return TeaEmptyState(
      title: title,
      message: message ?? 'Try adjusting your search or filters',
      icon: Icons.search_off_outlined,
      actionLabel: onClear != null ? 'Clear Filters' : null,
      onAction: onClear,
    );
  }

  factory TeaEmptyState.noConnection({
    String title = 'No connection',
    String? message,
    VoidCallback? onRetry,
  }) {
    return TeaEmptyState(
      title: title,
      message: message ?? 'Check your internet connection and try again',
      icon: Icons.wifi_off_outlined,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: TeaSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(TeaSpacing.lg),
              decoration: BoxDecoration(
                color: TeaColors.leafPale,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: TeaColors.freshLeaf.withOpacity(0.7),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            const SizedBox(height: TeaSpacing.lg),
            Text(
              title,
              style: TeaTypography.headlineSmall.copyWith(
                color: TeaColors.nearBlack,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            if (message != null) ...[
              const SizedBox(height: TeaSpacing.sm),
              Text(
                message!,
                style: TeaTypography.bodyMedium.copyWith(
                  color: TeaColors.darkGray,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: TeaSpacing.xl),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error State Widget
class TeaErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final VoidCallback? onRetry;

  const TeaErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
  });

  factory TeaErrorState.network({VoidCallback? onRetry}) {
    return TeaErrorState(
      title: 'No connection',
      message: 'Check your internet connection and try again',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }

  factory TeaErrorState.server({VoidCallback? onRetry}) {
    return TeaErrorState(
      title: 'Server error',
      message: 'We\'re working on fixing this. Please try again later.',
      icon: Icons.cloud_off,
      onRetry: onRetry,
    );
  }

  factory TeaErrorState.notFound() {
    return const TeaErrorState(
      title: 'Not found',
      message: 'The item you\'re looking for doesn\'t exist',
      icon: Icons.search_off,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: TeaSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(TeaSpacing.lg),
              decoration: BoxDecoration(
                color: TeaColors.alertRust.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: TeaColors.alertRust,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .shake(delay: 200.ms, duration: 500.ms, hz: 2),
            const SizedBox(height: TeaSpacing.lg),
            Text(
              title,
              style: TeaTypography.headlineSmall.copyWith(
                color: TeaColors.nearBlack,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            if (message != null) ...[
              const SizedBox(height: TeaSpacing.sm),
              Text(
                message!,
                style: TeaTypography.bodyMedium.copyWith(
                  color: TeaColors.darkGray,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: TeaSpacing.xl),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success State Widget
class TeaSuccessState extends StatelessWidget {
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TeaSuccessState({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: TeaSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(TeaSpacing.lg),
              decoration: BoxDecoration(
                color: TeaColors.healthyGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: TeaColors.healthyGreen,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0, 0), end: const Offset(1, 1)),
            const SizedBox(height: TeaSpacing.lg),
            Text(
              title,
              style: TeaTypography.headlineSmall.copyWith(
                color: TeaColors.nearBlack,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            if (message != null) ...[
              const SizedBox(height: TeaSpacing.sm),
              Text(
                message!,
                style: TeaTypography.bodyMedium.copyWith(
                  color: TeaColors.darkGray,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: TeaSpacing.xl),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}

/// Snackbar helper
class TeaSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: TeaColors.white, size: 20),
              const SizedBox(width: TeaSpacing.sm),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor ?? TeaColors.nearBlack,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: TeaRadius.radiusMd,
        ),
        margin: TeaSpacing.screenPaddingHorizontal,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction,
                textColor: TeaColors.goldenSunlight,
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: TeaColors.healthyGreen,
      icon: Icons.check_circle_outline,
    );
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: TeaColors.alertRust,
      icon: Icons.error_outline,
    );
  }

  static void warning(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: TeaColors.warningAmber,
      icon: Icons.warning_amber_outlined,
    );
  }

  static void info(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: TeaColors.infoSky,
      icon: Icons.info_outline,
    );
  }
}
