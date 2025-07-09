import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/budget.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/charts/pie_chart_widget.dart';
import '../../widgets/charts/line_chart_widget.dart';
import '../analytics/monthly_analytics_screen.dart';
import '../transactions/widgets/transaction_item.dart';
import 'widgets/category_icon_picker.dart';

class CategoryDetailsScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const CategoryDetailsScreen({
    super.key,
    required this.categoryId,
  });

  @override
  ConsumerState<CategoryDetailsScreen> createState() =>
      _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends ConsumerState<CategoryDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CategoryTimeframe _selectedTimeframe = CategoryTimeframe.thisMonth;
  CategorySortOption _sortOption = CategorySortOption.date;
  bool _sortAscending = false;

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
    final categoryAsync = ref.watch(categoryByIdProvider(widget.categoryId));

    return categoryAsync.when(
      loading: () => Scaffold(
        appBar: CustomAppBar(
          title: 'categories.loading'.tr(),
        ),
        body: const LoadingWidget(),
      ),
      error: (error, _) => Scaffold(
        appBar: CustomAppBar(
          title: 'categories.error'.tr(),
        ),
        body: CustomErrorWidget(
          message: 'categories.categoryNotFound'.tr(),
          onActionPressed: () => ref.refresh(categoryListProvider),
        ),
      ),
      data: (category) {
        if (category == null) {
          return Scaffold(
            appBar: CustomAppBar(
              title: 'categories.error'.tr(),
            ),
            body: CustomErrorWidget(
              message: 'categories.categoryNotFound'.tr(),
              onActionPressed: () => ref.refresh(categoryListProvider),
            ),
          );
        }

        return Scaffold(
          appBar: CustomAppBar(
            title: category.name,
            actions: [
              IconButton(
                onPressed: () => _showTimeframeSelector(),
                icon: const Icon(Icons.date_range),
                tooltip: 'categories.selectTimeframe'.tr(),
              ),
              PopupMenuButton<String>(
                onSelected: (action) => _handleMenuAction(action, category),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 16),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text('common.edit'.tr()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'addTransaction',
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 16),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text('categories.addTransaction'.tr()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'setBudget',
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance, size: 16),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text('categories.setBudget'.tr()),
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
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 16, color: Colors.red),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text('common.delete'.tr(),
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              _buildCategoryHeader(category),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(category),
                    _buildTransactionsTab(category),
                    _buildAnalyticsTab(category),
                    _buildBudgetTab(category),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(category),
        );
      },
    );
  }

  Widget _buildCategoryHeader(Category category) {
    final categoryStatsAsync =
        ref.watch(categoryStatsProvider(CategoryStatsParams(
      categoryId: widget.categoryId,
      timeframe: _selectedTimeframe,
    )));

    return categoryStatsAsync.when(
      loading: () => Container(
        height: 140,
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        child: const LoadingWidget(),
      ),
      error: (error, _) => Container(
        height: 140,
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        child: CustomErrorWidget(
          message: 'categories.errorLoadingStats'.tr(),
          onActionPressed: () =>
              ref.refresh(categoryStatsProvider(CategoryStatsParams(
            categoryId: widget.categoryId,
            timeframe: _selectedTimeframe,
          ))),
        ),
      ),
      data: (stats) => Container(
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(category.color),
              Color(category.color).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                  child: Icon(
                    _getCategoryIcon(category.iconName),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (category.description!.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text(
                          category.description!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.spacingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingS,
                          vertical: AppDimensions.paddingXs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: Text(
                          _getTypeLabel(category.type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'categories.totalSpent'.tr(),
                    CurrencyFormatter.format(stats.totalAmount),
                    Icons.monetization_on,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'categories.transactions'.tr(),
                    stats.transactionCount.toString(),
                    Icons.receipt_long,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'categories.avgAmount'.tr(),
                    CurrencyFormatter.format(stats.averageAmount),
                    Icons.analytics,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    _getTimeframeLabel(_selectedTimeframe),
                    '${stats.changePercentage.toStringAsFixed(1)}%',
                    stats.changePercentage >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: AppDimensions.spacingXs),
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
        const SizedBox(height: 2),
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
        Tab(text: 'categories.overview'.tr()),
        Tab(text: 'categories.transactions'.tr()),
        Tab(text: 'categories.analytics'.tr()),
        Tab(text: 'categories.budget'.tr()),
      ],
    );
  }

  Widget _buildOverviewTab(Category category) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStatsCard(category),
          const SizedBox(height: AppDimensions.spacingL),
          _buildRecentTransactionsCard(category),
          const SizedBox(height: AppDimensions.spacingL),
          _buildSpendingTrendCard(category),
          const SizedBox(height: AppDimensions.spacingL),
          _buildInsightsCard(category),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(Category category) {
    final transactionsAsync =
        ref.watch(transactionsByCategoryProvider(TransactionsByCategoryParams(
      categoryId: widget.categoryId,
      timeframe: _selectedTimeframe,
      sortOption: _sortOption,
      ascending: _sortAscending,
    )));

    return Column(
      children: [
        _buildTransactionFilters(),
        Expanded(
          child: transactionsAsync.when(
            loading: () => const LoadingWidget(),
            error: (error, _) => CustomErrorWidget(
              message: 'categories.errorLoadingTransactions'.tr(),
              onActionPressed: () => ref.refresh(
                  transactionsByCategoryProvider(TransactionsByCategoryParams(
                categoryId: widget.categoryId,
                timeframe: _selectedTimeframe,
                sortOption: _sortOption,
                ascending: _sortAscending,
              ))),
            ),
            data: (transactions) => transactions.isEmpty
                ? _buildEmptyTransactions()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppDimensions.spacingS),
                        child: TransactionItem(
                          transaction: transaction,
                          onTap: () => _viewTransaction(transaction),
                          showCategory:
                              false, // Since we're already in category view
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab(Category category) {
    final analyticsAsync =
        ref.watch(categoryAnalyticsProvider(CategoryAnalyticsParams(
      categoryId: widget.categoryId,
      timeframe: _selectedTimeframe,
    )));

    return analyticsAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'categories.errorLoadingAnalytics'.tr(),
        onActionPressed: () =>
            ref.refresh(categoryAnalyticsProvider(CategoryAnalyticsParams(
          categoryId: widget.categoryId,
          timeframe: _selectedTimeframe,
        ))),
      ),
      data: (analytics) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSpendingChart(analytics),
            const SizedBox(height: AppDimensions.spacingL),
            _buildFrequencyChart(analytics),
            const SizedBox(height: AppDimensions.spacingL),
            _buildPatternAnalysis(analytics),
            const SizedBox(height: AppDimensions.spacingL),
            _buildComparison(analytics),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetTab(Category category) {
    final budgetAsync = ref.watch(budgetByCategoryProvider(widget.categoryId));

    return budgetAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => _buildNoBudget(category),
      data: (budget) => budget == null
          ? _buildNoBudget(category)
          : _buildBudgetDetails(budget, category),
    );
  }

  Widget _buildQuickStatsCard(Category category) {
    final statsAsync = ref.watch(categoryStatsProvider(CategoryStatsParams(
      categoryId: widget.categoryId,
      timeframe: _selectedTimeframe,
    )));

    return statsAsync.when(
      loading: () => const Card(child: LoadingWidget()),
      error: (error, _) => const Card(child: SizedBox.shrink()),
      data: (stats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'categories.quickStats'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatTile(
                      'categories.thisMonth'.tr(),
                      CurrencyFormatter.format(stats.thisMonthAmount),
                      Icons.calendar_month,
                      AppColors.primary,
                      stats.monthlyChange,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: _buildQuickStatTile(
                      'categories.lastMonth'.tr(),
                      CurrencyFormatter.format(stats.lastMonthAmount),
                      Icons.calendar_today,
                      AppColors.secondary,
                      null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatTile(
                      'categories.highest'.tr(),
                      CurrencyFormatter.format(stats.highestTransaction),
                      Icons.trending_up,
                      AppColors.success,
                      null,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: _buildQuickStatTile(
                      'categories.frequency'.tr(),
                      '${stats.avgTransactionsPerMonth.toStringAsFixed(1)}/mo',
                      Icons.repeat,
                      AppColors.warning,
                      null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatTile(
      String title, String value, IconData icon, Color color, double? change) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              if (change != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: change >= 0 ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsCard(Category category) {
    final recentTransactionsAsync =
        ref.watch(recentTransactionsByCategoryProvider(widget.categoryId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'categories.recentTransactions'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ShadButton.ghost(
                  onPressed: () => _tabController.animateTo(1),
                  size: ShadButtonSize.sm,
                  child: Text('common.viewAll'.tr()),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
            recentTransactionsAsync.when(
              loading: () => const LoadingWidget(),
              error: (error, _) =>
                  Text('categories.errorLoadingTransactions'.tr()),
              data: (transactions) => transactions.isEmpty
                  ? _buildEmptyRecentTransactions()
                  : Column(
                      children: transactions
                          .take(5)
                          .map((transaction) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppDimensions.spacingS),
                                child: TransactionItem(
                                  transaction: transaction,
                                  onTap: () => _viewTransaction(transaction),
                                  showCategory: false,
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTrendCard(Category category) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'categories.spendingTrend'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 200,
              child: const Placeholder(), // Replace with actual line chart
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(Category category) {
    final insightsAsync =
        ref.watch(categoryInsightsProvider(widget.categoryId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'categories.insights'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            insightsAsync.when(
              loading: () => const LoadingWidget(),
              error: (error, _) => Text('categories.errorLoadingInsights'.tr()),
              data: (insights) => Column(
                children: insights
                    .map((insight) => Padding(
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
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionFilters() {
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
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<CategorySortOption>(
              segments: CategorySortOption.values
                  .map(
                    (option) => ButtonSegment<CategorySortOption>(
                      value: option,
                      label: Text(_getSortOptionLabel(option)),
                    ),
                  )
                  .toList(),
              selected: {_sortOption},
              onSelectionChanged: (selection) {
                setState(() {
                  _sortOption = selection.first;
                });
              },
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          IconButton(
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: AppColors.primary,
            ),
            tooltip: _sortAscending
                ? 'common.ascending'.tr()
                : 'common.descending'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            'categories.noTransactions'.tr(),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            'categories.noTransactionsDesc'.tr(),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          ShadButton(
            onPressed: () => _addTransaction(),
            child: Text('categories.addFirstTransaction'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecentTransactions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingL),
        child: Column(
          children: [
            Icon(
              Icons.receipt,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'categories.noRecentTransactions'.tr(),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingChart(CategoryAnalyticsData analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'categories.spendingOverTime'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 250,
              child: const Placeholder(), // Replace with actual chart
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyChart(CategoryAnalyticsData analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'categories.transactionFrequency'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 200,
              child: const Placeholder(), // Replace with actual chart
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternAnalysis(CategoryAnalyticsData analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'categories.patterns'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text('Pattern analysis content placeholder'),
          ],
        ),
      ),
    );
  }

  Widget _buildComparison(CategoryAnalyticsData analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'categories.comparison'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text('Comparison content placeholder'),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBudget(Category category) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'categories.noBudget'.tr(),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'categories.noBudgetDesc'.tr(),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ShadButton(
              onPressed: () => _setBudget(category),
              child: Text('categories.setBudget'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetDetails(Budget budget, Category category) {
    final budgetProgressAsync = ref.watch(budgetProgressProvider(budget.id));

    return budgetProgressAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'categories.errorLoadingBudget'.tr(),
        onActionPressed: () => ref.refresh(budgetProgressProvider(budget.id)),
      ),
      data: (progress) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBudgetOverview(budget, progress),
            const SizedBox(height: AppDimensions.spacingL),
            _buildBudgetChart(budget, progress),
            const SizedBox(height: AppDimensions.spacingL),
            _buildBudgetActions(budget),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOverview(Budget budget, BudgetProgress progress) {
    final percentage = progress.percentageUsed;
    final isOverBudget = percentage > 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'categories.budgetOverview'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingS,
                    vertical: AppDimensions.paddingXs,
                  ),
                  decoration: BoxDecoration(
                    color: isOverBudget ? AppColors.error : AppColors.success,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Text(
                    isOverBudget
                        ? 'categories.overBudget'.tr()
                        : 'categories.onTrack'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'categories.spent'.tr(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(progress.spentAmount),
                        style: TextStyle(
                          color: isOverBudget
                              ? AppColors.error
                              : AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'categories.budget'.tr(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(budget.limit),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'categories.remaining'.tr(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(progress.remainingAmount),
                        style: TextStyle(
                          color: isOverBudget
                              ? AppColors.error
                              : AppColors.success,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
            LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? AppColors.error : AppColors.success,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              '${percentage.toStringAsFixed(1)}% ${'categories.ofBudgetUsed'.tr()}',
              style: TextStyle(
                color: isOverBudget ? AppColors.error : AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetChart(Budget budget, BudgetProgress progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'categories.budgetProgress'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 200,
              child: const Placeholder(), // Replace with actual chart
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetActions(Budget budget) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'categories.budgetActions'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () => _editBudget(budget),
                    child: Text('categories.editBudget'.tr()),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () => _deleteBudget(budget),
                    child: Text('categories.deleteBudget'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(Category category) {
    return FloatingActionButton.extended(
      onPressed: () => _addTransaction(),
      icon: const Icon(Icons.add),
      label: Text('categories.addTransaction'.tr()),
      backgroundColor: Color(category.color),
    );
  }

  // Helper methods
  IconData _getCategoryIcon(String iconName) {
    // Map icon names to actual icons
    switch (iconName) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'utilities':
        return Icons.electrical_services;
      case 'salary':
        return Icons.work;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }

  String _getTypeLabel(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return 'transactions.income'.tr();
      case CategoryType.expense:
        return 'transactions.expense'.tr();
      case CategoryType.both:
        return 'transactions.transfer'.tr();
    }
  }

  String _getTimeframeLabel(CategoryTimeframe timeframe) {
    switch (timeframe) {
      case CategoryTimeframe.thisWeek:
        return 'categories.thisWeek'.tr();
      case CategoryTimeframe.thisMonth:
        return 'categories.thisMonth'.tr();
      case CategoryTimeframe.lastMonth:
        return 'categories.lastMonth'.tr();
      case CategoryTimeframe.thisYear:
        return 'categories.thisYear'.tr();
      case CategoryTimeframe.custom:
        return 'categories.custom'.tr();
    }
  }

  String _getSortOptionLabel(CategorySortOption option) {
    switch (option) {
      case CategorySortOption.date:
        return 'common.date'.tr();
      case CategorySortOption.amount:
        return 'common.amount'.tr();
      case CategorySortOption.description:
        return 'common.description'.tr();
    }
  }

  // Event handlers
  void _showTimeframeSelector() async {
    final selected = await showDialog<CategoryTimeframe>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('categories.selectTimeframe'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: CategoryTimeframe.values
              .map(
                (timeframe) => RadioListTile<CategoryTimeframe>(
                  title: Text(_getTimeframeLabel(timeframe)),
                  value: timeframe,
                  groupValue: _selectedTimeframe,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedTimeframe = selected;
      });
    }
  }

  void _handleMenuAction(String action, Category category) {
    switch (action) {
      case 'edit':
        _editCategory(category);
        break;
      case 'addTransaction':
        _addTransaction();
        break;
      case 'setBudget':
        _setBudget(category);
        break;
      case 'export':
        _exportData();
        break;
      case 'share':
        _shareData();
        break;
      case 'delete':
        _deleteCategory(category);
        break;
    }
  }

  void _editCategory(Category category) {
    context.pushNamed('edit-category', pathParameters: {
      'categoryId': category.id,
    });
  }

  void _addTransaction() {
    context.pushNamed('add-expense', queryParameters: {
      'categoryId': widget.categoryId,
    });
  }

  void _setBudget(Category category) {
    context.pushNamed('add-budget', queryParameters: {
      'categoryId': category.id,
    });
  }

  void _viewTransaction(Transaction transaction) {
    context.pushNamed('transaction-details', pathParameters: {
      'transactionId': transaction.id,
    });
  }

  void _editBudget(Budget budget) {
    context.pushNamed('edit-budget', pathParameters: {
      'budgetId': budget.id,
    });
  }

  void _deleteBudget(Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('categories.deleteBudget'.tr()),
        content: Text('categories.deleteBudgetConfirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete budget logic here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('categories.budgetDeleted'.tr()),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('categories.exportFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _shareData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('categories.shareFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('categories.deleteCategory'.tr()),
        content: Text(
            'categories.deleteCategoryConfirmation'.tr(args: [category.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(categoryListProvider.notifier)
            .deleteCategory(category.id);
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('categories.categoryDeleted'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('categories.errorDeletingCategory'.tr()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// Data models and enums
enum CategoryTimeframe { thisWeek, thisMonth, lastMonth, thisYear, custom }

enum CategorySortOption { date, amount, description }

class CategoryStatsParams {
  final String categoryId;
  final CategoryTimeframe timeframe;

  const CategoryStatsParams({
    required this.categoryId,
    required this.timeframe,
  });
}

class CategoryStatsData {
  final double totalAmount;
  final int transactionCount;
  final double averageAmount;
  final double changePercentage;
  final double thisMonthAmount;
  final double lastMonthAmount;
  final double highestTransaction;
  final double avgTransactionsPerMonth;
  final double monthlyChange;

  const CategoryStatsData({
    required this.totalAmount,
    required this.transactionCount,
    required this.averageAmount,
    required this.changePercentage,
    required this.thisMonthAmount,
    required this.lastMonthAmount,
    required this.highestTransaction,
    required this.avgTransactionsPerMonth,
    required this.monthlyChange,
  });
}

class TransactionsByCategoryParams {
  final String categoryId;
  final CategoryTimeframe timeframe;
  final CategorySortOption sortOption;
  final bool ascending;

  const TransactionsByCategoryParams({
    required this.categoryId,
    required this.timeframe,
    required this.sortOption,
    required this.ascending,
  });
}

class CategoryAnalyticsParams {
  final String categoryId;
  final CategoryTimeframe timeframe;

  const CategoryAnalyticsParams({
    required this.categoryId,
    required this.timeframe,
  });
}

class CategoryAnalyticsData {
  final List<SpendingDataPoint> spendingData;
  final List<FrequencyDataPoint> frequencyData;
  final List<String> patterns;
  final ComparisonData comparison;

  const CategoryAnalyticsData({
    required this.spendingData,
    required this.frequencyData,
    required this.patterns,
    required this.comparison,
  });
}

class SpendingDataPoint {
  final DateTime date;
  final double amount;

  const SpendingDataPoint({
    required this.date,
    required this.amount,
  });
}

class FrequencyDataPoint {
  final String period;
  final int count;

  const FrequencyDataPoint({
    required this.period,
    required this.count,
  });
}

class ComparisonData {
  final double vsLastPeriod;
  final double vsAverage;
  final String trend;

  const ComparisonData({
    required this.vsLastPeriod,
    required this.vsAverage,
    required this.trend,
  });
}

class CategoryInsight {
  final String message;
  final InsightType type;

  const CategoryInsight({
    required this.message,
    required this.type,
  });
}

class BudgetProgress {
  final double spentAmount;
  final double remainingAmount;
  final double percentageUsed;

  const BudgetProgress({
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentageUsed,
  });
}

// Providers
final categoryByIdProvider = Provider.family<AsyncValue<Category?>, String>(
  (ref, categoryId) {
    final categoriesAsync = ref.watch(categoryListProvider);
    return categoriesAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
      data: (categories) {
        try {
          final category = categories.firstWhere(
            (c) => c.id == categoryId,
          );
          return AsyncValue.data(category);
        } catch (e) {
          return AsyncValue.error('Category not found', StackTrace.current);
        }
      },
    );
  },
);

final categoryStatsProvider =
    FutureProvider.family<CategoryStatsData, CategoryStatsParams>(
  (ref, params) async {
    await Future.delayed(const Duration(seconds: 1));
    return const CategoryStatsData(
      totalAmount: 1500.0,
      transactionCount: 25,
      averageAmount: 60.0,
      changePercentage: 15.5,
      thisMonthAmount: 800.0,
      lastMonthAmount: 700.0,
      highestTransaction: 250.0,
      avgTransactionsPerMonth: 20.0,
      monthlyChange: 14.3,
    );
  },
);

final transactionsByCategoryProvider =
    FutureProvider.family<List<Transaction>, TransactionsByCategoryParams>(
  (ref, params) async {
    await Future.delayed(const Duration(seconds: 1));
    return []; // Return filtered transactions
  },
);

final recentTransactionsByCategoryProvider =
    FutureProvider.family<List<Transaction>, String>(
  (ref, categoryId) async {
    await Future.delayed(const Duration(seconds: 1));
    return []; // Return recent transactions
  },
);

final categoryAnalyticsProvider =
    FutureProvider.family<CategoryAnalyticsData, CategoryAnalyticsParams>(
  (ref, params) async {
    await Future.delayed(const Duration(seconds: 1));
    return const CategoryAnalyticsData(
      spendingData: [],
      frequencyData: [],
      patterns: [],
      comparison: ComparisonData(
        vsLastPeriod: 15.0,
        vsAverage: -5.0,
        trend: 'increasing',
      ),
    );
  },
);

final categoryInsightsProvider =
    FutureProvider.family<List<CategoryInsight>, String>(
  (ref, categoryId) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      const CategoryInsight(
        message: 'Your spending in this category increased by 15% this month',
        type: InsightType.warning,
      ),
      const CategoryInsight(
        message: 'You typically spend more on weekends in this category',
        type: InsightType.neutral,
      ),
    ];
  },
);

final budgetByCategoryProvider = FutureProvider.family<Budget?, String>(
  (ref, categoryId) async {
    await Future.delayed(const Duration(seconds: 1));
    return null; // Return budget if exists
  },
);

final budgetProgressProvider = FutureProvider.family<BudgetProgress, String>(
  (ref, budgetId) async {
    await Future.delayed(const Duration(seconds: 1));
    return const BudgetProgress(
      spentAmount: 750.0,
      remainingAmount: 250.0,
      percentageUsed: 75.0,
    );
  },
);
