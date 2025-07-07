import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/text_styles.dart';

class SplashLoadingWidget extends StatefulWidget {
  final String? message;
  final double? progress;
  final bool showProgress;
  final Color? primaryColor;
  final Color? backgroundColor;
  final double logoSize;
  final bool showLogo;
  final Duration animationDuration;
  final Curve animationCurve;
  final TextStyle? messageStyle;
  final EdgeInsetsGeometry? padding;

  const SplashLoadingWidget({
    super.key,
    this.message,
    this.progress,
    this.showProgress = false,
    this.primaryColor,
    this.backgroundColor,
    this.logoSize = 80.0,
    this.showLogo = true,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.animationCurve = Curves.easeInOut,
    this.messageStyle,
    this.padding,
  });

  @override
  State<SplashLoadingWidget> createState() => _SplashLoadingWidgetState();
}

class _SplashLoadingWidgetState extends State<SplashLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Logo entrance animation
    _logoController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Pulse animation for logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: widget.animationCurve,
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Interval(0.0, 0.7, curve: widget.animationCurve),
    ));

    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Progress animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress ?? 0.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimations() {
    // Start logo animation
    _logoController.forward();

    // Start pulse animation after logo appears
    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.repeat(reverse: true);
      }
    });

    // Update progress animation when progress changes
    if (widget.showProgress && widget.progress != null) {
      _progressController.forward();
    }
  }

  @override
  void didUpdateWidget(SplashLoadingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update progress animation when progress changes
    if (widget.progress != oldWidget.progress && widget.progress != null) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress ?? 0.0,
        end: widget.progress!,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOut,
      ));
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Widget _buildLogo() {
    if (!widget.showLogo) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final effectivePrimaryColor =
        widget.primaryColor ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: Listenable.merge(
          [_logoScaleAnimation, _logoOpacityAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value * _pulseAnimation.value,
          child: Opacity(
            opacity: _logoOpacityAnimation.value,
            child: Container(
              width: widget.logoSize,
              height: widget.logoSize,
              decoration: BoxDecoration(
                color: effectivePrimaryColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: effectivePrimaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: effectivePrimaryColor.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: widget.logoSize * 0.6,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppInfo() {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _logoOpacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacityAnimation.value,
          child: Column(
            children: [
              Text(
                'app.name'.tr(),
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                'app.tagline'.tr(),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    final theme = Theme.of(context);
    final effectivePrimaryColor =
        widget.primaryColor ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _logoOpacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacityAnimation.value,
          child: Column(
            children: [
              if (widget.showProgress && widget.progress != null) ...[
                // Progress bar
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: effectivePrimaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: effectivePrimaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingM),

                // Progress percentage
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    final percentage = (_progressAnimation.value * 100).round();
                    return Text(
                      '$percentage%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ] else ...[
                // Spinning indicator
                SizedBox(
                  width: AppDimensions.progressIndicatorSize,
                  height: AppDimensions.progressIndicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth: AppDimensions.progressIndicatorStroke,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(effectivePrimaryColor),
                  ),
                ),
              ],
              if (widget.message != null) ...[
                const SizedBox(height: AppDimensions.spacingL),
                Text(
                  widget.message!,
                  style: widget.messageStyle ??
                      AppTextStyles.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor =
        widget.backgroundColor ?? theme.colorScheme.surface;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            effectiveBackgroundColor,
            effectiveBackgroundColor.withOpacity(0.95),
          ],
        ),
      ),
      padding: widget.padding ?? const EdgeInsets.all(AppDimensions.paddingL),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Logo
            _buildLogo(),

            const SizedBox(height: AppDimensions.spacingXl),

            // App info
            _buildAppInfo(),

            const SizedBox(height: AppDimensions.spacingXxl * 2),

            // Loading indicator
            _buildLoadingIndicator(),

            const Spacer(flex: 3),

            const SizedBox(height: AppDimensions.spacingL),
          ],
        ),
      ),
    );
  }
}
