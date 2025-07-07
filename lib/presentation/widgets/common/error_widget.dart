import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:money_manager/core/utils/logger.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';

class CustomErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? icon;
  final IconData? iconData;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryActionPressed;
  final EdgeInsetsGeometry? padding;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final bool showDetails;
  final String? details;
  final Object? error;
  final StackTrace? stackTrace;

  const CustomErrorWidget({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.iconData,
    this.actionText,
    this.onActionPressed,
    this.secondaryActionText,
    this.onSecondaryActionPressed,
    this.padding,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.showDetails = false,
    this.details,
    this.error,
    this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: backgroundColor,
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          // Error Icon
          if (icon != null)
            icon!
          else
            Icon(
              iconData ?? Icons.error_outline_rounded,
              size: AppDimensions.iconXxl,
              color: iconColor ?? AppColors.error,
            ),

          const SizedBox(height: AppDimensions.spacingL),

          // Title
          Text(
            title ?? 'errors.general'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor ?? colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // Message
          Text(
            message ?? 'errors.tryAgain'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: (textColor ?? colorScheme.onSurface).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Action Buttons
          _buildActions(context),

          // Error Details (for debug mode)
          if (showDetails && (details != null || error != null))
            _buildErrorDetails(context),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final actions = <Widget>[];

    if (onActionPressed != null) {
      actions.add(
        ShadButton(
          onPressed: onActionPressed,
          child: Text(actionText ?? 'common.retry'.tr()),
        ),
      );
    }

    if (onSecondaryActionPressed != null) {
      actions.add(
        ShadButton.outline(
          onPressed: onSecondaryActionPressed,
          child: Text(secondaryActionText ?? 'common.back'.tr()),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    if (actions.length == 1) {
      return actions.first;
    }

    return Column(
      children: [
        actions.first,
        const SizedBox(height: AppDimensions.spacingM),
        actions.last,
      ],
    );
  }

  Widget _buildErrorDetails(BuildContext context) {
    final theme = Theme.of(context);
    final errorText = details ?? error?.toString() ?? '';

    if (errorText.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error Details:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            errorText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Network error widget
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      iconData: Icons.wifi_off_rounded,
      title: 'errors.network'.tr(),
      message: customMessage ?? 'errors.noInternet'.tr(),
      actionText: 'common.retry'.tr(),
      onActionPressed: onRetry,
    );
  }
}

/// Server error widget
class ServerErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const ServerErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      iconData: Icons.dns_rounded,
      title: 'errors.serverError'.tr(),
      message: customMessage ?? 'errors.serverUnavailable'.tr(),
      actionText: 'common.retry'.tr(),
      onActionPressed: onRetry,
    );
  }
}

/// Permission error widget
class PermissionErrorWidget extends StatelessWidget {
  final VoidCallback? onGrantPermission;
  final String? permission;
  final String? customMessage;

  const PermissionErrorWidget({
    super.key,
    this.onGrantPermission,
    this.permission,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      iconData: Icons.lock_outline_rounded,
      title: 'errors.permissionDenied'.tr(),
      message: customMessage ??
          'errors.permissionRequired'.tr(
              namedArgs: {'permission': permission ?? 'required permission'}),
      actionText: 'common.grant'.tr(),
      onActionPressed: onGrantPermission,
    );
  }
}

/// File not found error widget
class FileNotFoundErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? fileName;

  const FileNotFoundErrorWidget({
    super.key,
    this.onRetry,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      iconData: Icons.file_present_rounded,
      title: 'errors.fileNotFound'.tr(),
      message: fileName != null
          ? 'errors.fileNotFoundNamed'.tr(namedArgs: {'file': fileName!})
          : 'errors.fileNotFoundGeneric'.tr(),
      actionText: 'common.retry'.tr(),
      onActionPressed: onRetry,
    );
  }
}

/// Validation error widget
class ValidationErrorWidget extends StatelessWidget {
  final List<String> errors;
  final VoidCallback? onDismiss;

  const ValidationErrorWidget({
    super.key,
    required this.errors,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      margin: const EdgeInsets.all(AppDimensions.marginM),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  'errors.validation'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded),
                  iconSize: AppDimensions.iconS,
                  color: AppColors.error,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ...errors.map((error) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingXs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(
                        error,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Error boundary widget for catching Flutter errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final void Function(Object error, StackTrace? stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }
      return CustomErrorWidget(
        title: 'errors.general'.tr(),
        message: 'errors.unexpectedError'.tr(),
        error: _error,
        stackTrace: _stackTrace,
        showDetails: true,
        onActionPressed: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      if (mounted) {
        setState(() {
          _error = errorDetails.exception;
          _stackTrace = errorDetails.stack;
        });
        widget.onError?.call(errorDetails.exception, errorDetails.stack);
      }
      return CustomErrorWidget(
        title: 'errors.general'.tr(),
        message: 'errors.unexpectedError'.tr(),
        error: errorDetails.exception,
        stackTrace: errorDetails.stack,
        showDetails: true,
      );
    };
  }
}

/// Error card for inline error display
class ErrorCard extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool dismissible;

  const ErrorCard({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.onDismiss,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.margin,
    this.dismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: margin ?? const EdgeInsets.all(AppDimensions.marginM),
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: borderColor ?? AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  title ?? 'errors.general'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
              if (dismissible && onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded),
                  iconSize: AppDimensions.iconS,
                  color: AppColors.error,
                ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            ShadButton.outline(
              onPressed: onRetry,
              size: ShadButtonSize.sm,
              child: Text('common.retry'.tr()),
            ),
          ],
        ],
      ),
    );
  }
}
