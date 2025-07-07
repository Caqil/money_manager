// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:fl_chart/fl_chart.dart';

// import '../../../core/constants/dimensions.dart';
// import '../../../core/utils/date_utils.dart';
// import '../../../data/models/transaction.dart';
// import '../../providers/analytics_provider.dart';
// import '../../providers/budget_provider.dart';
// import '../../providers/category_provider.dart';
// import '../../providers/settings_provider.dart';
// import '../../providers/transaction_provider.dart';
// import 'base_chart_widget.dart';
// import 'chart_legend_widget.dart';

// /// Data model for bar chart items
// class BarChartItem {
//   final String id;
//   final String label;
//   final double value;
//   final Color color;
//   final String? subtitle;
//   final IconData? icon;
//   final double? targetValue;
//   final Color? targetColor;

//   const BarChartItem({
//     required this.id,
//     required this.label,
//     required this.value,
//     required this.color,
//     this.subtitle,
//     this.icon,
//     this.targetValue,
//     this.targetColor,
//   });

//   double get progressPercentage {
//     if (targetValue == null || targetValue! <= 0) return 0;
//     return (value / targetValue!).clamp(0.0, 1.0);
//   }

//   bool get isOverTarget => targetValue != null && value > targetValue!;
// }

// /// Bar chart data for grouped bars
// class GroupedBarChartData {
//   final String groupLabel;
//   final List<BarChartItem> bars;

//   const GroupedBarChartData({
//     required this.groupLabel,
//     required this.bars,
//   });
// }

// /// Bar chart widget for displaying categorical data
// class BarChartWidget extends BaseChartWidget {
//   final List<BarChartItem> data;
//   final List<GroupedBarChartData>? groupedData;
//   final BarChartType chartType;
//   final bool showGrid;
//   final bool showValues;
//   final bool showTargets;
//   final double barWidth;
//   final double groupsSpace;
//   final BarChartAlignment alignment;
//   final Function(BarChartItem?)? onBarTouched;
//   final double? maxY;
//   final double? minY;
//   final bool isHorizontal;
//   final String? yAxisLabel;
//   final String? xAxisLabel;
//   final int? maxBars;

//   const BarChartWidget({
//     super.key,
//     this.data = const [],
//     this.groupedData,
//     this.chartType = BarChartType.simple,
//     this.showGrid = true,
//     this.showValues = true,
//     this.showTargets = true,
//     this.barWidth = 16,
//     this.groupsSpace = 16,
//     this.alignment = BarChartAlignment.center,
//     this.onBarTouched,
//     this.maxY,
//     this.minY,
//     this.isHorizontal = false,
//     this.yAxisLabel,
//     this.xAxisLabel,
//     this.maxBars,
//     super.title,
//     super.height,
//     super.padding,
//     super.showTitle,
//     super.showAnimation,
//     super.backgroundColor,
//     super.borderRadius,
//     super.showBorder,
//     super.borderColor,
//     super.borderWidth,
//     super.emptyStateWidget,
//     super.emptyStateMessage,
//     super.onRefresh,
//     super.isLoading,
//     super.errorMessage,
//     super.showLegend = false,
//     super.legendPosition = LegendPosition.bottom,
//   });

//   @override
//   bool get hasData =>
//       (chartType == BarChartType.grouped
//           ? groupedData?.isNotEmpty
//           : data.isNotEmpty) ??
//       false;

//   @override
//   Widget buildChart(BuildContext context, WidgetRef ref) {
//     return _BarChartContent(
//       data: data,
//       groupedData: groupedData,
//       chartType: chartType,
//       showGrid: showGrid,
//       showValues: showValues,
//       showTargets: showTargets,
//       barWidth: barWidth,
//       groupsSpace: groupsSpace,
//       alignment: alignment,
//       onBarTouched: onBarTouched,
//       maxY: maxY,
//       minY: minY,
//       isHorizontal: isHorizontal,
//       yAxisLabel: yAxisLabel,
//       xAxisLabel: xAxisLabel,
//       maxBars: maxBars,
//     );
//   }

//   @override
//   Widget? buildLegend(BuildContext context, WidgetRef ref) {
//     if (!showLegend) return null;

//     List<LegendItem> legendItems = [];

//     if (chartType == BarChartType.grouped && groupedData != null) {
//       // For grouped charts, show legend for different series
//       final allColors = <Color>{};
//       for (final group in groupedData!) {
//         for (final bar in group.bars) {
//           allColors.add(bar.color);
//         }
//       }

//       legendItems = allColors.map((color) {
//         final item = groupedData!
//             .expand((group) => group.bars)
//             .firstWhere((bar) => bar.color == color);
//         return LegendItem(
//           label: item.label,
//           color: color,
//         );
//       }).toList();
//     } else {
//       // For simple charts, show top items
//       final displayData = maxBars != null ? data.take(maxBars!) : data;
//       final currency = ref.read(baseCurrencyProvider);

//       legendItems = displayData.map((item) {
//         return LegendItem(
//           label: item.label,
//           color: item.color,
//           value: item.value,
//           formattedValue: _formatCurrency(item.value, currency),
//         );
//       }).toList();
//     }

//     return ChartLegendWidget(
//       items: legendItems,
//       layout: LegendLayout.wrap,
//       showValues: true,
//     );
//   }

//   String _formatCurrency(double value, String currency) {
//     return NumberFormat.currency(
//       symbol: _getCurrencySymbol(currency),
//       decimalDigits: value % 1 == 0 ? 0 : 2,
//     ).format(value);
//   }

//   String _getCurrencySymbol(String currencyCode) {
//     switch (currencyCode.toLowerCase()) {
//       case 'usd':
//         return '\$';
//       case 'eur':
//         return '€';
//       case 'gbp':
//         return '£';
//       case 'jpy':
//         return '¥';
//       case 'cad':
//         return 'C\$';
//       case 'aud':
//         return 'A\$';
//       case 'chf':
//         return 'CHF ';
//       case 'cny':
//         return '¥';
//       case 'inr':
//         return '₹';
//       default:
//         return currencyCode.toUpperCase() + ' ';
//     }
//   }
// }

// class _BarChartContent extends ConsumerStatefulWidget {
//   final List<BarChartItem> data;
//   final List<GroupedBarChartData>? groupedData;
//   final BarChartType chartType;
//   final bool showGrid;
//   final bool showValues;
//   final bool showTargets;
//   final double barWidth;
//   final double groupsSpace;
//   final BarChartAlignment alignment;
//   final Function(BarChartItem?)? onBarTouched;
//   final double? maxY;
//   final double? minY;
//   final bool isHorizontal;
//   final String? yAxisLabel;
//   final String? xAxisLabel;
//   final int? maxBars;

//   const _BarChartContent({
//     required this.data,
//     this.groupedData,
//     required this.chartType,
//     required this.showGrid,
//     required this.showValues,
//     required this.showTargets,
//     required this.barWidth,
//     required this.groupsSpace,
//     required this.alignment,
//     this.onBarTouched,
//     this.maxY,
//     this.minY,
//     required this.isHorizontal,
//     this.yAxisLabel,
//     this.xAxisLabel,
//     this.maxBars,
//   });

//   @override
//   ConsumerState<_BarChartContent> createState() => _BarChartContentState();
// }

// class _BarChartContentState extends ConsumerState<_BarChartContent> {
//   int? _touchedGroupIndex;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(AppDimensions.paddingS),
//       child: BarChart(
//         BarChartData(
//           alignment: _getAlignment(),
//           maxY: _getMaxY(),
//           minY: widget.minY ?? 0,
//           groupsSpace: widget.groupsSpace,
//           barTouchData: _buildTouchData(),
//           titlesData: _buildTitlesData(),
//           borderData: defaultBorderData,
//           gridData: widget.showGrid ? defaultGridData : FlGridData(show: false),
//           barGroups: _buildBarGroups(),
//           extraLinesData: widget.showTargets ? _buildExtraLines() : null,
//         ),
//       ),
//     );
//   }

//   BarChartAlignment _getAlignment() {
//     switch (widget.alignment) {
//       case BarChartAlignment.start:
//         return BarChartAlignment.start;
//       case BarChartAlignment.center:
//         return BarChartAlignment.center;
//       case BarChartAlignment.end:
//         return BarChartAlignment.end;
//       case BarChartAlignment.spaceBetween:
//         return BarChartAlignment.spaceBetween;
//       case BarChartAlignment.spaceAround:
//         return BarChartAlignment.spaceAround;
//       case BarChartAlignment.spaceEvenly:
//         return BarChartAlignment.spaceEvenly;
//     }
//   }

//   double _getMaxY() {
//     if (widget.maxY != null) return widget.maxY!;

//     double maxValue = 0;
//     if (widget.chartType == BarChartType.grouped &&
//         widget.groupedData != null) {
//       for (final group in widget.groupedData!) {
//         for (final bar in group.bars) {
//           if (bar.value > maxValue) maxValue = bar.value;
//           if (bar.targetValue != null && bar.targetValue! > maxValue) {
//             maxValue = bar.targetValue!;
//           }
//         }
//       }
//     } else {
//       final displayData = widget.maxBars != null
//           ? widget.data.take(widget.maxBars!)
//           : widget.data;
//       for (final item in displayData) {
//         if (item.value > maxValue) maxValue = item.value;
//         if (item.targetValue != null && item.targetValue! > maxValue) {
//           maxValue = item.targetValue!;
//         }
//       }
//     }

//     return maxValue * 1.1; // Add 10% padding
//   }

//   BarTouchData _buildTouchData() {
//     return BarTouchData(
//       enabled: widget.onBarTouched != null,
//       touchCallback: (FlTouchEvent event, barTouchResponse) {
//         setState(() {
//           if (!event.isInterestedForInteractions ||
//               barTouchResponse == null ||
//               barTouchResponse.spot == null) {
//             _touchedGroupIndex = null;
//             widget.onBarTouched?.call(null);
//             return;
//           }

//           _touchedGroupIndex = barTouchResponse.spot!.touchedBarGroupIndex;

//           // Find the touched bar item
//           BarChartItem? touchedItem;
//           if (widget.chartType == BarChartType.grouped &&
//               widget.groupedData != null) {
//             final groupIndex = barTouchResponse.spot!.touchedBarGroupIndex;
//             final barIndex = barTouchResponse.spot!.touchedRodDataIndex;
//             if (groupIndex < widget.groupedData!.length &&
//                 barIndex < widget.groupedData![groupIndex].bars.length) {
//               touchedItem = widget.groupedData![groupIndex].bars[barIndex];
//             }
//           } else {
//             final index = barTouchResponse.spot!.touchedBarGroupIndex;
//             final displayData = widget.maxBars != null
//                 ? widget.data.take(widget.maxBars!)
//                 : widget.data;
//             if (index < displayData.length) {
//               touchedItem = displayData.elementAt(index);
//             }
//           }

//           widget.onBarTouched?.call(touchedItem);
//         });
//       },
//       touchTooltipData: BarTouchTooltipData(
//         tooltipPadding: const EdgeInsets.all(AppDimensions.paddingS),
//         tooltipMargin: AppDimensions.marginS,
//         getTooltipItem: (group, groupIndex, rod, rodIndex) {
//           String text;
//           if (widget.chartType == BarChartType.grouped &&
//               widget.groupedData != null) {
//             final groupData = widget.groupedData![groupIndex];
//             final barData = groupData.bars[rodIndex];
//             text = '${barData.label}\n${formatCurrency(barData.value)}';
//           } else {
//             final displayData = widget.maxBars != null
//                 ? widget.data.take(widget.maxBars!)
//                 : widget.data;
//             final item = displayData.elementAt(groupIndex);
//             text = '${item.label}\n${formatCurrency(item.value)}';
//           }

//           return BarTooltipItem(
//             text,
//             tooltipTextStyle,
//           );
//         },
//       ),
//     );
//   }

//   FlTitlesData _buildTitlesData() {
//     return FlTitlesData(
//       show: true,
//       rightTitles: const AxisTitles(
//         sideTitles: SideTitles(showTitles: false),
//       ),
//       topTitles: const AxisTitles(
//         sideTitles: SideTitles(showTitles: false),
//       ),
//       bottomTitles: AxisTitles(
//         axisNameWidget: widget.xAxisLabel != null
//             ? Text(
//                 widget.xAxisLabel!,
//                 style: Theme.of(context).textTheme.bodySmall,
//               )
//             : null,
//         sideTitles: SideTitles(
//           showTitles: true,
//           getTitlesWidget: _getBottomTitles,
//           reservedSize: 40,
//         ),
//       ),
//       leftTitles: AxisTitles(
//         axisNameWidget: widget.yAxisLabel != null
//             ? Text(
//                 widget.yAxisLabel!,
//                 style: Theme.of(context).textTheme.bodySmall,
//               )
//             : null,
//         sideTitles: SideTitles(
//           showTitles: true,
//           reservedSize: 60,
//           getTitlesWidget: _getLeftTitles,
//         ),
//       ),
//     );
//   }

//   Widget _getBottomTitles(double value, TitleMeta meta) {
//     final style = Theme.of(context).textTheme.bodySmall?.copyWith(
//           fontSize: 10,
//         );

//     String text = '';
//     if (widget.chartType == BarChartType.grouped &&
//         widget.groupedData != null) {
//       final index = value.toInt();
//       if (index >= 0 && index < widget.groupedData!.length) {
//         text = widget.groupedData![index].groupLabel;
//       }
//     } else {
//       final index = value.toInt();
//       final displayData = widget.maxBars != null
//           ? widget.data.take(widget.maxBars!)
//           : widget.data;
//       if (index >= 0 && index < displayData.length) {
//         text = displayData.elementAt(index).label;
//       }
//     }

//     return SideTitleWidget(
//       meta: meta,
//       child: Container(
//         constraints: const BoxConstraints(maxWidth: 60),
//         child: Text(
//           text,
//           style: style,
//           textAlign: TextAlign.center,
//           overflow: TextOverflow.ellipsis,
//           maxLines: 2,
//         ),
//       ),
//     );
//   }

//   Widget _getLeftTitles(double value, TitleMeta meta) {
//     final style = Theme.of(context).textTheme.bodySmall?.copyWith(
//           fontSize: 10,
//         );

//     return SideTitleWidget(
//       meta: meta,
//       child: Text(
//         formatCompactNumber(value),
//         style: style,
//       ),
//     );
//   }

//   List<BarChartGroupData> _buildBarGroups() {
//     if (widget.chartType == BarChartType.grouped &&
//         widget.groupedData != null) {
//       return _buildGroupedBars();
//     } else {
//       return _buildSimpleBars();
//     }
//   }

//   List<BarChartGroupData> _buildSimpleBars() {
//     final displayData = widget.maxBars != null
//         ? widget.data.take(widget.maxBars!).toList()
//         : widget.data.toList();

//     return displayData.asMap().entries.map((entry) {
//       final index = entry.key;
//       final item = entry.value;
//       final isTouched = index == _touchedGroupIndex;

//       return BarChartGroupData(
//         x: index,
//         barRods: [
//           BarChartRodData(
//             toY: item.value,
//             color: item.color,
//             width: isTouched ? widget.barWidth * 1.2 : widget.barWidth,
//             borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
//             backDrawRodData: item.targetValue != null && widget.showTargets
//                 ? BackgroundBarChartRodData(
//                     show: true,
//                     toY: item.targetValue!,
//                     color: (item.targetColor ?? item.color).withOpacity(0.3),
//                   )
//                 : null,
//           ),
//         ],
//         showingTooltipIndicators: isTouched ? [0] : [],
//       );
//     }).toList();
//   }

//   List<BarChartGroupData> _buildGroupedBars() {
//     return widget.groupedData!.asMap().entries.map((entry) {
//       final groupIndex = entry.key;
//       final group = entry.value;
//       final isTouched = groupIndex == _touchedGroupIndex;

//       return BarChartGroupData(
//         x: groupIndex,
//         barRods: group.bars.asMap().entries.map((barEntry) {
//           final barIndex = barEntry.key;
//           final bar = barEntry.value;

//           return BarChartRodData(
//             toY: bar.value,
//             color: bar.color,
//             width: (isTouched ? widget.barWidth * 1.1 : widget.barWidth) /
//                 group.bars.length,
//             borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
//             backDrawRodData: bar.targetValue != null && widget.showTargets
//                 ? BackgroundBarChartRodData(
//                     show: true,
//                     toY: bar.targetValue!,
//                     color: (bar.targetColor ?? bar.color).withOpacity(0.3),
//                   )
//                 : null,
//           );
//         }).toList(),
//         showingTooltipIndicators:
//             isTouched ? List.generate(group.bars.length, (index) => index) : [],
//       );
//     }).toList();
//   }

//   ExtraLinesData? _buildExtraLines() {
//     if (!widget.showTargets) return null;

//     final horizontalLines = <HorizontalLine>[];

//     // Add average target line if applicable
//     if (widget.chartType == BarChartType.simple) {
//       final itemsWithTargets =
//           widget.data.where((item) => item.targetValue != null);
//       if (itemsWithTargets.isNotEmpty) {
//         final averageTarget = itemsWithTargets
//                 .map((item) => item.targetValue!)
//                 .reduce((a, b) => a + b) /
//             itemsWithTargets.length;

//         horizontalLines.add(
//           HorizontalLine(
//             y: averageTarget,
//             color: Colors.red.withOpacity(0.8),
//             strokeWidth: 2,
//             dashArray: [5, 5],
//             label: HorizontalLineLabel(
//               show: true,
//               padding: const EdgeInsets.all(4),
//               style: const TextStyle(
//                 color: Colors.red,
//                 fontSize: 10,
//                 fontWeight: FontWeight.bold,
//               ),
//               labelResolver: (line) => 'common.target'.tr(),
//             ),
//           ),
//         );
//       }
//     }

//     return horizontalLines.isNotEmpty
//         ? ExtraLinesData(horizontalLines: horizontalLines)
//         : null;
//   }
// }

// /// Budget vs Spending Bar Chart
// class BudgetSpendingBarChart extends ConsumerWidget {
//   final String? title;
//   final double? height;
//   final DateTimeRange? dateRange;
//   final bool showLegend;
//   final Function(String? categoryId)? onCategorySelected;

//   const BudgetSpendingBarChart({
//     super.key,
//     this.title,
//     this.height,
//     this.dateRange,
//     this.showLegend = true,
//     this.onCategorySelected,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final budgetsAsync = ref.watch(activeBudgetsProvider);
//     final categoriesAsync = ref.watch(categoryListProvider);
//     final spendingDataAsync = ref.watch(
//       spendingByCategoryProvider(
//         dateRange != null
//             ? DateRange(start: dateRange!.start, end: dateRange!.end)
//             : null,
//       ),
//     );

//     return budgetsAsync.when(
//       data: (budgets) {
//         return categoriesAsync.when(
//           data: (categories) {
//             return spendingDataAsync.when(
//               data: (spendingData) {
//                 final chartItems = budgets.map((budget) {
//                   final category =
//                       categories.firstWhere((c) => c.id == budget.categoryId);
//                   final spentAmount = spendingData[budget.categoryId] ?? 0.0;
//                   final isOverBudget = spentAmount > budget.limit;

//                   return BarChartItem(
//                     id: budget.categoryId,
//                     label: category.name,
//                     value: spentAmount,
//                     color: isOverBudget ? Colors.red : Colors.blue,
//                     targetValue: budget.limit,
//                     targetColor: Colors.grey,
//                   );
//                 }).toList();

//                 return BarChartWidget(
//                   title: title ?? 'budgets.budgetVsSpending'.tr(),
//                   height: height ?? AppDimensions.barChartHeight,
//                   data: chartItems,
//                   showTargets: true,
//                   showLegend: showLegend,
//                   yAxisLabel: 'common.amount'.tr(),
//                   onBarTouched: (item) {
//                     onCategorySelected?.call(item?.id);
//                   },
//                 );
//               },
//               loading: () => BarChartWidget(
//                 title: title ?? 'budgets.budgetVsSpending'.tr(),
//                 height: height ?? AppDimensions.barChartHeight,
//                 data: const [],
//                 isLoading: true,
//               ),
//               error: (error, stack) => BarChartWidget(
//                 title: title ?? 'budgets.budgetVsSpending'.tr(),
//                 height: height ?? AppDimensions.barChartHeight,
//                 data: const [],
//                 errorMessage: error.toString(),
//               ),
//             );
//           },
//           loading: () => BarChartWidget(
//             title: title ?? 'budgets.budgetVsSpending'.tr(),
//             height: height ?? AppDimensions.barChartHeight,
//             data: const [],
//             isLoading: true,
//           ),
//           error: (error, stack) => BarChartWidget(
//             title: title ?? 'budgets.budgetVsSpending'.tr(),
//             height: height ?? AppDimensions.barChartHeight,
//             data: const [],
//             errorMessage: error.toString(),
//           ),
//         );
//       },
//       loading: () => BarChartWidget(
//         title: title ?? 'budgets.budgetVsSpending'.tr(),
//         height: height ?? AppDimensions.barChartHeight,
//         data: const [],
//         isLoading: true,
//       ),
//       error: (error, stack) => BarChartWidget(
//         title: title ?? 'budgets.budgetVsSpending'.tr(),
//         height: height ?? AppDimensions.barChartHeight,
//         data: const [],
//         errorMessage: error.toString(),
//       ),
//     );
//   }
// }

// /// Monthly Income vs Expense Bar Chart
// class MonthlyIncomeExpenseBarChart extends ConsumerWidget {
//   final String? title;
//   final double? height;
//   final int monthsToShow;
//   final bool showLegend;

//   const MonthlyIncomeExpenseBarChart({
//     super.key,
//     this.title,
//     this.height,
//     this.monthsToShow = 6,
//     this.showLegend = true,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return FutureBuilder<List<GroupedBarChartData>>(
//       future: _getMonthlyData(ref),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return BarChartWidget(
//             title: title ?? 'analytics.monthlyIncomeExpense'.tr(),
//             height: height ?? AppDimensions.barChartHeight,
//             groupedData: const [],
//             isLoading: true,
//           );
//         }

//         if (snapshot.hasError) {
//           return BarChartWidget(
//             title: title ?? 'analytics.monthlyIncomeExpense'.tr(),
//             height: height ?? AppDimensions.barChartHeight,
//             groupedData: const [],
//             errorMessage: snapshot.error.toString(),
//           );
//         }

//         return BarChartWidget(
//           title: title ?? 'analytics.monthlyIncomeExpense'.tr(),
//           height: height ?? AppDimensions.barChartHeight,
//           groupedData: snapshot.data ?? [],
//           chartType: BarChartType.grouped,
//           showLegend: showLegend,
//           yAxisLabel: 'common.amount'.tr(),
//           xAxisLabel: 'common.month'.tr(),
//         );
//       },
//     );
//   }

//   Future<List<GroupedBarChartData>> _getMonthlyData(WidgetRef ref) async {
//     final now = DateTime.now();
//     final data = <GroupedBarChartData>[];

//     for (int i = monthsToShow - 1; i >= 0; i--) {
//       final month = DateTime(now.year, now.month - i, 1);
//       final monthName = DateFormat.MMM().format(month);
//       final dateRange = AppDateUtils.getCurrentMonth(month);

//       final totals =
//           await ref.read(transactionTotalsProvider(dateRange).future);

//       data.add(GroupedBarChartData(
//         groupLabel: monthName,
//         bars: [
//           BarChartItem(
//             id: 'income_$i',
//             label: 'common.income'.tr(),
//             value: totals[TransactionType.income] ?? 0.0,
//             color: Colors.green,
//           ),
//           BarChartItem(
//             id: 'expense_$i',
//             label: 'common.expenses'.tr(),
//             value: totals[TransactionType.expense] ?? 0.0,
//             color: Colors.red,
//           ),
//         ],
//       ));
//     }

//     return data;
//   }
// }

// /// Enums
// enum BarChartType {
//   simple,
//   grouped,
// }

// enum BarChartAlignment {
//   start,
//   center,
//   end,
//   spaceBetween,
//   spaceAround,
//   spaceEvenly,
// }
