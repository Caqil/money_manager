import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/budget.dart';
import '../../../../presentation/providers/analytics_provider.dart';
import '../../../../presentation/providers/category_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/error_widget.dart';

class BudgetProgressCard extends ConsumerWidget {
  final Budget budget;
  final double? spentAmount;
  final bool showChart;
  final bool showInsights;
  final bool showComparison;

  const BudgetProgressCard({
    super.key,
    required this.budget,
    this.spentAmount,
    this.showChart = true,
    this.showInsights = true,
    this.showComparison = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final budgetPerformanceAsync = ref.watch(budgetPerformanceProvider);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: budgetPerformanceAsync.when(
          loading: () => const Center(
              child: ShimmerLoading(
            child: SizedBox(),
          )),
          error: (error, stack) => CustomErrorWidget(
            title: 'budgets.loadError'.tr(),
            message: error.toString(),
            onActionPressed: () => ref.refresh(budgetPerformanceProvider),
          ),
          data: (performances) {
            final performance = performances.firstWhere(
              (p) => p.budget.id == budget.id,
              orElse: () => BudgetPerformance(
                budget: budget,
                spentAmount: spentAmount ?? 0.0,
                remainingAmount: budget.limit - (spentAmount ?? 0.0),
                percentageUsed: budget.limit > 0
                    ? (spentAmount ?? 0.0) / budget.limit
                    : 0.0,
                isOverBudget: (spentAmount ?? 0.0) > budget.limit,
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context, ref),
                const SizedBox(height: AppDimensions.spacingL),

                // Main progress display
                _buildMainProgress(context, performance),

                if (showChart) ...[
                  const SizedBox(height: AppDimensions.spacingL),
                  _buildProgressChart(context, performance),
                ],

                if (showInsights) ...[
                  const SizedBox(height: AppDimensions.spacingL),
                  _buildInsights(context, performance),
                ],

                if (showComparison) ...[
                  const SizedBox(height: AppDimensions.spacingL),
                  _buildComparison(context, performance),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final categoryAsync = ref.watch(categoryProvider(budget.categoryId));

    return Row(
      children: [
        // Category icon
        categoryAsync.when(
          data: (category) {
            final color =
                category != null ? Color(category.color) : AppColors.primary;
            return Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                _getCategoryIcon(category?.iconName),
                color: color,
                size: AppDimensions.iconL,
              ),
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: const Icon(Icons.category),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: const Icon(Icons.category),
          ),
        ),

        const SizedBox(width: AppDimensions.spacingM),

        // Budget info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                budget.name,
                style: theme.textTheme.h3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              categoryAsync.when(
                data: (category) => Text(
                  category?.name ?? 'budgets.unknownCategory'.tr(),
                  style: theme.textTheme.p.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Row(
                children: [
                  _buildPeriodChip(context),
                  const SizedBox(width: AppDimensions.spacingS),
                  if (budget.enableAlerts) _buildAlertChip(context),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        _getPeriodLabel(budget.period),
        style: theme.textTheme.small.copyWith(
          color: AppColors.info,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildAlertChip(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_active,
            size: 10,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          Text(
            '${(budget.alertThreshold * 100).toInt()}%',
            style: theme.textTheme.small.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainProgress(
      BuildContext context, BudgetPerformance performance) {
    final theme = ShadTheme.of(context);
    final percentage = performance.percentageUsed;

    Color progressColor;
    if (percentage >= 1.0) {
      progressColor = AppColors.error;
    } else if (percentage >= budget.alertThreshold) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            progressColor.withOpacity(0.1),
            progressColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: progressColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Amount details
          Row(
            children: [
              Expanded(
                child: _buildAmountColumn(
                  context,
                  'budgets.spent'.tr(),
                  performance.spentAmount,
                  AppColors.error,
                  Icons.trending_down,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: _buildAmountColumn(
                  context,
                  'budgets.remaining'.tr(),
                  performance.remainingAmount,
                  AppColors.success,
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: _buildAmountColumn(
                  context,
                  'budgets.limit'.tr(),
                  budget.limit,
                  AppColors.primary,
                  Icons.flag,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'budgets.progress'.tr(),
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Stack(
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusS),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percentage.clamp(0.0, 1.0),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            progressColor,
                            progressColor.withOpacity(0.8)
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                        boxShadow: [
                          BoxShadow(
                            color: progressColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Alert threshold indicator
                  Positioned(
                    left: MediaQuery.of(context).size.width *
                            0.7 *
                            budget.alertThreshold -
                        1,
                    child: Container(
                      width: 2,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountColumn(
    BuildContext context,
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingS),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: Icon(
            icon,
            color: color,
            size: AppDimensions.iconM,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          CurrencyFormatter.format(amount),
          style: theme.textTheme.h4.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          label,
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressChart(
      BuildContext context, BudgetPerformance performance) {
    final theme = ShadTheme.of(context);
    final percentage = performance.percentageUsed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'budgets.progressVisualization'.tr(),
          style: theme.textTheme.p.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),

        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: [
                // Spent amount
                PieChartSectionData(
                  color: AppColors.error,
                  value: performance.spentAmount,
                  title: '${(percentage * 100).toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Remaining amount
                if (performance.remainingAmount > 0)
                  PieChartSectionData(
                    color: AppColors.success,
                    value: performance.remainingAmount,
                    title: '',
                    radius: 50,
                  ),
              ],
            ),
          ),
        ),

        // Legend
        const SizedBox(height: AppDimensions.spacingM),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(
              context,
              'budgets.spent'.tr(),
              AppColors.error,
              CurrencyFormatter.format(performance.spentAmount),
            ),
            if (performance.remainingAmount > 0)
              _buildLegendItem(
                context,
                'budgets.remaining'.tr(),
                AppColors.success,
                CurrencyFormatter.format(performance.remainingAmount),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    Color color,
    String value,
  ) {
    final theme = ShadTheme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsights(BuildContext context, BudgetPerformance performance) {
    final theme = ShadTheme.of(context);
    final insights = _generateInsights(performance);

    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'budgets.insights'.tr(),
          style: theme.textTheme.p.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: AppColors.info.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: insights
                .map((insight) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.spacingS),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.info,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          Expanded(
                            child: Text(
                              insight,
                              style: theme.textTheme.small.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildComparison(BuildContext context, BudgetPerformance performance) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'budgets.comparison'.tr(),
          style: theme.textTheme.p.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Text(
            'budgets.comparisonPlaceholder'.tr(),
            style: theme.textTheme.p.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }

  List<String> _generateInsights(BudgetPerformance performance) {
    final insights = <String>[];
    final percentage = performance.percentageUsed;
    final daysInPeriod = _getDaysInPeriod(budget.period);
    final now = DateTime.now();
    final daysPassed =
        now.difference(budget.startDate).inDays.clamp(1, daysInPeriod);
    final expectedPercentage = daysPassed / daysInPeriod;

    if (percentage > expectedPercentage + 0.1) {
      insights.add('budgets.spendingAheadOfSchedule'.tr());
    } else if (percentage < expectedPercentage - 0.1) {
      insights.add('budgets.spendingBehindSchedule'.tr());
    } else {
      insights.add('budgets.spendingOnTrack'.tr());
    }

    if (percentage >= 1.0) {
      insights.add('budgets.budgetExceeded'.tr());
    } else if (percentage >= budget.alertThreshold) {
      insights.add('budgets.approachingLimit'.tr());
    }

    if (performance.remainingAmount > 0) {
      final dailyBudget = performance.remainingAmount /
          (daysInPeriod - daysPassed).clamp(1, daysInPeriod);
      insights.add('budgets.dailyBudgetRemaining'
          .tr(args: [CurrencyFormatter.format(dailyBudget)]));
    }

    return insights;
  }

  int _getDaysInPeriod(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return 7;
      case BudgetPeriod.monthly:
        return 30;
      case BudgetPeriod.quarterly:
        return 90;
      case BudgetPeriod.yearly:
        return 365;
      case BudgetPeriod.custom:
        return budget.endDate?.difference(budget.startDate).inDays ?? 30;
    }
  }

  String _getPeriodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'budgets.periods.weekly'.tr();
      case BudgetPeriod.monthly:
        return 'budgets.periods.monthly'.tr();
      case BudgetPeriod.quarterly:
        return 'budgets.periods.quarterly'.tr();
      case BudgetPeriod.yearly:
        return 'budgets.periods.yearly'.tr();
      case BudgetPeriod.custom:
        return 'budgets.periods.custom'.tr();
    }
  }

  IconData _getCategoryIcon(String? iconName) {
    if (iconName == null) return Icons.category;

    switch (iconName.toLowerCase()) {
      case 'food':
      case 'restaurant':
        return Icons.restaurant;
      case 'transport':
      case 'car':
        return Icons.directions_car;
      case 'shopping':
      case 'shop':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'health':
      case 'medical':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'utilities':
        return Icons.electrical_services;
      case 'home':
      case 'house':
        return Icons.home;
      default:
        return Icons.category;
    }
  }
}
