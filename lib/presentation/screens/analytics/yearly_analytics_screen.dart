// lib/presentation/screens/analytics/yearly_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/charts/line_chart_widget.dart';
import '../../widgets/charts/pie_chart_widget.dart';
import 'monthly_analytics_screen.dart';

class YearlyAnalyticsScreen extends ConsumerStatefulWidget {
  const YearlyAnalyticsScreen({super.key});

  @override
  ConsumerState<YearlyAnalyticsScreen> createState() =>
      _YearlyAnalyticsScreenState();
}

class _YearlyAnalyticsScreenState extends ConsumerState<YearlyAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYearRange = 5; // Show last 5 years by default
  YearlyViewType _viewType = YearlyViewType.overview;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'analytics.yearlyAnalytics'.tr(),
        actions: [
          IconButton(
            onPressed: _toggleViewType,
            icon: Icon(_getViewTypeIcon()),
            tooltip: 'analytics.toggleView'.tr(),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'yearRange',
                child: Row(
                  children: [
                    const Icon(Icons.date_range, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('analytics.selectYearRange'.tr()),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.download, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('common.export'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.share, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('common.share'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildYearRangeSelector(),
          _buildHeaderMetrics(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTrendsTab(),
                _buildGoalsTab(),
                _buildForecastTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearRangeSelector() {
    final currentYear = DateTime.now().year;
    final startYear = currentYear - _selectedYearRange + 1;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        children: [
          Icon(
            Icons.calendar_view_month,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            'analytics.yearRange'
                .tr(args: [startYear.toString(), currentYear.toString()]),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          ShadButton.outline(
            onPressed: _selectYearRange,
            size: ShadButtonSize.sm,
            child: Text('analytics.changeRange'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetrics() {
    final yearlyDataAsync =
        ref.watch(yearlyAnalyticsProvider(_selectedYearRange));

    return yearlyDataAsync.when(
      loading: () => Container(
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
        child: const LoadingWidget(),
      ),
      error: (error, _) => Container(
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
        child: CustomErrorWidget(
          message: 'analytics.errorLoadingData'.tr(),
          onActionPressed: () =>
              ref.refresh(yearlyAnalyticsProvider(_selectedYearRange)),
        ),
      ),
      data: (data) => Container(
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'analytics.totalIncome'.tr(),
                    CurrencyFormatter.format(data.totalIncome),
                    Icons.trending_up,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingL),
                Expanded(
                  child: _buildMetricItem(
                    'analytics.totalExpense'.tr(),
                    CurrencyFormatter.format(data.totalExpense),
                    Icons.trending_down,
                    AppColors.error,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingL),
                Expanded(
                  child: _buildMetricItem(
                    'analytics.netWorth'.tr(),
                    CurrencyFormatter.format(data.netWorth),
                    Icons.account_balance,
                    AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'analytics.avgYearlyGrowth'.tr(),
                    '${data.avgGrowthRate.toStringAsFixed(1)}%',
                    data.avgGrowthRate >= 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    data.avgGrowthRate >= 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingL),
                Expanded(
                  child: _buildMetricItem(
                    'analytics.bestYear'.tr(),
                    data.bestYear.toString(),
                    Icons.star,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingL),
                Expanded(
                  child: _buildMetricItem(
                    'analytics.savingsRate'.tr(),
                    '${data.avgSavingsRate.toStringAsFixed(1)}%',
                    Icons.savings,
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: [
        Tab(text: 'analytics.overview'.tr()),
        Tab(text: 'analytics.trends'.tr()),
        Tab(text: 'analytics.goals'.tr()),
        Tab(text: 'analytics.forecast'.tr()),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final yearlyDataAsync =
        ref.watch(yearlyAnalyticsProvider(_selectedYearRange));

    return yearlyDataAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'analytics.errorLoadingData'.tr(),
        onActionPressed: () =>
            ref.refresh(yearlyAnalyticsProvider(_selectedYearRange)),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildYearlyPerformanceChart(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildCategoryTrendsOverYears(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildYearlyInsights(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildFinancialMilestones(data),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    final trendDataAsync = ref.watch(yearlyTrendsProvider(_selectedYearRange));

    return trendDataAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'analytics.errorLoadingData'.tr(),
        onActionPressed: () =>
            ref.refresh(yearlyTrendsProvider(_selectedYearRange)),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIncomeExpenseTrendChart(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildSavingsRateTrend(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildSeasonalTrends(data),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsTab() {
    final goalsDataAsync =
        ref.watch(yearlyGoalsAnalyticsProvider(_selectedYearRange));

    return goalsDataAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'analytics.errorLoadingData'.tr(),
        onActionPressed: () =>
            ref.refresh(yearlyGoalsAnalyticsProvider(_selectedYearRange)),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGoalCompletionChart(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildGoalProgressOverTime(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildGoalPerformanceMetrics(data),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastTab() {
    final forecastDataAsync =
        ref.watch(yearlyForecastProvider(_selectedYearRange));

    return forecastDataAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'analytics.errorLoadingData'.tr(),
        onActionPressed: () =>
            ref.refresh(yearlyForecastProvider(_selectedYearRange)),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildForecastChart(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildForecastScenarios(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildRecommendations(data),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyPerformanceChart(YearlyAnalyticsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'analytics.yearlyPerformance'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _toggleChartView('performance'),
                  icon: Icon(_viewType == YearlyViewType.overview
                      ? Icons.bar_chart
                      : Icons.show_chart),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 300,
              child: _viewType == YearlyViewType.chart
                  ? const Placeholder() // Replace with actual chart widget
                  : _buildYearlyGrid(data),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyGrid(YearlyAnalyticsData data) {
    final currentYear = DateTime.now().year;
    final years = List.generate(_selectedYearRange,
        (index) => currentYear - _selectedYearRange + 1 + index);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _selectedYearRange > 3 ? 3 : 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: AppDimensions.spacingS,
        mainAxisSpacing: AppDimensions.spacingS,
      ),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final yearData = data.yearlyData.firstWhere(
          (y) => y.year == year,
          orElse: () =>
              YearlyDataPoint(year: year, income: 0, expense: 0, netWorth: 0),
        );

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  year.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  'analytics.net'.tr(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatCompact(yearData.net),
                  style: TextStyle(
                    color:
                        yearData.net >= 0 ? AppColors.success : AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                LinearProgressIndicator(
                  value: yearData.savingsRate / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    yearData.savingsRate >= 20
                        ? AppColors.success
                        : yearData.savingsRate >= 10
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryTrendsOverYears(YearlyAnalyticsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.categoryTrends'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: data.categoryTrends.length,
                itemBuilder: (context, index) {
                  final trend = data.categoryTrends[index];
                  return Container(
                    width: 120,
                    margin:
                        const EdgeInsets.only(right: AppDimensions.spacingM),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.paddingS),
                        child: Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: trend.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingS),
                            Text(
                              trend.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Icon(
                              trend.isIncreasing
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: trend.isIncreasing
                                  ? AppColors.error
                                  : AppColors.success,
                              size: 16,
                            ),
                            Text(
                              '${trend.changePercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: trend.isIncreasing
                                    ? AppColors.error
                                    : AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyInsights(YearlyAnalyticsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.keyInsights'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ...data.insights.map((insight) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingS),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: insight.type.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          insight.type.icon,
                          color: insight.type.color,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              insight.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialMilestones(YearlyAnalyticsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.financialMilestones'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ...data.milestones.map((milestone) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingS),
                  child: Row(
                    children: [
                      Icon(
                        milestone.isAchieved
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: milestone.isAchieved
                            ? AppColors.success
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Text(
                          milestone.title,
                          style: TextStyle(
                            decoration: milestone.isAchieved
                                ? TextDecoration.lineThrough
                                : null,
                            color: milestone.isAchieved ? Colors.grey : null,
                          ),
                        ),
                      ),
                      if (milestone.targetAmount != null)
                        Text(
                          CurrencyFormatter.format(milestone.targetAmount!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // Implement other build methods for charts...
  Widget _buildIncomeExpenseTrendChart(YearlyTrendData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.incomeExpenseTrend'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 300, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsRateTrend(YearlyTrendData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.savingsRateTrend'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 200, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonalTrends(YearlyTrendData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.seasonalTrends'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 200, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCompletionChart(YearlyGoalsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.goalCompletion'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 300, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressOverTime(YearlyGoalsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.goalProgressOverTime'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 200, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalPerformanceMetrics(YearlyGoalsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.goalPerformance'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 200, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastChart(YearlyForecastData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.forecastChart'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 300, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastScenarios(YearlyForecastData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.forecastScenarios'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 200, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(YearlyForecastData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.recommendations'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ...data.recommendations.map((recommendation) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingS),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(child: Text(recommendation)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _selectYearRange() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('analytics.selectYearRange'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [3, 5, 7, 10].map((years) {
            return RadioListTile<int>(
              title: Text('analytics.lastNYears'.tr(args: [years.toString()])),
              value: years,
              groupValue: _selectedYearRange,
              onChanged: (value) {
                Navigator.of(context).pop(value);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedYearRange = selected;
      });
    }
  }

  void _toggleViewType() {
    setState(() {
      _viewType = _viewType == YearlyViewType.overview
          ? YearlyViewType.chart
          : YearlyViewType.overview;
    });
  }

  void _toggleChartView(String chartType) {
    // Toggle specific chart views
    setState(() {
      _viewType = _viewType == YearlyViewType.overview
          ? YearlyViewType.chart
          : YearlyViewType.overview;
    });
  }

  IconData _getViewTypeIcon() {
    return _viewType == YearlyViewType.overview
        ? Icons.grid_view
        : Icons.show_chart;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'yearRange':
        _selectYearRange();
        break;
      case 'export':
        _exportData();
        break;
      case 'share':
        _shareData();
        break;
    }
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('analytics.exportFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _shareData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('analytics.shareFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }
}

// Data models
class YearlyAnalyticsData {
  final double totalIncome;
  final double totalExpense;
  final double netWorth;
  final double avgGrowthRate;
  final int bestYear;
  final double avgSavingsRate;
  final List<YearlyDataPoint> yearlyData;
  final List<CategoryTrend> categoryTrends;
  final List<YearlyInsight> insights;
  final List<FinancialMilestone> milestones;

  const YearlyAnalyticsData({
    required this.totalIncome,
    required this.totalExpense,
    required this.netWorth,
    required this.avgGrowthRate,
    required this.bestYear,
    required this.avgSavingsRate,
    required this.yearlyData,
    required this.categoryTrends,
    required this.insights,
    required this.milestones,
  });
}

class YearlyDataPoint {
  final int year;
  final double income;
  final double expense;
  final double netWorth;

  const YearlyDataPoint({
    required this.year,
    required this.income,
    required this.expense,
    required this.netWorth,
  });

  double get net => income - expense;
  double get savingsRate =>
      income > 0 ? ((income - expense) / income) * 100 : 0;
}

class CategoryTrend {
  final String id;
  final String name;
  final Color color;
  final double changePercentage;
  final bool isIncreasing;

  const CategoryTrend({
    required this.id,
    required this.name,
    required this.color,
    required this.changePercentage,
    required this.isIncreasing,
  });
}

class YearlyInsight {
  final String title;
  final String description;
  final InsightType type;

  const YearlyInsight({
    required this.title,
    required this.description,
    required this.type,
  });
}

class FinancialMilestone {
  final String title;
  final bool isAchieved;
  final double? targetAmount;
  final DateTime? achievedDate;

  const FinancialMilestone({
    required this.title,
    required this.isAchieved,
    this.targetAmount,
    this.achievedDate,
  });
}

class YearlyTrendData {
  final List<TrendPoint> incomeExpenseTrend;
  final List<TrendPoint> savingsRateTrend;
  final List<SeasonalTrend> seasonalTrends;

  const YearlyTrendData({
    required this.incomeExpenseTrend,
    required this.savingsRateTrend,
    required this.seasonalTrends,
  });
}

class YearlyGoalsData {
  final int totalGoals;
  final int completedGoals;
  final double completionRate;
  final List<GoalProgressPoint> progressOverTime;

  const YearlyGoalsData({
    required this.totalGoals,
    required this.completedGoals,
    required this.completionRate,
    required this.progressOverTime,
  });
}

class YearlyForecastData {
  final List<ForecastPoint> forecastPoints;
  final List<ForecastScenario> scenarios;
  final List<String> recommendations;

  const YearlyForecastData({
    required this.forecastPoints,
    required this.scenarios,
    required this.recommendations,
  });
}

class SeasonalTrend {
  final String season;
  final double averageSpending;
  final List<String> topCategories;

  const SeasonalTrend({
    required this.season,
    required this.averageSpending,
    required this.topCategories,
  });
}

class GoalProgressPoint {
  final DateTime date;
  final double progress;

  const GoalProgressPoint({
    required this.date,
    required this.progress,
  });
}

class ForecastPoint {
  final DateTime date;
  final double value;
  final ForecastType type;

  const ForecastPoint({
    required this.date,
    required this.value,
    required this.type,
  });
}

class ForecastScenario {
  final String name;
  final String description;
  final double probability;
  final double projectedValue;

  const ForecastScenario({
    required this.name,
    required this.description,
    required this.probability,
    required this.projectedValue,
  });
}

enum YearlyViewType { overview, chart }

enum ForecastType { conservative, moderate, optimistic }

// Providers
final yearlyAnalyticsProvider = FutureProvider.family<YearlyAnalyticsData, int>(
  (ref, yearRange) async {
    await Future.delayed(const Duration(seconds: 1));
    return const YearlyAnalyticsData(
      totalIncome: 120000.0,
      totalExpense: 85000.0,
      netWorth: 150000.0,
      avgGrowthRate: 5.2,
      bestYear: 2023,
      avgSavingsRate: 29.2,
      yearlyData: [],
      categoryTrends: [],
      insights: [],
      milestones: [],
    );
  },
);

final yearlyTrendsProvider = FutureProvider.family<YearlyTrendData, int>(
  (ref, yearRange) async {
    await Future.delayed(const Duration(seconds: 1));
    return const YearlyTrendData(
      incomeExpenseTrend: [],
      savingsRateTrend: [],
      seasonalTrends: [],
    );
  },
);

final yearlyGoalsAnalyticsProvider =
    FutureProvider.family<YearlyGoalsData, int>(
  (ref, yearRange) async {
    await Future.delayed(const Duration(seconds: 1));
    return const YearlyGoalsData(
      totalGoals: 10,
      completedGoals: 7,
      completionRate: 70.0,
      progressOverTime: [],
    );
  },
);

final yearlyForecastProvider = FutureProvider.family<YearlyForecastData, int>(
  (ref, yearRange) async {
    await Future.delayed(const Duration(seconds: 1));
    return const YearlyForecastData(
      forecastPoints: [],
      scenarios: [],
      recommendations: [],
    );
  },
);
