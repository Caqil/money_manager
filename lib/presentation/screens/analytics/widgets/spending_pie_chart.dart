import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manager/presentation/screens/analytics/widgets/date_range_selector.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../presentation/providers/analytics_provider.dart';
import '../../../../presentation/providers/category_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/error_widget.dart';

class SpendingPieChart extends ConsumerStatefulWidget {
  final DateRange dateRange;
  final int maxCategories;
  final double size;
  final bool showLegend;
  final bool showCenter;
  final Function(String categoryId)? onSectionTapped;

  const SpendingPieChart({
    super.key,
    required this.dateRange,
    this.maxCategories = 6,
    this.size = 200,
    this.showLegend = true,
    this.showCenter = true,
    this.onSectionTapped,
  });

  @override
  ConsumerState<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends ConsumerState<SpendingPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final spendingAsync =
        ref.watch(spendingByCategoryProvider(widget.dateRange));

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

            // Chart
            spendingAsync.when(
              loading: () => SizedBox(
                height: widget.size + (widget.showLegend ? 150 : 0),
                child: const ShimmerLoading(child: SizedBox.shrink()),
              ),
              error: (error, stack) => SizedBox(
                height: widget.size + (widget.showLegend ? 150 : 0),
                child: CustomErrorWidget(
                  title: 'analytics.chartError'.tr(),
                  message: error.toString(),
                  onActionPressed: () =>
                      ref.refresh(spendingByCategoryProvider(widget.dateRange)),
                ),
              ),
              data: (spendingData) => _buildChart(context, spendingData),
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
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            Icons.pie_chart,
            color: AppColors.secondary,
            size: AppDimensions.iconM,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'analytics.spendingBreakdown'.tr(),
                style: theme.textTheme.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'analytics.categoryDistribution'.tr(),
                style: theme.textTheme.muted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context, Map<String, double> spendingData) {
    if (spendingData.isEmpty) {
      return _buildEmptyState();
    }

    final processedData = _processChartData(spendingData);
    final totalSpent = processedData.fold(0.0, (sum, item) => sum + item.value);

    return Column(
      children: [
        // Pie Chart
        SizedBox(
          height: widget.size,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = null;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: widget.showCenter ? 50 : 0,
                  sections: _buildPieSections(processedData),
                ),
              ),

              // Center content
              if (widget.showCenter) _buildCenterContent(totalSpent),
            ],
          ),
        ),

        // Legend
        if (widget.showLegend) ...[
          const SizedBox(height: AppDimensions.spacingL),
          _buildLegend(processedData, totalSpent),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = ShadTheme.of(context);

    return SizedBox(
      height: widget.size + (widget.showLegend ? 150 : 0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: theme.colorScheme.mutedForeground.withOpacity(0.5),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'analytics.noSpendingData'.tr(),
              style: theme.textTheme.p.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'analytics.noSpendingSubtitle'.tr(),
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

  Widget _buildCenterContent(double totalSpent) {
    final theme = ShadTheme.of(context);

    return Positioned.fill(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'analytics.total'.tr(),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXs),
            Text(
              CurrencyFormatter.formatCompact(totalSpent),
              style: theme.textTheme.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(List<SpendingPieChartData> data, double totalSpent) {
    return Column(
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final percentage = totalSpent > 0 ? (item.value / totalSpent) * 100 : 0;

        return _buildLegendItem(
          index,
          item.categoryId,
          item.value,
          percentage.toDouble(),
          item.color,
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(
    int index,
    String categoryId,
    double amount,
    double percentage,
    Color color,
  ) {
    final theme = ShadTheme.of(context);
    final categoryName = _getCategoryName(categoryId);
    final isHighlighted = _touchedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: isHighlighted
            ? Border.all(color: color.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingS),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),

            // Category icon
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingXs),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(
                _getCategoryIcon(categoryId),
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),

            // Category details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: theme.textTheme.p.copyWith(
                      fontWeight:
                          isHighlighted ? FontWeight.w600 : FontWeight.w500,
                      color: isHighlighted ? color : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(amount),
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isHighlighted ? color : AppColors.primary,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatCompact(amount),
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<SpendingPieChartData> _processChartData(
      Map<String, double> spendingData) {
    final sortedEntries = spendingData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var processedData = sortedEntries.take(widget.maxCategories - 1).toList();

    // If there are more categories, group them as "Others"
    if (sortedEntries.length > widget.maxCategories - 1) {
      final othersAmount = sortedEntries
          .skip(widget.maxCategories - 1)
          .fold(0.0, (sum, entry) => sum + entry.value);

      if (othersAmount > 0) {
        processedData.add(MapEntry('others', othersAmount));
      }
    }

    return processedData.asMap().entries.map((entry) {
      final index = entry.key;
      final mapEntry = entry.value;
      final color = _getCategoryColor(index, mapEntry.key);

      return SpendingPieChartData(
        categoryId: mapEntry.key,
        value: mapEntry.value,
        color: color,
      );
    }).toList();
  }

  List<PieChartSectionData> _buildPieSections(List<SpendingPieChartData> data) {
    final totalValue = data.fold(0.0, (sum, item) => sum + item.value);

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = _touchedIndex == index;
      final radius = isTouched ? 80.0 : 70.0;
      final percentage = totalValue > 0 ? (item.value / totalValue) * 100 : 0;

      return PieChartSectionData(
        color: item.color,
        value: item.value,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  Color _getCategoryColor(int index, String categoryId) {
    if (categoryId == 'others') {
      return AppColors.lightOnSurfaceVariant;
    }

    return AppColors.categoryColors[index % AppColors.categoryColors.length];
  }

  String _getCategoryName(String categoryId) {
    if (categoryId == 'others') {
      return 'analytics.others'.tr();
    }

    final categoryAsync = ref.read(categoryProvider(categoryId));
    return categoryAsync.when(
      data: (category) => category?.name ?? categoryId,
      loading: () => categoryId,
      error: (_, __) => categoryId,
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    if (categoryId == 'others') {
      return Icons.more_horiz;
    }

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
      },
      loading: () => Icons.category,
      error: (_, __) => Icons.category,
    );
  }
}

// Data model for pie chart
class SpendingPieChartData {
  final String categoryId;
  final double value;
  final Color color;

  const SpendingPieChartData({
    required this.categoryId,
    required this.value,
    required this.color,
  });
}
