import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:money_manager/presentation/screens/analytics/widgets/date_range_selector.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../presentation/providers/analytics_provider.dart';
import '../../../../presentation/providers/category_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/error_widget.dart';

class SpendingInsightsCard extends ConsumerWidget {
  final DateRange dateRange;
  final DateRange? comparisonRange;

  const SpendingInsightsCard({
    super.key,
    required this.dateRange,
    this.comparisonRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final spendingAsync = ref.watch(spendingByCategoryProvider(dateRange));
    final comparisonAsync = comparisonRange != null
        ? ref.watch(spendingByCategoryProvider(comparisonRange!))
        : null;

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: AppDimensions.spacingL),

            // Content
            spendingAsync.when(
              loading: () => const ShimmerLoading(child: SizedBox(height: 100)),
              error: (error, stack) => CustomErrorWidget(
                title: 'analytics.insightsError'.tr(),
                message: error.toString(),
                onActionPressed: () =>
                    ref.refresh(spendingByCategoryProvider(dateRange)),
              ),
              data: (spendingData) => _buildInsights(
                context,
                ref,
                spendingData,
                comparisonAsync?.value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingS),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            Icons.insights,
            color: AppColors.info,
            size: AppDimensions.iconM,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'analytics.spendingInsights'.tr(),
                style: theme.textTheme.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'analytics.keyMetrics'.tr(),
                style: theme.textTheme.muted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsights(
    BuildContext context,
    WidgetRef ref,
    Map<String, double> spendingData,
    Map<String, double>? comparisonData,
  ) {
    if (spendingData.isEmpty) {
      return _buildEmptyState(context);
    }

    final insights = _calculateInsights(spendingData, comparisonData);

    return Column(
      children: [
        // Total spending
        _buildTotalSpending(context, insights),
        const SizedBox(height: AppDimensions.spacingL),

        // Key metrics
        _buildKeyMetrics(context, insights),
        const SizedBox(height: AppDimensions.spacingL),

        // Top categories
        _buildTopCategories(context, ref, insights),
        const SizedBox(height: AppDimensions.spacingL),

        // Insights list
        _buildInsightsList(context, insights),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Center(
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 64,
            color: theme.colorScheme.mutedForeground.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            'analytics.noInsights'.tr(),
            style: theme.textTheme.p.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSpending(BuildContext context, SpendingInsights insights) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'analytics.totalSpent'.tr(),
                  style: theme.textTheme.small.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  CurrencyFormatter.format(insights.totalSpent),
                  style: theme.textTheme.h2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (insights.comparisonChange != null) ...[
                  const SizedBox(height: AppDimensions.spacingS),
                  _buildChangeIndicator(insights.comparisonChange!),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              size: AppDimensions.iconL,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(BuildContext context, SpendingInsights insights) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            'analytics.avgDaily'.tr(),
            CurrencyFormatter.format(insights.averageDailySpending),
            Icons.calendar_today,
            AppColors.success,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: _buildMetricCard(
            context,
            'analytics.categories'.tr(),
            insights.categoriesCount.toString(),
            Icons.category,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: _buildMetricCard(
            context,
            'analytics.topCategory'.tr(),
            '${insights.topCategoryPercentage.toStringAsFixed(0)}%',
            Icons.trending_up,
            AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: AppDimensions.iconM,
            color: color,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            value,
            style: theme.textTheme.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            title,
            style: theme.textTheme.small.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories(
    BuildContext context,
    WidgetRef ref,
    SpendingInsights insights,
  ) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'analytics.topSpendingCategories'.tr(),
          style: theme.textTheme.p.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        ...insights.topCategories
            .take(3)
            .map((category) => _buildCategoryItem(context, ref, category)),
      ],
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    WidgetRef ref,
    TopCategory category,
  ) {
    final theme = ShadTheme.of(context);
    final categoryName = _getCategoryName(ref, category.categoryId);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingS),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(
              _getCategoryIcon(ref, category.categoryId),
              size: AppDimensions.iconS,
              color: category.color,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${category.percentage.toStringAsFixed(1)}% of total',
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(category.amount),
            style: theme.textTheme.p.copyWith(
              fontWeight: FontWeight.w600,
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsList(BuildContext context, SpendingInsights insights) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'analytics.insights'.tr(),
          style: theme.textTheme.p.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        ...insights.insights
            .map((insight) => _buildInsightItem(context, insight)),
      ],
    );
  }

  Widget _buildInsightItem(BuildContext context, String insight) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.info,
              borderRadius: BorderRadius.circular(3),
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
    );
  }

  Widget _buildChangeIndicator(double change) {
    final isPositive = change > 0;
    final color = isPositive ? AppColors.error : AppColors.success;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final text = isPositive ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: AppDimensions.spacingXs),
        Text(
          '$text${change.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingXs),
        Text(
          'analytics.vsPrevious'.tr(),
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  SpendingInsights _calculateInsights(
    Map<String, double> spendingData,
    Map<String, double>? comparisonData,
  ) {
    final totalSpent =
        spendingData.values.fold(0.0, (sum, amount) => sum + amount);
    final categoriesCount = spendingData.length;
    final dayCount = dateRange.start.difference(dateRange.end).inDays.abs() + 1;
    final averageDailySpending = totalSpent / dayCount;

    // Calculate comparison change
    double? comparisonChange;
    if (comparisonData != null) {
      final previousTotal =
          comparisonData.values.fold(0.0, (sum, amount) => sum + amount);
      if (previousTotal > 0) {
        comparisonChange = ((totalSpent - previousTotal) / previousTotal) * 100;
      }
    }

    // Top categories
    final sortedCategories = spendingData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories.take(5).map((entry) {
      final percentage = totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0;
      final color = AppColors.categoryColors[
          sortedCategories.indexOf(entry) % AppColors.categoryColors.length];

      return TopCategory(
        categoryId: entry.key,
        amount: entry.value,
        percentage: percentage.toDouble(),
        color: color,
      );
    }).toList();

    final topCategoryPercentage =
        topCategories.isNotEmpty ? topCategories.first.percentage : 0.0;

    // Generate insights
    final insights = _generateInsights(
      totalSpent,
      averageDailySpending,
      categoriesCount,
      topCategoryPercentage,
      comparisonChange,
    );

    return SpendingInsights(
      totalSpent: totalSpent,
      categoriesCount: categoriesCount,
      averageDailySpending: averageDailySpending,
      topCategoryPercentage: topCategoryPercentage,
      comparisonChange: comparisonChange,
      topCategories: topCategories,
      insights: insights,
    );
  }

  List<String> _generateInsights(
    double totalSpent,
    double averageDailySpending,
    int categoriesCount,
    double topCategoryPercentage,
    double? comparisonChange,
  ) {
    final insights = <String>[];

    if (totalSpent > 0) {
      insights.add('analytics.spentTotal'.tr(args: [
        CurrencyFormatter.format(totalSpent),
        dateRange.start.toString()
      ]));
    }

    if (averageDailySpending > 0) {
      insights.add('analytics.avgDailySpending'
          .tr(args: [CurrencyFormatter.format(averageDailySpending)]));
    }

    if (topCategoryPercentage > 50) {
      insights.add('analytics.topCategoryDominant'
          .tr(args: [topCategoryPercentage.toStringAsFixed(0)]));
    }

    if (categoriesCount <= 3) {
      insights.add('analytics.fewCategories'.tr());
    } else if (categoriesCount >= 8) {
      insights.add('analytics.manyCategories'.tr());
    }

    if (comparisonChange != null) {
      if (comparisonChange > 20) {
        insights.add('analytics.spendingIncreased'
            .tr(args: [comparisonChange.toStringAsFixed(0)]));
      } else if (comparisonChange < -20) {
        insights.add('analytics.spendingDecreased'
            .tr(args: [comparisonChange.abs().toStringAsFixed(0)]));
      }
    }

    return insights;
  }

  String _getCategoryName(WidgetRef ref, String categoryId) {
    final categoryAsync = ref.read(categoryProvider(categoryId));
    return categoryAsync.when(
      data: (category) => category?.name ?? categoryId,
      loading: () => categoryId,
      error: (_, __) => categoryId,
    );
  }

  IconData _getCategoryIcon(WidgetRef ref, String categoryId) {
    final categoryAsync = ref.read(categoryProvider(categoryId));
    return categoryAsync.when(
      data: (category) {
        if (category == null) return Icons.category;

        switch (category.iconName.toLowerCase()) {
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
          default:
            return Icons.category;
        }
      },
      loading: () => Icons.category,
      error: (_, __) => Icons.category,
    );
  }
}

// Data models
class SpendingInsights {
  final double totalSpent;
  final int categoriesCount;
  final double averageDailySpending;
  final double topCategoryPercentage;
  final double? comparisonChange;
  final List<TopCategory> topCategories;
  final List<String> insights;

  const SpendingInsights({
    required this.totalSpent,
    required this.categoriesCount,
    required this.averageDailySpending,
    required this.topCategoryPercentage,
    this.comparisonChange,
    required this.topCategories,
    required this.insights,
  });
}

class TopCategory {
  final String categoryId;
  final double amount;
  final double percentage;
  final Color color;

  const TopCategory({
    required this.categoryId,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}
