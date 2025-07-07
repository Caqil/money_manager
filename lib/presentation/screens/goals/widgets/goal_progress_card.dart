import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/goal.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/common/currency_display_widget.dart';

class GoalProgressCard extends ConsumerWidget {
  final Goal goal;
  final bool showTitle;
  final bool compact;
  final bool showActions;
  final VoidCallback? onAddFunds;
  final VoidCallback? onViewDetails;

  const GoalProgressCard({
    super.key,
    required this.goal,
    this.showTitle = true,
    this.compact = false,
    this.showActions = false,
    this.onAddFunds,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final currency = ref.watch(baseCurrencyProvider);

    return ShadCard(
      child: Padding(
        padding: EdgeInsets.all(
            compact ? AppDimensions.paddingM : AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              _buildHeader(theme),
              const SizedBox(height: AppDimensions.spacingM),
            ],
            _buildAmountSection(currency, theme),
            const SizedBox(height: AppDimensions.spacingM),
            _buildProgressBar(context, theme),
            const SizedBox(height: AppDimensions.spacingM),
            _buildProgressDetails(currency, theme),
            if (!compact) ...[
              const SizedBox(height: AppDimensions.spacingM),
              _buildTimelineInfo(ref, theme),
            ],
            if (showActions) ...[
              const SizedBox(height: AppDimensions.spacingM),
              _buildActionButtons(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ShadThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.trending_up,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            'goals.progress'.tr(),
            style: theme.textTheme.h4.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        if (goal.isCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'goals.completed'.tr(),
                  style: theme.textTheme.small.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAmountSection(String currency, ShadThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'goals.currentAmount'.tr(),
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 2),
              CurrencyDisplayLarge(
                amount: goal.currentAmount,
                currency: currency,
                autoColor: false,
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: theme.colorScheme.border,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'goals.targetAmount'.tr(),
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: 2),
              CurrencyDisplayLarge(
                amount: goal.targetAmount,
                currency: currency,
                autoColor: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, ShadThemeData theme) {
    final progressPercentage = goal.progressPercentage;
    final progressColor = _getProgressColor(progressPercentage);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'goals.progress'.tr(),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            Text(
              '${progressPercentage.toInt()}%',
              style: theme.textTheme.p.copyWith(
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Stack(
          children: [
            Container(
              height: compact ? 6 : 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.muted,
                borderRadius: BorderRadius.circular(compact ? 3 : 4),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              height: compact ? 6 : 8,
              width: MediaQuery.of(context).size.width *
                  (progressPercentage / 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    progressColor,
                    progressColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(compact ? 3 : 4),
                boxShadow: progressPercentage > 0
                    ? [
                        BoxShadow(
                          color: progressColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressDetails(String currency, ShadThemeData theme) {
    final remaining = goal.targetAmount - goal.currentAmount;
    final progressPercentage = goal.progressPercentage;

    return Row(
      children: [
        Expanded(
          child: _buildProgressDetailItem(
            'goals.remaining'.tr(),
            CurrencyFormatter.format(remaining.clamp(0, double.infinity),
                currency: currency),
            remaining <= 0 ? AppColors.success : AppColors.primary,
            theme,
          ),
        ),
        Expanded(
          child: _buildProgressDetailItem(
            'goals.achieved'.tr(),
            '${progressPercentage.toInt()}%',
            _getProgressColor(progressPercentage),
            theme,
          ),
        ),
        if (goal.monthlyTarget > 0)
          Expanded(
            child: _buildProgressDetailItem(
              'goals.monthlyTarget'.tr(),
              CurrencyFormatter.format(goal.monthlyTarget, currency: currency),
              AppColors.info,
              theme,
            ),
          ),
      ],
    );
  }

  Widget _buildProgressDetailItem(
      String label, String value, Color color, ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.small.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.p.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineInfo(WidgetRef ref, ShadThemeData theme) {
    if (goal.targetDate == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final daysRemaining = goal.targetDate!.difference(now).inDays;
    final isOverdue = daysRemaining < 0;

    final timelineColor = isOverdue
        ? AppColors.error
        : daysRemaining <= 30
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: timelineColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: timelineColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning : Icons.schedule,
            color: timelineColor,
            size: 16,
          ),
          const SizedBox(width: AppDimensions.spacingS),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverdue
                      ? 'goals.overdue'.tr()
                      : daysRemaining == 0
                          ? 'goals.dueToday'.tr()
                          : daysRemaining == 1
                              ? 'goals.dueTomorrow'.tr()
                              : 'goals.daysRemaining'
                                  .tr(args: [daysRemaining.abs().toString()]),
                  style: theme.textTheme.small.copyWith(
                    color: timelineColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${'goals.targetDate'.tr()}: ${DateFormat.yMMMd().format(goal.targetDate!)}',
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),

          // Weekly/monthly requirement
          if (!isOverdue && daysRemaining > 0 && goal.monthlyTarget > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'goals.weeklyNeeded'.tr(),
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                CurrencyDisplaySmall(
                  amount: goal.monthlyTarget / 4.33, // Average weeks per month
                  currency: ref.watch(baseCurrencyProvider),
                  autoColor: false,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ShadThemeData theme) {
    if (goal.isCompleted) {
      return Row(
        children: [
          Expanded(
            child: ShadButton.outline(
              onPressed: onViewDetails,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility, size: 16),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Text('goals.viewDetails'.tr()),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (onAddFunds != null) ...[
          Expanded(
            child: ShadButton(
              onPressed: onAddFunds,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 16),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Text('goals.addFunds'.tr()),
                ],
              ),
            ),
          ),
          if (onViewDetails != null)
            const SizedBox(width: AppDimensions.spacingS),
        ],
        if (onViewDetails != null)
          Expanded(
            child: ShadButton.outline(
              onPressed: onViewDetails,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility, size: 16),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Text('goals.viewDetails'.tr()),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 100) return AppColors.success;
    if (percentage >= 75) return AppColors.primary;
    if (percentage >= 50) return AppColors.info;
    if (percentage >= 25) return AppColors.warning;
    return AppColors.error;
  }
}

// Compact version for small spaces
class CompactGoalProgressCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;

  const CompactGoalProgressCard({
    super.key,
    required this.goal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: GoalProgressCard(
        goal: goal,
        showTitle: false,
        compact: true,
        showActions: false,
      ),
    );
  }
}

// Summary card for multiple goals
class GoalsSummaryCard extends ConsumerWidget {
  final List<Goal> goals;
  final VoidCallback? onViewAll;

  const GoalsSummaryCard({
    super.key,
    required this.goals,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final currency = ref.watch(baseCurrencyProvider);

    if (goals.isEmpty) {
      return _buildEmptyState(theme);
    }

    final totalTarget = goals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
    final totalCurrent =
        goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
    final averageProgress =
        goals.fold(0.0, (sum, goal) => sum + goal.progressPercentage) /
            goals.length;
    final completedGoals = goals.where((goal) => goal.isCompleted).length;

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    'goals.summary'.tr(),
                    style: theme.textTheme.h4.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (onViewAll != null)
                  ShadButton.outline(
                    onPressed: onViewAll,
                    child: Text('common.viewAll'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // Summary stats
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'goals.totalGoals'.tr(),
                    goals.length.toString(),
                    AppColors.primary,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'goals.completed'.tr(),
                    completedGoals.toString(),
                    AppColors.success,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'goals.avgProgress'.tr(),
                    '${averageProgress.toInt()}%',
                    _getProgressColor(averageProgress),
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // Total amounts
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'goals.totalSaved'.tr(),
                        style: theme.textTheme.small.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                      CurrencyDisplayMedium(
                        amount: totalCurrent,
                        currency: currency,
                        autoColor: false,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'goals.totalTarget'.tr(),
                        style: theme.textTheme.small.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      CurrencyDisplayMedium(
                        amount: totalTarget,
                        currency: currency,
                        autoColor: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // Overall progress
            LinearProgressIndicator(
              value: totalTarget > 0
                  ? (totalCurrent / totalTarget).clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor: theme.colorScheme.muted,
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(averageProgress)),
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, Color color, ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.small.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ShadThemeData theme) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          children: [
            Icon(
              Icons.flag_outlined,
              size: 48,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'goals.noGoals'.tr(),
              style: theme.textTheme.h4.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'goals.createFirstGoal'.tr(),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 100) return AppColors.success;
    if (percentage >= 75) return AppColors.primary;
    if (percentage >= 50) return AppColors.info;
    if (percentage >= 25) return AppColors.warning;
    return AppColors.error;
  }
}
