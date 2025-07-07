import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/transaction_item.dart';
import 'widgets/transaction_filters.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  final TransactionType? filterType;
  final String? accountId;
  final String? categoryId;

  const TransactionListScreen({
    super.key,
    this.filterType,
    this.accountId,
    this.categoryId,
  });

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen>
    with TickerProviderStateMixin {
  late TabController? _tabController;
  bool _showFilters = false;
  bool _isSelectionMode = false;
  Set<String> _selectedTransactions = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Initialize filters based on parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.filterType != null) {
        ref.read(transactionTypeFilterProvider.notifier).state =
            widget.filterType;
      }
      if (widget.accountId != null) {
        ref.read(transactionAccountFilterProvider.notifier).state =
            widget.accountId;
      }
      if (widget.categoryId != null) {
        ref.read(transactionCategoryFilterProvider.notifier).state =
            widget.categoryId;
      }
    });

    // Set up tab controller only if no specific filter is applied
    if (widget.filterType == null &&
        widget.accountId == null &&
        widget.categoryId == null) {
      _tabController = TabController(length: 4, vsync: this);
      _tabController!.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController?.indexIsChanging == true) {
      switch (_tabController!.index) {
        case 0:
          ref.read(transactionTypeFilterProvider.notifier).state = null;
          break;
        case 1:
          ref.read(transactionTypeFilterProvider.notifier).state =
              TransactionType.income;
          break;
        case 2:
          ref.read(transactionTypeFilterProvider.notifier).state =
              TransactionType.expense;
          break;
        case 3:
          ref.read(transactionTypeFilterProvider.notifier).state =
              TransactionType.transfer;
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: _isSelectionMode
            ? 'transactions.selectedCount'.tr(
                namedArgs: {'count': _selectedTransactions.length.toString()},
              )
            : 'transactions.transactions'.tr(),
        showBackButton: false,
        actions: [
          if (_isSelectionMode) ...[
            // Selection mode actions
            if (_selectedTransactions.isNotEmpty) ...[
              IconButton(
                onPressed: _bulkDeleteTransactions,
                icon: const Icon(Icons.delete),
                tooltip: 'common.delete'.tr(),
              ),
              IconButton(
                onPressed: _bulkExportTransactions,
                icon: const Icon(Icons.file_download),
                tooltip: 'common.export'.tr(),
              ),
            ],
            IconButton(
              onPressed: _exitSelectionMode,
              icon: const Icon(Icons.close),
              tooltip: 'common.cancel'.tr(),
            ),
          ] else ...[
            // Normal mode actions
            IconButton(
              onPressed: _showSearchDialog,
              icon: const Icon(Icons.search),
              tooltip: 'common.search'.tr(),
            ),
            IconButton(
              onPressed: _toggleFilters,
              icon: Stack(
                children: [
                  const Icon(Icons.filter_list),
                  if (_hasActiveFilters())
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'transactions.filters.all'.tr(),
            ),
            ShadPopover(
              popover: (context) => _buildMoreActionsMenu(),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
                //tooltip: 'common.moreActions'.tr(),
              ),
            ),
          ],
        ],
        bottom: _tabController != null
            ? TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.all_inbox),
                    text: 'transactions.all'.tr(),
                  ),
                  Tab(
                    icon: Icon(Icons.arrow_upward, color: AppColors.income),
                    text: 'transactions.income'.tr(),
                  ),
                  Tab(
                    icon: Icon(Icons.arrow_downward, color: AppColors.expense),
                    text: 'transactions.expense'.tr(),
                  ),
                  Tab(
                    icon: Icon(Icons.swap_horiz, color: AppColors.transfer),
                    text: 'transactions.transfer'.tr(),
                  ),
                ],
              )
            : null,
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: _navigateToAddTransaction,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: Column(
        children: [
          // Filters section
          if (_showFilters) ...[
            TransactionFilters(
              onFiltersChanged: () {
                // Filters changed, refresh the UI
                setState(() {});
              },
            ),
            const SizedBox(height: AppDimensions.spacingS),
          ],

          // Transactions list
          Expanded(
            child: _tabController != null
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionList(),
                      _buildTransactionList(),
                      _buildTransactionList(),
                      _buildTransactionList(),
                    ],
                  )
                : _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreActionsMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.select_all, size: 18),
          title: Text('transactions.selectMode'.tr()),
          onTap: () {
            Navigator.of(context).pop();
            _enterSelectionMode();
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_download, size: 18),
          title: Text('transactions.exportAll'.tr()),
          onTap: () {
            Navigator.of(context).pop();
            _exportAllTransactions();
          },
        ),
        ListTile(
          leading: const Icon(Icons.refresh, size: 18),
          title: Text('common.refresh'.tr()),
          onTap: () {
            Navigator.of(context).pop();
            ref.invalidate(transactionListProvider);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);

    return transactionsAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(error),
      data: (transactions) => _buildTransactionContent(transactions),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: ShimmerLoading(
        child: Column(
          children: [
            SizedBox(height: AppDimensions.spacingL),
            SkeletonLoader(height: 80, width: double.infinity),
            SizedBox(height: AppDimensions.spacingM),
            SkeletonLoader(height: 80, width: double.infinity),
            SizedBox(height: AppDimensions.spacingM),
            SkeletonLoader(height: 80, width: double.infinity),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: CustomErrorWidget(
        title: 'errors.loadingTransactions'.tr(),
        message: error.toString(),
        actionText: 'common.retry'.tr(),
        onActionPressed: () => ref.invalidate(transactionListProvider),
      ),
    );
  }

  Widget _buildTransactionContent(List<Transaction> transactions) {
    // Filter by search query if applicable
    final filteredTransactions = _searchQuery.isEmpty
        ? transactions
        : transactions.where((transaction) {
            final query = _searchQuery.toLowerCase();
            return transaction.notes?.toLowerCase().contains(query) == true ||
                transaction.amount.toString().contains(query);
          }).toList();

    if (filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }

    // Group transactions by date
    final groupedTransactions = _groupTransactionsByDate(filteredTransactions);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(transactionListProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        itemCount: groupedTransactions.length,
        itemBuilder: (context, index) {
          final group = groupedTransactions[index];
          return _buildDateGroup(group);
        },
      ),
    );
  }

  Widget _buildDateGroup(TransactionDateGroup group) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingS,
            vertical: AppDimensions.paddingS,
          ),
          child: Row(
            children: [
              Text(
                group.dateLabel,
                style: theme.textTheme.h4.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                _formatGroupTotal(group.totalAmount),
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Transactions
        ...group.transactions.map((transaction) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
              child: TransactionItem(
                transaction: transaction,
                onTap: () => _handleTransactionTap(transaction),
                onEdit: () => _editTransaction(transaction),
                onDelete: () => _showDeleteConfirmation(transaction),
                onDuplicate: () => _duplicateTransaction(transaction),
                isSelectable: _isSelectionMode,
                isSelected: _selectedTransactions.contains(transaction.id),
              ),
            )),

        const SizedBox(height: AppDimensions.spacingM),
      ],
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return SearchEmptyState(
        searchQuery: _searchQuery,
        onClearSearch: () {
          setState(() {
            _searchQuery = '';
          });
          ref.read(transactionSearchQueryProvider.notifier).state = '';
        },
      );
    }

    if (_hasActiveFilters()) {
      return EmptyStateWidget(
        iconData: Icons.filter_list_off,
        title: 'transactions.noFilteredTransactions'.tr(),
        message: 'transactions.tryDifferentFilters'.tr(),
        actionText: 'transactions.clearFilters'.tr(),
        onActionPressed: _clearAllFilters,
      );
    }

    return EmptyStateWidget(
      iconData: Icons.receipt_long_outlined,
      title: 'transactions.noTransactions'.tr(),
      message: 'transactions.createFirstTransaction'.tr(),
      actionText: 'transactions.addTransaction'.tr(),
      onActionPressed: _navigateToAddTransaction,
    );
  }

  List<TransactionDateGroup> _groupTransactionsByDate(
      List<Transaction> transactions) {
    final groups = <String, List<Transaction>>{};
    final now = DateTime.now();

    for (final transaction in transactions) {
      final dateKey = _getDateGroupKey(transaction.date, now);
      groups[dateKey] ??= [];
      groups[dateKey]!.add(transaction);
    }

    return groups.entries.map((entry) {
      final totalAmount = entry.value.fold<double>(
        0.0,
        (sum, transaction) => sum + transaction.amount,
      );

      return TransactionDateGroup(
        dateLabel: entry.key,
        transactions: entry.value,
        totalAmount: totalAmount,
      );
    }).toList();
  }

  String _getDateGroupKey(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'transactions.today'.tr();
    } else if (transactionDate == yesterday) {
      return 'transactions.yesterday'.tr();
    } else if (now.difference(date).inDays < 7) {
      return DateFormat.EEEE().format(date);
    } else if (date.year == now.year) {
      return DateFormat.MMMd().format(date);
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  void _handleTransactionTap(Transaction transaction) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedTransactions.contains(transaction.id)) {
          _selectedTransactions.remove(transaction.id);
        } else {
          _selectedTransactions.add(transaction.id);
        }
      });
    } else {
      context.push('/transactions/${transaction.id}');
    }
  }

  void _navigateToAddTransaction() {
    context.push('/transactions/add');
  }

  void _editTransaction(Transaction transaction) {
    context.push('/transactions/edit/${transaction.id}');
  }

  void _duplicateTransaction(Transaction transaction) {
    context.push(
      '/transactions/add?'
      'type=${transaction.type.name}&'
      'account=${transaction.accountId}&'
      'category=${transaction.categoryId}&'
      'amount=${transaction.amount}',
    );
  }

  void _showSearchDialog() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('common.search'.tr()),
        child: ShadInput(
          placeholder: Text('transactions.searchTransactions'.tr()),
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            ref.read(transactionSearchQueryProvider.notifier).state = value;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedTransactions.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTransactions.clear();
    });
  }

  void _showDeleteConfirmation(Transaction transaction) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('transactions.deleteTransaction'.tr()),
        description: Text('transactions.deleteTransactionConfirmation'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton.destructive(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTransaction(transaction);
            },
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final notifier = ref.read(transactionListProvider.notifier);
    final success = await notifier.deleteTransaction(transaction.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'transactions.transactionDeleted'.tr()
              : 'transactions.errorDeletingTransaction'.tr()),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
      );
    }
  }

  void _bulkDeleteTransactions() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('transactions.deleteSelectedTransactions'.tr()),
        description: Text(
          'transactions.deleteSelectedTransactionsConfirmation'.tr(
            namedArgs: {'count': _selectedTransactions.length.toString()},
          ),
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton.destructive(
            onPressed: () {
              Navigator.of(context).pop();
              _performBulkDelete();
            },
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkDelete() async {
    final notifier = ref.read(transactionListProvider.notifier);

    for (final transactionId in _selectedTransactions) {
      await notifier.deleteTransaction(transactionId);
    }

    setState(() {
      _selectedTransactions.clear();
      _isSelectionMode = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('transactions.selectedTransactionsDeleted'.tr()),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _bulkExportTransactions() {
    // Implement bulk export functionality
  }

  void _exportAllTransactions() {
    // Implement export all functionality
  }

  void _clearAllFilters() {
    ref.read(transactionTypeFilterProvider.notifier).state = null;
    ref.read(transactionDateRangeFilterProvider.notifier).state = null;
    ref.read(transactionCategoryFilterProvider.notifier).state = null;
    ref.read(transactionAccountFilterProvider.notifier).state = null;
    ref.read(transactionSearchQueryProvider.notifier).state = '';
    setState(() {
      _searchQuery = '';
    });
  }

  bool _hasActiveFilters() {
    final typeFilter = ref.read(transactionTypeFilterProvider);
    final dateRangeFilter = ref.read(transactionDateRangeFilterProvider);
    final categoryFilter = ref.read(transactionCategoryFilterProvider);
    final accountFilter = ref.read(transactionAccountFilterProvider);

    return typeFilter != null ||
        dateRangeFilter != null ||
        categoryFilter != null ||
        accountFilter != null ||
        _searchQuery.isNotEmpty;
  }

  String _formatGroupTotal(double amount) {
    return CurrencyFormatter.format(amount);
  }
}

class TransactionDateGroup {
  final String dateLabel;
  final List<Transaction> transactions;
  final double totalAmount;

  const TransactionDateGroup({
    required this.dateLabel,
    required this.transactions,
    required this.totalAmount,
  });
}
