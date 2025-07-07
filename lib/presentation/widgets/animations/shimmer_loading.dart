import 'package:flutter/material.dart';

import '../../../core/constants/dimensions.dart';

/// A widget that provides shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  /// The child widget to apply shimmer effect to
  final Widget child;

  /// Base color for the shimmer effect
  final Color? baseColor;

  /// Highlight color for the shimmer effect
  final Color? highlightColor;

  /// Duration of one shimmer cycle
  final Duration duration;

  /// Direction of the shimmer effect
  final ShimmerDirection direction;

  /// Whether the shimmer effect is enabled
  final bool enabled;

  /// Number of color stops in the gradient
  final int gradientStops;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
    this.direction = ShimmerDirection.leftToRight,
    this.enabled = true,
    this.gradientStops = 3,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
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
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }

    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Alignment get _gradientBegin {
    switch (widget.direction) {
      case ShimmerDirection.leftToRight:
        return Alignment.centerLeft;
      case ShimmerDirection.rightToLeft:
        return Alignment.centerRight;
      case ShimmerDirection.topToBottom:
        return Alignment.topCenter;
      case ShimmerDirection.bottomToTop:
        return Alignment.bottomCenter;
      case ShimmerDirection.topLeftToBottomRight:
        return Alignment.topLeft;
      case ShimmerDirection.topRightToBottomLeft:
        return Alignment.topRight;
    }
  }

  Alignment get _gradientEnd {
    switch (widget.direction) {
      case ShimmerDirection.leftToRight:
        return Alignment.centerRight;
      case ShimmerDirection.rightToLeft:
        return Alignment.centerLeft;
      case ShimmerDirection.topToBottom:
        return Alignment.bottomCenter;
      case ShimmerDirection.bottomToTop:
        return Alignment.topCenter;
      case ShimmerDirection.topLeftToBottomRight:
        return Alignment.bottomRight;
      case ShimmerDirection.topRightToBottomLeft:
        return Alignment.bottomLeft;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final baseColor =
        widget.baseColor ?? theme.colorScheme.surfaceVariant.withOpacity(0.3);
    final highlightColor =
        widget.highlightColor ?? theme.colorScheme.surface.withOpacity(0.8);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculate shimmer position stops
        final position = _animation.value;
        final stops = List.generate(widget.gradientStops, (index) {
          final stopPosition = (index / (widget.gradientStops - 1)) * 2 - 1;
          return (position + stopPosition).clamp(0.0, 1.0);
        });

        // Create gradient colors
        final colors = <Color>[];
        for (int i = 0; i < widget.gradientStops; i++) {
          if (i == widget.gradientStops ~/ 2) {
            colors.add(highlightColor);
          } else {
            colors.add(baseColor);
          }
        }

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: _gradientBegin,
              end: _gradientEnd,
              colors: colors,
              stops: stops,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Pre-built shimmer skeleton for common UI elements
class ShimmerSkeleton extends StatelessWidget {
  /// Width of the skeleton
  final double? width;

  /// Height of the skeleton
  final double? height;

  /// Border radius of the skeleton
  final BorderRadius? borderRadius;

  /// Margin around the skeleton
  final EdgeInsetsGeometry? margin;

  /// Type of skeleton shape
  final SkeletonType type;

  const ShimmerSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
    this.type = SkeletonType.rectangle,
  });

  /// Creates a circular skeleton (e.g., for avatars)
  const ShimmerSkeleton.circular({
    super.key,
    double? size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = null,
        type = SkeletonType.circle;

  /// Creates a text line skeleton
  const ShimmerSkeleton.text({
    super.key,
    this.width,
    double? fontSize,
    this.margin,
  })  : height = fontSize ?? 16,
        borderRadius = const BorderRadius.all(Radius.circular(4)),
        type = SkeletonType.text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    BorderRadius? effectiveBorderRadius;
    switch (type) {
      case SkeletonType.circle:
        effectiveBorderRadius = BorderRadius.circular(
          (width ?? height ?? AppDimensions.iconM) / 2,
        );
        break;
      case SkeletonType.text:
        effectiveBorderRadius =
            borderRadius ?? BorderRadius.circular(AppDimensions.radiusXs);
        break;
      case SkeletonType.rectangle:
        effectiveBorderRadius =
            borderRadius ?? BorderRadius.circular(AppDimensions.radiusS);
        break;
    }

    return ShimmerLoading(
      child: Container(
        width: width,
        height: height ?? AppDimensions.spacingL,
        margin: margin,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: effectiveBorderRadius,
        ),
      ),
    );
  }
}

/// A shimmer skeleton for list items
class ShimmerListItem extends StatelessWidget {
  /// Height of the list item
  final double? height;

  /// Padding inside the list item
  final EdgeInsetsGeometry? padding;

  /// Whether to show an avatar/icon
  final bool showAvatar;

  /// Whether to show trailing content
  final bool showTrailing;

  /// Number of text lines to show
  final int textLines;

  /// Custom content widget
  final Widget? content;

  const ShimmerListItem({
    super.key,
    this.height,
    this.padding,
    this.showAvatar = true,
    this.showTrailing = true,
    this.textLines = 2,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height ?? AppDimensions.listTileHeight,
        padding: padding ?? const EdgeInsets.all(AppDimensions.paddingM),
        child: content ?? _buildDefaultContent(),
      ),
    );
  }

  Widget _buildDefaultContent() {
    return Row(
      children: [
        if (showAvatar) ...[
          const ShimmerSkeleton.circular(size: AppDimensions.iconL),
          const SizedBox(width: AppDimensions.spacingM),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < textLines; i++) ...[
                ShimmerSkeleton.text(
                  width: i == textLines - 1 ? 120 : double.infinity,
                  fontSize: i == 0 ? 16 : 14,
                ),
                if (i < textLines - 1)
                  const SizedBox(height: AppDimensions.spacingS),
              ],
            ],
          ),
        ),
        if (showTrailing) ...[
          const SizedBox(width: AppDimensions.spacingM),
          const ShimmerSkeleton(
            width: 80,
            height: 18,
          ),
        ],
      ],
    );
  }
}

/// A shimmer skeleton for card content
class ShimmerCard extends StatelessWidget {
  /// Height of the card
  final double? height;

  /// Padding inside the card
  final EdgeInsetsGeometry? padding;

  /// Margin around the card
  final EdgeInsetsGeometry? margin;

  /// Whether to show header content
  final bool showHeader;

  /// Whether to show footer content
  final bool showFooter;

  /// Number of content lines
  final int contentLines;

  /// Custom content widget
  final Widget? content;

  const ShimmerCard({
    super.key,
    this.height,
    this.padding,
    this.margin,
    this.showHeader = true,
    this.showFooter = true,
    this.contentLines = 3,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height ?? AppDimensions.cardDefaultHeight,
        margin: margin ?? const EdgeInsets.all(AppDimensions.marginM),
        padding: padding ?? const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: content ?? _buildDefaultContent(),
      ),
    );
  }

  Widget _buildDefaultContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          const ShimmerSkeleton(
            height: 20,
            width: double.infinity,
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],
        ...List.generate(contentLines, (index) {
          return Column(
            children: [
              ShimmerSkeleton.text(
                width: index == contentLines - 1 ? 150 : double.infinity,
                fontSize: 16,
              ),
              if (index < contentLines - 1)
                const SizedBox(height: AppDimensions.spacingS),
            ],
          );
        }),
        if (showFooter) ...[
          const Spacer(),
          Row(
            children: [
              const ShimmerSkeleton(
                width: 80,
                height: 14,
              ),
              const Spacer(),
              const ShimmerSkeleton(
                width: 60,
                height: 14,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A shimmer skeleton for grid items
class ShimmerGridItem extends StatelessWidget {
  /// Aspect ratio of the grid item
  final double aspectRatio;

  /// Padding inside the grid item
  final EdgeInsetsGeometry? padding;

  /// Whether to show text below the content
  final bool showText;

  /// Number of text lines
  final int textLines;

  const ShimmerGridItem({
    super.key,
    this.aspectRatio = 1.0,
    this.padding,
    this.showText = true,
    this.textLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppDimensions.paddingS),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
              ),
              if (showText) ...[
                const SizedBox(height: AppDimensions.spacingS),
                ...List.generate(textLines, (index) {
                  return Column(
                    children: [
                      ShimmerSkeleton.text(
                        width: index == textLines - 1 ? 80 : double.infinity,
                        fontSize: 14,
                      ),
                      if (index < textLines - 1) const SizedBox(height: 4),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A shimmer loading for chart content
class ShimmerChart extends StatelessWidget {
  /// Height of the chart
  final double? height;

  /// Type of chart to simulate
  final ChartType chartType;

  /// Whether to show legend
  final bool showLegend;

  const ShimmerChart({
    super.key,
    this.height,
    this.chartType = ChartType.line,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height ?? AppDimensions.chartHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            children: [
              Expanded(
                child: _buildChartContent(),
              ),
              if (showLegend) ...[
                const SizedBox(height: AppDimensions.spacingM),
                _buildLegend(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartContent() {
    switch (chartType) {
      case ChartType.line:
        return _buildLineChart();
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.pie:
        return _buildPieChart();
    }
  }

  Widget _buildLineChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
    );
  }

  Widget _buildBarChart() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (index) {
        final heights = [0.3, 0.7, 0.5, 0.9, 0.4];
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: FractionallySizedBox(
              heightFactor: heights[index],
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPieChart() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const ShimmerSkeleton(
              width: 40,
              height: 12,
            ),
          ],
        );
      }),
    );
  }
}

/// Enum for shimmer directions
enum ShimmerDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
  topLeftToBottomRight,
  topRightToBottomLeft,
}

/// Enum for skeleton types
enum SkeletonType {
  rectangle,
  circle,
  text,
}

/// Enum for chart types
enum ChartType {
  line,
  bar,
  pie,
}
