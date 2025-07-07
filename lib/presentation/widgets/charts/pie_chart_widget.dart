import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/dimensions.dart';
import '../../../data/models/budget.dart';
import '../../../data/models/category.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import 'base_chart_widget.dart';
import 'chart_legend_widget.dart';

/// Data model for pie chart sections
class AppPieChartData {
  final String id;
  final String label;
  final double value;
  final Color color;
  final String? subtitle;
  final IconData? icon;

  const AppPieChartData({
    required this.id,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
    this.icon,
  });

  double getPercentage(double total) => total > 0 ? (value / total) * 100 : 0;
}

/// Pie chart widget for displaying categorical data
class PieChartWidget extends BaseChartWidget {
  final List<AppPieChartData> data;
  final double? centerSpaceRadius;
  final bool showLabels;
  final bool showPercentages;
  final bool showValues;
  final double sectionSpace;
  final double radius;
  final Function(int?)? onSectionTouched;
  final PieChartDisplayMode displayMode;
  final String? centerText;
  final Widget? centerWidget;
  final bool enableInteraction;
  final double startDegreeOffset;
  final List<int>? sectionsSpace;

  const PieChartWidget({
    super.key,
    required this.data,
    this.centerSpaceRadius,
    this.showLabels = true,
    this.showPercentages = true,
    this.showValues = false,
    this.sectionSpace = 2,
    this.radius = 80,
    this.onSectionTouched,
    this.displayMode = PieChartDisplayMode.pie,
    this.centerText,
    this.centerWidget,
    this.enableInteraction = true,
    this.startDegreeOffset = 270,
    this.sectionsSpace,
    super.title,
    super.height,
    super.padding,
    super.showTitle,
    super.showAnimation,
    super.backgroundColor,
    super.borderRadius,
    super.showBorder,
    super.borderColor,
    super.borderWidth,
    super.emptyStateWidget,
    super.emptyStateMessage,
    super.onRefresh,
    super.isLoading,
    super.errorMessage,
    super.showLegend = true,
    super.legendPosition = LegendPosition.bottom,
  });

  @override
  bool get hasData => data.isNotEmpty;

  @override
  Widget buildChart(BuildContext context, WidgetRef ref) {
    return _PieChartContent(
      data: data,
      centerSpaceRadius: centerSpaceRadius,
      showLabels: showLabels,
      showPercentages: showPercentages,
      showValues: showValues,
      sectionSpace: sectionSpace,
      radius: radius,
      onSectionTouched: onSectionTouched,
      displayMode: displayMode,
      centerText: centerText,
      centerWidget: centerWidget,
      enableInteraction: enableInteraction,
      startDegreeOffset: startDegreeOffset,
      sectionsSpace: sectionsSpace,
    );
  }

  @override
  Widget? buildLegend(BuildContext context, WidgetRef ref) {
    if (!showLegend || data.isEmpty) return null;

    final totalValue = data.fold<double>(0, (sum, item) => sum + item.value);
    final legendItems = data.map((item) {
      return LegendItem(
        label: item.label,
        color: item.color,
        value: item.value,
        formattedValue: _formatCurrency(item.value, ref),
      );
    }).toList();

    return ChartLegendWidget(
      items: legendItems,
      showValues: showValues,
      showPercentages: showPercentages,
      totalValue: totalValue,
      layout: LegendLayout.wrap,
      maxColumns: 2,
    );
  }

  String _formatCurrency(double value, WidgetRef ref) {
    final currency = ref.read(baseCurrencyProvider);
    return NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: value % 1 == 0 ? 0 : 2,
    ).format(value);
  }

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toLowerCase()) {
      case 'usd':
        return '\$';
      case 'eur':
        return '€';
      case 'gbp':
        return '£';
      case 'jpy':
        return '¥';
      case 'cad':
        return 'C\$';
      case 'aud':
        return 'A\$';
      case 'chf':
        return 'CHF ';
      case 'cny':
        return '¥';
      case 'inr':
        return '₹';
      default:
        return currencyCode.toUpperCase() + ' ';
    }
  }
}

class _PieChartContent extends ConsumerStatefulWidget {
  final List<AppPieChartData> data;
  final double? centerSpaceRadius;
  final bool showLabels;
  final bool showPercentages;
  final bool showValues;
  final double sectionSpace;
  final double radius;
  final Function(int?)? onSectionTouched;
  final PieChartDisplayMode displayMode;
  final String? centerText;
  final Widget? centerWidget;
  final bool enableInteraction;
  final double startDegreeOffset;
  final List<int>? sectionsSpace;

  const _PieChartContent({
    required this.data,
    this.centerSpaceRadius,
    required this.showLabels,
    required this.showPercentages,
    required this.showValues,
    required this.sectionSpace,
    required this.radius,
    this.onSectionTouched,
    required this.displayMode,
    this.centerText,
    this.centerWidget,
    required this.enableInteraction,
    required this.startDegreeOffset,
    this.sectionsSpace,
  });

  @override
  ConsumerState<_PieChartContent> createState() => _PieChartContentState();
}

class _PieChartContentState extends ConsumerState<_PieChartContent> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final totalValue =
        widget.data.fold<double>(0, (sum, item) => sum + item.value);

    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              pieTouchData: _buildTouchData(),
              borderData: FlBorderData(show: false),
              sectionsSpace: widget.sectionSpace,
              centerSpaceRadius: _getCenterSpaceRadius(),
              startDegreeOffset: widget.startDegreeOffset,
              sections: _buildSections(totalValue),
            ),
          ),
          if (widget.centerWidget != null || widget.centerText != null)
            _buildCenterContent(totalValue),
        ],
      ),
    );
  }

  PieTouchData _buildTouchData() {
    if (!widget.enableInteraction) {
      return PieTouchData(enabled: false);
    }

    return PieTouchData(
      touchCallback: (FlTouchEvent event, pieTouchResponse) {
        setState(() {
          if (!event.isInterestedForInteractions ||
              pieTouchResponse == null ||
              pieTouchResponse.touchedSection == null) {
            _touchedIndex = null;
            widget.onSectionTouched?.call(null);
            return;
          }
          _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
          widget.onSectionTouched?.call(_touchedIndex);
        });
      },
    );
  }

  double _getCenterSpaceRadius() {
    if (widget.centerSpaceRadius != null) {
      return widget.centerSpaceRadius!;
    }

    switch (widget.displayMode) {
      case PieChartDisplayMode.pie:
        return 0;
      case PieChartDisplayMode.donut:
        return widget.radius * 0.4;
    }
  }

  List<PieChartSectionData> _buildSections(double totalValue) {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 14.0 : 12.0;
      final radius = isTouched ? widget.radius + 10 : widget.radius;
      final percentage = data.getPercentage(totalValue);

      return PieChartSectionData(
        color: data.color,
        value: data.value,
        title: _getSectionTitle(data, percentage),
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black26,
            ),
          ],
        ),
        titlePositionPercentageOffset: 0.7,
        badgeWidget: isTouched ? _buildBadgeWidget(data) : null,
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  String _getSectionTitle(AppPieChartData data, double percentage) {
    if (!widget.showLabels) return '';

    if (widget.showPercentages && widget.showValues) {
      return '${percentage.toStringAsFixed(1)}%\n${formatCurrency(data.value)}';
    } else if (widget.showPercentages) {
      return '${percentage.toStringAsFixed(1)}%';
    } else if (widget.showValues) {
      return formatCurrency(data.value);
    } else {
      return data.label;
    }
  }

  Widget? _buildBadgeWidget(AppPieChartData data) {
    if (data.icon == null) return null;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: data.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        data.icon,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildCenterContent(double totalValue) {
    return Center(
      child: widget.centerWidget ??
          (widget.centerText != null ? _buildCenterText(totalValue) : null),
    );
  }

  Widget _buildCenterText(double totalValue) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.centerText ?? 'common.total'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatCurrency(totalValue),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String formatCurrency(double value) {
    final currency = ref.read(baseCurrencyProvider);
    return NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: value % 1 == 0 ? 0 : 2,
    ).format(value);
  }

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toLowerCase()) {
      case 'usd':
        return '\$';
      case 'eur':
        return '€';
      case 'gbp':
        return '£';
      case 'jpy':
        return '¥';
      case 'cad':
        return 'C\$';
      case 'aud':
        return 'A\$';
      case 'chf':
        return 'CHF ';
      case 'cny':
        return '¥';
      case 'inr':
        return '₹';
      default:
        return currencyCode.toUpperCase() + ' ';
    }
  }
}

/// Provider for expense category distribution
final expenseCategoryDistributionProvider =
    FutureProvider.family<List<AppPieChartData>, DateTimeRange?>(
        (ref, dateRange) async {
  final spendingByCategory = await ref.watch(
    spendingByCategoryProvider(_toDateRange(dateRange)).future,
  );
  final categoriesAsync = ref.watch(categoryListProvider);

  final pieData = <AppPieChartData>[];
  int colorIndex = 0;

  // Wait for categories to be loaded
  if (categoriesAsync is AsyncData<List<Category>>) {
    final categories = categoriesAsync.value;

    for (final entry in spendingByCategory.entries) {
      final categoryId = entry.key;
      final amount = entry.value;

      try {
        final category = categories.firstWhere((c) => c.id == categoryId);
        pieData.add(AppPieChartData(
          id: categoryId,
          label: category.name,
          value: amount,
          color: Color(category.color),
          icon: _getCategoryIcon(category.iconName),
        ));
      } catch (e) {
        // Handle category not found
        pieData.add(AppPieChartData(
          id: categoryId,
          label: 'categories.unknown'.tr(),
          value: amount,
          color: BaseChartState
              .defaultColors[colorIndex % BaseChartState.defaultColors.length],
        ));
      }
      colorIndex++;
    }

    // Sort by value descending
    pieData.sort((a, b) => b.value.compareTo(a.value));
    return pieData;
  } else {
    // Still loading or error, return empty list
    return [];
  }
});

/// Provider for budget allocation pie chart
final budgetAllocationProvider =
    FutureProvider<List<AppPieChartData>>((ref) async {
  final budgetsAsync = ref.watch(activeBudgetsProvider);
  final categoriesAsync = ref.watch(categoryListProvider);

  final pieData = <AppPieChartData>[];
  int colorIndex = 0;

  // Wait for both AsyncValues to be loaded
  if (budgetsAsync is AsyncData<List<Budget>> && categoriesAsync is AsyncData<List<Category>>) {
    final budgets = budgetsAsync.value;
    final categories = categoriesAsync.value;

    for (final budget in budgets) {
      try {
        final category = categories.firstWhere((c) => c.id == budget.categoryId);
        pieData.add(AppPieChartData(
          id: budget.id,
          label: category.name,
          value: budget.limit,
          color: Color(category.color),
          subtitle: budget.name,
          icon: _getCategoryIcon(category.iconName),
        ));
      } catch (e) {
        pieData.add(AppPieChartData(
          id: budget.id,
          label: budget.name,
          value: budget.limit,
          color: BaseChartState
              .defaultColors[colorIndex % BaseChartState.defaultColors.length],
        ));
      }
      colorIndex++;
    }

    pieData.sort((a, b) => b.value.compareTo(a.value));
    return pieData;
  } else {
    // Still loading or error, return empty list
    return [];
  }
});

/// Expense category pie chart widget
class ExpenseCategoryPieChart extends ConsumerWidget {
  final DateTimeRange? dateRange;
  final String? title;
  final double? height;
  final bool showLegend;
  final PieChartDisplayMode displayMode;
  final Function(String? categoryId)? onCategorySelected;

  const ExpenseCategoryPieChart({
    super.key,
    this.dateRange,
    this.title,
    this.height,
    this.showLegend = true,
    this.displayMode = PieChartDisplayMode.donut,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseDataAsync =
        ref.watch(expenseCategoryDistributionProvider(dateRange));

    return expenseDataAsync.when(
      data: (data) => PieChartWidget(
        title: title ?? 'analytics.spendingByCategory'.tr(),
        height: height ?? AppDimensions.chartHeight,
        data: data,
        showLegend: showLegend,
        displayMode: displayMode,
        centerText: 'analytics.totalExpenses'.tr(),
        onSectionTouched: (index) {
          if (index != null && index < data.length) {
            onCategorySelected?.call(data[index].id);
          } else {
            onCategorySelected?.call(null);
          }
        },
      ),
      loading: () => PieChartWidget(
        title: title ?? 'analytics.spendingByCategory'.tr(),
        height: height ?? AppDimensions.chartHeight,
        data: const [],
        isLoading: true,
      ),
      error: (error, stack) => PieChartWidget(
        title: title ?? 'analytics.spendingByCategory'.tr(),
        height: height ?? AppDimensions.chartHeight,
        data: const [],
        errorMessage: error.toString(),
      ),
    );
  }
}

/// Budget allocation pie chart widget
class BudgetAllocationPieChart extends ConsumerWidget {
  final String? title;
  final double? height;
  final bool showLegend;
  final PieChartDisplayMode displayMode;

  const BudgetAllocationPieChart({
    super.key,
    this.title,
    this.height,
    this.showLegend = true,
    this.displayMode = PieChartDisplayMode.donut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetDataAsync = ref.watch(budgetAllocationProvider);

    return budgetDataAsync.when(
      data: (data) => PieChartWidget(
        title: title ?? 'budgets.budgetAllocation'.tr(),
        height: height ?? AppDimensions.chartHeight,
        data: data,
        showLegend: showLegend,
        displayMode: displayMode,
        centerText: 'budgets.totalBudget'.tr(),
      ),
      loading: () => PieChartWidget(
        title: title ?? 'budgets.budgetAllocation'.tr(),
        height: height ?? AppDimensions.chartHeight,
        data: const [],
        isLoading: true,
      ),
      error: (error, stack) => PieChartWidget(
        title: title ?? 'budgets.budgetAllocation'.tr(),
        height: height ?? AppDimensions.chartHeight,
        data: const [],
        errorMessage: error.toString(),
      ),
    );
  }
}

/// Helper function to get category icon
IconData? _getCategoryIcon(String? iconName) {
  if (iconName == null) return null;

  // Map icon names to IconData
  const iconMap = {
    'food': Icons.restaurant,
    'transport': Icons.directions_car,
    'shopping': Icons.shopping_bag,
    'entertainment': Icons.movie,
    'healthcare': Icons.medical_services,
    'utilities': Icons.home,
    'salary': Icons.work,
    'freelance': Icons.computer,
    'investment': Icons.trending_up,
  };

  return iconMap[iconName] ?? Icons.category;
}

/// Enums
enum PieChartDisplayMode {
  pie,
  donut,
}

/// Helper to convert Flutter's DateTimeRange to app's DateRange
DateRange? _toDateRange(DateTimeRange? range) {
  if (range == null) return null;
  return DateRange(start: range.start, end: range.end);
}
