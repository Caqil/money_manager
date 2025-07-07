import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../providers/analytics_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/error_widget.dart';
import '../../analytics/widgets/date_range_selector.dart';

class SpendingChartWidget extends ConsumerStatefulWidget {
  const SpendingChartWidget({super.key});

  @override
  ConsumerState<SpendingChartWidget> createState() =>
      _SpendingChartWidgetState();
}

class _SpendingChartWidgetState extends ConsumerState<SpendingChartWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final dateRange = DateRange(start: startOfMonth, end: endOfMonth);

    final spendingDataAsync = ref.watch(spendingByCategoryProvider(dateRange));

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: AppDimensions.spacingM),

            // Content
            spendingDataAsync.when(
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
              data: (spendingData) => _buildContent(spendingData),
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
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            Icons.bar_chart,
            color: AppColors.accent,
            size: AppDimensions.iconM,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'dashboard.topExpenses'.tr(),
                style: theme.textTheme.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'dashboard.thisMonth'.tr(),
                style: theme.textTheme.muted,
              ),
            ],
          ),
        ),
        ShadButton.outline(
          onPressed: () => context.push('/analytics'),
          size: ShadButtonSize.sm,
          child: Text('common.viewAll'.tr()),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const ShimmerLoading(
      child: Column(
        children: [
          SkeletonLoader(height: 120, width: double.infinity),
          SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                  child: SkeletonLoader(height: 20, width: double.infinity)),
              SizedBox(width: AppDimensions.spacingS),
              SkeletonLoader(height: 20, width: 60),
            ],
          ),
          SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              Expanded(
                  child: SkeletonLoader(height: 20, width: double.infinity)),
              SizedBox(width: AppDimensions.spacingS),
              SkeletonLoader(height: 20, width: 60),
            ],
          ),
          SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              Expanded(
                  child: SkeletonLoader(height: 20, width: double.infinity)),
              SizedBox(width: AppDimensions.spacingS),
              SkeletonLoader(height: 20, width: 60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return CustomErrorWidget(
      title: 'Error loading spending data',
      message: error.toString(),
      actionText: 'common.retry'.tr(),
      onActionPressed: () {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        final dateRange = DateRange(start: startOfMonth, end: endOfMonth);
        ref.refresh(spendingByCategoryProvider(dateRange));
      },
    );
  }

  Widget _buildContent(Map<String, double> spendingData) {
    final theme = ShadTheme.of(context);

    if (spendingData.isEmpty) {
      return _buildEmptyState();
    }

    // Sort categories by spending amount
    final sortedEntries = spendingData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 categories
    final topCategories = sortedEntries.take(5).toList();
    final totalSpent =
        spendingData.values.fold(0.0, (sum, amount) => sum + amount);

    return Column(
      children: [
        // Visual Chart Representation
        _buildBarChart(topCategories, totalSpent),

        const SizedBox(height: AppDimensions.spacingM),

        // Category List
        ...topCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final categoryEntry = entry.value;
          final percentage =
              totalSpent > 0 ? (categoryEntry.value / totalSpent) * 100 : 0;
          final isLast = index == topCategories.length - 1;

          return Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : AppDimensions.spacingS,
            ),
            child: _buildCategoryItem(
              categoryEntry.key,
              categoryEntry.value,
              percentage.toDouble(),
              _getCategoryColor(index),
            ),
          );
        }),

        // Show total if there are more categories
        if (sortedEntries.length > 5) ...[
          const SizedBox(height: AppDimensions.spacingS),
          const Divider(),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total (${sortedEntries.length} categories)',
                style: theme.textTheme.p.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                CurrencyFormatter.format(totalSpent),
                style: theme.textTheme.p.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        Icon(
          Icons.bar_chart_outlined,
          size: 64,
          color: theme.colorScheme.mutedForeground.withOpacity(0.5),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          'No spending data',
          style: theme.textTheme.p.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          'Add some expenses to see your spending breakdown',
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        ShadButton(
          onPressed: () => context.push('/transactions/add?type=expense'),
          size: ShadButtonSize.sm,
          child: Text('quickActions.addExpense'.tr()),
        ),
      ],
    );
  }

  Widget _buildBarChart(
      List<MapEntry<String, double>> categories, double total) {
    if (categories.isEmpty || total <= 0) {
      return const SizedBox(height: 120);
    }

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: categories.asMap().entries.map((entry) {
            final index = entry.key;
            final categoryEntry = entry.value;
            final percentage = categoryEntry.value / total;
            final height =
                (percentage * 80).clamp(8.0, 80.0); // Min height 8, max 80
            final color = _getCategoryColor(index);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: categories.length > 3 ? 2.0 : 4.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Amount label
                    Text(
                      CurrencyFormatter.formatCompact(categoryEntry.value),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // Bar
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.easeOutBack,
                      height: height,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            color,
                            color.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Category label
                    Text(
                      _getCategoryDisplayName(categoryEntry.key),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    String categoryId,
    double amount,
    double percentage,
    Color color,
  ) {
    final theme = ShadTheme.of(context);

    return Row(
      children: [
        // Color indicator
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),

        // Category name
        Expanded(
          child: Text(
            _getCategoryDisplayName(categoryId),
            style: theme.textTheme.p.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Percentage
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(width: AppDimensions.spacingS),

        // Amount
        Text(
          CurrencyFormatter.format(amount),
          style: theme.textTheme.p.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(int index) {
    const colors = [
      AppColors.error,
      AppColors.warning,
      AppColors.info,
      AppColors.success,
      AppColors.secondary,
    ];
    return colors[index % colors.length];
  }

  String _getCategoryDisplayName(String categoryId) {
    // For now, return the category ID
    // In a real app, you would fetch the category name from the category provider
    // Example: final category = ref.read(categoryProvider(categoryId));
    return categoryId.length > 15
        ? '${categoryId.substring(0, 12)}...'
        : categoryId;
  }
}
