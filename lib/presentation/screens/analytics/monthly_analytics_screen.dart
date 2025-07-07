// lib/presentation/screens/analytics/monthly_analytics_screen.dart
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
import 'widgets/date_range_selector.dart';

class MonthlyAnalyticsScreen extends ConsumerStatefulWidget {
  const MonthlyAnalyticsScreen({super.key});

  @override
  ConsumerState<MonthlyAnalyticsScreen> createState() =>
      _MonthlyAnalyticsScreenState();
}

class _MonthlyAnalyticsScreenState extends ConsumerState<MonthlyAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedYear = DateTime.now();
  MonthlyViewType _viewType = MonthlyViewType.overview;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: 'analytics.monthlyAnalytics'.tr(),
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
          _buildYearSelector(),
          _buildHeaderMetrics(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTrendsTab(),
                _buildComparisonTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeYear(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              _selectedYear.year.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeYear(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetrics() {
    final monthlyDataAsync = ref.watch(monthlyAnalyticsProvider(_selectedYear));

    return monthlyDataAsync.when(
      loading: () => Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
        child: const LoadingWidget(),
      ),
      error: (error, _) => Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
        child: CustomErrorWidget(
          message: 'analytics.errorLoadingData'.tr(),
          onActionPressed: () =>
              ref.refresh(monthlyAnalyticsProvider(_selectedYear)),
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
        child: Row(
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
                'analytics.netSavings'.tr(),
                CurrencyFormatter.format(data.netSavings),
                data.netSavings >= 0 ? Icons.savings : Icons.warning,
                data.netSavings >= 0 ? AppColors.success : AppColors.warning,
              ),
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
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
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
      tabs: [
        Tab(text: 'analytics.overview'.tr()),
        Tab(text: 'analytics.trends'.tr()),
        Tab(text: 'analytics.comparison'.tr()),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final monthlyDataAsync = ref.watch(monthlyAnalyticsProvider(_selectedYear));

    return monthlyDataAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'analytics.errorLoadingData'.tr(),
        onActionPressed: () =>
            ref.refresh(monthlyAnalyticsProvider(_selectedYear)),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthlyBreakdownChart(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildCategoryBreakdown(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildMonthlyInsights(data),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    final trendDataAsync = ref.watch(monthlyTrendsProvider(_selectedYear));

    return trendDataAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'analytics.errorLoadingData'.tr(),
        onActionPressed: () =>
            ref.refresh(monthlyTrendsProvider(_selectedYear)),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrendChart(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildTrendInsights(data),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTab() {
    final comparisonDataAsync =
        ref.watch(monthlyComparisonProvider(_selectedYear));

    return comparisonDataAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'analytics.errorLoadingData'.tr(),
        onActionPressed: () =>
            ref.refresh(monthlyComparisonProvider(_selectedYear)),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildYearOverYearComparison(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildMonthOverMonthComparison(data),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBreakdownChart(MonthlyAnalyticsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.monthlyBreakdown'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 300,
              child: _viewType == MonthlyViewType.chart
                  ? const Placeholder() // Replace with actual chart widget
                  : _buildMonthlyGrid(data),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyGrid(MonthlyAnalyticsData data) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: AppDimensions.spacingS,
        mainAxisSpacing: AppDimensions.spacingS,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final monthData = data.monthlyData.firstWhere(
          (m) => m.month == month,
          orElse: () => MonthlyDataPoint(month: month, income: 0, expense: 0),
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat.MMM().format(DateTime(2023, month)),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  CurrencyFormatter.formatCompact(monthData.income),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatCompact(monthData.expense),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: monthData.net >= 0
                        ? AppColors.success
                        : AppColors.error,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryBreakdown(MonthlyAnalyticsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.topCategories'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ...data.topCategories.take(5).map((category) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingS),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Text(category.name),
                      ),
                      Text(
                        CurrencyFormatter.format(category.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
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

  Widget _buildMonthlyInsights(MonthlyAnalyticsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.insights'.tr(),
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
                      Icon(
                        insight.type.icon,
                        color: insight.type.color,
                        size: 16,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Text(insight.message),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(MonthlyTrendData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.spendingTrends'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 300,
              child: const Placeholder(), // Replace with actual line chart
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendInsights(MonthlyTrendData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.trendInsights'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text('analytics.trendInsightDetails'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildYearOverYearComparison(MonthlyComparisonData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.yearOverYear'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 300,
              child: const Placeholder(), // Replace with comparison chart
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthOverMonthComparison(MonthlyComparisonData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.monthOverMonth'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 300,
              child: const Placeholder(), // Replace with comparison chart
            ),
          ],
        ),
      ),
    );
  }

  void _changeYear(int delta) {
    setState(() {
      _selectedYear = DateTime(_selectedYear.year + delta);
    });
  }

  void _toggleViewType() {
    setState(() {
      _viewType = _viewType == MonthlyViewType.overview
          ? MonthlyViewType.chart
          : MonthlyViewType.overview;
    });
  }

  IconData _getViewTypeIcon() {
    return _viewType == MonthlyViewType.overview
        ? Icons.grid_view
        : Icons.show_chart;
  }

  void _handleMenuAction(String action) {
    switch (action) {
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
class MonthlyAnalyticsData {
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final List<MonthlyDataPoint> monthlyData;
  final List<CategorySpendingItem> topCategories;
  final List<MonthlyInsight> insights;

  const MonthlyAnalyticsData({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.monthlyData,
    required this.topCategories,
    required this.insights,
  });
}

class MonthlyDataPoint {
  final int month;
  final double income;
  final double expense;

  const MonthlyDataPoint({
    required this.month,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;
}

class CategorySpendingItem {
  final String id;
  final String name;
  final double amount;
  final Color color;

  const CategorySpendingItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.color,
  });
}

class MonthlyInsight {
  final String message;
  final InsightType type;

  const MonthlyInsight({
    required this.message,
    required this.type,
  });
}

class MonthlyTrendData {
  final List<TrendPoint> trendPoints;
  final double averageGrowthRate;
  final String trendDirection;

  const MonthlyTrendData({
    required this.trendPoints,
    required this.averageGrowthRate,
    required this.trendDirection,
  });
}

class MonthlyComparisonData {
  final List<ComparisonPoint> yearOverYear;
  final List<ComparisonPoint> monthOverMonth;

  const MonthlyComparisonData({
    required this.yearOverYear,
    required this.monthOverMonth,
  });
}

class TrendPoint {
  final DateTime date;
  final double value;

  const TrendPoint({
    required this.date,
    required this.value,
  });
}

class ComparisonPoint {
  final String label;
  final double currentValue;
  final double previousValue;
  final double change;

  const ComparisonPoint({
    required this.label,
    required this.currentValue,
    required this.previousValue,
    required this.change,
  });
}

enum MonthlyViewType { overview, chart }

enum InsightType {
  positive(Icons.trending_up, AppColors.success),
  negative(Icons.trending_down, AppColors.error),
  neutral(Icons.info, AppColors.info),
  warning(Icons.warning, AppColors.warning);

  const InsightType(this.icon, this.color);
  final IconData icon;
  final Color color;
}

// Providers
final monthlyAnalyticsProvider =
    FutureProvider.family<MonthlyAnalyticsData, DateTime>(
  (ref, year) async {
    // Simulate data loading
    await Future.delayed(const Duration(seconds: 1));

    // Return mock data - replace with actual implementation
    return const MonthlyAnalyticsData(
      totalIncome: 12000.0,
      totalExpense: 8500.0,
      netSavings: 3500.0,
      monthlyData: [],
      topCategories: [],
      insights: [],
    );
  },
);

final monthlyTrendsProvider = FutureProvider.family<MonthlyTrendData, DateTime>(
  (ref, year) async {
    await Future.delayed(const Duration(seconds: 1));
    return const MonthlyTrendData(
      trendPoints: [],
      averageGrowthRate: 0.0,
      trendDirection: 'stable',
    );
  },
);

final monthlyComparisonProvider =
    FutureProvider.family<MonthlyComparisonData, DateTime>(
  (ref, year) async {
    await Future.delayed(const Duration(seconds: 1));
    return const MonthlyComparisonData(
      yearOverYear: [],
      monthOverMonth: [],
    );
  },
);
