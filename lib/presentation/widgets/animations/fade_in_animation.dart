import 'package:flutter/material.dart';

import '../../../core/constants/dimensions.dart';

/// A widget that provides fade-in animation for its child
class FadeInAnimation extends StatefulWidget {
  /// The child widget to animate
  final Widget child;

  /// Duration of the fade-in animation
  final Duration duration;

  /// Delay before starting the animation
  final Duration delay;

  /// Animation curve to use
  final Curve curve;

  /// Whether to start the animation automatically
  final bool autoStart;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  /// Initial opacity value (0.0 to 1.0)
  final double startOpacity;

  /// Final opacity value (0.0 to 1.0)
  final double endOpacity;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.curve = Curves.easeInOut,
    this.autoStart = true,
    this.onComplete,
    this.startOpacity = 0.0,
    this.endOpacity = 1.0,
  });

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
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
      begin: widget.startOpacity,
      end: widget.endOpacity,
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

  /// Manually trigger the fade-in animation
  void fadeIn() {
    _controller.forward();
  }

  /// Manually trigger the fade-out animation
  void fadeOut() {
    _controller.reverse();
  }

  /// Reset the animation to its initial state
  void reset() {
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// A widget that provides staggered fade-in animation for a list of children
class StaggeredFadeInAnimation extends StatefulWidget {
  /// List of child widgets to animate
  final List<Widget> children;

  /// Duration of each individual fade-in animation
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

  const StaggeredFadeInAnimation({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 400),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.initialDelay = Duration.zero,
    this.curve = Curves.easeInOut,
    this.autoStart = true,
    this.onAllComplete,
    this.axis = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  State<StaggeredFadeInAnimation> createState() =>
      _StaggeredFadeInAnimationState();
}

class _StaggeredFadeInAnimationState extends State<StaggeredFadeInAnimation> {
  final List<GlobalKey<_FadeInAnimationState>> _keys = [];
  int _completedAnimations = 0;

  @override
  void initState() {
    super.initState();

    // Create keys for each child
    for (int i = 0; i < widget.children.length; i++) {
      _keys.add(GlobalKey<_FadeInAnimationState>());
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
        _keys[i].currentState?.fadeIn();
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

      return FadeInAnimation(
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

/// A widget that provides fade-in animation with slide effect
class FadeInSlideAnimation extends StatefulWidget {
  /// The child widget to animate
  final Widget child;

  /// Duration of the animation
  final Duration duration;

  /// Delay before starting the animation
  final Duration delay;

  /// Animation curve to use
  final Curve curve;

  /// Whether to start the animation automatically
  final bool autoStart;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  /// Direction to slide from
  final SlideDirection direction;

  /// Distance to slide (in pixels)
  final double slideDistance;

  const FadeInSlideAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.autoStart = true,
    this.onComplete,
    this.direction = SlideDirection.bottom,
    this.slideDistance = AppDimensions.spacingXxl,
  });

  @override
  State<FadeInSlideAnimation> createState() => _FadeInSlideAnimationState();
}

class _FadeInSlideAnimationState extends State<FadeInSlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Calculate slide offset based on direction
    Offset beginOffset;
    switch (widget.direction) {
      case SlideDirection.top:
        beginOffset = Offset(0.0, -widget.slideDistance / 100);
        break;
      case SlideDirection.bottom:
        beginOffset = Offset(0.0, widget.slideDistance / 100);
        break;
      case SlideDirection.left:
        beginOffset = Offset(-widget.slideDistance / 100, 0.0);
        break;
      case SlideDirection.right:
        beginOffset = Offset(widget.slideDistance / 100, 0.0);
        break;
    }

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _controller.addStatusListener((status) {
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

  /// Manually trigger the animation
  void animate() {
    _controller.forward();
  }

  /// Reset the animation
  void reset() {
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Directions for slide animations
enum SlideDirection {
  top,
  bottom,
  left,
  right,
}

/// A convenient widget for animating list items with fade-in effect
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration staggerDelay;
  final Curve curve;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 400),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInSlideAnimation(
      duration: duration,
      delay: Duration(milliseconds: index * staggerDelay.inMilliseconds),
      curve: curve,
      direction: SlideDirection.bottom,
      slideDistance: AppDimensions.spacingL,
      child: child,
    );
  }
}
