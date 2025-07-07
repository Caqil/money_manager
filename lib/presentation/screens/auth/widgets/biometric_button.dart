import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../data/services/auth_service.dart';
import '../../../providers/auth_provider.dart';

class BiometricButton extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final ValueChanged<String>? onError;
  final String? reason;
  final bool enabled;
  final bool showLabel;
  final String? customLabel;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final BorderRadius? borderRadius;
  final bool hapticFeedback;
  final Duration animationDuration;
  final BiometricButtonStyle style;

  const BiometricButton({
    super.key,
    this.onSuccess,
    this.onError,
    this.reason,
    this.enabled = true,
    this.showLabel = true,
    this.customLabel,
    this.padding,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = AppDimensions.elevationM,
    this.borderRadius,
    this.hapticFeedback = true,
    this.animationDuration = const Duration(milliseconds: 200),
    this.style = BiometricButtonStyle.elevated,
  });

  @override
  ConsumerState<BiometricButton> createState() => _BiometricButtonState();
}

class _BiometricButtonState extends ConsumerState<BiometricButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (!widget.enabled || _isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final success = await authNotifier.authenticateWithBiometrics(
        reason: widget.reason ?? 'auth.biometricPrompt'.tr(),
      );

      if (success) {
        widget.onSuccess?.call();
        if (widget.hapticFeedback) {
          HapticFeedback.heavyImpact();
        }
      } else {
        widget.onError?.call('auth.authenticationFailed'.tr());
        if (widget.hapticFeedback) {
          HapticFeedback.vibrate();
        }
      }
    } catch (e) {
      widget.onError?.call(e.toString());
      if (widget.hapticFeedback) {
        HapticFeedback.vibrate();
      }
    } finally {
      _pulseController.stop();
      _pulseController.reset();
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  Widget _buildIcon(BiometricInfo? biometricInfo) {
    IconData iconData;
    
    if (biometricInfo != null && biometricInfo.isAvailable) {
      if (biometricInfo.hasFaceID) {
        iconData = Icons.face_rounded;
      } else if (biometricInfo.hasFingerprint) {
        iconData = Icons.fingerprint_rounded;
      } else {
        iconData = Icons.security_rounded;
      }
    } else {
      iconData = Icons.security_rounded;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isAuthenticating ? _pulseAnimation.value : 1.0,
          child: Icon(
            iconData,
            size: AppDimensions.iconL,
            color: widget.foregroundColor ?? 
                   (_isAuthenticating ? AppColors.primary : null),
          ),
        );
      },
    );
  }

  String _getLabel(BiometricInfo? biometricInfo) {
    if (widget.customLabel != null) {
      return widget.customLabel!;
    }

    if (biometricInfo != null && biometricInfo.isAvailable) {
      if (biometricInfo.hasFaceID) {
        return 'auth.useFaceId'.tr();
      } else if (biometricInfo.hasFingerprint) {
        return 'auth.useFingerprint'.tr();
      } else {
        return 'auth.useBiometric'.tr();
      }
    }

    return 'auth.useBiometric'.tr();
  }

  Widget _buildElevatedButton(BiometricInfo? biometricInfo) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height ?? AppDimensions.buttonHeightL,
            child: ElevatedButton(
              onPressed: widget.enabled ? _authenticate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.backgroundColor ?? theme.colorScheme.primary,
                foregroundColor: widget.foregroundColor ?? theme.colorScheme.onPrimary,
                elevation: widget.elevation,
                padding: widget.padding ?? const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingL,
                  vertical: AppDimensions.paddingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: widget.borderRadius ?? 
                              BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(biometricInfo),
                  if (widget.showLabel) ...[
                    const SizedBox(width: AppDimensions.spacingS),
                    Flexible(
                      child: Text(
                        _getLabel(biometricInfo),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: widget.foregroundColor ?? theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutlinedButton(BiometricInfo? biometricInfo) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: widget.width,
            height: widget.height ?? AppDimensions.buttonHeightL,
            child: OutlinedButton(
              onPressed: widget.enabled ? _authenticate : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.foregroundColor ?? theme.colorScheme.primary,
                side: BorderSide(
                  color: widget.backgroundColor ?? theme.colorScheme.primary,
                  width: 2.0,
                ),
                padding: widget.padding ?? const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingL,
                  vertical: AppDimensions.paddingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: widget.borderRadius ?? 
                              BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(biometricInfo),
                  if (widget.showLabel) ...[
                    const SizedBox(width: AppDimensions.spacingS),
                    Flexible(
                      child: Text(
                        _getLabel(biometricInfo),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: widget.foregroundColor ?? theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton(BiometricInfo? biometricInfo) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width ?? AppDimensions.iconXl + AppDimensions.paddingM,
            height: widget.height ?? AppDimensions.iconXl + AppDimensions.paddingM,
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: widget.borderRadius ?? 
                           BorderRadius.circular(AppDimensions.radiusCircular),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: IconButton(
              onPressed: widget.enabled ? _authenticate : null,
              padding: widget.padding ?? const EdgeInsets.all(AppDimensions.paddingS),
              icon: _buildIcon(biometricInfo),
              tooltip: _getLabel(biometricInfo),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final biometricInfo = ref.watch(biometricAvailabilityProvider);

    return biometricInfo.when(
      data: (info) {
        if (!info.isAvailable) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedOpacity(
            opacity: widget.enabled ? 1.0 : 0.6,
            duration: widget.animationDuration,
            child: switch (widget.style) {
              BiometricButtonStyle.elevated => _buildElevatedButton(info),
              BiometricButtonStyle.outlined => _buildOutlinedButton(info),
              BiometricButtonStyle.icon => _buildIconButton(info),
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

enum BiometricButtonStyle {
  elevated,
  outlined,
  icon,
}