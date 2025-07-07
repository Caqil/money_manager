import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:money_manager/core/utils/currency_formatter.dart';
import 'package:money_manager/presentation/screens/analytics/widgets/date_range_selector.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../presentation/providers/analytics_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import 'widgets/spending_bar_chart.dart';
import 'widgets/spending_insights_card.dart';
import 'widgets/spending_pie_chart.dart';
import 'widgets/trend_analysis_card.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateRange _selectedDateRange = DateRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

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
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Date Range Selector
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: DateRangeSelector(
                selectedRange: _selectedDateRange,
                onRangeChanged: (range) {
                  setState(() {
                    _selectedDateRange = range;
                  });
                },
              ),
            ),

            // Tab Bar
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: AppDimensions.marginM),
              decoration: BoxDecoration(
                color: AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.mutedForeground,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: 'analytics.overview'.tr()),
                  Tab(text: 'analytics.trends'.tr()),
                  Tab(text: 'analytics.insights'.tr()),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildTrendsTab(),
                  _buildInsightsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Icon(
              Icons.analytics,
              color: Colors.white,
              size: AppDimensions.iconL,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'analytics.title'.tr(),
                  style: theme.textTheme.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  'analytics.subtitle'.tr(),
                  style: theme.textTheme.p.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Export button
          ShadButton.ghost(
            onPressed: _showExportOptions,
            size: ShadButtonSize.sm,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(
                Icons.file_download,
                color: Colors.white,
                size: AppDimensions.iconS,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          // Quick Stats
          _buildQuickStats(),
          const SizedBox(height: AppDimensions.spacingL),

          // Spending Breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pie Chart
              Expanded(
                flex: 1,
                child: SpendingPieChart(
                  dateRange: _selectedDateRange,
                  maxCategories: 6,
                  size: 200,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),

              // Bar Chart
              Expanded(
                flex: 1,
                child: SpendingBarChart(
                  dateRange: _selectedDateRange,
                  maxCategories: 8,
                  height: 300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          // Trend Analysis
          TrendAnalysisCard(
            dateRange: _selectedDateRange,
            period: TrendPeriod.daily,
            height: 300,
            showIncomeExpense: true,
          ),
          const SizedBox(height: AppDimensions.spacingL),

          // Net Trend Analysis
          TrendAnalysisCard(
            dateRange: _selectedDateRange,
            period: TrendPeriod.weekly,
            height: 250,
            showIncomeExpense: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          // Spending Insights
          SpendingInsightsCard(
            dateRange: _selectedDateRange,
            comparisonRange: _getPreviousPeriodRange(),
          ),
          const SizedBox(height: AppDimensions.spacingL),

          // Budget Performance
          _buildBudgetPerformance(),
          const SizedBox(height: AppDimensions.spacingL),

          // Goal Progress
          _buildGoalProgress(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final spendingAsync =
        ref.watch(spendingByCategoryProvider(_selectedDateRange));
    final theme = ShadTheme.of(context);

    return spendingAsync.when(
      loading: () => const ShimmerLoading(child: SizedBox()),
      error: (error, stack) => CustomErrorWidget(
        title: 'analytics.statsError'.tr(),
        message: error.toString(),
        onActionPressed: () =>
            ref.refresh(spendingByCategoryProvider(_selectedDateRange)),
      ),
      data: (spendingData) {
        final totalSpent =
            spendingData.values.fold(0.0, (sum, amount) => sum + amount);
        final categoriesCount = spendingData.length;
        final avgDaily = totalSpent / _selectedDateRange.days;
        final topCategory = spendingData.isNotEmpty
            ? spendingData.entries.reduce((a, b) => a.value > b.value ? a : b)
            : null;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'analytics.totalSpent'.tr(),
                totalSpent.toString(),
                Icons.account_balance_wallet,
                AppColors.primary,
                isCurrency: true,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: _buildStatCard(
                'analytics.avgDaily'.tr(),
                avgDaily.toString(),
                Icons.calendar_today,
                AppColors.success,
                isCurrency: true,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: _buildStatCard(
                'analytics.categories'.tr(),
                categoriesCount.toString(),
                Icons.category,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: _buildStatCard(
                'analytics.topSpending'.tr(),
                topCategory?.value.toString() ?? '0',
                Icons.trending_up,
                AppColors.error,
                isCurrency: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isCurrency = false,
  }) {
    final theme = ShadTheme.of(context);
    final displayValue = isCurrency && value != '0'
        ? CurrencyFormatter.formatCompact(double.tryParse(value) ?? 0)
        : value;

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Icon(
                icon,
                color: color,
                size: AppDimensions.iconM,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              displayValue,
              style: theme.textTheme.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              title,
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

  Widget _buildBudgetPerformance() {
    final budgetAsync = ref.watch(budgetPerformanceProvider);
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: AppColors.info,
                    size: AppDimensions.iconM,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'analytics.budgetPerformance'.tr(),
                        style: theme.textTheme.h4.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'analytics.budgetStatus'.tr(),
                        style: theme.textTheme.muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
            budgetAsync.when(
              loading: () => const ShimmerLoading(child: SizedBox()),
              error: (error, stack) => Text('Error: $error'),
              data: (budgetPerformances) {
                if (budgetPerformances.isEmpty) {
                  return Center(
                    child: Text(
                      'analytics.noBudgets'.tr(),
                      style: theme.textTheme.muted,
                    ),
                  );
                }

                return Column(
                  children: budgetPerformances.take(3).map((performance) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.spacingM),
                      child: _buildBudgetItem(performance),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem(BudgetPerformance performance) {
    final theme = ShadTheme.of(context);
    final progress = performance.percentageUsed.clamp(0.0, 1.0);
    final isOverBudget = performance.percentageUsed > 1.0;
    final color = isOverBudget ? AppColors.error : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              performance.budget.categoryId, // Would need category name lookup
              style: theme.textTheme.p.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(performance.percentageUsed * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.p.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'analytics.spent'.tr(),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            Text(
              '${CurrencyFormatter.format(performance.spentAmount)} / ${CurrencyFormatter.format(performance.budget.limit)}',
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalProgress() {
    final goalAsync = ref.watch(goalAnalyticsProvider);
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    Icons.flag,
                    color: AppColors.success,
                    size: AppDimensions.iconM,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'analytics.goalProgress'.tr(),
                        style: theme.textTheme.h4.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'analytics.activeGoals'.tr(),
                        style: theme.textTheme.muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
            goalAsync.when(
              loading: () => ShimmerLoading(child: SizedBox()),
              error: (error, stack) => Text('Error: $error'),
              data: (goalAnalytics) {
                if (goalAnalytics.activeGoals == 0) {
                  return Center(
                    child: Text(
                      'analytics.noGoals'.tr(),
                      style: theme.textTheme.muted,
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildGoalMetric(
                        'analytics.activeGoals'.tr(),
                        goalAnalytics.activeGoals.toString(),
                        AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: _buildGoalMetric(
                        'analytics.avgProgress'.tr(),
                        '${(goalAnalytics.averageProgress * 100).toStringAsFixed(0)}%',
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: _buildGoalMetric(
                        'analytics.completed'.tr(),
                        goalAnalytics.completedGoals.toString(),
                        AppColors.warning,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalMetric(String label, String value, Color color) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
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

  DateRange _getPreviousPeriodRange() {
    final currentDuration = _selectedDateRange.duration;
    return DateRange(
      start: _selectedDateRange.start.subtract(currentDuration),
      end: _selectedDateRange.start.subtract(const Duration(days: 1)),
    );
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('analytics.exportData'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text('analytics.exportPDF'.tr()),
              onTap: () {
                Navigator.of(context).pop();
                _exportToPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: Text('analytics.exportCSV'.tr()),
              onTap: () {
                Navigator.of(context).pop();
                _exportToCSV();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _exportToPDF() {
    // Implementation for PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('analytics.exportingPDF'.tr())),
    );
  }

  void _exportToCSV() {
    // Implementation for CSV export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('analytics.exportingCSV'.tr())),
    );
  }
}
