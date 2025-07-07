import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/budget.dart';
import '../../providers/budget_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import 'widgets/budget_item.dart';
import 'widgets/budget_alert_widget.dart';

class BudgetListScreen extends ConsumerStatefulWidget {
  const BudgetListScreen({super.key});

  @override
  ConsumerState<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends ConsumerState<BudgetListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BudgetSortOption _sortOption = BudgetSortOption.newest;
  BudgetFilterOption _filterOption = BudgetFilterOption.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

            // Search and filters
            _buildSearchAndFilters(context),

            // Tab Bar
            _buildTabBar(context),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllBudgetsTab(),
                  _buildActiveBudgetsTab(),
                  _buildAlertsTab(),
                  _buildInactiveBudgetsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/budgets/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
      child: Column(
        children: [
          // Top row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
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
                      'budgets.title'.tr(),
                      style: theme.textTheme.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'budgets.subtitle'.tr(),
                      style: theme.textTheme.p.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              ShadButton.ghost(
                onPressed: () => _showSortOptions(context),
                size: ShadButtonSize.sm,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    Icons.sort,
                    color: Colors.white,
                    size: AppDimensions.iconS,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Budget summary
          _buildBudgetSummary(),
        ],
      ),
    );
  }

  Widget _buildBudgetSummary() {
    final budgetPerformanceAsync = ref.watch(budgetPerformanceProvider);

    return budgetPerformanceAsync.when(
      loading: () => ShimmerLoading(
        child: SizedBox(),
      ),
      error: (error, stack) => const SizedBox.shrink(),
      data: (performances) {
        final totalBudget =
            performances.fold<double>(0.0, (sum, p) => sum + p.budget.limit);
        final totalSpent =
            performances.fold<double>(0.0, (sum, p) => sum + p.spentAmount);
        final totalRemaining =
            performances.fold<double>(0.0, (sum, p) => sum + p.remainingAmount);
        final averageUsage = performances.isNotEmpty
            ? performances.fold<double>(
                    0.0, (sum, p) => sum + p.percentageUsed) /
                performances.length
            : 0.0;

        return Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'budgets.totalBudget'.tr(),
                CurrencyFormatter.format(totalBudget),
                Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: _buildSummaryItem(
                'budgets.totalSpent'.tr(),
                CurrencyFormatter.format(totalSpent),
                Icons.trending_down,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: _buildSummaryItem(
                'budgets.avgUsage'.tr(),
                '${(averageUsage * 100).toStringAsFixed(0)}%',
                Icons.pie_chart,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: AppDimensions.iconM,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            value,
            style: theme.textTheme.p.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            label,
            style: theme.textTheme.small.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'budgets.searchBudgets'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          ShadButton.outline(
            onPressed: () => _showFilterOptions(context),
            size: ShadButtonSize.sm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_list, size: AppDimensions.iconS),
                const SizedBox(width: AppDimensions.spacingXs),
                Text('common.filter'.tr()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final budgetsAsync = ref.watch(budgetListProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.marginM),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: budgetsAsync.when(
        data: (budgets) {
          final activeBudgets = budgets.where((b) => b.isActive).length;
          final inactiveBudgets = budgets.where((b) => !b.isActive).length;

          return TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            labelColor: Colors.white,
            unselectedLabelColor:
                ShadTheme.of(context).colorScheme.mutedForeground,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            tabs: [
              Tab(text: 'budgets.all'.tr() + ' (${budgets.length})'),
              Tab(text: 'budgets.active'.tr() + ' ($activeBudgets)'),
              Tab(text: 'budgets.alerts'.tr()),
              Tab(text: 'budgets.inactive'.tr() + ' ($inactiveBudgets)'),
            ],
          );
        },
        loading: () => TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'budgets.all'.tr()),
            Tab(text: 'budgets.active'.tr()),
            Tab(text: 'budgets.alerts'.tr()),
            Tab(text: 'budgets.inactive'.tr()),
          ],
        ),
        error: (_, __) => TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'budgets.all'.tr()),
            Tab(text: 'budgets.active'.tr()),
            Tab(text: 'budgets.alerts'.tr()),
            Tab(text: 'budgets.inactive'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildAllBudgetsTab() {
    final budgetsAsync = ref.watch(budgetListProvider);

    return budgetsAsync.when(
      loading: () => const Center(child: ShimmerLoading(child: SizedBox())),
      error: (error, stack) => Center(
        child: CustomErrorWidget(
          title: 'budgets.loadError'.tr(),
          message: error.toString(),
          onActionPressed: () => ref.refresh(budgetListProvider),
        ),
      ),
      data: (budgets) {
        final filteredBudgets = _filterAndSortBudgets(budgets);

        if (filteredBudgets.isEmpty) {
          return _buildEmptyState(
            'budgets.noBudgets'.tr(),
            'budgets.createFirstBudget'.tr(),
            Icons.account_balance_wallet_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(budgetListProvider);
            ref.refresh(budgetPerformanceProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: filteredBudgets.length,
            itemBuilder: (context, index) {
              final budget = filteredBudgets[index];
              return _buildBudgetItemWithPerformance(budget);
            },
          ),
        );
      },
    );
  }

  Widget _buildActiveBudgetsTab() {
    final activeBudgetsAsync = ref.watch(activeBudgetsProvider);

    return activeBudgetsAsync.when(
      loading: () => const Center(
          child: ShimmerLoading(
        child: SizedBox(),
      )),
      error: (error, stack) => Center(
        child: CustomErrorWidget(
          title: 'budgets.loadError'.tr(),
          message: error.toString(),
          onActionPressed: () => ref.refresh(activeBudgetsProvider),
        ),
      ),
      data: (budgets) {
        final filteredBudgets = _filterAndSortBudgets(budgets);

        if (filteredBudgets.isEmpty) {
          return _buildEmptyState(
            'budgets.noActiveBudgets'.tr(),
            'budgets.activateOrCreateBudget'.tr(),
            Icons.play_circle_outline,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(activeBudgetsProvider);
            ref.refresh(budgetPerformanceProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: filteredBudgets.length,
            itemBuilder: (context, index) {
              final budget = filteredBudgets[index];
              return _buildBudgetItemWithPerformance(budget);
            },
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    final budgetAlertsAsync = ref.watch(budgetAlertsProvider);

    return budgetAlertsAsync.when(
      loading: () => const Center(child: ShimmerLoading(child: SizedBox())),
      error: (error, stack) => Center(
        child: CustomErrorWidget(
          title: 'budgets.alertsLoadError'.tr(),
          message: error.toString(),
          onActionPressed: () => ref.refresh(budgetAlertsProvider),
        ),
      ),
      data: (alerts) {
        if (alerts.isEmpty) {
          return _buildEmptyState(
            'budgets.noAlerts'.tr(),
            'budgets.noAlertsMessage'.tr(),
            Icons.notifications_off_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(budgetAlertsProvider);
            ref.refresh(budgetPerformanceProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return BudgetAlertWidget(
                budget: alert.budget,
                spentAmount: alert.spentAmount,
                showActions: true,
                onViewDetails: () =>
                    context.push('/budgets/${alert.budget.id}'),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInactiveBudgetsTab() {
    final budgetsAsync = ref.watch(budgetListProvider);

    return budgetsAsync.when(
      loading: () => const Center(child: ShimmerLoading(child: SizedBox())),
      error: (error, stack) => Center(
        child: CustomErrorWidget(
          title: 'budgets.loadError'.tr(),
          message: error.toString(),
          onActionPressed: () => ref.refresh(budgetListProvider),
        ),
      ),
      data: (budgets) {
        final inactiveBudgets = budgets.where((b) => !b.isActive).toList();
        final filteredBudgets = _filterAndSortBudgets(inactiveBudgets);

        if (filteredBudgets.isEmpty) {
          return _buildEmptyState(
            'budgets.noInactiveBudgets'.tr(),
            'budgets.allBudgetsActive'.tr(),
            Icons.check_circle_outline,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(budgetListProvider);
            ref.refresh(budgetPerformanceProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: filteredBudgets.length,
            itemBuilder: (context, index) {
              final budget = filteredBudgets[index];
              return _buildBudgetItemWithPerformance(budget);
            },
          ),
        );
      },
    );
  }

  Widget _buildBudgetItemWithPerformance(Budget budget) {
    final budgetPerformanceAsync = ref.watch(budgetPerformanceProvider);

    return budgetPerformanceAsync.when(
      data: (performances) {
        final performance = performances.firstWhere(
          (p) => p.budget.id == budget.id,
          orElse: () => BudgetPerformance(
            budget: budget,
            spentAmount: 0.0,
            remainingAmount: budget.limit,
            percentageUsed: 0.0,
            isOverBudget: false,
          ),
        );

        return BudgetItem(
          budget: budget,
          spentAmount: performance.spentAmount,
          onTap: () => context.push('/budgets/${budget.id}'),
          onEdit: () => context.push('/budgets/${budget.id}/edit'),
          onDelete: () => _deleteBudget(budget),
          onToggleActive: () => _toggleBudgetStatus(budget),
        );
      },
      loading: () => BudgetItem(
        budget: budget,
        spentAmount: 0.0,
        onTap: () => context.push('/budgets/${budget.id}'),
        showProgress: false,
      ),
      error: (_, __) => BudgetItem(
        budget: budget,
        spentAmount: 0.0,
        onTap: () => context.push('/budgets/${budget.id}'),
        showProgress: false,
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    final theme = ShadTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.mutedForeground.withOpacity(0.5),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              title,
              style: theme.textTheme.h3.copyWith(
                color: theme.colorScheme.mutedForeground,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              subtitle,
              style: theme.textTheme.p.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingXl),
            ShadButton(
              onPressed: () => context.push('/budgets/add'),
              size: ShadButtonSize.lg,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text('budgets.createBudget'.tr()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Budget> _filterAndSortBudgets(List<Budget> budgets) {
    var filtered = budgets.where((budget) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!budget.name.toLowerCase().contains(query) &&
            !(budget.description?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Period filter
      switch (_filterOption) {
        case BudgetFilterOption.all:
          return true;
        case BudgetFilterOption.weekly:
          return budget.period == BudgetPeriod.weekly;
        case BudgetFilterOption.monthly:
          return budget.period == BudgetPeriod.monthly;
        case BudgetFilterOption.yearly:
          return budget.period == BudgetPeriod.yearly;
        case BudgetFilterOption.custom:
          return budget.period == BudgetPeriod.custom;
      }
    }).toList();

    // Sort
    switch (_sortOption) {
      case BudgetSortOption.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case BudgetSortOption.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case BudgetSortOption.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case BudgetSortOption.amount:
        filtered.sort((a, b) => b.limit.compareTo(a.limit));
        break;
      case BudgetSortOption.period:
        filtered.sort((a, b) => a.period.index.compareTo(b.period.index));
        break;
    }

    return filtered;
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'common.sortBy'.tr(),
              style: ShadTheme.of(context).textTheme.h4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ...BudgetSortOption.values.map(
              (option) => ListTile(
                title: Text(_getSortOptionLabel(option)),
                leading: Radio<BudgetSortOption>(
                  value: option,
                  groupValue: _sortOption,
                  onChanged: (value) {
                    setState(() => _sortOption = value!);
                    Navigator.of(context).pop();
                  },
                ),
                onTap: () {
                  setState(() => _sortOption = option);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'common.filterBy'.tr(),
              style: ShadTheme.of(context).textTheme.h4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ...BudgetFilterOption.values.map(
              (option) => ListTile(
                title: Text(_getFilterOptionLabel(option)),
                leading: Radio<BudgetFilterOption>(
                  value: option,
                  groupValue: _filterOption,
                  onChanged: (value) {
                    setState(() => _filterOption = value!);
                    Navigator.of(context).pop();
                  },
                ),
                onTap: () {
                  setState(() => _filterOption = option);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleBudgetStatus(Budget budget) async {
    final budgetNotifier = ref.read(budgetListProvider.notifier);
    await budgetNotifier.toggleBudgetStatus(budget.id, !budget.isActive);
  }

  void _deleteBudget(Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('budgets.deleteBudget'.tr()),
        content: Text('budgets.deleteConfirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final budgetNotifier = ref.read(budgetListProvider.notifier);
      await budgetNotifier.deleteBudget(budget.id);
    }
  }

  String _getSortOptionLabel(BudgetSortOption option) {
    switch (option) {
      case BudgetSortOption.newest:
        return 'common.sortNewest'.tr();
      case BudgetSortOption.oldest:
        return 'common.sortOldest'.tr();
      case BudgetSortOption.name:
        return 'common.sortName'.tr();
      case BudgetSortOption.amount:
        return 'common.sortAmount'.tr();
      case BudgetSortOption.period:
        return 'common.sortPeriod'.tr();
    }
  }

  String _getFilterOptionLabel(BudgetFilterOption option) {
    switch (option) {
      case BudgetFilterOption.all:
        return 'common.all'.tr();
      case BudgetFilterOption.weekly:
        return 'budgets.periods.weekly'.tr();
      case BudgetFilterOption.monthly:
        return 'budgets.periods.monthly'.tr();
      case BudgetFilterOption.yearly:
        return 'budgets.periods.yearly'.tr();
      case BudgetFilterOption.custom:
        return 'budgets.periods.custom'.tr();
    }
  }
}

enum BudgetSortOption {
  newest,
  oldest,
  name,
  amount,
  period,
}

enum BudgetFilterOption {
  all,
  weekly,
  monthly,
  yearly,
  custom,
}
