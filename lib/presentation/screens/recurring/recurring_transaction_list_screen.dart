import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/recurring_transaction.dart';
import '../../../data/models/transaction.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/recurring_transaction_item.dart';

// Note: You'll need to create this provider similar to your existing patterns
// For now, I'll use placeholder provider names that should be implemented
class RecurringTransactionListNotifier extends StateNotifier<AsyncValue<List<RecurringTransaction>>> {
  RecurringTransactionListNotifier() : super(const AsyncValue.loading());
  // TODO: Implement actual logic
}

final recurringTransactionListProvider =
    StateNotifierProvider<RecurringTransactionListNotifier, AsyncValue<List<RecurringTransaction>>>(
        (ref) => RecurringTransactionListNotifier());

class RecurringTransactionListScreen extends ConsumerStatefulWidget {
  final TransactionType? filterType;
  final String? accountId;
  final String? categoryId;

  const RecurringTransactionListScreen({
    super.key,
    this.filterType,
    this.accountId,
    this.categoryId,
  });

  @override
  ConsumerState<RecurringTransactionListScreen> createState() =>
      _RecurringTransactionListScreenState();
}

class _RecurringTransactionListScreenState
    extends ConsumerState<RecurringTransactionListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
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
      appBar: CustomAppBar(
        title: 'recurring.title'.tr(),
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: () => context.push('/recurring-transactions/quick'),
            icon: const Icon(Icons.add),
            tooltip: 'recurring.addRecurring'.tr(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(theme),

          // Tab bar
          _buildTabBar(theme),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTab(),
                _buildActiveTab(),
                _buildDueTab(),
                _buildInactiveTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/recurring-transactions/add'),
        child: const Icon(Icons.add),
        tooltip: 'recurring.addRecurring'.tr(),
      ),
    );
  }

  Widget _buildSearchBar(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: ShadInput(
        controller: _searchController,
        placeholder: Text('recurring.searchRecurring'.tr()),
        leading: const Icon(Icons.search, size: 20),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildTabBar(ShadThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.border,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: theme.colorScheme.mutedForeground,
        indicatorColor: AppColors.primary,
        tabs: [
          Tab(text: 'recurring.all'.tr()),
          Tab(text: 'recurring.active'.tr()),
          Tab(text: 'recurring.due'.tr()),
          Tab(text: 'recurring.inactive'.tr()),
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    return _buildRecurringTransactionsList(
      filter: RecurringTransactionFilter.all,
    );
  }

  Widget _buildActiveTab() {
    return _buildRecurringTransactionsList(
      filter: RecurringTransactionFilter.active,
    );
  }

  Widget _buildDueTab() {
    return _buildRecurringTransactionsList(
      filter: RecurringTransactionFilter.due,
    );
  }

  Widget _buildInactiveTab() {
    return _buildRecurringTransactionsList(
      filter: RecurringTransactionFilter.inactive,
    );
  }

  Widget _buildRecurringTransactionsList({
    required RecurringTransactionFilter filter,
  }) {
    // TODO: Replace with actual provider call when implemented
    // final recurringTransactions = ref.watch(recurringTransactionListProvider);

    // For now, return a placeholder that shows the structure
    return _buildPlaceholderList(filter);
  }

  Widget _buildPlaceholderList(RecurringTransactionFilter filter) {
    // This is a placeholder implementation
    // Replace with actual provider integration when ready
    return RefreshIndicator(
      onRefresh: _refreshRecurringTransactions,
      child: CustomScrollView(
        slivers: [
          // Stats cards
          SliverToBoxAdapter(
            child: _buildStatsCards(),
          ),

          // Recurring transactions list
          SliverPadding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            sliver: _buildEmptyState(filter),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'recurring.totalRecurring'.tr(),
              '0', // Placeholder
              AppColors.primary,
              Icons.repeat,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: _buildStatCard(
              'recurring.dueThisWeek'.tr(),
              '0', // Placeholder
              AppColors.warning,
              Icons.schedule,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: _buildStatCard(
              'recurring.monthlyTotal'.tr(),
              '\$0', // Placeholder
              AppColors.success,
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
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
                const Spacer(),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              value,
              style: theme.textTheme.h3.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  Widget _buildEmptyState(RecurringTransactionFilter filter) {
    String title;
    String description;
    IconData icon;

    switch (filter) {
      case RecurringTransactionFilter.all:
        title = 'recurring.noRecurringTransactions'.tr();
        description = 'recurring.createFirstRecurring'.tr();
        icon = Icons.repeat;
        break;
      case RecurringTransactionFilter.active:
        title = 'recurring.noActiveRecurring'.tr();
        description = 'recurring.activateRecurringTransactions'.tr();
        icon = Icons.play_arrow;
        break;
      case RecurringTransactionFilter.due:
        title = 'recurring.noDueRecurring'.tr();
        description = 'recurring.nothingDueToday'.tr();
        icon = Icons.schedule;
        break;
      case RecurringTransactionFilter.inactive:
        title = 'recurring.noInactiveRecurring'.tr();
        description = 'recurring.allRecurringActive'.tr();
        icon = Icons.pause;
        break;
    }

    return SliverToBoxAdapter(
      child: EmptyStateWidget(
        icon: Icon(icon),
        title: title,
        message: description,
        actionText: filter == RecurringTransactionFilter.all
            ? 'recurring.createFirst'.tr()
            : null,
        onActionPressed: filter == RecurringTransactionFilter.all
            ? () => context.push('/recurring-transactions/add')
            : null,
      ),
    );
  }

  Widget _buildRecurringTransactionItem(
      RecurringTransaction recurringTransaction) {
    return RecurringTransactionItem(
      recurringTransaction: recurringTransaction,
      onTap: () => _navigateToDetails(recurringTransaction.id),
      onEdit: () => _navigateToEdit(recurringTransaction.id),
      onDelete: () => _showDeleteConfirmation(recurringTransaction),
      onToggleActive: () =>
          _toggleRecurringTransactionStatus(recurringTransaction),
      onExecuteNow: () => _executeRecurringTransaction(recurringTransaction),
    );
  }

  Future<void> _refreshRecurringTransactions() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implement refresh when provider is ready
      // await ref.read(recurringTransactionListProvider.notifier).refresh();
      await Future.delayed(const Duration(milliseconds: 500)); // Placeholder
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToDetails(String recurringTransactionId) {
    context.push('/recurring-transactions/$recurringTransactionId');
  }

  void _navigateToEdit(String recurringTransactionId) {
    context.push('/recurring-transactions/$recurringTransactionId/edit');
  }

  Future<void> _showDeleteConfirmation(
      RecurringTransaction recurringTransaction) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('recurring.deleteRecurring'.tr()),
        description: Text('recurring.deleteConfirmation'
            .tr(args: [recurringTransaction.name])),
        actions: [
          ShadButton.outline(
            child: Text('common.cancel'.tr()),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: Text('common.delete'.tr()),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRecurringTransaction(recurringTransaction);
    }
  }

  Future<void> _deleteRecurringTransaction(
      RecurringTransaction recurringTransaction) async {
    try {
      // TODO: Implement delete when provider is ready
      // await ref.read(recurringTransactionListProvider.notifier).deleteRecurringTransaction(recurringTransaction.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('recurring.transactionDeleted'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('recurring.deleteError'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleRecurringTransactionStatus(
      RecurringTransaction recurringTransaction) async {
    try {
      // TODO: Implement toggle when provider is ready
      // await ref.read(recurringTransactionListProvider.notifier).toggleRecurringTransactionStatus(recurringTransaction.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(recurringTransaction.isActive
                ? 'recurring.transactionPaused'.tr()
                : 'recurring.transactionResumed'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('recurring.statusUpdateError'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _executeRecurringTransaction(
      RecurringTransaction recurringTransaction) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('recurring.executeNow'.tr()),
        description: Text('recurring.executeNowConfirmation'
            .tr(args: [recurringTransaction.name])),
        actions: [
          ShadButton.outline(
            child: Text('common.cancel'.tr()),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton(
            child: Text('recurring.execute'.tr()),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implement execute when provider is ready
        // await ref.read(recurringTransactionListProvider.notifier).executeRecurringTransaction(recurringTransaction.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('recurring.transactionExecuted'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('recurring.executeError'.tr()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  List<RecurringTransaction> _filterRecurringTransactions(
    List<RecurringTransaction> transactions,
    RecurringTransactionFilter filter,
  ) {
    List<RecurringTransaction> filtered = transactions;

    // Apply filter
    switch (filter) {
      case RecurringTransactionFilter.all:
        break;
      case RecurringTransactionFilter.active:
        filtered = filtered.where((t) => t.isActive).toList();
        break;
      case RecurringTransactionFilter.due:
        final now = DateTime.now();
        filtered = filtered.where((t) {
          return t.isActive &&
              t.nextExecution != null &&
              (t.nextExecution!.isBefore(now) ||
                  t.nextExecution!.isAtSameMomentAs(now));
        }).toList();
        break;
      case RecurringTransactionFilter.inactive:
        filtered = filtered.where((t) => !t.isActive).toList();
        break;
    }

    // Apply type filter
    if (widget.filterType != null) {
      filtered = filtered.where((t) => t.type == widget.filterType).toList();
    }

    // Apply account filter
    if (widget.accountId != null) {
      filtered = filtered
          .where((t) =>
              t.accountId == widget.accountId ||
              t.transferToAccountId == widget.accountId)
          .toList();
    }

    // Apply category filter
    if (widget.categoryId != null) {
      filtered =
          filtered.where((t) => t.categoryId == widget.categoryId).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        final name = t.name.toLowerCase();
        final notes = t.notes?.toLowerCase() ?? '';
        return name.contains(_searchQuery) || notes.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }
}

// Filter types
enum RecurringTransactionFilter {
  all,
  active,
  due,
  inactive,
}

// Statistics widget for dashboard
class RecurringTransactionStatsWidget extends ConsumerWidget {
  final bool compact;
  final VoidCallback? onViewAll;

  const RecurringTransactionStatsWidget({
    super.key,
    this.compact = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    // TODO: Replace with actual provider call when implemented
    // final recurringTransactions = ref.watch(recurringTransactionListProvider);

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    'recurring.recurringTransactions'.tr(),
                    style: theme.textTheme.h4.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (onViewAll != null)
                  ShadButton.outline(
                    onPressed: onViewAll,
                    child: Text('common.viewAll'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // Placeholder stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'recurring.active'.tr(),
                    '0', // Placeholder
                    AppColors.success,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'recurring.due'.tr(),
                    '0', // Placeholder
                    AppColors.warning,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'recurring.total'.tr(),
                    '0', // Placeholder
                    AppColors.primary,
                    theme,
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
      String label, String value, Color color, ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.small.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
