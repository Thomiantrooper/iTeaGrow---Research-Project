import 'package:flutter/material.dart';

/// Tea Plantation Animation System
/// Organic, nature-inspired motion curves and durations
class TeaAnimations {
  TeaAnimations._();

  // ═══════════════════════════════════════════════════════════════════════════
  // DURATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Instant feedback (100ms)
  static const Duration instant = Duration(milliseconds: 100);

  /// Fast transitions (200ms)
  static const Duration fast = Duration(milliseconds: 200);

  /// Normal transitions (300ms)
  static const Duration normal = Duration(milliseconds: 300);

  /// Slow, deliberate transitions (500ms)
  static const Duration slow = Duration(milliseconds: 500);

  /// Dramatic, attention-grabbing (800ms)
  static const Duration dramatic = Duration(milliseconds: 800);

  /// Very slow, ambient animations (1200ms)
  static const Duration ambient = Duration(milliseconds: 1200);

  /// Extended animations (2000ms)
  static const Duration extended = Duration(milliseconds: 2000);

  // ═══════════════════════════════════════════════════════════════════════════
  // CURVES (Organic feel)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Standard enter curve - elements appearing
  static const Curve enter = Curves.easeOutCubic;

  /// Standard exit curve - elements disappearing
  static const Curve exit = Curves.easeInCubic;

  /// Emphasis curve - drawing attention
  static const Curve emphasis = Curves.easeInOutCubic;

  /// Bounce effect - playful feedback
  static const Curve bounce = Curves.elasticOut;

  /// Spring effect - natural physics
  static const Curve spring = Curves.easeOutBack;

  /// Decelerate - coming to rest
  static const Curve decelerate = Curves.decelerate;

  /// Accelerate - starting movement
  static const Curve accelerate = Curves.easeIn;

  /// Linear - constant speed
  static const Curve linear = Curves.linear;

  /// Overshoot - goes past target then settles
  static const Curve overshoot = Curves.easeOutBack;

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE TRANSITIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fade and slide up transition
  static Widget fadeSlideUp({
    required Widget child,
    required Animation<double> animation,
    double offset = 20,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, offset / 100),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: enter,
        )),
        child: child,
      ),
    );
  }

  /// Fade and slide from right
  static Widget fadeSlideRight({
    required Widget child,
    required Animation<double> animation,
    double offset = 30,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(offset / 100, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: enter,
        )),
        child: child,
      ),
    );
  }

  /// Scale and fade transition
  static Widget scaleFade({
    required Widget child,
    required Animation<double> animation,
    double beginScale = 0.95,
  }) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: beginScale,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: enter,
        )),
        child: child,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAGGERED ANIMATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate delay for staggered animations
  static Duration staggerDelay(int index, {Duration base = const Duration(milliseconds: 50)}) {
    return Duration(milliseconds: base.inMilliseconds * index);
  }

  /// Get interval for staggered animation
  static Interval staggerInterval(
    int index,
    int total, {
    double overlap = 0.4,
  }) {
    final start = (index / total) * (1 - overlap);
    final end = start + overlap + ((1 - overlap) / total);
    return Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: enter);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO ANIMATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Custom hero flight shuttle builder
  static Widget heroFlightShuttle(
    BuildContext context,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: toContext.widget,
    );
  }
}

/// Custom page route with Tea-themed transitions
class TeaPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final TeaPageTransition transition;

  TeaPageRoute({
    required this.page,
    this.transition = TeaPageTransition.fadeSlideUp,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: TeaAnimations.normal,
          reverseTransitionDuration: TeaAnimations.fast,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (transition) {
              case TeaPageTransition.fadeSlideUp:
                return TeaAnimations.fadeSlideUp(
                  child: child,
                  animation: animation,
                );
              case TeaPageTransition.fadeSlideRight:
                return TeaAnimations.fadeSlideRight(
                  child: child,
                  animation: animation,
                );
              case TeaPageTransition.scaleFade:
                return TeaAnimations.scaleFade(
                  child: child,
                  animation: animation,
                );
              case TeaPageTransition.fade:
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
            }
          },
        );
}

/// Page transition types
enum TeaPageTransition {
  fadeSlideUp,
  fadeSlideRight,
  scaleFade,
  fade,
}

/// Animated list item wrapper
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration? delay;
  final Duration? duration;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration ?? TeaAnimations.normal,
      curve: TeaAnimations.enter,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Breathing animation for ambient effects
class BreathingAnimation extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const BreathingAnimation({
    super.key,
    required this.child,
    this.minScale = 0.98,
    this.maxScale = 1.02,
    this.duration = const Duration(milliseconds: 3000),
  });

  @override
  State<BreathingAnimation> createState() => _BreathingAnimationState();
}

class _BreathingAnimationState extends State<BreathingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Fade in on scroll animation
class FadeOnScroll extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final double fadeStart;
  final double fadeEnd;

  const FadeOnScroll({
    super.key,
    required this.child,
    required this.scrollController,
    this.fadeStart = 0,
    this.fadeEnd = 100,
  });

  @override
  State<FadeOnScroll> createState() => _FadeOnScrollState();
}

class _FadeOnScrollState extends State<FadeOnScroll> {
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = widget.scrollController.offset;
    final opacity = 1 -
        ((offset - widget.fadeStart) / (widget.fadeEnd - widget.fadeStart))
            .clamp(0.0, 1.0);
    if (opacity != _opacity) {
      setState(() => _opacity = opacity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _opacity,
      child: widget.child,
    );
  }
}
