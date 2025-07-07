import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
class ProgressRing extends StatefulWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final Widget? child;
  final bool showAnimation;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool showGlow;
  final double? startAngle;
  final bool clockwise;
  final StrokeCap strokeCap;
  final List<Color>? gradientColors;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 60.0,
    this.strokeWidth = 6.0,
    this.progressColor,
    this.backgroundColor,
    this.child,
    this.showAnimation = true,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.animationCurve = Curves.easeOutCubic,
    this.showGlow = false,
    this.startAngle,
    this.clockwise = true,
    this.strokeCap = StrokeCap.round,
    this.gradientColors,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));

    if (widget.showAnimation) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      ));

      _animationController.reset();
      if (widget.showAnimation) {
        _animationController.forward();
      } else {
        _animationController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultProgressColor = widget.progressColor ?? AppColors.primary;
    final defaultBackgroundColor =
        widget.backgroundColor ?? theme.colorScheme.outline.withOpacity(0.2);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect (if enabled)
          if (widget.showGlow && widget.progress > 0)
            Container(
              width: widget.size + 8,
              height: widget.size + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: defaultProgressColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),

          // Progress ring
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ProgressRingPainter(
                  progress: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  progressColor: defaultProgressColor,
                  backgroundColor: defaultBackgroundColor,
                  startAngle: widget.startAngle ?? -math.pi / 2,
                  clockwise: widget.clockwise,
                  strokeCap: widget.strokeCap,
                  gradientColors: widget.gradientColors,
                ),
              );
            },
          ),

          // Child widget
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;
  final double startAngle;
  final bool clockwise;
  final StrokeCap strokeCap;
  final List<Color>? gradientColors;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
    required this.startAngle,
    required this.clockwise,
    required this.strokeCap,
    this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = strokeCap;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress > 0) {
      // Progress arc
      final progressPaint = Paint()
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = strokeCap;

      // Apply gradient or solid color
      if (gradientColors != null && gradientColors!.length >= 2) {
        progressPaint.shader = SweepGradient(
          colors: gradientColors!,
          startAngle: startAngle,
          endAngle: startAngle + (2 * math.pi * progress),
        ).createShader(rect);
      } else {
        progressPaint.color = progressColor;
      }

      final sweepAngle = 2 * math.pi * progress * (clockwise ? 1 : -1);

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.startAngle != startAngle ||
        oldDelegate.clockwise != clockwise ||
        oldDelegate.strokeCap != strokeCap ||
        oldDelegate.gradientColors != gradientColors;
  }
}

// Specialized progress ring variants

/// Achievement progress ring with preset styling
class AchievementProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final bool isCompleted;
  final Widget? child;
  final bool showAnimation;

  const AchievementProgressRing({
    super.key,
    required this.progress,
    this.size = 60.0,
    this.isCompleted = false,
    this.child,
    this.showAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = isCompleted ? AppColors.success : AppColors.primary;
    final gradientColors = isCompleted
        ? [AppColors.success, AppColors.success.withOpacity(0.7)]
        : [AppColors.primary, AppColors.accent];

    return ProgressRing(
      progress: progress,
      size: size,
      strokeWidth: size * 0.08, // 8% of size
      progressColor: progressColor,
      backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.1),
      showAnimation: showAnimation,
      showGlow: isCompleted,
      gradientColors: gradientColors,
      child: child,
    );
  }
}

/// Circular progress indicator with percentage text
class PercentageProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final TextStyle? textStyle;
  final bool showAnimation;
  final Color? progressColor;

  const PercentageProgressRing({
    super.key,
    required this.progress,
    this.size = 60.0,
    this.textStyle,
    this.showAnimation = true,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress * 100).round();

    return ProgressRing(
      progress: progress,
      size: size,
      progressColor: progressColor,
      showAnimation: showAnimation,
      child: Text(
        '$percentage%',
        style: textStyle ??
            theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: size * 0.2, // 20% of size
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Mini progress ring for compact displays
class MiniProgressRing extends StatelessWidget {
  final double progress;
  final Color? progressColor;
  final bool showAnimation;

  const MiniProgressRing({
    super.key,
    required this.progress,
    this.progressColor,
    this.showAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    return ProgressRing(
      progress: progress,
      size: 24.0,
      strokeWidth: 3.0,
      progressColor: progressColor ?? AppColors.primary,
      showAnimation: showAnimation,
      strokeCap: StrokeCap.round,
    );
  }
}
