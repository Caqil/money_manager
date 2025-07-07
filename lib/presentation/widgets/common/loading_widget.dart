import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;
  final double? strokeWidth;
  final EdgeInsetsGeometry? padding;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool showMessage;
  final TextStyle? messageStyle;

  const LoadingWidget({
    super.key,
    this.message,
    this.color,
    this.size,
    this.strokeWidth,
    this.padding,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.showMessage = true,
    this.messageStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? AppDimensions.progressIndicatorSize * 2,
            height: size ?? AppDimensions.progressIndicatorSize * 2,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth ?? AppDimensions.progressIndicatorStroke,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? theme.colorScheme.primary,
              ),
            ),
          ),
          if (showMessage && message != null) ...[
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              message!,
              style: messageStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Small loading indicator for inline use
class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double? size;
  final double? strokeWidth;

  const LoadingIndicator({
    super.key,
    this.color,
    this.size,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: size ?? AppDimensions.progressIndicatorSize,
      height: size ?? AppDimensions.progressIndicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? AppDimensions.progressIndicatorStroke,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Loading overlay that can be shown over existing content
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final Color? overlayColor;
  final Color? indicatorColor;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.overlayColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: overlayColor ?? Colors.black.withOpacity(0.3),
            child: LoadingWidget(
              message: loadingMessage ?? 'common.loading'.tr(),
              color: indicatorColor,
            ),
          ),
      ],
    );
  }
}

/// Shimmer loading effect for placeholders
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration? duration;
  final bool enabled;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration,
    this.enabled = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton loader for list items
class SkeletonLoader extends StatelessWidget {
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoader({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height ?? AppDimensions.listTileHeight,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppDimensions.radiusM),
      ),
    );
  }
}

/// Card skeleton for loading card content
class CardSkeleton extends StatelessWidget {
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Widget? child;

  const CardSkeleton({
    super.key,
    this.height,
    this.padding,
    this.margin,
    this.child,
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
        child: child ??
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  height: 20,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                SkeletonLoader(
                  height: 16,
                  width: 150,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                const Spacer(),
                Row(
                  children: [
                    SkeletonLoader(
                      height: 14,
                      width: 80,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    const Spacer(),
                    SkeletonLoader(
                      height: 14,
                      width: 60,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                  ],
                ),
              ],
            ),
      ),
    );
  }
}

/// List skeleton for loading list content
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final double? itemHeight;
  final EdgeInsetsGeometry? itemPadding;
  final Widget Function(BuildContext context, int index)? itemBuilder;

  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight,
    this.itemPadding,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        itemCount: itemCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: itemBuilder ?? _defaultItemBuilder,
      ),
    );
  }

  Widget _defaultItemBuilder(BuildContext context, int index) {
    return Container(
      height: itemHeight ?? AppDimensions.listTileHeight,
      padding: itemPadding ?? const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        children: [
          SkeletonLoader(
            height: AppDimensions.iconL,
            width: AppDimensions.iconL,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircular),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonLoader(
                  height: 16,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                SkeletonLoader(
                  height: 14,
                  width: 120,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          SkeletonLoader(
            height: 18,
            width: 80,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
        ],
      ),
    );
  }
}

/// Text skeleton for loading text content
class TextSkeleton extends StatelessWidget {
  final int lines;
  final double? height;
  final double? spacing;
  final List<double>? lineWidths;

  const TextSkeleton({
    super.key,
    this.lines = 3,
    this.height,
    this.spacing,
    this.lineWidths,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lines, (index) {
          final isLast = index == lines - 1;
          final lineWidth = lineWidths != null && lineWidths!.length > index
              ? lineWidths![index]
              : (isLast ? 0.7 : 1.0);

          return Column(
            children: [
              SkeletonLoader(
                height: height ?? 16,
                width: lineWidth == 1.0 ? double.infinity : null,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              if (!isLast) SizedBox(height: spacing ?? AppDimensions.spacingS),
            ],
          );
        }),
      ),
    );
  }
}

/// Specialized loading widgets for money manager features

/// Transaction loading card
class TransactionLoadingCard extends StatelessWidget {
  const TransactionLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CardSkeleton(
      height: 80,
      child: Row(
        children: [
          SkeletonLoader(
            height: AppDimensions.iconL,
            width: AppDimensions.iconL,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonLoader(
                  height: 16,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                SkeletonLoader(
                  height: 14,
                  width: 100,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
              ],
            ),
          ),
          SkeletonLoader(
            height: 18,
            width: 80,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
        ],
      ),
    );
  }
}

/// Account balance loading widget
class AccountBalanceLoading extends StatelessWidget {
  const AccountBalanceLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          SkeletonLoader(
            height: 24,
            width: 150,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          SkeletonLoader(
            height: 32,
            width: 200,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
        ],
      ),
    );
  }
}

/// Chart loading placeholder
class ChartLoadingPlaceholder extends StatelessWidget {
  final double? height;

  const ChartLoadingPlaceholder({
    super.key,
    this.height,
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
        child: const Center(
          child: LoadingIndicator(),
        ),
      ),
    );
  }
}
