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
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import 'widgets/budget_progress_card.dart';
import 'widgets/budget_alert_widget.dart';

class BudgetDetailScreen extends ConsumerStatefulWidget {
  final String budgetId;

  const BudgetDetailScreen({
    super.key,
    required this.budgetId,
  });

  @override
  ConsumerState<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends ConsumerState<BudgetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final budgetAsync = ref.watch(budgetProvider(widget.budgetId));

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: budgetAsync.when(
        loading: () => const Center(
            child: ShimmerLoading(
          child: SizedBox(),
        )),
        error: (error, stack) => Center(
          child: CustomErrorWidget(
            title: 'budgets.loadError'.tr(),
            message: error.toString(),
            onActionPressed: () => ref.refresh(budgetProvider(widget.budgetId)),
          ),
        ),
        data: (budget) {
          if (budget == null) {
            return Center(
              child: CustomErrorWidget(
                title: 'budgets.budgetNotFound'.tr(),
                message: 'budgets.budgetNotFoundMessage'.tr(),
                onActionPressed: () => context.pop(),
                actionText: 'common.goBack'.tr(),
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context, budget),

                // Tab Bar
                _buildTabBar(context),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(budget),
                      _buildTransactionsTab(budget),
                      _buildAnalyticsTab(budget),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Budget budget) {
    final theme = ShadTheme.of(context);
    final categoryAsync = ref.watch(categoryProvider(budget.categoryId));

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
          // Top row with back button and actions
          Row(
            children: [
              ShadButton.ghost(
                onPressed: () => context.pop(),
                size: ShadButtonSize.sm,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: AppDimensions.iconS,
                  ),
                ),
              ),
              const Spacer(),
              ShadButton.ghost(
                onPressed: () => context.push('/budgets/${budget.id}/edit'),
                size: ShadButtonSize.sm,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: AppDimensions.iconS,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              ShadButton.ghost(
                onPressed: () => _showMoreOptions(context, budget),
                size: ShadButtonSize.sm,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: AppDimensions.iconS,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Budget info
          Row(
            children: [
              // Category icon
              categoryAsync.when(
                data: (category) {
                  final color =
                      category != null ? Color(category.color) : Colors.white;
                  return Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusL),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getCategoryIcon(category?.iconName),
                      color: Colors.white,
                      size: AppDimensions.iconXl,
                    ),
                  );
                },
                loading: () => Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                  child: const Icon(Icons.category, color: Colors.white),
                ),
                error: (_, __) => Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                  child: const Icon(Icons.category, color: Colors.white),
                ),
              ),

              const SizedBox(width: AppDimensions.spacingL),

              // Budget details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: theme.textTheme.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    categoryAsync.when(
                      data: (category) => Text(
                        category?.name ?? 'budgets.unknownCategory'.tr(),
                        style: theme.textTheme.p.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Row(
                      children: [
                        _buildHeaderChip(
                          context,
                          _getPeriodLabel(budget.period),
                          Icons.schedule,
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        _buildHeaderChip(
                          context,
                          CurrencyFormatter.format(budget.limit),
                          Icons.account_balance_wallet,
                        ),
                        if (!budget.isActive) ...[
                          const SizedBox(width: AppDimensions.spacingS),
                          _buildHeaderChip(
                            context,
                            'budgets.inactive'.tr(),
                            Icons.pause,
                            color: AppColors.warning,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(
    BuildContext context,
    String text,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXs,
      ),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: (color ?? Colors.white).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.marginM),
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
          Tab(text: 'budgets.overview'.tr()),
          Tab(text: 'budgets.transactions'.tr()),
          Tab(text: 'budgets.analytics'.tr()),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Budget budget) {
    final budgetPerformanceAsync = ref.watch(budgetPerformanceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          // Budget alerts
          budgetPerformanceAsync.when(
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

              return BudgetAlertWidget(
                budget: budget,
                spentAmount: performance.spentAmount,
                showActions: false,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Progress card
          BudgetProgressCard(
            budget: budget,
            showChart: true,
            showInsights: true,
            showComparison: false,
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Budget details
          _buildBudgetDetailsCard(budget),

          const SizedBox(height: AppDimensions.spacingL),

          // Quick actions
          _buildQuickActionsCard(budget),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(Budget budget) {
    final transactionsAsync =
        ref.watch(transactionsByCategoryProvider(budget.categoryId));

    return transactionsAsync.when(
      loading: () => const Center(
          child: ShimmerLoading(
        child: SizedBox(),
      )),
      error: (error, stack) => Center(
        child: CustomErrorWidget(
          title: 'transactions.loadError'.tr(),
          message: error.toString(),
          onActionPressed: () =>
              ref.refresh(transactionsByCategoryProvider(budget.categoryId)),
        ),
      ),
      data: (transactions) {
        // Filter transactions by budget period
        final filteredTransactions = transactions.where((transaction) {
          return transaction.date.isAfter(
                  budget.startDate.subtract(const Duration(days: 1))) &&
              (budget.endDate == null ||
                  transaction.date
                      .isBefore(budget.endDate!.add(const Duration(days: 1))));
        }).toList();

        if (filteredTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: ShadTheme.of(context)
                      .colorScheme
                      .mutedForeground
                      .withOpacity(0.5),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  'budgets.noTransactions'.tr(),
                  style: ShadTheme.of(context).textTheme.p.copyWith(
                        color:
                            ShadTheme.of(context).colorScheme.mutedForeground,
                      ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  'budgets.noTransactionsHint'.tr(),
                  style: ShadTheme.of(context).textTheme.small.copyWith(
                        color:
                            ShadTheme.of(context).colorScheme.mutedForeground,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          itemCount: filteredTransactions.length,
          itemBuilder: (context, index) {
            final transaction = filteredTransactions[index];
            // return TransactionItem(
            //   transaction: transaction,
            //   onTap: () => context.push('/transactions/${transaction.id}'),
            // );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab(Budget budget) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          // Detailed progress card
          BudgetProgressCard(
            budget: budget,
            showChart: true,
            showInsights: true,
            showComparison: true,
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Spending trends
          _buildSpendingTrendsCard(budget),

          const SizedBox(height: AppDimensions.spacingL),

          // Historical performance
          _buildHistoricalPerformanceCard(budget),
        ],
      ),
    );
  }

  Widget _buildBudgetDetailsCard(Budget budget) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'budgets.budgetDetails'.tr(),
              style: theme.textTheme.h4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            _buildDetailRow(
                'budgets.period'.tr(), _getPeriodLabel(budget.period)),
            _buildDetailRow('budgets.startDate'.tr(),
                DateFormat.yMMMd().format(budget.startDate)),
            if (budget.endDate != null)
              _buildDetailRow('budgets.endDate'.tr(),
                  DateFormat.yMMMd().format(budget.endDate!)),
            _buildDetailRow('budgets.alertThreshold'.tr(),
                '${(budget.alertThreshold * 100).toInt()}%'),
            _buildDetailRow('budgets.rolloverType'.tr(),
                _getRolloverTypeLabel(budget.rolloverType)),
            if (budget.description != null && budget.description!.isNotEmpty)
              _buildDetailRow('budgets.description'.tr(), budget.description!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(Budget budget) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'budgets.quickActions'.tr(),
              style: theme.textTheme.h4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () => context.push(
                        '/transactions/add?categoryId=${budget.categoryId}'),
                    size: ShadButtonSize.lg,
                    child: Column(
                      children: [
                        Icon(Icons.add, size: AppDimensions.iconM),
                        const SizedBox(height: AppDimensions.spacingS),
                        Text('budgets.addExpense'.tr()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () => context.push('/budgets/${budget.id}/edit'),
                    size: ShadButtonSize.lg,
                    child: Column(
                      children: [
                        Icon(Icons.edit, size: AppDimensions.iconM),
                        const SizedBox(height: AppDimensions.spacingS),
                        Text('budgets.editBudget'.tr()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTrendsCard(Budget budget) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'budgets.spendingTrends'.tr(),
              style: theme.textTheme.h4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'budgets.spendingTrendsPlaceholder'.tr(),
              style: theme.textTheme.p.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalPerformanceCard(Budget budget) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'budgets.historicalPerformance'.tr(),
              style: theme.textTheme.h4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'budgets.historicalPerformancePlaceholder'.tr(),
              style: theme.textTheme.p.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, Budget budget) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                budget.isActive ? Icons.pause : Icons.play_arrow,
                color: AppColors.warning,
              ),
              title: Text(budget.isActive
                  ? 'budgets.deactivate'.tr()
                  : 'budgets.activate'.tr()),
              onTap: () {
                Navigator.of(context).pop();
                _toggleBudgetStatus(budget);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.copy,
                color: AppColors.info,
              ),
              title: Text('budgets.duplicate'.tr()),
              onTap: () {
                Navigator.of(context).pop();
                _duplicateBudget(budget);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: AppColors.error,
              ),
              title: Text('budgets.delete'.tr()),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation(budget);
              },
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

  void _duplicateBudget(Budget budget) {
    final duplicatedBudget = budget.copyWith(
      id: '',
      name: '${budget.name} ${'common.copy'.tr()}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.push('/budgets/add', extra: duplicatedBudget);
  }

  void _showDeleteConfirmation(Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('budgets.deleteBudget'.tr()),
        content: Text('budgets.deleteConfirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteBudget(budget);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _deleteBudget(Budget budget) async {
    final budgetNotifier = ref.read(budgetListProvider.notifier);
    final success = await budgetNotifier.deleteBudget(budget.id);

    if (success) {
      context.pop();
    }
  }

  String _getPeriodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'budgets.periods.weekly'.tr();
      case BudgetPeriod.monthly:
        return 'budgets.periods.monthly'.tr();
      case BudgetPeriod.quarterly:
        return 'budgets.periods.quarterly'.tr();
      case BudgetPeriod.yearly:
        return 'budgets.periods.yearly'.tr();
      case BudgetPeriod.custom:
        return 'budgets.periods.custom'.tr();
    }
  }

  String _getRolloverTypeLabel(BudgetRolloverType type) {
    switch (type) {
      case BudgetRolloverType.reset:
        return 'budgets.rollover.reset'.tr();
      case BudgetRolloverType.rollover:
        return 'budgets.rollover.rollover'.tr();
      case BudgetRolloverType.accumulate:
        return 'budgets.rollover.accumulate'.tr();
    }
  }

  IconData _getCategoryIcon(String? iconName) {
    if (iconName == null) return Icons.category;

    switch (iconName.toLowerCase()) {
      case 'food':
      case 'restaurant':
        return Icons.restaurant;
      case 'transport':
      case 'car':
        return Icons.directions_car;
      case 'shopping':
      case 'shop':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'health':
      case 'medical':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'utilities':
        return Icons.electrical_services;
      case 'home':
      case 'house':
        return Icons.home;
      default:
        return Icons.category;
    }
  }
}
