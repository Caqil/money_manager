import 'dart:math';

import 'package:flutter/material.dart';


/// A widget that provides scale animation for its child
class ScaleAnimation extends StatefulWidget {
  /// The child widget to animate
  final Widget child;

  /// Duration of the scale animation
  final Duration duration;

  /// Delay before starting the animation
  final Duration delay;

  /// Animation curve to use
  final Curve curve;

  /// Whether to start the animation automatically
  final bool autoStart;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  /// Initial scale value
  final double startScale;

  /// Final scale value
  final double endScale;

  /// Alignment for the scale transformation
  final Alignment alignment;

  const ScaleAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = Curves.elasticOut,
    this.autoStart = true,
    this.onComplete,
    this.startScale = 0.0,
    this.endScale = 1.0,
    this.alignment = Alignment.center,
  });

  @override
  State<ScaleAnimation> createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.startScale,
      end: widget.endScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.autoStart) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    if (widget.delay != Duration.zero) {
      await Future.delayed(widget.delay);
    }
    if (mounted) {
      _controller.forward();
    }
  }

  /// Manually trigger the scale-in animation
  void scaleIn() {
    _controller.forward();
  }

  /// Manually trigger the scale-out animation
  void scaleOut() {
    _controller.reverse();
  }

  /// Reset the animation to its initial state
  void reset() {
    _controller.reset();
  }

  /// Toggle the animation state
  void toggle() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          alignment: widget.alignment,
          child: widget.child,
        );
      },
    );
  }
}

/// A widget that provides bounce scale animation
class BounceScaleAnimation extends StatefulWidget {
  /// The child widget to animate
  final Widget child;

  /// Duration of the animation
  final Duration duration;

  /// Delay before starting the animation
  final Duration delay;

  /// Whether to start the animation automatically
  final bool autoStart;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  /// Number of bounces
  final int bounces;

  /// Maximum scale during bounce
  final double maxScale;

  const BounceScaleAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.autoStart = true,
    this.onComplete,
    this.bounces = 2,
    this.maxScale = 1.2,
  });

  @override
  State<BounceScaleAnimation> createState() => _BounceScaleAnimationState();
}

class _BounceScaleAnimationState extends State<BounceScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Create a custom bounce curve
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: _BounceInCurve(bounces: widget.bounces),
    ));

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.autoStart) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    if (widget.delay != Duration.zero) {
      await Future.delayed(widget.delay);
    }
    if (mounted) {
      _controller.forward();
    }
  }

  /// Manually trigger the bounce animation
  void bounce() {
    _controller.reset();
    _controller.forward();
  }

  /// Reset the animation
  void reset() {
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculate scale based on bounce progress
        final progress = _animation.value;
        final bounceValue = progress < 0.5
            ? progress * 2 * widget.maxScale
            : widget.maxScale -
                ((progress - 0.5) * 2 * (widget.maxScale - 1.0));

        return Transform.scale(
          scale: bounceValue,
          child: widget.child,
        );
      },
    );
  }
}

/// A widget that provides pulsing scale animation
class PulseScaleAnimation extends StatefulWidget {
  /// The child widget to animate
  final Widget child;

  /// Duration of one pulse cycle
  final Duration duration;

  /// Delay before starting the animation
  final Duration delay;

  /// Whether to start the animation automatically
  final bool autoStart;

  /// Whether to repeat the animation
  final bool repeat;

  /// Minimum scale value
  final double minScale;

  /// Maximum scale value
  final double maxScale;

  /// Animation curve to use
  final Curve curve;

  const PulseScaleAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.delay = Duration.zero,
    this.autoStart = true,
    this.repeat = true,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.curve = Curves.easeInOut,
  });

  @override
  State<PulseScaleAnimation> createState() => _PulseScaleAnimationState();
}

class _PulseScaleAnimationState extends State<PulseScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.autoStart) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    if (widget.delay != Duration.zero) {
      await Future.delayed(widget.delay);
    }
    if (mounted) {
      if (widget.repeat) {
        _controller.repeat(reverse: true);
      } else {
        _controller.forward();
      }
    }
  }

  /// Start the pulse animation
  void startPulse() {
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  /// Stop the pulse animation
  void stopPulse() {
    _controller.stop();
  }

  /// Reset the animation
  void reset() {
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// A widget that provides staggered scale animation for multiple children
class StaggeredScaleAnimation extends StatefulWidget {
  /// List of child widgets to animate
  final List<Widget> children;

  /// Duration of each individual scale animation
  final Duration duration;

  /// Delay between each child animation
  final Duration staggerDelay;

  /// Initial delay before starting animations
  final Duration initialDelay;

  /// Animation curve to use
  final Curve curve;

  /// Whether to start animations automatically
  final bool autoStart;

  /// Callback when all animations complete
  final VoidCallback? onAllComplete;

  /// Layout axis for the children
  final Axis axis;

  /// Alignment for the children
  final MainAxisAlignment mainAxisAlignment;

  /// Cross axis alignment for the children
  final CrossAxisAlignment crossAxisAlignment;

  const StaggeredScaleAnimation({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 80),
    this.initialDelay = Duration.zero,
    this.curve = Curves.elasticOut,
    this.autoStart = true,
    this.onAllComplete,
    this.axis = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  State<StaggeredScaleAnimation> createState() =>
      _StaggeredScaleAnimationState();
}

class _StaggeredScaleAnimationState extends State<StaggeredScaleAnimation> {
  final List<GlobalKey<_ScaleAnimationState>> _keys = [];
  int _completedAnimations = 0;

  @override
  void initState() {
    super.initState();

    // Create keys for each child
    for (int i = 0; i < widget.children.length; i++) {
      _keys.add(GlobalKey<_ScaleAnimationState>());
    }

    if (widget.autoStart) {
      _startStaggeredAnimation();
    }
  }

  void _startStaggeredAnimation() async {
    if (widget.initialDelay != Duration.zero) {
      await Future.delayed(widget.initialDelay);
    }

    for (int i = 0; i < widget.children.length; i++) {
      if (mounted) {
        _keys[i].currentState?.scaleIn();
        await Future.delayed(widget.staggerDelay);
      }
    }
  }

  void _onChildComplete() {
    _completedAnimations++;
    if (_completedAnimations == widget.children.length) {
      widget.onAllComplete?.call();
    }
  }

  /// Manually trigger all animations
  void startAnimation() {
    _completedAnimations = 0;
    _startStaggeredAnimation();
  }

  /// Reset all animations
  void resetAll() {
    _completedAnimations = 0;
    for (final key in _keys) {
      key.currentState?.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final animatedChildren = widget.children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;

      return ScaleAnimation(
        key: _keys[index],
        duration: widget.duration,
        curve: widget.curve,
        autoStart: false,
        onComplete: _onChildComplete,
        child: child,
      );
    }).toList();

    if (widget.axis == Axis.vertical) {
      return Column(
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        children: animatedChildren,
      );
    } else {
      return Row(
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        children: animatedChildren,
      );
    }
  }
}

/// A widget that provides tap-to-scale animation
class TapScaleAnimation extends StatefulWidget {
  /// The child widget to animate
  final Widget child;

  /// Scale value when pressed
  final double pressedScale;

  /// Duration of the scale animation
  final Duration duration;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Whether the animation is enabled
  final bool enabled;

  /// Animation curve
  final Curve curve;

  const TapScaleAnimation({
    super.key,
    required this.child,
    this.pressedScale = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.onTap,
    this.enabled = true,
    this.curve = Curves.easeInOut,
  });

  @override
  State<TapScaleAnimation> createState() => _TapScaleAnimationState();
}

class _TapScaleAnimationState extends State<TapScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Custom bounce-in curve
class _BounceInCurve extends Curve {
  final int bounces;

  const _BounceInCurve({this.bounces = 2});

  @override
  double transform(double t) {
    if (t < 0.5) {
      // Scale up phase
      return t * 2;
    } else {
      // Bounce phase
      final bouncePhase = (t - 0.5) * 2;
      final bounceFreq = bounces * 3.14159;
      return 1.0 + (0.2 * (1 - bouncePhase) * sin(bounceFreq * bouncePhase));
    }
  }
}

/// A convenient widget for animating cards with scale effect
class AnimatedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double pressedScale;
  final bool enabled;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
    this.pressedScale = 0.98,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TapScaleAnimation(
      onTap: onTap,
      pressedScale: pressedScale,
      duration: duration,
      enabled: enabled,
      child: child,
    );
  }
}
