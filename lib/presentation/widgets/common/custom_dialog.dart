import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';

class CustomDialog extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String? content;
  final Widget? contentWidget;
  final List<Widget>? actions;
  final Widget? icon;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final MainAxisAlignment? actionsAlignment;
  final bool barrierDismissible;
  final double? width;
  final double? height;
  final bool scrollable;

  const CustomDialog({
    super.key,
    this.title,
    this.titleWidget,
    this.content,
    this.contentWidget,
    this.actions,
    this.icon,
    this.backgroundColor,
    this.contentPadding,
    this.actionsPadding,
    this.actionsAlignment,
    this.barrierDismissible = true,
    this.width,
    this.height,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: backgroundColor ?? theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width ?? AppDimensions.modalMaxWidth,
          maxHeight: height ?? AppDimensions.modalMaxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            if (titleWidget != null || title != null || icon != null)
              _buildHeader(context),

            // Content
            if (scrollable)
              Flexible(child: _buildScrollableContent(context))
            else
              _buildContent(context),

            // Actions
            if (actions != null && actions!.isNotEmpty) _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingL,
        AppDimensions.paddingL,
        AppDimensions.paddingL,
        AppDimensions.paddingM,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: AppDimensions.spacingM),
          ],
          Expanded(
            child: titleWidget ??
                Text(
                  title ?? '',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
      child: contentWidget ??
          (content != null
              ? Text(
                  content!,
                  style: theme.textTheme.bodyMedium,
                )
              : const SizedBox.shrink()),
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
      child: contentWidget ??
          (content != null
              ? Text(
                  content!,
                  style: theme.textTheme.bodyMedium,
                )
              : const SizedBox.shrink()),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: actionsPadding ??
          const EdgeInsets.fromLTRB(
            AppDimensions.paddingL,
            AppDimensions.paddingM,
            AppDimensions.paddingL,
            AppDimensions.paddingL,
          ),
      child: Row(
        mainAxisAlignment: actionsAlignment ?? MainAxisAlignment.end,
        children: _buildActionWidgets(),
      ),
    );
  }

  List<Widget> _buildActionWidgets() {
    final List<Widget> widgets = [];
    for (int i = 0; i < actions!.length; i++) {
      if (i > 0) {
        widgets.add(const SizedBox(width: AppDimensions.spacingM));
      }
      widgets.add(actions![i]);
    }
    return widgets;
  }

  /// Show a custom dialog
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    Widget? titleWidget,
    String? content,
    Widget? contentWidget,
    List<Widget>? actions,
    Widget? icon,
    Color? backgroundColor,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsetsGeometry? actionsPadding,
    MainAxisAlignment? actionsAlignment,
    bool barrierDismissible = true,
    double? width,
    double? height,
    bool scrollable = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomDialog(
        title: title,
        titleWidget: titleWidget,
        content: content,
        contentWidget: contentWidget,
        actions: actions,
        icon: icon,
        backgroundColor: backgroundColor,
        contentPadding: contentPadding,
        actionsPadding: actionsPadding,
        actionsAlignment: actionsAlignment,
        width: width,
        height: height,
        scrollable: scrollable,
      ),
    );
  }
}

/// Alert dialog for simple notifications
class AlertDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final String? buttonText;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? buttonColor;

  const AlertDialog({
    super.key,
    this.title,
    this.message,
    this.buttonText,
    this.onPressed,
    this.icon,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: title,
      content: message,
      icon: icon,
      actions: [
        ShadButton(
          backgroundColor: buttonColor,
          onPressed: onPressed ?? () => Navigator.of(context).pop(),
          child: Text(buttonText ?? 'common.ok'.tr()),
        ),
      ],
    );
  }

  /// Show an alert dialog
  static Future<void> show(
    BuildContext context, {
    String? title,
    String? message,
    String? buttonText,
    VoidCallback? onPressed,
    Widget? icon,
    Color? buttonColor,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: onPressed,
        icon: icon,
        buttonColor: buttonColor,
      ),
    );
  }

  /// Show a success alert
  static Future<void> showSuccess(
    BuildContext context, {
    String? title,
    String? message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return show(
      context,
      title: title ?? 'messages.success'.tr(),
      message: message,
      buttonText: buttonText,
      onPressed: onPressed,
      icon: const Icon(
        Icons.check_circle_rounded,
        color: AppColors.success,
        size: AppDimensions.iconL,
      ),
      buttonColor: AppColors.success,
    );
  }

  /// Show an error alert
  static Future<void> showError(
    BuildContext context, {
    String? title,
    String? message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return show(
      context,
      title: title ?? 'errors.general'.tr(),
      message: message,
      buttonText: buttonText,
      onPressed: onPressed,
      icon: const Icon(
        Icons.error_rounded,
        color: AppColors.error,
        size: AppDimensions.iconL,
      ),
      buttonColor: AppColors.error,
    );
  }

  /// Show a warning alert
  static Future<void> showWarning(
    BuildContext context, {
    String? title,
    String? message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return show(
      context,
      title: title ?? 'common.warning'.tr(),
      message: message,
      buttonText: buttonText,
      onPressed: onPressed,
      icon: const Icon(
        Icons.warning_rounded,
        color: AppColors.warning,
        size: AppDimensions.iconL,
      ),
      buttonColor: AppColors.warning,
    );
  }

  /// Show an info alert
  static Future<void> showInfo(
    BuildContext context, {
    String? title,
    String? message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return show(
      context,
      title: title ?? 'common.info'.tr(),
      message: message,
      buttonText: buttonText,
      onPressed: onPressed,
      icon: const Icon(
        Icons.info_rounded,
        color: AppColors.info,
        size: AppDimensions.iconL,
      ),
      buttonColor: AppColors.info,
    );
  }
}

/// Form dialog for input operations
class FormDialog extends StatefulWidget {
  final String? title;
  final Widget formContent;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool confirmEnabled;
  final GlobalKey<FormState>? formKey;

  const FormDialog({
    super.key,
    this.title,
    required this.formContent,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.confirmEnabled = true,
    this.formKey,
  });

  @override
  State<FormDialog> createState() => _FormDialogState();

  /// Show a form dialog
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget formContent,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool confirmEnabled = true,
    GlobalKey<FormState>? formKey,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => FormDialog(
        title: title,
        formContent: formContent,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmEnabled: confirmEnabled,
        formKey: formKey,
      ),
    );
  }
}

class _FormDialogState extends State<FormDialog> {
  late GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = widget.formKey ?? GlobalKey<FormState>();
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: widget.title,
      scrollable: true,
      contentWidget: Form(
        key: _formKey,
        child: widget.formContent,
      ),
      actions: [
        ShadButton.outline(
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
          child: Text(widget.cancelText ?? 'common.cancel'.tr()),
        ),
        ShadButton(
          onPressed: widget.confirmEnabled
              ? () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onConfirm?.call();
                    Navigator.of(context).pop(true);
                  }
                }
              : null,
          child: Text(widget.confirmText ?? 'common.confirm'.tr()),
        ),
      ],
    );
  }
}

/// Loading dialog with spinner
class LoadingDialog extends StatelessWidget {
  final String? message;
  final bool cancellable;
  final VoidCallback? onCancel;

  const LoadingDialog({
    super.key,
    this.message,
    this.cancellable = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => cancellable,
      child: CustomDialog(
        barrierDismissible: cancellable,
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.spacingL),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: cancellable
            ? [
                ShadButton.outline(
                  onPressed: onCancel ?? () => Navigator.of(context).pop(),
                  child: Text('common.cancel'.tr()),
                ),
              ]
            : null,
      ),
    );
  }

  /// Show a loading dialog
  static Future<T?> show<T>(
    BuildContext context, {
    String? message,
    bool cancellable = false,
    VoidCallback? onCancel,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: cancellable,
      builder: (context) => LoadingDialog(
        message: message,
        cancellable: cancellable,
        onCancel: onCancel,
      ),
    );
  }
}
