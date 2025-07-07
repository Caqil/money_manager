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
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/error_widget.dart';

enum TrendPeriod { daily, weekly, monthly }

class TrendAnalysisCard extends ConsumerStatefulWidget {
  final DateRange dateRange;
  final TrendPeriod period;
  final double height;
  final bool showIncomeExpense;

  const TrendAnalysisCard({
    super.key,
    required this.dateRange,
    this.period = TrendPeriod.daily,
    this.height = 300,
    this.showIncomeExpense = true,
  });

  @override
  ConsumerState<TrendAnalysisCard> createState() => _TrendAnalysisCardState();
}

class _TrendAnalysisCardState extends ConsumerState<TrendAnalysisCard> {
  late TrendPeriod _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.period;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final trendAsync = ref.watch(incomeVsExpenseProvider(AnalyticsParams(
      startDate: widget.dateRange.start,
      endDate: widget.dateRange.end,
      grouping: _getTimeGrouping(),
    )));

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
            trendAsync.when(
              loading: () => SizedBox(
                height: widget.height,
                child: const ShimmerLoading(child: SizedBox.expand()),
              ),
              error: (error, stack) => SizedBox(
                height: widget.height,
                child: CustomErrorWidget(
                  title: 'analytics.trendError'.tr(),
                  message: error.toString(),
                  onActionPressed: () =>
                      ref.refresh(incomeVsExpenseProvider(AnalyticsParams(
                    startDate: widget.dateRange.start,
                    endDate: widget.dateRange.end,
                    grouping: _getTimeGrouping(),
                  ))),
                ),
              ),
              data: (trendData) => _buildChart(context, trendData),
            ),

            const SizedBox(height: AppDimensions.spacingL),

            // Analysis
            trendAsync.when(
              data: (trendData) => _buildAnalysis(context, trendData),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
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
            Icons.trending_up,
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
                'analytics.trendAnalysis'.tr(),
                style: theme.textTheme.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'analytics.spendingTrends'.tr(),
                style: theme.textTheme.muted,
              ),
            ],
          ),
        ),
        _buildPeriodSelector(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TrendPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;

          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingS,
                vertical: AppDimensions.paddingXs,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Text(
                _getPeriodLabel(period),
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<FinancialDataPoint> trendData) {
    if (trendData.isEmpty) {
      return _buildEmptyState();
    }

    final spots = _prepareChartData(trendData);

    return SizedBox(
      height: widget.height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            drawHorizontalLine: true,
            horizontalInterval: _calculateYInterval(trendData),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
                strokeWidth: 0.5,
                dashArray: [3, 3],
              );
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
                showTitles: true,
                getTitlesWidget: (value, meta) => _buildBottomTitle(
                  value,
                  trendData,
                ),
                reservedSize: 40,
                interval: _calculateXInterval(trendData),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => _buildLeftTitle(value),
                reservedSize: 60,
                interval: _calculateYInterval(trendData),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (trendData.length - 1).toDouble(),
          minY: _getMinY(trendData),
          maxY: _getMaxY(trendData),
          lineBarsData: [
            if (widget.showIncomeExpense) ...[
              // Income line
              LineChartBarData(
                spots: spots['income']!,
                isCurved: true,
                color: AppColors.success,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.success.withOpacity(0.1),
                ),
              ),
              // Expense line
              LineChartBarData(
                spots: spots['expense']!,
                isCurved: true,
                color: AppColors.error,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.error.withOpacity(0.1),
                ),
              ),
            ] else ...[
              // Net line
              LineChartBarData(
                spots: spots['net']!,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
            ],
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(AppDimensions.paddingS),
              tooltipMargin: AppDimensions.spacingS,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final dataPoint = trendData[spot.x.toInt()];
                  final date = _formatDate(dataPoint.date);

                  String label;
                  double value;
                  Color color;

                  if (widget.showIncomeExpense) {
                    if (spot.barIndex == 0) {
                      label = 'analytics.income'.tr();
                      value = dataPoint.income;
                      color = AppColors.success;
                    } else {
                      label = 'analytics.expense'.tr();
                      value = dataPoint.expense;
                      color = AppColors.error;
                    }
                  } else {
                    label = 'analytics.net'.tr();
                    value = dataPoint.net;
                    color = AppColors.primary;
                  }

                  return LineTooltipItem(
                    '$label\n$date\n${CurrencyFormatter.format(value)}',
                    TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
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
              Icons.trending_up_outlined,
              size: 64,
              color: theme.colorScheme.mutedForeground.withOpacity(0.5),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'analytics.noTrendData'.tr(),
              style: theme.textTheme.p.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysis(
      BuildContext context, List<FinancialDataPoint> trendData) {
    final analysis = _calculateTrendAnalysis(trendData);
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                size: AppDimensions.iconS,
                color: AppColors.info,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'analytics.trendInsights'.tr(),
                style: theme.textTheme.p.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Key metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricChip(
                  'analytics.avgSpending'.tr(),
                  CurrencyFormatter.format(analysis.averageExpense),
                  AppColors.error,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: _buildMetricChip(
                  'analytics.avgIncome'.tr(),
                  CurrencyFormatter.format(analysis.averageIncome),
                  AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: _buildMetricChip(
                  'analytics.trend'.tr(),
                  '${analysis.trend > 0 ? '+' : ''}${analysis.trend.toStringAsFixed(1)}%',
                  analysis.trend > 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // Insights
          ...analysis.insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
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
                        style: theme.textTheme.small,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.p.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            label,
            style: theme.textTheme.small.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTitle(double value, List<FinancialDataPoint> trendData) {
    final index = value.toInt();
    if (index >= trendData.length) return const SizedBox.shrink();

    final date = trendData[index].date;
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingS),
      child: Text(
        _formatDate(date),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLeftTitle(double value) {
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

  Map<String, List<FlSpot>> _prepareChartData(
      List<FinancialDataPoint> trendData) {
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    final netSpots = <FlSpot>[];

    for (int i = 0; i < trendData.length; i++) {
      final point = trendData[i];
      incomeSpots.add(FlSpot(i.toDouble(), point.income));
      expenseSpots.add(FlSpot(i.toDouble(), point.expense));
      netSpots.add(FlSpot(i.toDouble(), point.net));
    }

    return {
      'income': incomeSpots,
      'expense': expenseSpots,
      'net': netSpots,
    };
  }

  double _getMinY(List<FinancialDataPoint> trendData) {
    if (widget.showIncomeExpense) return 0;

    final minNet = trendData.map((p) => p.net).reduce((a, b) => a < b ? a : b);
    return minNet < 0 ? minNet * 1.1 : 0;
  }

  double _getMaxY(List<FinancialDataPoint> trendData) {
    if (widget.showIncomeExpense) {
      final maxIncome =
          trendData.map((p) => p.income).reduce((a, b) => a > b ? a : b);
      final maxExpense =
          trendData.map((p) => p.expense).reduce((a, b) => a > b ? a : b);
      return [maxIncome, maxExpense].reduce((a, b) => a > b ? a : b) * 1.1;
    } else {
      final maxNet =
          trendData.map((p) => p.net).reduce((a, b) => a > b ? a : b);
      return maxNet * 1.1;
    }
  }

  double _calculateYInterval(List<FinancialDataPoint> trendData) {
    final maxY = _getMaxY(trendData);
    final minY = _getMinY(trendData);
    final range = maxY - minY;

    if (range <= 100) return 20;
    if (range <= 500) return 100;
    if (range <= 1000) return 200;
    if (range <= 5000) return 1000;
    return (range / 5).roundToDouble();
  }

  double _calculateXInterval(List<FinancialDataPoint> trendData) {
    final length = trendData.length;
    if (length <= 7) return 1;
    if (length <= 14) return 2;
    if (length <= 30) return 5;
    return (length / 6).roundToDouble();
  }

  TimeGrouping _getTimeGrouping() {
    switch (_selectedPeriod) {
      case TrendPeriod.daily:
        return TimeGrouping.daily;
      case TrendPeriod.weekly:
        return TimeGrouping.weekly;
      case TrendPeriod.monthly:
        return TimeGrouping.monthly;
    }
  }

  String _getPeriodLabel(TrendPeriod period) {
    switch (period) {
      case TrendPeriod.daily:
        return 'analytics.daily'.tr();
      case TrendPeriod.weekly:
        return 'analytics.weekly'.tr();
      case TrendPeriod.monthly:
        return 'analytics.monthly'.tr();
    }
  }

  String _formatDate(DateTime date) {
    switch (_selectedPeriod) {
      case TrendPeriod.daily:
        return DateFormat.MMMd().format(date);
      case TrendPeriod.weekly:
        return DateFormat.MMMd().format(date);
      case TrendPeriod.monthly:
        return DateFormat.MMM().format(date);
    }
  }

  TrendAnalysis _calculateTrendAnalysis(List<FinancialDataPoint> trendData) {
    if (trendData.isEmpty) {
      return const TrendAnalysis(
        averageIncome: 0,
        averageExpense: 0,
        trend: 0,
        insights: [],
      );
    }

    final averageIncome =
        trendData.map((p) => p.income).reduce((a, b) => a + b) /
            trendData.length;

    final averageExpense =
        trendData.map((p) => p.expense).reduce((a, b) => a + b) /
            trendData.length;

    // Calculate trend (simple linear regression slope)
    double trend = 0;
    if (trendData.length > 1) {
      final firstHalf = trendData.take(trendData.length ~/ 2);
      final secondHalf = trendData.skip(trendData.length ~/ 2);

      final firstAvg = firstHalf.map((p) => p.expense).reduce((a, b) => a + b) /
          firstHalf.length;

      final secondAvg =
          secondHalf.map((p) => p.expense).reduce((a, b) => a + b) /
              secondHalf.length;

      if (firstAvg > 0) {
        trend = ((secondAvg - firstAvg) / firstAvg) * 100;
      }
    }

    final insights =
        _generateTrendInsights(averageIncome, averageExpense, trend);

    return TrendAnalysis(
      averageIncome: averageIncome,
      averageExpense: averageExpense,
      trend: trend,
      insights: insights,
    );
  }

  List<String> _generateTrendInsights(
    double averageIncome,
    double averageExpense,
    double trend,
  ) {
    final insights = <String>[];

    if (trend > 10) {
      insights.add('analytics.spendingIncreasing'.tr());
    } else if (trend < -10) {
      insights.add('analytics.spendingDecreasing'.tr());
    } else {
      insights.add('analytics.spendingStable'.tr());
    }

    if (averageIncome > averageExpense) {
      insights.add('analytics.positiveBalance'.tr());
    } else {
      insights.add('analytics.negativeBalance'.tr());
    }

    final savingsRate = averageIncome > 0
        ? ((averageIncome - averageExpense) / averageIncome) * 100
        : 0;

    if (savingsRate > 20) {
      insights.add('analytics.goodSavingsRate'.tr());
    } else if (savingsRate < 10) {
      insights.add('analytics.lowSavingsRate'.tr());
    }

    return insights;
  }
}

// Data model for trend analysis
class TrendAnalysis {
  final double averageIncome;
  final double averageExpense;
  final double trend;
  final List<String> insights;

  const TrendAnalysis({
    required this.averageIncome,
    required this.averageExpense,
    required this.trend,
    required this.insights,
  });
}
