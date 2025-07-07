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
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late DateRange _selectedDateRange;
  bool _isDisposed = false;

  // Cache for expensive operations
  String? _cachedDateRangeKey;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeDateRange();
  }

  void _initializeControllers() {
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 0,
    );

    // Add listener to handle tab changes
    _tabController.addListener(_onTabChanged);
  }

  void _initializeDateRange() {
    final now = DateTime.now();
    _selectedDateRange = DateRange(
      start: DateTime(now.year, now.month, 1), // Start of current month
      end: now,
    );
    _updateCacheKey();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // Force refresh when tab changes to prevent stale data
      _refreshCurrentTab();
    }
  }

  String _getCacheKey(DateRange range) {
    return '${range.start.millisecondsSinceEpoch}_${range.end.millisecondsSinceEpoch}';
  }

  void _updateCacheKey() {
    _cachedDateRangeKey = _getCacheKey(_selectedDateRange);
  }

  void _refreshProviders() {
    if (_isDisposed || !mounted) return;

    try {
      ref.invalidate(spendingByCategoryProvider(_selectedDateRange));
      ref.invalidate(budgetPerformanceProvider);
      ref.invalidate(goalAnalyticsProvider);
    } catch (e) {
      debugPrint('Error refreshing providers: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            // _buildDateRangeSelector(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
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
          _buildExportButton(),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return ShadButton.ghost(
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
    );
  }

  Widget _buildDateRangeSelector() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: DateRangeSelector(
        selectedRange: _selectedDateRange,
        onRangeChanged: _onDateRangeChanged,
        initialOption: DateRangeOption.thisMonth,
      ),
    );
  }

  void _onDateRangeChanged(DateRange range) {
    if (_isDisposed || !mounted) return;

    // Validate date range
    if (!range.isValid()) {
      _showErrorMessage('analytics.invalidDateRange'.tr());
      return;
    }

    // Check if range is too large (prevent performance issues)
    if (range.days > 365) {
      _showErrorMessage('analytics.dateRangeTooLarge'.tr());
      return;
    }

    setState(() {
      _selectedDateRange = range;
    });

    _updateCacheKey();
    _refreshProviders();
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginM),
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
        unselectedLabelColor: ShadTheme.of(context).colorScheme.mutedForeground,
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
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildTrendsTab(),
        _buildInsightsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            _buildQuickStats(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildSpendingBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingBreakdown() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive layout for different screen sizes
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: SpendingPieChart(
                  dateRange: _selectedDateRange,
                  maxCategories: 6,
                  size: 200,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                flex: 1,
                child: SpendingBarChart(
                  dateRange: _selectedDateRange,
                  maxCategories: 8,
                  height: 300,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              SpendingPieChart(
                dateRange: _selectedDateRange,
                maxCategories: 6,
                size: 200,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              SpendingBarChart(
                dateRange: _selectedDateRange,
                maxCategories: 8,
                height: 300,
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildTrendsTab() {
    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            TrendAnalysisCard(
              dateRange: _selectedDateRange,
              period: TrendPeriod.daily,
              height: 300,
              showIncomeExpense: true,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            TrendAnalysisCard(
              dateRange: _selectedDateRange,
              period: TrendPeriod.weekly,
              height: 250,
              showIncomeExpense: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            SpendingInsightsCard(
              dateRange: _selectedDateRange,
              comparisonRange: _getPreviousPeriodRange(),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            _buildBudgetPerformance(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildGoalProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final spendingAsync =
        ref.watch(spendingByCategoryProvider(_selectedDateRange));

    return spendingAsync.when(
      loading: () => _buildLoadingStats(),
      error: (error, stack) => _buildErrorStats(error),
      data: _buildStatsCards,
    );
  }

  Widget _buildLoadingStats() {
    return const ShimmerLoading(
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            Expanded(child: Card()),
            SizedBox(width: AppDimensions.spacingM),
            Expanded(child: Card()),
            SizedBox(width: AppDimensions.spacingM),
            Expanded(child: Card()),
            SizedBox(width: AppDimensions.spacingM),
            Expanded(child: Card()),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorStats(Object error) {
    return CustomErrorWidget(
      title: 'analytics.statsError'.tr(),
      message: error.toString(),
      onActionPressed: () {
        if (!_isDisposed && mounted) {
          ref.refresh(spendingByCategoryProvider(_selectedDateRange));
        }
      },
    );
  }

  Widget _buildStatsCards(Map<String, double> spendingData) {
    final totalSpent =
        spendingData.values.fold(0.0, (sum, amount) => sum + amount);
    final categoriesCount = spendingData.length;
    final avgDaily = _selectedDateRange.days > 0
        ? totalSpent / _selectedDateRange.days
        : 0.0;
    final topCategory = spendingData.isNotEmpty
        ? spendingData.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive stats layout
        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'analytics.totalSpent'.tr(),
                      totalSpent.toString(),
                      Icons.account_balance_wallet,
                      AppColors.primary,
                      isCurrency: true)),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                  child: _buildStatCard(
                      'analytics.avgDaily'.tr(),
                      avgDaily.toString(),
                      Icons.calendar_today,
                      AppColors.success,
                      isCurrency: true)),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                  child: _buildStatCard(
                      'analytics.categories'.tr(),
                      categoriesCount.toString(),
                      Icons.category,
                      AppColors.warning)),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                  child: _buildStatCard(
                      'analytics.topSpending'.tr(),
                      topCategory?.value.toString() ?? '0',
                      Icons.trending_up,
                      AppColors.error,
                      isCurrency: true)),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard(
                          'analytics.totalSpent'.tr(),
                          totalSpent.toString(),
                          Icons.account_balance_wallet,
                          AppColors.primary,
                          isCurrency: true)),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                      child: _buildStatCard(
                          'analytics.avgDaily'.tr(),
                          avgDaily.toString(),
                          Icons.calendar_today,
                          AppColors.success,
                          isCurrency: true)),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard(
                          'analytics.categories'.tr(),
                          categoriesCount.toString(),
                          Icons.category,
                          AppColors.warning)),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                      child: _buildStatCard(
                          'analytics.topSpending'.tr(),
                          topCategory?.value.toString() ?? '0',
                          Icons.trending_up,
                          AppColors.error,
                          isCurrency: true)),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {bool isCurrency = false}) {
    final theme = ShadTheme.of(context);
    final numericValue = double.tryParse(value) ?? 0.0;
    final displayValue = isCurrency && numericValue > 0
        ? CurrencyFormatter.formatCompact(numericValue)
        : numericValue == 0
            ? '0'
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
              child: Icon(icon, color: color, size: AppDimensions.iconM),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              displayValue,
              style: theme.textTheme.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              title,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
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
            _buildSectionHeader(
              'analytics.budgetPerformance'.tr(),
              'analytics.budgetStatus'.tr(),
              Icons.account_balance,
              AppColors.info,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            budgetAsync.when(
              loading: () => const ShimmerLoading(child: SizedBox(height: 150)),
              error: (error, stack) => _buildErrorMessage(error.toString()),
              data: (budgetPerformances) {
                if (budgetPerformances.isEmpty) {
                  return _buildEmptyState('analytics.noBudgets'.tr());
                }
                return Column(
                  children: budgetPerformances
                      .take(3)
                      .map((performance) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppDimensions.spacingM),
                            child: _buildBudgetItem(performance),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgress() {
    final goalAsync = ref.watch(goalAnalyticsProvider);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'analytics.goalProgress'.tr(),
              'analytics.activeGoals'.tr(),
              Icons.flag,
              AppColors.success,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            goalAsync.when(
              loading: () => const ShimmerLoading(child: SizedBox(height: 100)),
              error: (error, stack) => _buildErrorMessage(error.toString()),
              data: (goalAnalytics) {
                if (goalAnalytics.activeGoals == 0) {
                  return _buildEmptyState('analytics.noGoals'.tr());
                }
                return Row(
                  children: [
                    Expanded(
                        child: _buildGoalMetric(
                            'analytics.activeGoals'.tr(),
                            goalAnalytics.activeGoals.toString(),
                            AppColors.info)),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                        child: _buildGoalMetric(
                            'analytics.avgProgress'.tr(),
                            '${(goalAnalytics.averageProgress * 100).toStringAsFixed(0)}%',
                            AppColors.success)),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                        child: _buildGoalMetric(
                            'analytics.completed'.tr(),
                            goalAnalytics.completedGoals.toString(),
                            AppColors.warning)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, String subtitle, IconData icon, Color color) {
    final theme = ShadTheme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingS),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(icon, color: color, size: AppDimensions.iconM),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold)),
              Text(subtitle, style: theme.textTheme.muted),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Text(message, style: theme.textTheme.muted),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Text(
          'Error: $error',
          style: theme.textTheme.small.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
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
            Expanded(
              child: Text(
                performance.budget.categoryId,
                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${(performance.percentageUsed * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.p
                  .copyWith(fontWeight: FontWeight.w600, color: color),
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
              style: theme.textTheme.small
                  .copyWith(color: theme.colorScheme.mutedForeground),
            ),
            Text(
              '${CurrencyFormatter.format(performance.spentAmount)} / ${CurrencyFormatter.format(performance.budget.limit)}',
              style: theme.textTheme.small
                  .copyWith(color: theme.colorScheme.mutedForeground),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalMetric(String label, String value, Color color) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.h3
                .copyWith(fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            label,
            style:
                theme.textTheme.small.copyWith(color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
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

  Future<void> _refreshCurrentTab() async {
    if (_isDisposed || !mounted) return;

    try {
      _refreshProviders();
      await Future.delayed(const Duration(
          milliseconds: 500)); // Give time for providers to refresh
    } catch (e) {
      debugPrint('Error during refresh: $e');
    }
  }

  void _showExportOptions() {
    if (_isDisposed || !mounted) return;

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
    _showSuccessMessage('analytics.exportingPDF'.tr());
  }

  void _exportToCSV() {
    _showSuccessMessage('analytics.exportingCSV'.tr());
  }

  void _showErrorMessage(String message) {
    if (_isDisposed || !mounted) return;
    ShadSonner.of(context).show(
      ShadToast(
        description: Text(message),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (_isDisposed || !mounted) return;
    ShadSonner.of(context).show(
      ShadToast(
        description: Text(message),
      ),
    );
  }
}
