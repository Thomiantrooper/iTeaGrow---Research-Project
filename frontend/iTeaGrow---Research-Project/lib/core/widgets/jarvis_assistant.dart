import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/jarvis_theme.dart';

/// Jarvis-style AI Assistant Widget with hologram effect
class JarvisAssistant extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;
  final String? message;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double size;

  const JarvisAssistant({
    super.key,
    this.isListening = false,
    this.isSpeaking = false,
    this.isProcessing = false,
    this.message,
    this.onTap,
    this.onLongPress,
    this.size = 80,
  });

  @override
  State<JarvisAssistant> createState() => _JarvisAssistantState();
}

class _JarvisAssistantState extends State<JarvisAssistant>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotate animation
    _rotateController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
    _rotateController.repeat();

    // Wave animation for listening
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _updateAnimations();
  }

  void _updateAnimations() {
    if (widget.isListening || widget.isSpeaking) {
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
    } else if (widget.isProcessing) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _waveController.stop();
    }
  }

  @override
  void didUpdateWidget(JarvisAssistant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isListening != widget.isListening ||
        oldWidget.isSpeaking != widget.isSpeaking ||
        oldWidget.isProcessing != widget.isProcessing) {
      _updateAnimations();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Color get _primaryColor {
    if (widget.isListening) return JarvisTheme.hologramCyan;
    if (widget.isSpeaking) return JarvisTheme.hologramGreen;
    if (widget.isProcessing) return JarvisTheme.softGoldAccent;
    return JarvisTheme.teaGreen;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _rotateAnimation]),
        builder: (context, child) {
          return SizedBox(
            width: widget.size * 1.5,
            height: widget.size * 1.5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating ring
                Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: CustomPaint(
                    size: Size(widget.size * 1.4, widget.size * 1.4),
                    painter: HologramRingPainter(
                      color: _primaryColor,
                      strokeWidth: 2,
                      dashCount: 12,
                    ),
                  ),
                ),

                // Middle ring (counter-rotate)
                Transform.rotate(
                  angle: -_rotateAnimation.value * 0.7,
                  child: CustomPaint(
                    size: Size(widget.size * 1.2, widget.size * 1.2),
                    painter: HologramRingPainter(
                      color: _primaryColor.withOpacity(0.6),
                      strokeWidth: 1.5,
                      dashCount: 8,
                      innerRing: true,
                    ),
                  ),
                ),

                // Glow effect
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.2),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),

                // Core orb
                Container(
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primaryColor.withOpacity(0.9),
                        _primaryColor.withOpacity(0.6),
                        _primaryColor.withOpacity(0.3),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    border: Border.all(
                      color: _primaryColor.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: _buildCoreContent(),
                  ),
                ),

                // Sound waves when listening/speaking
                if (widget.isListening || widget.isSpeaking)
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        final delay = index * 0.3;
                        final progress = (_waveController.value + delay) % 1.0;
                        return Transform.scale(
                          scale: 1.0 + progress * 0.5,
                          child: Container(
                            width: widget.size * 0.8,
                            height: widget.size * 0.8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _primaryColor.withOpacity(
                                  (1 - progress) * 0.5,
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoreContent() {
    if (widget.isListening) {
      return Icon(
        Icons.mic,
        color: Colors.white,
        size: widget.size * 0.35,
      );
    }
    if (widget.isSpeaking) {
      return Icon(
        Icons.volume_up,
        color: Colors.white,
        size: widget.size * 0.35,
      );
    }
    if (widget.isProcessing) {
      return SizedBox(
        width: widget.size * 0.4,
        height: widget.size * 0.4,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.9)),
        ),
      );
    }
    // Default: tea leaf icon
    return Icon(
      Icons.eco,
      color: Colors.white,
      size: widget.size * 0.35,
    );
  }
}

/// Custom painter for hologram rings
class HologramRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;
  final bool innerRing;

  HologramRingPainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashCount = 12,
    this.innerRing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final dashAngle = 2 * pi / dashCount;
    final gapAngle = dashAngle * (innerRing ? 0.4 : 0.3);

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle - gapAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Add small circles at dash ends for inner ring
    if (innerRing) {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (var i = 0; i < dashCount; i++) {
        final angle = i * dashAngle;
        final x = center.dx + radius * cos(angle);
        final y = center.dy + radius * sin(angle);
        canvas.drawCircle(Offset(x, y), strokeWidth * 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HologramRingPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.dashCount != dashCount;
  }
}

/// Floating AI Assistant FAB
class JarvisFloatingButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  const JarvisFloatingButton({
    super.key,
    this.isActive = false,
    this.onPressed,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: JarvisAssistant(
          size: 48,
          isListening: isActive,
          onTap: onPressed,
        ),
      ),
    );
  }
}

/// Message bubble for AI assistant chat
class JarvisMessageBubble extends StatelessWidget {
  final String message;
  final bool isFromAssistant;
  final DateTime? timestamp;
  final bool isLoading;

  const JarvisMessageBubble({
    super.key,
    required this.message,
    this.isFromAssistant = true,
    this.timestamp,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isFromAssistant ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(
          left: isFromAssistant ? 8 : 48,
          right: isFromAssistant ? 48 : 8,
          bottom: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isFromAssistant
              ? LinearGradient(
                  colors: [
                    JarvisTheme.teaGreen.withOpacity(0.1),
                    JarvisTheme.hologramGreen.withOpacity(0.05),
                  ],
                )
              : LinearGradient(
                  colors: [
                    JarvisTheme.earthyBrown.withOpacity(0.1),
                    JarvisTheme.softGold.withOpacity(0.05),
                  ],
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isFromAssistant ? 4 : 16),
            bottomRight: Radius.circular(isFromAssistant ? 16 : 4),
          ),
          border: Border.all(
            color: isFromAssistant
                ? JarvisTheme.teaGreen.withOpacity(0.2)
                : JarvisTheme.softGold.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 600 + index * 200),
                    builder: (context, value, child) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: JarvisTheme.teaGreen.withOpacity(
                            0.3 + (sin(value * pi * 2) + 1) * 0.35,
                          ),
                        ),
                      );
                    },
                  );
                }),
              )
            else
              Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  color: JarvisTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            if (timestamp != null) ...[
              const SizedBox(height: 6),
              Text(
                '${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 11,
                  color: JarvisTheme.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
