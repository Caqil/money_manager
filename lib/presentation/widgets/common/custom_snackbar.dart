import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';

class CustomSnackBar extends StatelessWidget {
  final String message;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Duration? duration;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final VoidCallback? onDismissed;
  final SnackBarBehavior behavior;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool showCloseIcon;

  const CustomSnackBar({
    super.key,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.duration,
    this.actionLabel,
    this.onActionPressed,
    this.onDismissed,
    this.behavior = SnackBarBehavior.floating,
    this.margin,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.showCloseIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: AppDimensions.spacingM),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor ?? colorScheme.inverseSurface,
      duration: duration ?? const Duration(seconds: 4),
      behavior: behavior,
      margin: margin ?? const EdgeInsets.all(AppDimensions.paddingM),
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
      elevation: elevation ?? AppDimensions.elevationM,
      shape: RoundedRectangleBorder(
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppDimensions.radiusM),
      ),
      action: _buildAction(context),
      showCloseIcon: showCloseIcon,
      onVisible: () {
        // Callback when snackbar is visible
      },
      dismissDirection: DismissDirection.horizontal,
    );
  }

  SnackBarAction? _buildAction(BuildContext context) {
    if (actionLabel == null) return null;

    return SnackBarAction(
      label: actionLabel!,
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        onActionPressed?.call();
      },
      textColor: textColor ?? Colors.white,
    );
  }

  /// Show a custom snackbar
  static void show(
    BuildContext context, {
    required String message,
    Widget? icon,
    Color? backgroundColor,
    Color? textColor,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
    VoidCallback? onDismissed,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? elevation,
    BorderRadius? borderRadius,
    bool showCloseIcon = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(width: AppDimensions.spacingM),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.inverseSurface,
        duration: duration ?? const Duration(seconds: 4),
        behavior: behavior,
        margin: margin ?? const EdgeInsets.all(AppDimensions.paddingM),
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
        elevation: elevation ?? AppDimensions.elevationM,
        shape: RoundedRectangleBorder(
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppDimensions.radiusM),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onActionPressed?.call();
                },
                textColor: textColor ?? Colors.white,
              )
            : null,
        showCloseIcon: showCloseIcon,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// Show a success snackbar
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      icon: const Icon(
        Icons.check_circle_rounded,
        color: Colors.white,
        size: AppDimensions.iconS,
      ),
      backgroundColor: AppColors.success,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  /// Show an error snackbar
  static void showError(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      icon: const Icon(
        Icons.error_rounded,
        color: Colors.white,
        size: AppDimensions.iconS,
      ),
      backgroundColor: AppColors.error,
      actionLabel: actionLabel ?? 'common.retry'.tr(),
      onActionPressed: onActionPressed,
      duration: duration ?? const Duration(seconds: 6),
      showCloseIcon: true,
    );
  }

  /// Show a warning snackbar
  static void showWarning(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      icon: const Icon(
        Icons.warning_rounded,
        color: Colors.white,
        size: AppDimensions.iconS,
      ),
      backgroundColor: AppColors.warning,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  /// Show an info snackbar
  static void showInfo(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      icon: const Icon(
        Icons.info_rounded,
        color: Colors.white,
        size: AppDimensions.iconS,
      ),
      backgroundColor: AppColors.info,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  /// Show a loading snackbar (indefinite duration)
  static void showLoading(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    show(
      context,
      message: message,
      icon: const SizedBox(
        width: AppDimensions.iconS,
        height: AppDimensions.iconS,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
      duration: const Duration(days: 1), // Indefinite
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Show a transaction-related snackbar
  static void showTransaction(
    BuildContext context, {
    required String message,
    required String transactionType, // 'income', 'expense', 'transfer'
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    IconData iconData;
    Color backgroundColor;

    switch (transactionType.toLowerCase()) {
      case 'income':
        iconData = Icons.arrow_upward_rounded;
        backgroundColor = AppColors.income;
        break;
      case 'expense':
        iconData = Icons.arrow_downward_rounded;
        backgroundColor = AppColors.expense;
        break;
      case 'transfer':
        iconData = Icons.swap_horiz_rounded;
        backgroundColor = AppColors.transfer;
        break;
      default:
        iconData = Icons.receipt_rounded;
        backgroundColor = AppColors.primary;
    }

    show(
      context,
      message: message,
      icon: Icon(
        iconData,
        color: Colors.white,
        size: AppDimensions.iconS,
      ),
      backgroundColor: backgroundColor,
      actionLabel: actionLabel ?? 'common.view'.tr(),
      onActionPressed: onActionPressed,
    );
  }

  /// Show a budget-related snackbar
  static void showBudget(
    BuildContext context, {
    required String message,
    bool isExceeded = false,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    show(
      context,
      message: message,
      icon: Icon(
        isExceeded ? Icons.warning_rounded : Icons.pie_chart_rounded,
        color: Colors.white,
        size: AppDimensions.iconS,
      ),
      backgroundColor: isExceeded ? AppColors.error : AppColors.warning,
      actionLabel: actionLabel ?? 'common.view'.tr(),
      onActionPressed: onActionPressed,
      duration:
          isExceeded ? const Duration(seconds: 8) : const Duration(seconds: 4),
    );
  }

  /// Show a goal-related snackbar
  static void showGoal(
    BuildContext context, {
    required String message,
    bool isAchieved = false,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    show(
      context,
      message: message,
      icon: Icon(
        isAchieved ? Icons.emoji_events_rounded : Icons.flag_rounded,
        color: Colors.white,
        size: AppDimensions.iconS,
      ),
      backgroundColor: isAchieved ? AppColors.success : AppColors.info,
      actionLabel: actionLabel ?? 'common.view'.tr(),
      onActionPressed: onActionPressed,
      duration:
          isAchieved ? const Duration(seconds: 6) : const Duration(seconds: 4),
    );
  }

  /// Hide current snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Remove all snackbars
  static void removeAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}

/// Snackbar queue manager for handling multiple snackbars
class SnackBarQueue {
  static final List<_QueuedSnackBar> _queue = [];
  static bool _isShowing = false;

  static void add(
    BuildContext context, {
    required String message,
    Widget? icon,
    Color? backgroundColor,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    _queue.add(_QueuedSnackBar(
      message: message,
      icon: icon,
      backgroundColor: backgroundColor,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    ));

    _showNext(context);
  }

  static void _showNext(BuildContext context) {
    if (_isShowing || _queue.isEmpty) return;

    _isShowing = true;
    final snackbar = _queue.removeAt(0);

    CustomSnackBar.show(
      context,
      message: snackbar.message,
      icon: snackbar.icon,
      backgroundColor: snackbar.backgroundColor,
      actionLabel: snackbar.actionLabel,
      onActionPressed: snackbar.onActionPressed,
      duration: snackbar.duration,
    );

    // Schedule next snackbar
    Future.delayed(snackbar.duration ?? const Duration(seconds: 4), () {
      _isShowing = false;
      _showNext(context);
    });
  }

  static void clear() {
    _queue.clear();
  }
}

class _QueuedSnackBar {
  final String message;
  final Widget? icon;
  final Color? backgroundColor;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Duration? duration;

  _QueuedSnackBar({
    required this.message,
    this.icon,
    this.backgroundColor,
    this.actionLabel,
    this.onActionPressed,
    this.duration,
  });
}
