
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/date_range_selector.dart';

class IncomeExpenseAnalyticsScreen extends ConsumerStatefulWidget {
  const IncomeExpenseAnalyticsScreen({super.key});

  @override
  ConsumerState<IncomeExpenseAnalyticsScreen> createState() =>
      _IncomeExpenseAnalyticsScreenState();
}

class _IncomeExpenseAnalyticsScreenState
    extends ConsumerState<IncomeExpenseAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateRange _selectedDateRange;

  // Comparison periods
  bool _showComparison = false;
  ComparisonPeriod _comparisonPeriod = ComparisonPeriod.previousPeriod;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDateRange = DateRange(
      start: DateTime.now().subtract(Duration(days: DateTime.now().day - 1)),
      end: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'analytics.incomeExpense'.tr(),
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _toggleComparison,
            icon: Icon(
              _showComparison ? Icons.compare_arrows : Icons.compare,
              color: _showComparison ? AppColors.primary : null,
            ),
            tooltip: 'analytics.toggleComparison'.tr(),
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
          // Header with key metrics
          _buildHeaderMetrics(),

          // Date range selector
          _buildDateRangeSelector(),

          // Comparison toggle
          if (_showComparison) _buildComparisonControls(),

          // Tab bar
          _buildTabBar(),

          // Tab content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetrics() {
    final incomeExpenseAsync =
        ref.watch(incomeExpenseProvider(_selectedDateRange));

    return incomeExpenseAsync.when(
      loading: () => Container(
        height: 120,
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        child: const LoadingWidget(),
      ),
      error: (error, _) => Container(
        height: 120,
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Center(
          child: Text(
            'analytics.errorLoadingData'.tr(),
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
      data: (data) => Container(
        margin: const EdgeInsets.all(AppDimensions.paddingM),
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
            // Income
            Expanded(
              child: _buildMetricCard(
                'analytics.totalIncome'.tr(),
                CurrencyFormatter.format(data.totalIncome),
                Icons.trending_up,
                AppColors.success,
                isWhiteText: true,
              ),
            ),

            Container(
              width: 1,
              height: 60,
              color: Colors.white.withOpacity(0.3),
              margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM),
            ),

            // Expenses
            Expanded(
              child: _buildMetricCard(
                'analytics.totalExpenses'.tr(),
                CurrencyFormatter.format(data.totalExpenses),
                Icons.trending_down,
                AppColors.error,
                isWhiteText: true,
              ),
            ),

            Container(
              width: 1,
              height: 60,
              color: Colors.white.withOpacity(0.3),
              margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM),
            ),

            // Net Income
            Expanded(
              child: _buildMetricCard(
                'analytics.netIncome'.tr(),
                CurrencyFormatter.format(data.netIncome),
                data.netIncome >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                data.netIncome >= 0 ? AppColors.success : AppColors.error,
                isWhiteText: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color iconColor,
      {bool isWhiteText = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isWhiteText ? Colors.white : iconColor,
              size: 20,
            ),
            const SizedBox(width: AppDimensions.spacingXs),
            Text(
              title,
              style: TextStyle(
                color: isWhiteText
                    ? Colors.white.withOpacity(0.9)
                    : AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          value,
          style: TextStyle(
            color: isWhiteText ? Colors.white : AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      child: DateRangeSelector(
        selectedRange: _selectedDateRange,
        onRangeChanged: (range) {
          setState(() {
            _selectedDateRange = range;
          });
        },
        initialOption: DateRangeOption.thisMonth,
      ),
    );
  }

  Widget _buildComparisonControls() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'analytics.comparisonPeriod'.tr(),
            style: ShadTheme.of(context).textTheme.h4,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Wrap(
            spacing: AppDimensions.spacingS,
            children: ComparisonPeriod.values.map((period) {
              final isSelected = _comparisonPeriod == period;
              return ChoiceChip(
                label: Text('analytics.${period.name}'.tr()),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _comparisonPeriod = period;
                    });
                  }
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.secondary,
        tabs: [
          Tab(text: 'analytics.overview'.tr()),
          Tab(text: 'analytics.trends'.tr()),
          Tab(text: 'analytics.breakdown'.tr()),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildTrendsTab(),
        _buildBreakdownTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Income vs Expense Chart
          _buildIncomeExpenseChart(),

          const SizedBox(height: AppDimensions.spacingL),

          // Summary Cards
          _buildSummaryCards(),

          const SizedBox(height: AppDimensions.spacingL),

          // Key Insights
          _buildKeyInsights(),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseChart() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'analytics.incomeVsExpenses'.tr(),
            style: ShadTheme.of(context).textTheme.h4,
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Placeholder for chart
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    'analytics.chartComingSoon'.tr(),
                    style: ShadTheme.of(context).textTheme.muted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final incomeExpenseAsync =
        ref.watch(incomeExpenseProvider(_selectedDateRange));

    return incomeExpenseAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => Text('Error: $error'),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'analytics.summary'.tr(),
            style: ShadTheme.of(context).textTheme.h4,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'analytics.averageIncome'.tr(),
                  CurrencyFormatter.format(data.averageIncome),
                  Icons.trending_up,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: _buildSummaryCard(
                  'analytics.averageExpenses'.tr(),
                  CurrencyFormatter.format(data.averageExpenses),
                  Icons.trending_down,
                  AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'analytics.savingsRate'.tr(),
                  '${(data.savingsRate * 100).toStringAsFixed(1)}%',
                  Icons.savings,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: _buildSummaryCard(
                  'analytics.transactionCount'.tr(),
                  data.transactionCount.toString(),
                  Icons.receipt,
                  AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInsights() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'analytics.keyInsights'.tr(),
            style: ShadTheme.of(context).textTheme.h4,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildInsightItem(
            Icons.lightbulb,
            AppColors.warning,
            'analytics.insight1'.tr(),
            'analytics.insight1Desc'.tr(),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildInsightItem(
            Icons.trending_up,
            AppColors.success,
            'analytics.insight2'.tr(),
            'analytics.insight2Desc'.tr(),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildInsightItem(
            Icons.warning,
            AppColors.error,
            'analytics.insight3'.tr(),
            'analytics.insight3Desc'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
      IconData icon, Color color, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                description,
                style: ShadTheme.of(context).textTheme.muted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          // Monthly Trend Chart
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border:
                  Border.all(color: ShadTheme.of(context).colorScheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'analytics.monthlyTrends'.tr(),
                  style: ShadTheme.of(context).textTheme.h4,
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 48,
                          color: AppColors.info,
                        ),
                        const SizedBox(height: AppDimensions.spacingS),
                        Text(
                          'analytics.trendsChartComingSoon'.tr(),
                          style: ShadTheme.of(context).textTheme.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Trend Analysis
          _buildTrendAnalysis(),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'analytics.trendAnalysis'.tr(),
            style: ShadTheme.of(context).textTheme.h4,
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Placeholder for trend analysis
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Center(
              child: Text(
                'analytics.trendAnalysisComingSoon'.tr(),
                style: ShadTheme.of(context).textTheme.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          // Income Breakdown
          _buildBreakdownSection(
            'analytics.incomeBreakdown'.tr(),
            TransactionType.income,
            AppColors.success,
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Expense Breakdown
          _buildBreakdownSection(
            'analytics.expenseBreakdown'.tr(),
            TransactionType.expense,
            AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(
      String title, TransactionType type, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ShadTheme.of(context).textTheme.h4,
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Placeholder for breakdown chart
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == TransactionType.income
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 48,
                    color: color,
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    'analytics.breakdownChartComingSoon'.tr(),
                    style: ShadTheme.of(context).textTheme.muted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleComparison() {
    setState(() {
      _showComparison = !_showComparison;
    });
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

// Data classes
class IncomeExpenseData {
  final double totalIncome;
  final double totalExpenses;
  final double netIncome;
  final double averageIncome;
  final double averageExpenses;
  final double savingsRate;
  final int transactionCount;

  const IncomeExpenseData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
    required this.averageIncome,
    required this.averageExpenses,
    required this.savingsRate,
    required this.transactionCount,
  });
}

enum ComparisonPeriod {
  previousPeriod,
  previousMonth,
  previousYear,
  samePeriodLastYear,
}

// Provider placeholder
final incomeExpenseProvider =
    FutureProvider.family<IncomeExpenseData, DateRange>((ref, dateRange) async {
  // Placeholder implementation
  await Future.delayed(const Duration(seconds: 1));

  return const IncomeExpenseData(
    totalIncome: 5000.0,
    totalExpenses: 3500.0,
    netIncome: 1500.0,
    averageIncome: 2500.0,
    averageExpenses: 1750.0,
    savingsRate: 0.3,
    transactionCount: 45,
  );
});
