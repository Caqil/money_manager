import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';
import 'currency_display_widget.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? valueColor;
  final BorderRadius? borderRadius;
  final String? label;
  final Widget? labelWidget;
  final bool showPercentage;
  final bool showAnimation;
  final Duration? animationDuration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ProgressIndicatorWidget({
    super.key,
    required this.value,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.valueColor,
    this.borderRadius,
    this.label,
    this.labelWidget,
    this.showPercentage = false,
    this.showAnimation = true,
    this.animationDuration,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final clampedValue = value.clamp(0.0, 1.0);
    final effectiveBackgroundColor =
        backgroundColor ?? colorScheme.surfaceVariant.withOpacity(0.3);
    final effectiveValueColor = _getValueColor(clampedValue, colorScheme);

    Widget progressBar = Container(
      height: height ?? 8.0,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Stack(
        children: [
          if (showAnimation)
            AnimatedContainer(
              duration: animationDuration ?? const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: MediaQuery.of(context).size.width * clampedValue,
              decoration: BoxDecoration(
                color: effectiveValueColor,
                borderRadius: borderRadius ??
                    BorderRadius.circular(AppDimensions.radiusS),
              ),
            )
          else
            FractionallySizedBox(
              widthFactor: clampedValue,
              child: Container(
                decoration: BoxDecoration(
                  color: effectiveValueColor,
                  borderRadius: borderRadius ??
                      BorderRadius.circular(AppDimensions.radiusS),
                ),
              ),
            ),
        ],
      ),
    );

    if (labelWidget != null || label != null || showPercentage) {
      return Container(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (labelWidget != null || label != null || showPercentage)
              _buildLabel(context, clampedValue),
            const SizedBox(height: AppDimensions.spacingS),
            progressBar,
          ],
        ),
      );
    }

    return Container(
      padding: padding,
      child: progressBar,
    );
  }

  Widget _buildLabel(BuildContext context, double clampedValue) {
    final theme = Theme.of(context);

    if (labelWidget != null) {
      return labelWidget!;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (label != null)
          Expanded(
            child: Text(
              label!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (showPercentage)
          Text(
            '${(clampedValue * 100).toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: _getValueColor(clampedValue, theme.colorScheme),
            ),
          ),
      ],
    );
  }

  Color _getValueColor(double value, ColorScheme colorScheme) {
    if (valueColor != null) return valueColor!;

    // Default color logic based on progress
    if (value < 0.5) {
      return AppColors.success;
    } else if (value < 0.8) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }
}

/// Circular progress indicator with custom styling
class CircularProgressIndicatorWidget extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double? size;
  final double? strokeWidth;
  final Color? backgroundColor;
  final Color? valueColor;
  final String? centerText;
  final Widget? centerWidget;
  final bool showPercentage;
  final bool showAnimation;
  final Duration? animationDuration;
  final StrokeCap? strokeCap;

  const CircularProgressIndicatorWidget({
    super.key,
    required this.value,
    this.size,
    this.strokeWidth,
    this.backgroundColor,
    this.valueColor,
    this.centerText,
    this.centerWidget,
    this.showPercentage = false,
    this.showAnimation = true,
    this.animationDuration,
    this.strokeCap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final clampedValue = value.clamp(0.0, 1.0);
    final effectiveSize = size ?? 60.0;
    final effectiveStrokeWidth = strokeWidth ?? 6.0;
    final effectiveValueColor = valueColor ?? colorScheme.primary;

    return SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: effectiveSize,
            height: effectiveSize,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: effectiveStrokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                backgroundColor ?? colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              strokeCap: strokeCap ?? StrokeCap.round,
            ),
          ),
          // Progress circle
          if (showAnimation)
            AnimatedBuilder(
              animation: AlwaysStoppedAnimation(clampedValue),
              builder: (context, child) => SizedBox(
                width: effectiveSize,
                height: effectiveSize,
                child: CircularProgressIndicator(
                  value: clampedValue,
                  strokeWidth: effectiveStrokeWidth,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(effectiveValueColor),
                  strokeCap: strokeCap ?? StrokeCap.round,
                ),
              ),
            )
          else
            SizedBox(
              width: effectiveSize,
              height: effectiveSize,
              child: CircularProgressIndicator(
                value: clampedValue,
                strokeWidth: effectiveStrokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveValueColor),
                strokeCap: strokeCap ?? StrokeCap.round,
              ),
            ),
          // Center content
          if (centerWidget != null)
            centerWidget!
          else if (centerText != null)
            Text(
              centerText!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            )
          else if (showPercentage)
            Text(
              '${(clampedValue * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

/// Budget progress indicator with amount display
class BudgetProgressIndicator extends StatelessWidget {
  final double spent;
  final double budget;
  final String? currency;
  final String? categoryName;
  final bool showAmounts;
  final bool showPercentage;
  final EdgeInsetsGeometry? padding;

  const BudgetProgressIndicator({
    super.key,
    required this.spent,
    required this.budget,
    this.currency,
    this.categoryName,
    this.showAmounts = true,
    this.showPercentage = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > budget;
    final remaining = budget - spent;

    return Container(
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category name and percentage
          if (categoryName != null || showPercentage)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (categoryName != null)
                  Expanded(
                    child: Text(
                      categoryName!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (showPercentage)
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getProgressColor(progress, isOverBudget),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: AppDimensions.spacingS),

          // Progress bar
          ProgressIndicatorWidget(
            value: progress,
            height: 8.0,
            valueColor: _getProgressColor(progress, isOverBudget),
            showAnimation: true,
          ),

          if (showAmounts) ...[
            const SizedBox(height: AppDimensions.spacingS),

            // Amount information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'budgets.spent'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    CurrencyDisplaySmall(
                      amount: spent,
                      currency: currency,
                      autoColor: false,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOverBudget
                          ? 'budgets.exceeded'.tr()
                          : 'budgets.remaining'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    CurrencyDisplaySmall(
                      amount: isOverBudget ? (spent - budget) : remaining,
                      currency: currency,
                      autoColor: false,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getProgressColor(double progress, bool isOverBudget) {
    if (isOverBudget) return AppColors.error;
    if (progress < 0.7) return AppColors.success;
    if (progress < 0.9) return AppColors.warning;
    return AppColors.error;
  }
}

/// Goal progress indicator with target display
class GoalProgressIndicator extends StatelessWidget {
  final double current;
  final double target;
  final String? currency;
  final String? goalName;
  final DateTime? targetDate;
  final bool showAmounts;
  final bool showPercentage;
  final EdgeInsetsGeometry? padding;

  const GoalProgressIndicator({
    super.key,
    required this.current,
    required this.target,
    this.currency,
    this.goalName,
    this.targetDate,
    this.showAmounts = true,
    this.showPercentage = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isCompleted = current >= target;
    final remaining = target - current;

    return Container(
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with goal name and percentage
          if (goalName != null || showPercentage)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (goalName != null)
                  Expanded(
                    child: Text(
                      goalName!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (showPercentage)
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isCompleted ? AppColors.success : AppColors.primary,
                    ),
                  ),
              ],
            ),

          const SizedBox(height: AppDimensions.spacingS),

          // Progress bar
          ProgressIndicatorWidget(
            value: progress,
            height: 8.0,
            valueColor: isCompleted ? AppColors.success : AppColors.primary,
            showAnimation: true,
          ),

          if (showAmounts) ...[
            const SizedBox(height: AppDimensions.spacingS),

            // Amount information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'goals.current'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    CurrencyDisplaySmall(
                      amount: current,
                      currency: currency,
                      autoColor: false,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isCompleted
                          ? 'goals.completed'.tr()
                          : 'goals.remaining'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    if (isCompleted)
                      Text(
                        'goals.achieved'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      CurrencyDisplaySmall(
                        amount: remaining,
                        currency: currency,
                      ),
                  ],
                ),
              ],
            ),
          ],

          // Target date information
          if (targetDate != null) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              '${'goals.targetDate'.tr()}: ${DateFormat.yMMMd().format(targetDate!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Step progress indicator for multi-step processes
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? completedColor;
  final double? lineHeight;
  final double? circleRadius;
  final EdgeInsetsGeometry? padding;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
    this.activeColor,
    this.inactiveColor,
    this.completedColor,
    this.lineHeight,
    this.circleRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveActiveColor = activeColor ?? colorScheme.primary;
    final effectiveInactiveColor =
        inactiveColor ?? colorScheme.outline.withOpacity(0.3);
    final effectiveCompletedColor = completedColor ?? AppColors.success;

    return Container(
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          // Step indicators
          Row(
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < currentStep;
              final isActive = index == currentStep;
              final isInactive = index > currentStep;

              Color circleColor;
              if (isCompleted) {
                circleColor = effectiveCompletedColor;
              } else if (isActive) {
                circleColor = effectiveActiveColor;
              } else {
                circleColor = effectiveInactiveColor;
              }

              return Expanded(
                child: Row(
                  children: [
                    // Step circle
                    Container(
                      width: (circleRadius ?? 12) * 2,
                      height: (circleRadius ?? 12) * 2,
                      decoration: BoxDecoration(
                        color: circleColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(
                                Icons.check_rounded,
                                size: circleRadius ?? 12,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (circleRadius ?? 12) * 0.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    // Connection line (except for last step)
                    if (index < totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: lineHeight ?? 2,
                          color: isCompleted
                              ? effectiveCompletedColor
                              : effectiveInactiveColor,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),

          // Step labels
          if (stepLabels != null && stepLabels!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              children: List.generate(totalSteps, (index) {
                if (index >= stepLabels!.length)
                  return const Expanded(child: SizedBox());

                final isCompleted = index < currentStep;
                final isActive = index == currentStep;

                return Expanded(
                  child: Text(
                    stepLabels![index],
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: (isCompleted || isActive)
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
