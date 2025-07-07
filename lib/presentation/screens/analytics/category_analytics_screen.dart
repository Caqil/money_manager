// lib/presentation/screens/analytics/category_analytics_screen.dart
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
import '../../widgets/common/empty_state_widget.dart';
import 'widgets/date_range_selector.dart';

class CategoryAnalyticsScreen extends ConsumerStatefulWidget {
  const CategoryAnalyticsScreen({super.key});

  @override
  ConsumerState<CategoryAnalyticsScreen> createState() =>
      _CategoryAnalyticsScreenState();
}

class _CategoryAnalyticsScreenState
    extends ConsumerState<CategoryAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateRange _selectedDateRange;

  TransactionType _selectedType = TransactionType.expense;
  CategorySortOption _sortOption = CategorySortOption.amount;
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDateRange = DateRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
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
        title: 'analytics.categoryAnalytics'.tr(),
        showBackButton: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('common.filter'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort',
                child: Row(
                  children: [
                    const Icon(Icons.sort, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('common.sort'.tr()),
                  ],
                ),
              ),
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
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with summary
          _buildHeaderSummary(),

          // Date range selector
          _buildDateRangeSelector(),

          // Type selector
          _buildTypeSelector(),

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

  Widget _buildHeaderSummary() {
    final categoryDataAsync = ref
        .watch(categoryAnalyticsProvider((_selectedDateRange, _selectedType)));

    return categoryDataAsync.when(
      loading: () => Container(
        height: 100,
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        child: const LoadingWidget(),
      ),
      error: (error, _) => Container(
        height: 100,
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
              _getTypeColor(_selectedType),
              _getTypeColor(_selectedType).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                _getTypeIcon(_selectedType),
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
                    'analytics.total${_selectedType.name.capitalize()}'.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(data.totalAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'analytics.categoriesCount'
                        .tr(args: [data.categoriesCount.toString()]),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'analytics.avgPerCategory'.tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(data.averagePerCategory),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  Widget _buildTypeSelector() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        children: [
          Text(
            'analytics.transactionType'.tr(),
            style: ShadTheme.of(context).textTheme.h4,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Wrap(
              spacing: AppDimensions.spacingS,
              children:
                  [TransactionType.income, TransactionType.expense].map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTypeIcon(type),
                        size: 16,
                        color: isSelected ? Colors.white : _getTypeColor(type),
                      ),
                      const SizedBox(width: AppDimensions.spacingXs),
                      Text('transactions.${type.name}'.tr()),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = type;
                      });
                    }
                  },
                  selectedColor: _getTypeColor(type),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                  ),
                );
              }).toList(),
            ),
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
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pie_chart, size: 16),
                const SizedBox(width: AppDimensions.spacingXs),
                Text('analytics.breakdown'.tr()),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.list, size: 16),
                const SizedBox(width: AppDimensions.spacingXs),
                Text('analytics.details'.tr()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildBreakdownTab(),
        _buildDetailsTab(),
      ],
    );
  }

  Widget _buildBreakdownTab() {
    final categoryDataAsync = ref
        .watch(categoryAnalyticsProvider((_selectedDateRange, _selectedType)));

    return categoryDataAsync.when(
      loading: () => const Center(child: LoadingWidget()),
      error: (error, _) => Center(
        child: EmptyStateWidget(
          title: 'analytics.errorLoadingData'.tr(),
          message: error.toString(),
          icon: Icon(Icons.error_outline),
        ),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            // Pie Chart
            _buildPieChart(data),

            const SizedBox(height: AppDimensions.spacingL),

            // Top Categories
            _buildTopCategories(data),

            const SizedBox(height: AppDimensions.spacingL),

            // Category Comparison
            _buildCategoryComparison(data),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(CategoryAnalyticsData data) {
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
            'analytics.categoryBreakdown'.tr(),
            style: ShadTheme.of(context).textTheme.h4,
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Placeholder for pie chart
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    'analytics.pieChartComingSoon'.tr(),
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

  Widget _buildTopCategories(CategoryAnalyticsData data) {
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
            'analytics.topCategories'.tr(),
            style: ShadTheme.of(context).textTheme.h4,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ...data.categoryBreakdown.take(5).map((category) {
            final percentage = (category.amount / data.totalAmount * 100);
            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: category.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(category.amount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: ShadTheme.of(context).textTheme.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    valueColor: AlwaysStoppedAnimation<Color>(category.color),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryComparison(CategoryAnalyticsData data) {
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
            'analytics.categoryComparison'.tr(),
            style: ShadTheme.of(context).textTheme.h4,
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Placeholder for comparison chart
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: AppColors.info,
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    'analytics.comparisonChartComingSoon'.tr(),
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

  Widget _buildDetailsTab() {
    final categoryDataAsync = ref
        .watch(categoryAnalyticsProvider((_selectedDateRange, _selectedType)));

    return categoryDataAsync.when(
      loading: () => const Center(child: LoadingWidget()),
      error: (error, _) => Center(
        child: EmptyStateWidget(
          title: 'analytics.errorLoadingData'.tr(),
          message: error.toString(),
          icon: Icon(Icons.error_outline),
        ),
      ),
      data: (data) => Column(
        children: [
          // Sort controls
          _buildSortControls(),

          // Category list
          Expanded(
            child: _buildCategoryList(data),
          ),
        ],
      ),
    );
  }

  Widget _buildSortControls() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
      ),
      child: Row(
        children: [
          Text(
            'common.sortBy'.tr(),
            style: ShadTheme.of(context).textTheme.muted,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Wrap(
              spacing: AppDimensions.spacingS,
              children: CategorySortOption.values.map((option) {
                final isSelected = _sortOption == option;
                return ChoiceChip(
                  label: Text('analytics.${option.name}'.tr()),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _sortOption = option;
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
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _sortDescending = !_sortDescending;
              });
            },
            icon: Icon(
              _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
              color: AppColors.primary,
            ),
            tooltip: _sortDescending
                ? 'common.descending'.tr()
                : 'common.ascending'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(CategoryAnalyticsData data) {
    var sortedCategories =
        List<CategoryBreakdownItem>.from(data.categoryBreakdown);

    // Sort based on selected option
    switch (_sortOption) {
      case CategorySortOption.amount:
        sortedCategories.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case CategorySortOption.name:
        sortedCategories.sort((a, b) => a.name.compareTo(b.name));
        break;
      case CategorySortOption.transactionCount:
        sortedCategories
            .sort((a, b) => a.transactionCount.compareTo(b.transactionCount));
        break;
      case CategorySortOption.percentage:
        sortedCategories.sort((a, b) => (a.amount / data.totalAmount)
            .compareTo(b.amount / data.totalAmount));
        break;
    }

    if (_sortDescending) {
      sortedCategories = sortedCategories.reversed.toList();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final percentage = (category.amount / data.totalAmount * 100);

        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: ShadTheme.of(context).colorScheme.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusS),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'analytics.transactionsCount'
                              .tr(args: [category.transactionCount.toString()]),
                          style: ShadTheme.of(context).textTheme.muted,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(category.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: ShadTheme.of(context).textTheme.muted,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),
              LinearProgressIndicator(
                value: percentage / 100,
                valueColor: AlwaysStoppedAnimation<Color>(category.color),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.success;
      case TransactionType.expense:
        return AppColors.error;
      case TransactionType.transfer:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.trending_up;
      case TransactionType.expense:
        return Icons.trending_down;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'filter':
        _showFilterDialog();
        break;
      case 'sort':
        _showSortDialog();
        break;
      case 'export':
        _exportData();
        break;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('common.filter'.tr()),
        content: Text('analytics.filterFeatureComingSoon'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.gotIt'.tr()),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('common.sort'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: CategorySortOption.values.map((option) {
            return RadioListTile<CategorySortOption>(
              title: Text('analytics.${option.name}'.tr()),
              value: option,
              groupValue: _sortOption,
              onChanged: (value) {
                setState(() {
                  _sortOption = value!;
                });
                Navigator.of(context).pop();
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
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('analytics.exportFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }
}

// Data classes
class CategoryAnalyticsData {
  final double totalAmount;
  final int categoriesCount;
  final double averagePerCategory;
  final List<CategoryBreakdownItem> categoryBreakdown;

  const CategoryAnalyticsData({
    required this.totalAmount,
    required this.categoriesCount,
    required this.averagePerCategory,
    required this.categoryBreakdown,
  });
}

class CategoryBreakdownItem {
  final String id;
  final String name;
  final double amount;
  final int transactionCount;
  final Color color;

  const CategoryBreakdownItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.transactionCount,
    required this.color,
  });
}

enum CategorySortOption {
  amount,
  name,
  transactionCount,
  percentage,
}

// Extension for string capitalization
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

// Provider placeholder
final categoryAnalyticsProvider =
    FutureProvider.family<CategoryAnalyticsData, (DateRange, TransactionType)>(
        (ref, params) async {
  final (dateRange, type) = params;

  // Placeholder implementation
  await Future.delayed(const Duration(seconds: 1));

  final sampleCategories = [
    CategoryBreakdownItem(
      id: '1',
      name: 'Food & Dining',
      amount: 1500.0,
      transactionCount: 25,
      color: AppColors.error,
    ),
    CategoryBreakdownItem(
      id: '2',
      name: 'Transportation',
      amount: 800.0,
      transactionCount: 15,
      color: AppColors.primary,
    ),
    CategoryBreakdownItem(
      id: '3',
      name: 'Entertainment',
      amount: 600.0,
      transactionCount: 12,
      color: AppColors.warning,
    ),
    CategoryBreakdownItem(
      id: '4',
      name: 'Shopping',
      amount: 400.0,
      transactionCount: 8,
      color: AppColors.info,
    ),
    CategoryBreakdownItem(
      id: '5',
      name: 'Bills & Utilities',
      amount: 300.0,
      transactionCount: 6,
      color: AppColors.success,
    ),
  ];

  final totalAmount =
      sampleCategories.fold(0.0, (sum, cat) => sum + cat.amount);

  return CategoryAnalyticsData(
    totalAmount: totalAmount,
    categoriesCount: sampleCategories.length,
    averagePerCategory: totalAmount / sampleCategories.length,
    categoryBreakdown: sampleCategories,
  );
});
