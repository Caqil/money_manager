import 'package:flutter/material.dart';


/// A widget that provides slide animation for its child
class SlideAnimation extends StatefulWidget {
  /// The child widget to animate
  final Widget child;

  /// Duration of the slide animation
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

  /// Distance to slide (as offset multiplier)
  final double offset;

  /// Whether to animate opacity along with position
  final bool fadeIn;

  const SlideAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.autoStart = true,
    this.onComplete,
    this.direction = SlideDirection.bottom,
    this.offset = 1.0,
    this.fadeIn = false,
  });

  @override
  State<SlideAnimation> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Calculate slide offset based on direction
    Offset beginOffset = _getBeginOffset();

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _fadeAnimation = Tween<double>(
      begin: widget.fadeIn ? 0.0 : 1.0,
      end: 1.0,
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

  Offset _getBeginOffset() {
    switch (widget.direction) {
      case SlideDirection.top:
        return Offset(0.0, -widget.offset);
      case SlideDirection.bottom:
        return Offset(0.0, widget.offset);
      case SlideDirection.left:
        return Offset(-widget.offset, 0.0);
      case SlideDirection.right:
        return Offset(widget.offset, 0.0);
      case SlideDirection.topLeft:
        return Offset(-widget.offset, -widget.offset);
      case SlideDirection.topRight:
        return Offset(widget.offset, -widget.offset);
      case SlideDirection.bottomLeft:
        return Offset(-widget.offset, widget.offset);
      case SlideDirection.bottomRight:
        return Offset(widget.offset, widget.offset);
    }
  }

  void _startAnimation() async {
    if (widget.delay != Duration.zero) {
      await Future.delayed(widget.delay);
    }
    if (mounted) {
      _controller.forward();
    }
  }

  /// Manually trigger the slide-in animation
  void slideIn() {
    _controller.forward();
  }

  /// Manually trigger the slide-out animation
  void slideOut() {
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
    Widget animatedChild = SlideTransition(
      position: _slideAnimation,
      child: widget.child,
    );

    if (widget.fadeIn) {
      animatedChild = FadeTransition(
        opacity: _fadeAnimation,
        child: animatedChild,
      );
    }

    return animatedChild;
  }
}

/// A widget that provides page slide transition animation
class PageSlideAnimation extends StatefulWidget {
  /// The child widget to animate
  final Widget child;

  /// Duration of the animation
  final Duration duration;

  /// Animation curve to use
  final Curve curve;

  /// Direction of the slide
  final SlideDirection direction;

  /// Whether to start the animation automatically
  final bool autoStart;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  const PageSlideAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.direction = SlideDirection.right,
    this.autoStart = true,
    this.onComplete,
  });

  @override
  State<PageSlideAnimation> createState() => _PageSlideAnimationState();
}

class _PageSlideAnimationState extends State<PageSlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    Offset beginOffset;
    switch (widget.direction) {
      case SlideDirection.left:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.right:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case SlideDirection.top:
        beginOffset = const Offset(0.0, -1.0);
        break;
      case SlideDirection.bottom:
        beginOffset = const Offset(0.0, 1.0);
        break;
      default:
        beginOffset = const Offset(1.0, 0.0);
    }

    _animation = Tween<Offset>(
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
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Start the slide animation
  void start() {
    _controller.forward();
  }

  /// Reverse the slide animation
  void reverse() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }
}

/// A widget that provides staggered slide animation for multiple children
class StaggeredSlideAnimation extends StatefulWidget {
  /// List of child widgets to animate
  final List<Widget> children;

  /// Duration of each individual slide animation
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

  /// Direction to slide from
  final SlideDirection direction;

  /// Layout axis for the children
  final Axis axis;

  /// Alignment for the children
  final MainAxisAlignment mainAxisAlignment;

  /// Cross axis alignment for the children
  final CrossAxisAlignment crossAxisAlignment;

  const StaggeredSlideAnimation({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.initialDelay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.autoStart = true,
    this.onAllComplete,
    this.direction = SlideDirection.bottom,
    this.axis = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  State<StaggeredSlideAnimation> createState() =>
      _StaggeredSlideAnimationState();
}

class _StaggeredSlideAnimationState extends State<StaggeredSlideAnimation> {
  final List<GlobalKey<_SlideAnimationState>> _keys = [];
  int _completedAnimations = 0;

  @override
  void initState() {
    super.initState();

    // Create keys for each child
    for (int i = 0; i < widget.children.length; i++) {
      _keys.add(GlobalKey<_SlideAnimationState>());
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
        _keys[i].currentState?.slideIn();
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

      return SlideAnimation(
        key: _keys[index],
        duration: widget.duration,
        curve: widget.curve,
        direction: widget.direction,
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

/// A widget that provides slide transition between two children
class SlideTransitionSwitcher extends StatefulWidget {
  /// The first child widget
  final Widget firstChild;

  /// The second child widget
  final Widget secondChild;

  /// Whether to show the first or second child
  final bool showFirst;

  /// Duration of the transition
  final Duration duration;

  /// Animation curve to use
  final Curve curve;

  /// Direction of the slide transition
  final SlideDirection direction;

  const SlideTransitionSwitcher({
    super.key,
    required this.firstChild,
    required this.secondChild,
    required this.showFirst,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.direction = SlideDirection.left,
  });

  @override
  State<SlideTransitionSwitcher> createState() =>
      _SlideTransitionSwitcherState();
}

class _SlideTransitionSwitcherState extends State<SlideTransitionSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: _getEndOffset(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (!widget.showFirst) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SlideTransitionSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showFirst != oldWidget.showFirst) {
      if (widget.showFirst) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _getEndOffset() {
    switch (widget.direction) {
      case SlideDirection.left:
        return const Offset(-1.0, 0.0);
      case SlideDirection.right:
        return const Offset(1.0, 0.0);
      case SlideDirection.top:
        return const Offset(0.0, -1.0);
      case SlideDirection.bottom:
        return const Offset(0.0, 1.0);
      default:
        return const Offset(-1.0, 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: widget.firstChild,
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: _getEndOffset() * -1,
                end: Offset.zero,
              ).animate(_controller),
              child: widget.secondChild,
            ),
          ],
        );
      },
    );
  }
}

/// A widget that provides reveal animation by sliding a mask
class SlideRevealAnimation extends StatefulWidget {
  /// The child widget to reveal
  final Widget child;

  /// Duration of the reveal animation
  final Duration duration;

  /// Delay before starting the animation
  final Duration delay;

  /// Animation curve to use
  final Curve curve;

  /// Whether to start the animation automatically
  final bool autoStart;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  /// Direction of the reveal
  final SlideDirection direction;

  /// Color of the reveal mask
  final Color? maskColor;

  const SlideRevealAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.curve = Curves.easeInOut,
    this.autoStart = true,
    this.onComplete,
    this.direction = SlideDirection.left,
    this.maskColor,
  });

  @override
  State<SlideRevealAnimation> createState() => _SlideRevealAnimationState();
}

class _SlideRevealAnimationState extends State<SlideRevealAnimation>
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
      begin: 0.0,
      end: 1.0,
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

  /// Start the reveal animation
  void reveal() {
    _controller.forward();
  }

  /// Hide with reverse animation
  void hide() {
    _controller.reverse();
  }

  /// Reset the animation
  void reset() {
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveMaskColor = widget.maskColor ?? theme.canvasColor;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRect(
          child: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: _buildMask(effectiveMaskColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMask(Color maskColor) {
    final progress = _animation.value;

    switch (widget.direction) {
      case SlideDirection.left:
        return Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 1.0 - progress,
            child: Container(color: maskColor),
          ),
        );
      case SlideDirection.right:
        return Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: 1.0 - progress,
            child: Container(color: maskColor),
          ),
        );
      case SlideDirection.top:
        return Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 1.0 - progress,
            child: Container(color: maskColor),
          ),
        );
      case SlideDirection.bottom:
        return Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            heightFactor: 1.0 - progress,
            child: Container(color: maskColor),
          ),
        );
      default:
        return Container(color: maskColor);
    }
  }
}

/// Enum for slide directions
enum SlideDirection {
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// A convenient widget for animating list items with slide effect
class AnimatedSlideListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration staggerDelay;
  final Curve curve;
  final SlideDirection direction;

  const AnimatedSlideListItem({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 80),
    this.curve = Curves.easeOutCubic,
    this.direction = SlideDirection.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return SlideAnimation(
      duration: duration,
      delay: Duration(milliseconds: index * staggerDelay.inMilliseconds),
      curve: curve,
      direction: direction,
      offset: 0.5,
      fadeIn: true,
      child: child,
    );
  }
}

/// A page route that uses slide transition
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final SlideDirection direction;
  final Duration duration;
  final Curve curve;

  SlidePageRoute({
    required this.child,
    this.direction = SlideDirection.right,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, _) => child,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset beginOffset;
            switch (direction) {
              case SlideDirection.left:
                beginOffset = const Offset(-1.0, 0.0);
                break;
              case SlideDirection.right:
                beginOffset = const Offset(1.0, 0.0);
                break;
              case SlideDirection.top:
                beginOffset = const Offset(0.0, -1.0);
                break;
              case SlideDirection.bottom:
                beginOffset = const Offset(0.0, 1.0);
                break;
              default:
                beginOffset = const Offset(1.0, 0.0);
            }

            return SlideTransition(
              position: Tween<Offset>(
                begin: beginOffset,
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: curve,
              )),
              child: child,
            );
          },
        );
}
