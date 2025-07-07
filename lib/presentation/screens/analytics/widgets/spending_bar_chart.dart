import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manager/presentation/screens/analytics/widgets/date_range_selector.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/category.dart';
import '../../../../presentation/providers/analytics_provider.dart';
import '../../../../presentation/providers/category_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/error_widget.dart';

class SpendingBarChart extends ConsumerStatefulWidget {
  final DateRange dateRange;
  final int maxCategories;
  final double height;
  final bool showValues;
  final bool showHorizontalLabels;
  final Function(String categoryId)? onBarTapped;

  const SpendingBarChart({
    super.key,
    required this.dateRange,
    this.maxCategories = 8,
    this.height = 300,
    this.showValues = true,
    this.showHorizontalLabels = true,
    this.onBarTapped,
  });

  @override
  ConsumerState<SpendingBarChart> createState() => _SpendingBarChartState();
}

class _SpendingBarChartState extends ConsumerState<SpendingBarChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
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
                height: widget.height,
                child: ShimmerLoading(child: SizedBox.expand()),
              ),
              error: (error, stack) => SizedBox(
                height: widget.height,
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
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            Icons.bar_chart,
            color: AppColors.primary,
            size: AppDimensions.iconM,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'analytics.spendingByCategory'.tr(),
                style: theme.textTheme.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'analytics.topCategories'.tr(),
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

    // Sort and limit categories
    final sortedEntries = spendingData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final limitedEntries = sortedEntries.take(widget.maxCategories).toList();

    if (limitedEntries.isEmpty) {
      return _buildEmptyState();
    }

    final maxValue = limitedEntries.first.value;

    return SizedBox(
      height: widget.height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2, // Add 20% padding to top
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(AppDimensions.paddingS),
              tooltipMargin: AppDimensions.spacingS,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final categoryId = limitedEntries[group.x].key;
                final amount = limitedEntries[group.x].value;
                final categoryName = _getCategoryName(categoryId);

                return BarTooltipItem(
                  '$categoryName\n${CurrencyFormatter.format(amount)}',
                  TextStyle(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    barTouchResponse == null ||
                    barTouchResponse.spot == null) {
                  _touchedIndex = null;
                  return;
                }
                _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              });
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: widget.showHorizontalLabels,
                getTitlesWidget: (value, meta) => _buildBottomTitle(
                  value.toInt(),
                  limitedEntries,
                ),
                reservedSize: 60,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _calculateYInterval(maxValue),
                getTitlesWidget: (value, meta) => _buildLeftTitle(value),
                reservedSize: 60,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            drawHorizontalLine: true,
            horizontalInterval: _calculateYInterval(maxValue),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
                strokeWidth: 0.5,
                dashArray: [3, 3],
              );
            },
          ),
          barGroups: _buildBarGroups(limitedEntries, maxValue),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = ShadTheme.of(context);

    return SizedBox(
      height: widget.height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
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

  List<BarChartGroupData> _buildBarGroups(
    List<MapEntry<String, double>> entries,
    double maxValue,
  ) {
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final categoryEntry = entry.value;
      final isTouched = _touchedIndex == index;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: categoryEntry.value,
            color: _getCategoryColor(index, isTouched),
            width: isTouched ? 24 : 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusS),
              topRight: Radius.circular(AppDimensions.radiusS),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxValue * 1.2,
              color: AppColors.lightSurfaceVariant,
            ),
          ),
        ],
        showingTooltipIndicators: isTouched ? [0] : [],
      );
    }).toList();
  }

  Widget _buildBottomTitle(int index, List<MapEntry<String, double>> entries) {
    if (index >= entries.length) return const SizedBox.shrink();

    final categoryId = entries[index].key;
    final categoryName = _getCategoryName(categoryId);

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingS),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getCategoryColor(index, false).withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(
              _getCategoryIcon(categoryId),
              size: 16,
              color: _getCategoryColor(index, false),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          SizedBox(
            width: 50,
            child: Text(
              categoryName,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftTitle(double value) {
    if (value == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.spacingS),
      child: Text(
        CurrencyFormatter.formatCompact(value),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  double _calculateYInterval(double maxValue) {
    if (maxValue <= 100) return 20;
    if (maxValue <= 500) return 100;
    if (maxValue <= 1000) return 200;
    if (maxValue <= 5000) return 1000;
    if (maxValue <= 10000) return 2000;
    return (maxValue / 5).roundToDouble();
  }

  Color _getCategoryColor(int index, bool isTouched) {
    final colors = AppColors.categoryColors;
    final baseColor = colors[index % colors.length];

    if (isTouched) {
      return baseColor;
    }

    return baseColor.withOpacity(0.8);
  }

  String _getCategoryName(String categoryId) {
    final categoryAsync = ref.read(categoryProvider(categoryId));
    return categoryAsync.when(
      data: (category) => category?.name ?? categoryId,
      loading: () => categoryId,
      error: (_, __) => categoryId,
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    final categoryAsync = ref.read(categoryProvider(categoryId));
    return categoryAsync.when(
      data: (category) {
        if (category == null) return Icons.category;

        // Map icon names to actual icons
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
