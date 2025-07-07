import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';

class ConfirmationDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool destructive;
  final Widget? icon;
  final Color? confirmButtonColor;
  final Color? cancelButtonColor;

  const ConfirmationDialog({
    super.key,
    this.title,
    this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.destructive = false,
    this.icon,
    this.confirmButtonColor,
    this.cancelButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      child: ShadCard(
        width: AppDimensions.modalMaxWidth,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: AppDimensions.spacingM),
                  ] else if (destructive) ...[
                    Icon(
                      Icons.warning_rounded,
                      color: AppColors.error,
                      size: AppDimensions.iconL,
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                  ],
                  Expanded(
                    child: Text(
                      title ??
                          (destructive
                              ? 'common.confirm'.tr()
                              : 'messages.areYouSure'.tr()),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),

              if (message != null) ...[
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],

              const SizedBox(height: AppDimensions.spacingL),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ShadButton.outline(
                    onPressed:
                        onCancel ?? () => Navigator.of(context).pop(false),
                    child: Text(cancelText ?? 'common.cancel'.tr()),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  ShadButton(
                    backgroundColor: confirmButtonColor ??
                        (destructive ? AppColors.error : null),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onConfirm?.call();
                    },
                    child: Text(confirmText ?? 'common.confirm'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show a confirmation dialog
  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
    String? confirmText,
    String? cancelText,
    bool destructive = false,
    Widget? icon,
    Color? confirmButtonColor,
    Color? cancelButtonColor,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        destructive: destructive,
        icon: icon,
        confirmButtonColor: confirmButtonColor,
        cancelButtonColor: cancelButtonColor,
      ),
    );
  }

  /// Show a delete confirmation dialog
  static Future<bool?> showDelete(
    BuildContext context, {
    String? title,
    String? message,
    String? itemName,
  }) async {
    return show(
      context,
      title: title ?? 'common.delete'.tr(),
      message: message ?? 'messages.confirmDelete'.tr(),
      confirmText: 'common.delete'.tr(),
      destructive: true,
    );
  }

  /// Show a reset confirmation dialog
  static Future<bool?> showReset(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    return show(
      context,
      title: title ?? 'settings.resetApp'.tr(),
      message: message ?? 'settings.resetConfirmation'.tr(),
      confirmText: 'settings.resetApp'.tr(),
      destructive: true,
      icon: Icon(
        Icons.restart_alt_rounded,
        color: AppColors.error,
        size: AppDimensions.iconL,
      ),
    );
  }
}
