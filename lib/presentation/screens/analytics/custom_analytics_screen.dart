// lib/presentation/screens/analytics/custom_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/charts/line_chart_widget.dart';
import '../../widgets/charts/pie_chart_widget.dart';
import 'monthly_analytics_screen.dart';
import 'widgets/date_range_selector.dart';

class CustomAnalyticsScreen extends ConsumerStatefulWidget {
  const CustomAnalyticsScreen({super.key});

  @override
  ConsumerState<CustomAnalyticsScreen> createState() =>
      _CustomAnalyticsScreenState();
}

class _CustomAnalyticsScreenState extends ConsumerState<CustomAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter state
  DateRange? _selectedDateRange;
  List<String> _selectedAccountIds = [];
  List<String> _selectedCategoryIds = [];
  TransactionType? _selectedTransactionType;
  CustomAnalyticsViewType _viewType = CustomAnalyticsViewType.summary;
  CustomTimeGrouping _timeGrouping = CustomTimeGrouping.monthly;

  // UI state
  bool _showFilters = false;
  bool _isFilterApplied = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedDateRange = DateRange(
      start: DateTime.now().subtract(const Duration(days: 90)),
      end: DateTime.now(),
    );
    _initializeDefaultFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeDefaultFilters() {
    // Initialize with all accounts and categories selected by default
    final accountsAsync = ref.read(accountListProvider);
    final categoriesAsync = ref.read(categoryListProvider);

    accountsAsync.whenData((accounts) {
      _selectedAccountIds = accounts.map((a) => a.id).toList();
    });

    categoriesAsync.whenData((categories) {
      _selectedCategoryIds = categories.map((c) => c.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'analytics.customAnalytics'.tr(),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: _isFilterApplied ? AppColors.primary : null,
            ),
            tooltip: 'analytics.toggleFilters'.tr(),
          ),
          IconButton(
            onPressed: _toggleViewType,
            icon: Icon(_getViewTypeIcon()),
            tooltip: 'analytics.toggleView'.tr(),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'saveTemplate',
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_add, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('analytics.saveTemplate'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'loadTemplate',
                child: Row(
                  children: [
                    const Icon(Icons.bookmark, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('analytics.loadTemplate'.tr()),
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
          if (_showFilters) _buildFilterPanel(),
          _buildQuickStats(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildTrendsTab(),
                _buildCategoriesTab(),
                _buildComparisonTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'analytics.filters'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isFilterApplied)
                ShadButton.ghost(
                  onPressed: _resetFilters,
                  size: ShadButtonSize.sm,
                  child: Text('analytics.resetFilters'.tr()),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Wrap(
            spacing: AppDimensions.spacingM,
            runSpacing: AppDimensions.spacingS,
            children: [
              _buildDateRangeFilter(),
              _buildAccountFilter(),
              _buildCategoryFilter(),
              _buildTransactionTypeFilter(),
              _buildTimeGroupingFilter(),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                child: ShadButton(
                  onPressed: _applyFilters,
                  child: Text('analytics.applyFilters'.tr()),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: ShadButton.outline(
                  onPressed: _resetFilters,
                  child: Text('analytics.reset'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'analytics.dateRange'.tr(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        ShadButton.outline(
          onPressed: _selectDateRange,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.date_range, size: 16),
              const SizedBox(width: AppDimensions.spacingXs),
              Text(_formatDateRange(_selectedDateRange)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountFilter() {
    final accountsAsync = ref.watch(accountListProvider);

    return accountsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (accounts) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'analytics.accounts'.tr(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          ShadButton.outline(
            onPressed: () => _selectAccounts(accounts),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet, size: 16),
                const SizedBox(width: AppDimensions.spacingXs),
                Text('${_selectedAccountIds.length}/${accounts.length}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categoriesAsync = ref.watch(categoryListProvider);

    return categoriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (categories) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'analytics.categories'.tr(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          ShadButton.outline(
            onPressed: () => _selectCategories(categories),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.category, size: 16),
                const SizedBox(width: AppDimensions.spacingXs),
                Text('${_selectedCategoryIds.length}/${categories.length}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'analytics.transactionType'.tr(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        ShadButton.outline(
          onPressed: _selectTransactionType,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getTransactionTypeIcon(), size: 16),
              const SizedBox(width: AppDimensions.spacingXs),
              Text(_getTransactionTypeLabel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeGroupingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'analytics.timeGrouping'.tr(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        SegmentedButton<CustomTimeGrouping>(
          segments: CustomTimeGrouping.values
              .map(
                (grouping) => ButtonSegment<CustomTimeGrouping>(
                  value: grouping,
                  label: Text(_getTimeGroupingLabel(grouping)),
                ),
              )
              .toList(),
          selected: {_timeGrouping},
          onSelectionChanged: (selection) {
            setState(() {
              _timeGrouping = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final customDataAsync = ref.watch(customAnalyticsProvider(
      CustomAnalyticsParams(
        dateRange: _selectedDateRange!,
        accountIds: _selectedAccountIds,
        categoryIds: _selectedCategoryIds,
        transactionType: _selectedTransactionType,
        timeGrouping: _timeGrouping,
      ),
    ));

    return customDataAsync.when(
      loading: () => Container(
        height: 100,
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        child: const LoadingWidget(),
      ),
      error: (error, _) => Container(
        height: 100,
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        child: CustomErrorWidget(
          message: 'analytics.errorLoadingData'.tr(),
          onActionPressed: () =>
              ref.refresh(customAnalyticsProvider(CustomAnalyticsParams(
            dateRange: _selectedDateRange!,
            accountIds: _selectedAccountIds,
            categoryIds: _selectedCategoryIds,
            transactionType: _selectedTransactionType,
            timeGrouping: _timeGrouping,
          ))),
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
            Expanded(
              child: _buildQuickStatItem(
                'analytics.totalTransactions'.tr(),
                data.totalTransactions.toString(),
                Icons.receipt_long,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingL),
            Expanded(
              child: _buildQuickStatItem(
                'analytics.totalAmount'.tr(),
                CurrencyFormatter.format(data.totalAmount),
                Icons.monetization_on,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingL),
            Expanded(
              child: _buildQuickStatItem(
                'analytics.avgTransaction'.tr(),
                CurrencyFormatter.format(data.averageAmount),
                Icons.analytics,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingL),
            Expanded(
              child: _buildQuickStatItem(
                'analytics.dateRange'.tr(),
                '${_selectedDateRange!.days} ${'analytics.days'.tr()}',
                Icons.today,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
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
        Tab(text: 'analytics.summary'.tr()),
        Tab(text: 'analytics.trends'.tr()),
        Tab(text: 'analytics.categories'.tr()),
        Tab(text: 'analytics.comparison'.tr()),
      ],
    );
  }

  Widget _buildSummaryTab() {
    final customDataAsync =
        ref.watch(customAnalyticsProvider(_buildAnalyticsParams()));

    return customDataAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'analytics.errorLoadingData'.tr(),
        onActionPressed: () =>
            ref.refresh(customAnalyticsProvider(_buildAnalyticsParams())),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountChart(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildTopCategoriesCard(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildStatisticsCard(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildInsightsCard(data),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    final trendDataAsync =
        ref.watch(customTrendsProvider(_buildAnalyticsParams()));

    return trendDataAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'analytics.errorLoadingData'.tr(),
        onActionPressed: () =>
            ref.refresh(customTrendsProvider(_buildAnalyticsParams())),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrendChart(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildVelocityAnalysis(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildPatternsCard(data),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final categoryDataAsync =
        ref.watch(customCategoryAnalyticsProvider(_buildAnalyticsParams()));

    return categoryDataAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'analytics.errorLoadingData'.tr(),
        onActionPressed: () => ref
            .refresh(customCategoryAnalyticsProvider(_buildAnalyticsParams())),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryDistributionChart(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildCategoryRankingCard(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildCategoryInsights(data),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTab() {
    final comparisonDataAsync =
        ref.watch(customComparisonProvider(_buildAnalyticsParams()));

    return comparisonDataAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'analytics.errorLoadingData'.tr(),
        onActionPressed: () =>
            ref.refresh(customComparisonProvider(_buildAnalyticsParams())),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodComparison(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildAccountComparison(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildBenchmarkComparison(data),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountChart(CustomAnalyticsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'analytics.amountOverTime'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _toggleChartView('amount'),
                  icon: Icon(_viewType == CustomAnalyticsViewType.summary
                      ? Icons.bar_chart
                      : Icons.show_chart),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 300,
              child: _viewType == CustomAnalyticsViewType.chart
                  ? const Placeholder() // Replace with actual chart widget
                  : _buildAmountGrid(data),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountGrid(CustomAnalyticsData data) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: AppDimensions.spacingS,
        mainAxisSpacing: AppDimensions.spacingS,
      ),
      itemCount: data.timeSeriesData.length,
      itemBuilder: (context, index) {
        final dataPoint = data.timeSeriesData[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTimeLabel(dataPoint.date),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  CurrencyFormatter.formatCompact(dataPoint.amount),
                  style: TextStyle(
                    color: _getAmountColor(dataPoint.amount),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopCategoriesCard(CustomAnalyticsData data) {
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
                        flex: 2,
                        child: Text(category.name),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: category.percentage / 100,
                          backgroundColor: Colors.grey.shade300,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(category.color),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
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

  Widget _buildStatisticsCard(CustomAnalyticsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.statistics'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'analytics.highest'.tr(),
                    CurrencyFormatter.format(data.highestAmount),
                    Icons.trending_up,
                    AppColors.success,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'analytics.lowest'.tr(),
                    CurrencyFormatter.format(data.lowestAmount),
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
                  child: _buildStatItem(
                    'analytics.median'.tr(),
                    CurrencyFormatter.format(data.medianAmount),
                    Icons.analytics,
                    AppColors.info,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'analytics.stdDev'.tr(),
                    CurrencyFormatter.format(data.standardDeviation),
                    Icons.scatter_plot,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(CustomAnalyticsData data) {
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

  // Implement other chart building methods...
  Widget _buildTrendChart(CustomTrendsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.trendAnalysis'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 300, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildVelocityAnalysis(CustomTrendsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.velocityAnalysis'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 200, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternsCard(CustomTrendsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.patterns'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text('Patterns analysis placeholder'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDistributionChart(CustomCategoryData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.categoryDistribution'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 300, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRankingCard(CustomCategoryData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.categoryRanking'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 200, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryInsights(CustomCategoryData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.categoryInsights'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text('Category insights placeholder'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodComparison(CustomComparisonData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.periodComparison'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 300, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountComparison(CustomComparisonData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.accountComparison'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 200, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkComparison(CustomComparisonData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics.benchmarkComparison'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(height: 200, child: const Placeholder()),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _quickAnalysis,
      icon: const Icon(Icons.auto_awesome),
      label: Text('analytics.quickAnalysis'.tr()),
      backgroundColor: AppColors.primary,
    );
  }

  // Helper methods
  CustomAnalyticsParams _buildAnalyticsParams() {
    return CustomAnalyticsParams(
      dateRange: _selectedDateRange!,
      accountIds: _selectedAccountIds,
      categoryIds: _selectedCategoryIds,
      transactionType: _selectedTransactionType,
      timeGrouping: _timeGrouping,
    );
  }

  String _formatDateRange(DateRange? dateRange) {
    if (dateRange == null) return 'analytics.selectDateRange'.tr();

    final formatter = DateFormat.MMMd();
    if (dateRange.days == 1) {
      return formatter.format(dateRange.start);
    }
    return '${formatter.format(dateRange.start)} - ${formatter.format(dateRange.end)}';
  }

  String _formatTimeLabel(DateTime date) {
    switch (_timeGrouping) {
      case CustomTimeGrouping.daily:
        return DateFormat.MMMd().format(date);
      case CustomTimeGrouping.weekly:
        return 'W${((date.day - 1) ~/ 7) + 1}';
      case CustomTimeGrouping.monthly:
        return DateFormat.MMM().format(date);
      case CustomTimeGrouping.yearly:
        return date.year.toString();
    }
  }

  Color _getAmountColor(double amount) {
    if (_selectedTransactionType == TransactionType.income)
      return AppColors.success;
    if (_selectedTransactionType == TransactionType.expense)
      return AppColors.error;
    return amount >= 0 ? AppColors.success : AppColors.error;
  }

  IconData _getTransactionTypeIcon() {
    switch (_selectedTransactionType) {
      case TransactionType.income:
        return Icons.trending_up;
      case TransactionType.expense:
        return Icons.trending_down;
      case TransactionType.transfer:
        return Icons.compare_arrows;
      case null:
        return Icons.all_inclusive;
    }
  }

  String _getTransactionTypeLabel() {
    switch (_selectedTransactionType) {
      case TransactionType.income:
        return 'transactions.income'.tr();
      case TransactionType.expense:
        return 'transactions.expense'.tr();
      case TransactionType.transfer:
        return 'transactions.transfer'.tr();
      case null:
        return 'analytics.allTypes'.tr();
    }
  }

  String _getTimeGroupingLabel(CustomTimeGrouping grouping) {
    switch (grouping) {
      case CustomTimeGrouping.daily:
        return 'analytics.daily'.tr();
      case CustomTimeGrouping.weekly:
        return 'analytics.weekly'.tr();
      case CustomTimeGrouping.monthly:
        return 'analytics.monthly'.tr();
      case CustomTimeGrouping.yearly:
        return 'analytics.yearly'.tr();
    }
  }

  IconData _getViewTypeIcon() {
    return _viewType == CustomAnalyticsViewType.summary
        ? Icons.grid_view
        : Icons.show_chart;
  }

  void _toggleViewType() {
    setState(() {
      _viewType = _viewType == CustomAnalyticsViewType.summary
          ? CustomAnalyticsViewType.chart
          : CustomAnalyticsViewType.summary;
    });
  }

  void _toggleChartView(String chartType) {
    setState(() {
      _viewType = _viewType == CustomAnalyticsViewType.summary
          ? CustomAnalyticsViewType.chart
          : CustomAnalyticsViewType.summary;
    });
  }

  Future<void> _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _selectedDateRange!.start,
        end: _selectedDateRange!.end,
      ),
    );

    if (dateRange != null) {
      setState(() {
        _selectedDateRange = DateRange(
          start: dateRange.start,
          end: dateRange.end,
        );
      });
    }
  }

  Future<void> _selectAccounts(List<Account> accounts) async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => _AccountSelectorDialog(
        accounts: accounts,
        selectedIds: _selectedAccountIds,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedAccountIds = selected;
      });
    }
  }

  Future<void> _selectCategories(List<Category> categories) async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => _CategorySelectorDialog(
        categories: categories,
        selectedIds: _selectedCategoryIds,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedCategoryIds = selected;
      });
    }
  }

  Future<void> _selectTransactionType() async {
    final selected = await showDialog<TransactionType?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('analytics.selectTransactionType'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<TransactionType?>(
              title: Text('analytics.allTypes'.tr()),
              value: null,
              groupValue: _selectedTransactionType,
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
            ...TransactionType.values
                .map((type) => RadioListTile<TransactionType?>(
                      title: Text(_getTransactionTypeLabel()),
                      value: type,
                      groupValue: _selectedTransactionType,
                      onChanged: (value) => Navigator.of(context).pop(value),
                    )),
          ],
        ),
      ),
    );

    if (selected != null || selected == null) {
      setState(() {
        _selectedTransactionType = selected;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _isFilterApplied = true;
    });
    ref.invalidate(customAnalyticsProvider);
  }

  void _resetFilters() {
    setState(() {
      _selectedDateRange = DateRange(
        start: DateTime.now().subtract(const Duration(days: 90)),
        end: DateTime.now(),
      );
      _selectedAccountIds.clear();
      _selectedCategoryIds.clear();
      _selectedTransactionType = null;
      _timeGrouping = CustomTimeGrouping.monthly;
      _isFilterApplied = false;
    });
    _initializeDefaultFilters();
    ref.invalidate(customAnalyticsProvider);
  }

  void _quickAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('analytics.quickAnalysisFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'saveTemplate':
        _saveTemplate();
        break;
      case 'loadTemplate':
        _loadTemplate();
        break;
      case 'export':
        _exportData();
        break;
      case 'share':
        _shareData();
        break;
    }
  }

  void _saveTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('analytics.saveTemplateFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _loadTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('analytics.loadTemplateFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
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

// Dialog widgets
class _AccountSelectorDialog extends StatefulWidget {
  final List<Account> accounts;
  final List<String> selectedIds;

  const _AccountSelectorDialog({
    required this.accounts,
    required this.selectedIds,
  });

  @override
  State<_AccountSelectorDialog> createState() => _AccountSelectorDialogState();
}

class _AccountSelectorDialogState extends State<_AccountSelectorDialog> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('analytics.selectAccounts'.tr()),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: Text('analytics.selectAll'.tr()),
              value: _selectedIds.length == widget.accounts.length,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds = widget.accounts.map((a) => a.id).toList();
                  } else {
                    _selectedIds.clear();
                  }
                });
              },
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.accounts.length,
                itemBuilder: (context, index) {
                  final account = widget.accounts[index];
                  return CheckboxListTile(
                    title: Text(account.name),
                    subtitle: Text(CurrencyFormatter.format(account.balance)),
                    value: _selectedIds.contains(account.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(account.id);
                        } else {
                          _selectedIds.remove(account.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds),
          child: Text('common.confirm'.tr()),
        ),
      ],
    );
  }
}

class _CategorySelectorDialog extends StatefulWidget {
  final List<Category> categories;
  final List<String> selectedIds;

  const _CategorySelectorDialog({
    required this.categories,
    required this.selectedIds,
  });

  @override
  State<_CategorySelectorDialog> createState() =>
      _CategorySelectorDialogState();
}

class _CategorySelectorDialogState extends State<_CategorySelectorDialog> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('analytics.selectCategories'.tr()),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: Text('analytics.selectAll'.tr()),
              value: _selectedIds.length == widget.categories.length,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds = widget.categories.map((c) => c.id).toList();
                  } else {
                    _selectedIds.clear();
                  }
                });
              },
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.categories.length,
                itemBuilder: (context, index) {
                  final category = widget.categories[index];
                  return CheckboxListTile(
                    title: Text(category.name),
                    value: _selectedIds.contains(category.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(category.id);
                        } else {
                          _selectedIds.remove(category.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds),
          child: Text('common.confirm'.tr()),
        ),
      ],
    );
  }
}

// Data models
class CustomAnalyticsParams {
  final DateRange dateRange;
  final List<String> accountIds;
  final List<String> categoryIds;
  final TransactionType? transactionType;
  final CustomTimeGrouping timeGrouping;

  const CustomAnalyticsParams({
    required this.dateRange,
    required this.accountIds,
    required this.categoryIds,
    this.transactionType,
    required this.timeGrouping,
  });
}

class CustomAnalyticsData {
  final int totalTransactions;
  final double totalAmount;
  final double averageAmount;
  final double highestAmount;
  final double lowestAmount;
  final double medianAmount;
  final double standardDeviation;
  final List<TimeSeriesDataPoint> timeSeriesData;
  final List<CategoryAnalyticsItem> topCategories;
  final List<CustomInsight> insights;

  const CustomAnalyticsData({
    required this.totalTransactions,
    required this.totalAmount,
    required this.averageAmount,
    required this.highestAmount,
    required this.lowestAmount,
    required this.medianAmount,
    required this.standardDeviation,
    required this.timeSeriesData,
    required this.topCategories,
    required this.insights,
  });
}

class CustomTrendsData {
  final List<TrendPoint> trendPoints;
  final double trendSlope;
  final String trendDirection;

  const CustomTrendsData({
    required this.trendPoints,
    required this.trendSlope,
    required this.trendDirection,
  });
}

class CustomCategoryData {
  final List<CategoryDistributionItem> distribution;
  final List<CategoryRankingItem> ranking;

  const CustomCategoryData({
    required this.distribution,
    required this.ranking,
  });
}

class CustomComparisonData {
  final List<ComparisonPeriod> periodComparison;
  final List<AccountComparisonItem> accountComparison;

  const CustomComparisonData({
    required this.periodComparison,
    required this.accountComparison,
  });
}

class TimeSeriesDataPoint {
  final DateTime date;
  final double amount;

  const TimeSeriesDataPoint({
    required this.date,
    required this.amount,
  });
}

class CategoryAnalyticsItem {
  final String id;
  final String name;
  final double amount;
  final double percentage;
  final Color color;

  const CategoryAnalyticsItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class CustomInsight {
  final String message;
  final InsightType type;

  const CustomInsight({
    required this.message,
    required this.type,
  });
}

class CategoryDistributionItem {
  final String id;
  final String name;
  final double amount;
  final double percentage;

  const CategoryDistributionItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.percentage,
  });
}

class CategoryRankingItem {
  final String id;
  final String name;
  final double amount;
  final int rank;

  const CategoryRankingItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.rank,
  });
}

class ComparisonPeriod {
  final String label;
  final double currentValue;
  final double previousValue;
  final double change;

  const ComparisonPeriod({
    required this.label,
    required this.currentValue,
    required this.previousValue,
    required this.change,
  });
}

class AccountComparisonItem {
  final String id;
  final String name;
  final double amount;
  final double percentage;

  const AccountComparisonItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.percentage,
  });
}

enum CustomAnalyticsViewType { summary, chart }

enum CustomTimeGrouping { daily, weekly, monthly, yearly }

// Providers
final customAnalyticsProvider =
    FutureProvider.family<CustomAnalyticsData, CustomAnalyticsParams>(
  (ref, params) async {
    await Future.delayed(const Duration(seconds: 1));
    return const CustomAnalyticsData(
      totalTransactions: 150,
      totalAmount: 15000.0,
      averageAmount: 100.0,
      highestAmount: 500.0,
      lowestAmount: 10.0,
      medianAmount: 80.0,
      standardDeviation: 45.0,
      timeSeriesData: [],
      topCategories: [],
      insights: [],
    );
  },
);

final customTrendsProvider =
    FutureProvider.family<CustomTrendsData, CustomAnalyticsParams>(
  (ref, params) async {
    await Future.delayed(const Duration(seconds: 1));
    return const CustomTrendsData(
      trendPoints: [],
      trendSlope: 0.0,
      trendDirection: 'stable',
    );
  },
);

final customCategoryAnalyticsProvider =
    FutureProvider.family<CustomCategoryData, CustomAnalyticsParams>(
  (ref, params) async {
    await Future.delayed(const Duration(seconds: 1));
    return const CustomCategoryData(
      distribution: [],
      ranking: [],
    );
  },
);

final customComparisonProvider =
    FutureProvider.family<CustomComparisonData, CustomAnalyticsParams>(
  (ref, params) async {
    await Future.delayed(const Duration(seconds: 1));
    return const CustomComparisonData(
      periodComparison: [],
      accountComparison: [],
    );
  },
);
