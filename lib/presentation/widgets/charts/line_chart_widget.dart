// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:fl_chart/fl_chart.dart';

// import '../../../core/constants/dimensions.dart';
// import '../../../core/utils/date_utils.dart';
// import '../../../data/models/transaction.dart';
// import '../../core/constants/dimensions.dart';
// import '../../core/utils/date_utils.dart';
// import '../../core/extensions/datetime_extension.dart';
// import '../../presentation/providers/analytics_provider.dart';
// import '../../presentation/providers/account_provider.dart';
// import '../../presentation/providers/goal_provider.dart';
// import '../../presentation/providers/transaction_provider.dart';
// import '../../presentation/providers/settings_provider.dart';
// import '../../data/models/transaction.dart';
// import '../../data/models/goal.dart';
// import '../../core/enums/transaction_type.dart';
// import '../../providers/account_provider.dart';
// import '../../providers/goal_provider.dart';
// import '../../providers/transaction_provider.dart';
// import 'base_chart_widget.dart';
// import 'chart_legend_widget.dart';

// /// Data model for line chart points
// class LineChartPoint {
//   final DateTime date;
//   final double value;
//   final String? label;
//   final Color? color;

//   const LineChartPoint({
//     required this.date,
//     required this.value,
//     this.label,
//     this.color,
//   });

//   FlSpot get flSpot => FlSpot(
//         date.millisecondsSinceEpoch.toDouble(),
//         value,
//       );
// }

// /// Data model for line chart series
// class LineChartSeries {
//   final String id;
//   final String label;
//   final List<LineChartPoint> points;
//   final Color color;
//   final double strokeWidth;
//   final bool isCurved;
//   final bool showDots;
//   final bool fillArea;
//   final Gradient? gradient;
//   final List<int>? dashArray;
//   final bool isVisible;

//   const LineChartSeries({
//     required this.id,
//     required this.label,
//     required this.points,
//     required this.color,
//     this.strokeWidth = 2.0,
//     this.isCurved = true,
//     this.showDots = true,
//     this.fillArea = false,
//     this.gradient,
//     this.dashArray,
//     this.isVisible = true,
//   });

//   LineChartSeries copyWith({
//     String? id,
//     String? label,
//     List<LineChartPoint>? points,
//     Color? color,
//     double? strokeWidth,
//     bool? isCurved,
//     bool? showDots,
//     bool? fillArea,
//     Gradient? gradient,
//     List<int>? dashArray,
//     bool? isVisible,
//   }) {
//     return LineChartSeries(
//       id: id ?? this.id,
//       label: label ?? this.label,
//       points: points ?? this.points,
//       color: color ?? this.color,
//       strokeWidth: strokeWidth ?? this.strokeWidth,
//       isCurved: isCurved ?? this.isCurved,
//       showDots: showDots ?? this.showDots,
//       fillArea: fillArea ?? this.fillArea,
//       gradient: gradient ?? this.gradient,
//       dashArray: dashArray ?? this.dashArray,
//       isVisible: isVisible ?? this.isVisible,
//     );
//   }

//   List<FlSpot> get flSpots => points.map((point) => point.flSpot).toList();
// }

// /// Line chart widget for displaying time series data
// class LineChartWidget extends BaseChartWidget {
//   final List<LineChartSeries> series;
//   final bool showGrid;
//   final bool showTooltip;
//   final bool enablePinchZoom;
//   final bool enablePanning;
//   final double? minX;
//   final double? maxX;
//   final double? minY;
//   final double? maxY;
//   final Function(List<LineChartPoint>?)? onPointTouched;
//   final String? xAxisLabel;
//   final String? yAxisLabel;
//   final LineChartDateFormat dateFormat;
//   final bool showBaseline;
//   final double? baselineValue;
//   final Color? baselineColor;
//   final bool allowSeriesToggle;

//   const LineChartWidget({
//     super.key,
//     required this.series,
//     this.showGrid = true,
//     this.showTooltip = true,
//     this.enablePinchZoom = false,
//     this.enablePanning = false,
//     this.minX,
//     this.maxX,
//     this.minY,
//     this.maxY,
//     this.onPointTouched,
//     this.xAxisLabel,
//     this.yAxisLabel,
//     this.dateFormat = LineChartDateFormat.auto,
//     this.showBaseline = false,
//     this.baselineValue,
//     this.baselineColor,
//     this.allowSeriesToggle = true,
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
//     super.showLegend = true,
//     super.legendPosition = LegendPosition.bottom,
//   });

//   @override
//   bool get hasData =>
//       series.isNotEmpty && series.any((s) => s.points.isNotEmpty);

//   @override
//   Widget buildChart(BuildContext context, WidgetRef ref) {
//     return _LineChartContent(
//       series: series,
//       showGrid: showGrid,
//       showTooltip: showTooltip,
//       enablePinchZoom: enablePinchZoom,
//       enablePanning: enablePanning,
//       minX: minX,
//       maxX: maxX,
//       minY: minY,
//       maxY: maxY,
//       onPointTouched: onPointTouched,
//       xAxisLabel: xAxisLabel,
//       yAxisLabel: yAxisLabel,
//       dateFormat: dateFormat,
//       showBaseline: showBaseline,
//       baselineValue: baselineValue,
//       baselineColor: baselineColor,
//     );
//   }

//   @override
//   Widget? buildLegend(BuildContext context, WidgetRef ref) {
//     if (!showLegend || series.isEmpty) return null;

//     final legendItems = series.map((s) {
//       return LegendItem(
//         label: s.label,
//         color: s.color,
//         isVisible: s.isVisible,
//       );
//     }).toList();

//     if (allowSeriesToggle) {
//       return InteractiveLegendWidget(
//         items: legendItems,
//         layout: LegendLayout.wrap,
//         allowMultipleSelection: true,
//         onToggle: (index, isVisible) {
//           // This would need to be handled by the parent widget
//           // to update the series visibility
//         },
//       );
//     }

//     return ChartLegendWidget(
//       items: legendItems,
//       layout: LegendLayout.wrap,
//       indicatorType: LegendIndicatorType.line,
//     );
//   }
// }

// class _LineChartContent extends ConsumerStatefulWidget {
//   final List<LineChartSeries> series;
//   final bool showGrid;
//   final bool showTooltip;
//   final bool enablePinchZoom;
//   final bool enablePanning;
//   final double? minX;
//   final double? maxX;
//   final double? minY;
//   final double? maxY;
//   final Function(List<LineChartPoint>?)? onPointTouched;
//   final String? xAxisLabel;
//   final String? yAxisLabel;
//   final LineChartDateFormat dateFormat;
//   final bool showBaseline;
//   final double? baselineValue;
//   final Color? baselineColor;

//   const _LineChartContent({
//     required this.series,
//     required this.showGrid,
//     required this.showTooltip,
//     required this.enablePinchZoom,
//     required this.enablePanning,
//     this.minX,
//     this.maxX,
//     this.minY,
//     this.maxY,
//     this.onPointTouched,
//     this.xAxisLabel,
//     this.yAxisLabel,
//     required this.dateFormat,
//     required this.showBaseline,
//     this.baselineValue,
//     this.baselineColor,
//   });

//   @override
//   ConsumerState<_LineChartContent> createState() => _LineChartContentState();
// }

// class _LineChartContentState extends BaseChartState<_LineChartContent> {
//   List<int>? _touchedSpotIndices;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(AppDimensions.paddingS),
//       child: LineChart(
//         LineChartData(
//           gridData:
//               widget.showGrid ? _buildGridData() : FlGridData(show: false),
//           titlesData: _buildTitlesData(),
//           borderData: defaultBorderData,
//           minX: widget.minX ?? _getMinX(),
//           maxX: widget.maxX ?? _getMaxX(),
//           minY: widget.minY ?? _getMinY(),
//           maxY: widget.maxY ?? _getMaxY(),
//           lineBarsData: _buildLineBarsData(),
//           lineTouchData: _buildTouchData(),
//           extraLinesData: _buildExtraLines(),
//           clipData: const FlClipData.all(),
//           backgroundColor: Colors.transparent,
//         ),
//       ),
//     );
//   }

//   FlGridData _buildGridData() {
//     return FlGridData(
//       show: true,
//       drawVerticalLine: true,
//       drawHorizontalLine: true,
//       horizontalInterval: null,
//       verticalInterval: null,
//       getDrawingHorizontalLine: (value) {
//         return FlLine(
//           color: Theme.of(context).dividerColor.withOpacity(0.3),
//           strokeWidth: 0.5,
//           dashArray: [3, 3],
//         );
//       },
//       getDrawingVerticalLine: (value) {
//         return FlLine(
//           color: Theme.of(context).dividerColor.withOpacity(0.2),
//           strokeWidth: 0.5,
//           dashArray: [3, 3],
//         );
//       },
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
//           reservedSize: 32,
//           interval: _getXInterval(),
//           getTitlesWidget: _getBottomTitles,
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
//           interval: _getYInterval(),
//           getTitlesWidget: _getLeftTitles,
//         ),
//       ),
//     );
//   }

//   Widget _getBottomTitles(double value, TitleMeta meta) {
//     final style = Theme.of(context).textTheme.bodySmall?.copyWith(
//           fontSize: 10,
//         );

//     final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
//     String text = _formatDate(date);

//     return SideTitleWidget(
//       axisSide: meta.axisSide,
//       child: Text(
//         text,
//         style: style,
//         textAlign: TextAlign.center,
//       ),
//     );
//   }

//   Widget _getLeftTitles(double value, TitleMeta meta) {
//     final style = Theme.of(context).textTheme.bodySmall?.copyWith(
//           fontSize: 10,
//         );

//     return SideTitleWidget(
//       axisSide: meta.axisSide,
//       child: Text(
//         formatCompactNumber(value),
//         style: style,
//       ),
//     );
//   }

//   List<LineChartBarData> _buildLineBarsData() {
//     return widget.series.where((s) => s.isVisible).map((series) {
//       return LineChartBarData(
//         spots: series.flSpots,
//         color: series.color,
//         barWidth: series.strokeWidth,
//         isCurved: series.isCurved,
//         curveSmoothness: 0.35,
//         isStrokeCapRound: true,
//         isStrokeJoinRound: true,
//         dotData: FlDotData(
//           show: series.showDots,
//           getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
//             radius: 3,
//             color: series.color,
//             strokeWidth: 2,
//             strokeColor: Colors.white,
//           ),
//         ),
//         belowBarData: series.fillArea
//             ? BarAreaData(
//                 show: true,
//                 gradient: series.gradient ??
//                     LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [
//                         series.color.withOpacity(0.3),
//                         series.color.withOpacity(0.0),
//                       ],
//                     ),
//               )
//             : BarAreaData(show: false),
//         dashArray: series.dashArray,
//         gradient: series.gradient,
//       );
//     }).toList();
//   }

//   LineTouchData _buildTouchData() {
//     if (!widget.showTooltip) {
//       return LineTouchData(enabled: false);
//     }

//     return LineTouchData(
//       enabled: true,
//       touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
//         setState(() {
//           if (!event.isInterestedForInteractions ||
//               touchResponse == null ||
//               touchResponse.lineBarSpots == null) {
//             _touchedSpotIndices = null;
//             widget.onPointTouched?.call(null);
//             return;
//           }

//           _touchedSpotIndices = touchResponse.lineBarSpots!
//               .map((barSpot) => barSpot.spotIndex)
//               .toList();

//           // Find touched points
//           final touchedPoints = <LineChartPoint>[];
//           for (final barSpot in touchResponse.lineBarSpots!) {
//             final seriesIndex = widget.series.indexWhere(
//               (s) => s.flSpots
//                   .any((spot) => spot.x == barSpot.x && spot.y == barSpot.y),
//             );
//             if (seriesIndex >= 0) {
//               final series = widget.series[seriesIndex];
//               final pointIndex = series.flSpots.indexWhere(
//                 (spot) => spot.x == barSpot.x && spot.y == barSpot.y,
//               );
//               if (pointIndex >= 0) {
//                 touchedPoints.add(series.points[pointIndex]);
//               }
//             }
//           }

//           widget.onPointTouched?.call(touchedPoints);
//         });
//       },
//       touchTooltipData: LineTouchTooltipData(
//         tooltipBgColor: Theme.of(context).colorScheme.inverseSurface,
//         tooltipRoundedRadius: AppDimensions.radiusS,
//         tooltipPadding: const EdgeInsets.all(AppDimensions.paddingS),
//         tooltipMargin: AppDimensions.marginS,
//         maxContentWidth: 200,
//         getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
//           return touchedBarSpots.map((barSpot) {
//             final date = DateTime.fromMillisecondsSinceEpoch(barSpot.x.toInt());
//             final value = barSpot.y;

//             // Find the series for this spot
//             final seriesIndex = widget.series.indexWhere(
//               (s) => s.flSpots
//                   .any((spot) => spot.x == barSpot.x && spot.y == barSpot.y),
//             );

//             String seriesLabel = '';
//             Color textColor = Colors.white;
//             if (seriesIndex >= 0) {
//               seriesLabel = widget.series[seriesIndex].label;
//               textColor = widget.series[seriesIndex].color;
//             }

//             return LineTooltipItem(
//               '$seriesLabel\n${_formatDate(date)}\n${formatCurrency(value)}',
//               TextStyle(
//                 color: textColor,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             );
//           }).toList();
//         },
//       ),
//       getTouchedSpotIndicator:
//           (LineChartBarData barData, List<int> spotIndexes) {
//         return spotIndexes.map((spotIndex) {
//           return TouchedSpotIndicatorData(
//             FlLine(
//               color: barData.color ?? Colors.blue,
//               strokeWidth: 2,
//               dashArray: [3, 3],
//             ),
//             FlDotData(
//               getDotPainter: (spot, percent, barData, index) =>
//                   FlDotCirclePainter(
//                 radius: 5,
//                 color: barData.color ?? Colors.blue,
//                 strokeWidth: 2,
//                 strokeColor: Colors.white,
//               ),
//             ),
//           );
//         }).toList();
//       },
//     );
//   }

//   ExtraLinesData? _buildExtraLines() {
//     final extraLines = <HorizontalLine>[];

//     if (widget.showBaseline && widget.baselineValue != null) {
//       extraLines.add(
//         HorizontalLine(
//           y: widget.baselineValue!,
//           color: widget.baselineColor ?? Colors.grey,
//           strokeWidth: 1,
//           dashArray: [5, 5],
//           label: HorizontalLineLabel(
//             show: true,
//             padding: const EdgeInsets.all(4),
//             style: TextStyle(
//               color: widget.baselineColor ?? Colors.grey,
//               fontSize: 10,
//             ),
//             labelResolver: (line) => formatCurrency(line.y),
//           ),
//         ),
//       );
//     }

//     return extraLines.isNotEmpty
//         ? ExtraLinesData(horizontalLines: extraLines)
//         : null;
//   }

//   double _getMinX() {
//     if (widget.series.isEmpty) return 0;

//     double minX = double.infinity;
//     for (final series in widget.series.where((s) => s.isVisible)) {
//       for (final point in series.points) {
//         if (point.date.millisecondsSinceEpoch < minX) {
//           minX = point.date.millisecondsSinceEpoch.toDouble();
//         }
//       }
//     }
//     return minX == double.infinity ? 0 : minX;
//   }

//   double _getMaxX() {
//     if (widget.series.isEmpty) return 1;

//     double maxX = double.negativeInfinity;
//     for (final series in widget.series.where((s) => s.isVisible)) {
//       for (final point in series.points) {
//         if (point.date.millisecondsSinceEpoch > maxX) {
//           maxX = point.date.millisecondsSinceEpoch.toDouble();
//         }
//       }
//     }
//     return maxX == double.negativeInfinity ? 1 : maxX;
//   }

//   double _getMinY() {
//     if (widget.series.isEmpty) return 0;

//     double minY = double.infinity;
//     for (final series in widget.series.where((s) => s.isVisible)) {
//       for (final point in series.points) {
//         if (point.value < minY) {
//           minY = point.value;
//         }
//       }
//     }

//     // Add 10% padding below
//     final padding = (minY * 0.1).abs();
//     return minY == double.infinity ? 0 : minY - padding;
//   }

//   double _getMaxY() {
//     if (widget.series.isEmpty) return 1;

//     double maxY = double.negativeInfinity;
//     for (final series in widget.series.where((s) => s.isVisible)) {
//       for (final point in series.points) {
//         if (point.value > maxY) {
//           maxY = point.value;
//         }
//       }
//     }

//     // Add 10% padding above
//     final padding = maxY * 0.1;
//     return maxY == double.negativeInfinity ? 1 : maxY + padding;
//   }

//   double? _getXInterval() {
//     final minX = _getMinX();
//     final maxX = _getMaxX();
//     final duration = Duration(milliseconds: (maxX - minX).toInt());

//     if (duration.inDays <= 7) {
//       return const Duration(days: 1).inMilliseconds.toDouble();
//     } else if (duration.inDays <= 30) {
//       return const Duration(days: 7).inMilliseconds.toDouble();
//     } else if (duration.inDays <= 365) {
//       return const Duration(days: 30).inMilliseconds.toDouble();
//     } else {
//       return const Duration(days: 90).inMilliseconds.toDouble();
//     }
//   }

//   double? _getYInterval() {
//     final minY = _getMinY();
//     final maxY = _getMaxY();
//     final range = maxY - minY;

//     if (range <= 100) return 10;
//     if (range <= 1000) return 100;
//     if (range <= 10000) return 1000;
//     return null; // Let fl_chart decide
//   }

//   String _formatDate(DateTime date) {
//     switch (widget.dateFormat) {
//       case LineChartDateFormat.dayMonth:
//         return DateFormat.MMMd().format(date);
//       case LineChartDateFormat.monthYear:
//         return DateFormat.yMMM().format(date);
//       case LineChartDateFormat.yearOnly:
//         return DateFormat.y().format(date);
//       case LineChartDateFormat.dayOnly:
//         return DateFormat.d().format(date);
//       case LineChartDateFormat.monthOnly:
//         return DateFormat.MMM().format(date);
//       case LineChartDateFormat.auto:
//         final range = _getMaxX() - _getMinX();
//         final duration = Duration(milliseconds: range.toInt());

//         if (duration.inDays <= 7) {
//           return DateFormat.MMMd().format(date);
//         } else if (duration.inDays <= 365) {
//           return DateFormat.MMMd().format(date);
//         } else {
//           return DateFormat.yMMM().format(date);
//         }
//     }
//   }
// }

// /// Net Worth Line Chart Provider
// final netWorthTrendProvider =
//     FutureProvider.family<List<LineChartPoint>, DateTimeRange>(
//         (ref, dateRange) async {
//   final accountsAsync = ref.watch(accountListProvider.future);
//   final transactionsAsync = ref.watch(transactionListProvider.future);

//   final accounts = await accountsAsync;
//   final transactions = await transactionsAsync;

//   // Filter active accounts that contribute to total
//   final trackingAccounts =
//       accounts.where((a) => a.isActive && a.includeInTotal).toList();

//   final dataPoints = <LineChartPoint>[];
//   final dates = AppDateUtils.getDatesInRange(dateRange.start, dateRange.end);

//   for (final date in dates) {
//     double netWorth = 0.0;

//     for (final account in trackingAccounts) {
//       // Calculate account balance up to this date
//       double balance = account.balance;

//       // Adjust for transactions after this date
//       final futureTransactions = transactions.where((t) =>
//           (t.accountId == account.id || t.transferToAccountId == account.id) &&
//           t.date.isAfter(date));

//       for (final transaction in futureTransactions) {
//         switch (transaction.type) {
//           case TransactionType.income:
//             if (transaction.accountId == account.id) {
//               balance -= transaction.amount;
//             }
//             break;
//           case TransactionType.expense:
//             if (transaction.accountId == account.id) {
//               balance += transaction.amount;
//             }
//             break;
//           case TransactionType.transfer:
//             if (transaction.accountId == account.id) {
//               balance += transaction.amount;
//             } else if (transaction.transferToAccountId == account.id) {
//               balance -= transaction.amount;
//             }
//             break;
//         }
//       }

//       netWorth += balance;
//     }

//     dataPoints.add(LineChartPoint(
//       date: date,
//       value: netWorth,
//     ));
//   }

//   return dataPoints;
// });

// /// Income vs Expense Trend Provider
// final incomeVsExpenseTrendProvider =
//     FutureProvider.family<List<LineChartSeries>, DateTimeRange>(
//         (ref, dateRange) async {
//   final transactionsAsync = ref.watch(transactionListProvider.future);
//   final transactions = await transactionsAsync;

//   // Filter transactions by date range
//   final filteredTransactions = transactions
//       .where((t) =>
//           t.date.isAfter(dateRange.start) && t.date.isBefore(dateRange.end))
//       .toList();

//   // Group by month
//   final monthlyData = <DateTime, Map<TransactionType, double>>{};

//   for (final transaction in filteredTransactions) {
//     final monthKey = DateTime(transaction.date.year, transaction.date.month, 1);

//     monthlyData.putIfAbsent(
//         monthKey,
//         () => {
//               TransactionType.income: 0.0,
//               TransactionType.expense: 0.0,
//             });

//     if (transaction.type == TransactionType.income) {
//       monthlyData[monthKey]![TransactionType.income] =
//           (monthlyData[monthKey]![TransactionType.income] ?? 0.0) +
//               transaction.amount;
//     } else if (transaction.type == TransactionType.expense) {
//       monthlyData[monthKey]![TransactionType.expense] =
//           (monthlyData[monthKey]![TransactionType.expense] ?? 0.0) +
//               transaction.amount;
//     }
//   }

//   // Convert to line chart series
//   final incomePoints = monthlyData.entries
//       .map((entry) => LineChartPoint(
//             date: entry.key,
//             value: entry.value[TransactionType.income] ?? 0.0,
//           ))
//       .toList();

//   final expensePoints = monthlyData.entries
//       .map((entry) => LineChartPoint(
//             date: entry.key,
//             value: entry.value[TransactionType.expense] ?? 0.0,
//           ))
//       .toList();

//   final netPoints = monthlyData.entries
//       .map((entry) => LineChartPoint(
//             date: entry.key,
//             value: (entry.value[TransactionType.income] ?? 0.0) -
//                 (entry.value[TransactionType.expense] ?? 0.0),
//           ))
//       .toList();

//   return [
//     LineChartSeries(
//       id: 'income',
//       label: 'common.income'.tr(),
//       points: incomePoints,
//       color: Colors.green,
//       strokeWidth: 2,
//     ),
//     LineChartSeries(
//       id: 'expense',
//       label: 'common.expenses'.tr(),
//       points: expensePoints,
//       color: Colors.red,
//       strokeWidth: 2,
//     ),
//     LineChartSeries(
//       id: 'net',
//       label: 'analytics.netIncome'.tr(),
//       points: netPoints,
//       color: Colors.blue,
//       strokeWidth: 3,
//       dashArray: [5, 5],
//     ),
//   ];
// });

// /// Net Worth Line Chart Widget
// class NetWorthLineChart extends ConsumerWidget {
//   final String? title;
//   final double? height;
//   final DateTimeRange? dateRange;
//   final bool showTarget;
//   final double? targetNetWorth;

//   const NetWorthLineChart({
//     super.key,
//     this.title,
//     this.height,
//     this.dateRange,
//     this.showTarget = false,
//     this.targetNetWorth,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final effectiveDateRange = dateRange ?? AppDateUtils.getCurrentYear();
//     final netWorthDataAsync =
//         ref.watch(netWorthTrendProvider(effectiveDateRange));

//     return netWorthDataAsync.when(
//       data: (netWorthData) {
//         final series = [
//           LineChartSeries(
//             id: 'net_worth',
//             label: 'analytics.netWorth'.tr(),
//             points: netWorthData,
//             color: Colors.blue,
//             fillArea: true,
//             isCurved: true,
//           ),
//         ];

//         return LineChartWidget(
//           title: title ?? 'analytics.netWorth'.tr(),
//           height: height ?? AppDimensions.lineChartHeight,
//           series: series,
//           yAxisLabel: 'common.amount'.tr(),
//           showBaseline: showTarget && targetNetWorth != null,
//           baselineValue: targetNetWorth,
//           baselineColor: Colors.green,
//         );
//       },
//       loading: () => LineChartWidget(
//         title: title ?? 'analytics.netWorth'.tr(),
//         height: height ?? AppDimensions.lineChartHeight,
//         series: const [],
//         isLoading: true,
//       ),
//       error: (error, stack) => LineChartWidget(
//         title: title ?? 'analytics.netWorth'.tr(),
//         height: height ?? AppDimensions.lineChartHeight,
//         series: const [],
//         errorMessage: error.toString(),
//       ),
//     );
//   }
// }

// /// Income vs Expense Trend Chart
// class IncomeExpenseTrendChart extends ConsumerWidget {
//   final String? title;
//   final double? height;
//   final DateTimeRange? dateRange;

//   const IncomeExpenseTrendChart({
//     super.key,
//     this.title,
//     this.height,
//     this.dateRange,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final effectiveDateRange = dateRange ?? AppDateUtils.getCurrentYear();
//     final trendDataAsync =
//         ref.watch(incomeVsExpenseTrendProvider(effectiveDateRange));

//     return trendDataAsync.when(
//       data: (seriesData) {
//         return LineChartWidget(
//           title: title ?? 'analytics.incomeVsExpense'.tr(),
//           height: height ?? AppDimensions.lineChartHeight,
//           series: seriesData,
//           yAxisLabel: 'common.amount'.tr(),
//           showBaseline: true,
//           baselineValue: 0,
//           baselineColor: Colors.grey,
//           showLegend: true,
//         );
//       },
//       loading: () => LineChartWidget(
//         title: title ?? 'analytics.incomeVsExpense'.tr(),
//         height: height ?? AppDimensions.lineChartHeight,
//         series: const [],
//         isLoading: true,
//       ),
//       error: (error, stack) => LineChartWidget(
//         title: title ?? 'analytics.incomeVsExpense'.tr(),
//         height: height ?? AppDimensions.lineChartHeight,
//         series: const [],
//         errorMessage: error.toString(),
//       ),
//     );
//   }
// }

// /// Goal Progress Line Chart
// class GoalProgressLineChart extends ConsumerWidget {
//   final String goalId;
//   final String? title;
//   final double? height;

//   const GoalProgressLineChart({
//     super.key,
//     required this.goalId,
//     this.title,
//     this.height,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final goalAsync = ref.watch(goalProvider(goalId));

//     return goalAsync.when(
//       data: (goal) {
//         if (goal == null) {
//           return LineChartWidget(
//             title: title ?? 'goals.progress'.tr(),
//             height: height ?? AppDimensions.lineChartHeight,
//             series: const [],
//             errorMessage: 'goals.goalNotFound'.tr(),
//           );
//         }

//         // Generate progress points from goal creation to current date
//         final now = DateTime.now();
//         final startDate = goal.createdAt;
//         final endDate = goal.targetDate ?? now;

//         final actualPoints = <LineChartPoint>[];
//         final targetPoints = <LineChartPoint>[];

//         // Generate monthly progress points
//         var current = startDate;
//         while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
//           final progress = current.isBefore(now) ? goal.currentAmount : 0.0;
//           final target = goal.targetAmount *
//               (current.difference(startDate).inDays /
//                   endDate.difference(startDate).inDays);

//           actualPoints.add(LineChartPoint(
//             date: current,
//             value: progress,
//           ));

//           targetPoints.add(LineChartPoint(
//             date: current,
//             value: target.clamp(0.0, goal.targetAmount),
//           ));

//           current = DateTime(current.year, current.month + 1, current.day);
//         }

//         final series = [
//           LineChartSeries(
//             id: 'actual',
//             label: 'goals.actualProgress'.tr(),
//             points: actualPoints,
//             color: Colors.blue,
//             fillArea: true,
//           ),
//           LineChartSeries(
//             id: 'target',
//             label: 'goals.targetProgress'.tr(),
//             points: targetPoints,
//             color: Colors.green,
//             dashArray: [5, 5],
//             fillArea: false,
//           ),
//         ];

//         return LineChartWidget(
//           title: title ?? 'goals.progress'.tr(),
//           height: height ?? AppDimensions.lineChartHeight,
//           series: series,
//           yAxisLabel: 'common.amount'.tr(),
//           showLegend: true,
//         );
//       },
//       loading: () => LineChartWidget(
//         title: title ?? 'goals.progress'.tr(),
//         height: height ?? AppDimensions.lineChartHeight,
//         series: const [],
//         isLoading: true,
//       ),
//       error: (error, stack) => LineChartWidget(
//         title: title ?? 'goals.progress'.tr(),
//         height: height ?? AppDimensions.lineChartHeight,
//         series: const [],
//         errorMessage: error.toString(),
//       ),
//     );
//   }
// }

// /// Enums
// enum LineChartDateFormat {
//   auto,
//   dayMonth,
//   monthYear,
//   yearOnly,
//   dayOnly,
//   monthOnly,
// }
