import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/budget.dart';
import '../../../../presentation/providers/analytics_provider.dart';
import '../../../../presentation/providers/category_provider.dart';

class BudgetAlertWidget extends ConsumerWidget {
  final Budget budget;
  final double spentAmount;
  final bool showActions;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewDetails;

  const BudgetAlertWidget({
    super.key,
    required this.budget,
    required this.spentAmount,
    this.showActions = true,
    this.onDismiss,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final percentage = budget.limit > 0 ? (spentAmount / budget.limit) : 0.0;
    final alertType = _getAlertType(percentage, budget.alertThreshold);

    if (alertType == BudgetAlertType.none) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: ShadCard(
        padding: const EdgeInsets.all(AppDimensions.paddingS),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: _getAlertColor(alertType).withOpacity(0.3),
              width: 2,
            ),
            gradient: LinearGradient(
              colors: [
                _getAlertColor(alertType).withOpacity(0.1),
                _getAlertColor(alertType).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingS),
                      decoration: BoxDecoration(
                        color: _getAlertColor(alertType).withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
                      ),
                      child: Icon(
                        _getAlertIcon(alertType),
                        color: _getAlertColor(alertType),
                        size: AppDimensions.iconM,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getAlertTitle(alertType),
                            style: theme.textTheme.p.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getAlertColor(alertType),
                            ),
                          ),
                          Text(
                            _getCategoryName(ref, budget.categoryId),
                            style: theme.textTheme.small.copyWith(
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onDismiss != null)
                      ShadButton.ghost(
                        onPressed: onDismiss,
                        size: ShadButtonSize.sm,
                        child: Icon(
                          Icons.close,
                          size: AppDimensions.iconS,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spacingM),

                // Budget details
                _buildBudgetDetails(context, percentage),

                const SizedBox(height: AppDimensions.spacingM),

                // Progress bar
                _buildProgressBar(context, percentage, alertType),

                if (showActions) ...[
                  const SizedBox(height: AppDimensions.spacingM),
                  _buildActionButtons(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetDetails(BuildContext context, double percentage) {
    final theme = ShadTheme.of(context);
    final remaining = (budget.limit - spentAmount).clamp(0.0, double.infinity);

    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            context,
            'budgets.spent'.tr(),
            CurrencyFormatter.format(spentAmount),
            AppColors.error,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: _buildDetailItem(
            context,
            'budgets.remaining'.tr(),
            CurrencyFormatter.format(remaining),
            AppColors.success,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: _buildDetailItem(
            context,
            'budgets.limit'.tr(),
            CurrencyFormatter.format(budget.limit),
            AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          value,
          style: theme.textTheme.p.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    double percentage,
    BudgetAlertType alertType,
  ) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'budgets.progress'.tr(),
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.bold,
                color: _getAlertColor(alertType),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: _getAlertColor(alertType),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  boxShadow: [
                    BoxShadow(
                      color: _getAlertColor(alertType).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            // Alert threshold indicator
            Positioned(
              left: MediaQuery.of(context).size.width *
                      0.8 *
                      budget.alertThreshold -
                  1,
              child: Container(
                width: 2,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ShadButton.outline(
            onPressed: onViewDetails ??
                () {
                  context.push('/budgets/${budget.id}');
                },
            size: ShadButtonSize.sm,
            child: Text('budgets.viewDetails'.tr()),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: ShadButton(
            onPressed: () {
              context.push('/budgets/${budget.id}/edit');
            },
            size: ShadButtonSize.sm,
            child: Text('budgets.editBudget'.tr()),
          ),
        ),
      ],
    );
  }

  BudgetAlertType _getAlertType(double percentage, double threshold) {
    if (percentage >= 1.0) {
      return BudgetAlertType.overBudget;
    } else if (percentage >= threshold) {
      return BudgetAlertType.nearLimit;
    }
    return BudgetAlertType.none;
  }

  Color _getAlertColor(BudgetAlertType type) {
    switch (type) {
      case BudgetAlertType.overBudget:
        return AppColors.error;
      case BudgetAlertType.nearLimit:
        return AppColors.warning;
      case BudgetAlertType.none:
        return AppColors.success;
    }
  }

  IconData _getAlertIcon(BudgetAlertType type) {
    switch (type) {
      case BudgetAlertType.overBudget:
        return Icons.error;
      case BudgetAlertType.nearLimit:
        return Icons.warning;
      case BudgetAlertType.none:
        return Icons.check_circle;
    }
  }

  String _getAlertTitle(BudgetAlertType type) {
    switch (type) {
      case BudgetAlertType.overBudget:
        return 'budgets.overBudget'.tr();
      case BudgetAlertType.nearLimit:
        return 'budgets.nearLimit'.tr();
      case BudgetAlertType.none:
        return 'budgets.onTrack'.tr();
    }
  }

  String _getCategoryName(WidgetRef ref, String categoryId) {
    final categoryAsync = ref.read(categoryProvider(categoryId));
    return categoryAsync.when(
      data: (category) => category?.name ?? 'budgets.budget'.tr(),
      loading: () => 'budgets.budget'.tr(),
      error: (_, __) => 'budgets.budget'.tr(),
    );
  }
}

enum BudgetAlertType {
  none,
  nearLimit,
  overBudget,
}

// Budget alert provider for checking all active budgets
final budgetAlertsProvider = FutureProvider<List<BudgetAlert>>(
  (ref) async {
    final budgetPerformances = await ref.read(budgetPerformanceProvider.future);
    final alerts = <BudgetAlert>[];

    for (final performance in budgetPerformances) {
      final budget = performance.budget;
      final percentage = performance.percentageUsed;

      BudgetAlertType alertType;
      if (percentage >= 1.0) {
        alertType = BudgetAlertType.overBudget;
      } else if (percentage >= budget.alertThreshold) {
        alertType = BudgetAlertType.nearLimit;
      } else {
        continue; // No alert needed
      }

      if (budget.enableAlerts) {
        alerts.add(BudgetAlert(
          budget: budget,
          spentAmount: performance.spentAmount,
          alertType: alertType,
        ));
      }
    }

    return alerts;
  },
);

class BudgetAlert {
  final Budget budget;
  final double spentAmount;
  final BudgetAlertType alertType;

  const BudgetAlert({
    required this.budget,
    required this.spentAmount,
    required this.alertType,
  });
}
