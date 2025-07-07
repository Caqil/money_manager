// lib/presentation/screens/transactions/transaction_list_screen.dart
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
import '../../providers/settings_provider.dart';
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

  // FIXED: Add controllers for ShadPopover
  final ShadPopoverController _moreActionsController = ShadPopoverController();

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
    _moreActionsController.dispose(); // FIXED: Dispose controller
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
            // FIXED: Add controller to ShadPopover
            ShadPopover(
              controller: _moreActionsController,
              popover: (context) => _buildMoreActionsMenu(),
              child: IconButton(
                onPressed: () {
                  _moreActionsController.toggle();
                },
                icon: const Icon(Icons.more_vert),
                tooltip: 'common.moreActions'.tr(),
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
    return ShadCard(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.select_all, size: 18),
            title: Text('transactions.selectMode'.tr()),
            onTap: () {
              _moreActionsController.hide();
              _enterSelectionMode();
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download, size: 18),
            title: Text('transactions.exportAll'.tr()),
            onTap: () {
              _moreActionsController.hide();
              _exportAllTransactions();
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh, size: 18),
            title: Text('common.refresh'.tr()),
            onTap: () {
              _moreActionsController.hide();
              ref.invalidate(transactionListProvider);
            },
          ),
        ],
      ),
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
            return transaction.notes?.toLowerCase().contains(query) == true;
          }).toList();

    if (filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(transactionListProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        itemCount: filteredTransactions.length,
        separatorBuilder: (context, index) => const SizedBox(
          height: AppDimensions.spacingS,
        ),
        itemBuilder: (context, index) {
          final transaction = filteredTransactions[index];
          final isSelected = _selectedTransactions.contains(transaction.id);

          return GestureDetector(
            onLongPress: _isSelectionMode
                ? null
                : () => _enterSelectionModeWithTransaction(transaction.id),
            child: TransactionItem(
              transaction: transaction,
              onTap: _isSelectionMode
                  ? () => _toggleTransactionSelection(transaction.id)
                  : () => _navigateToTransactionDetail(transaction),
              onEdit: () => _navigateToEditTransaction(transaction),
              onDelete: () => _showDeleteConfirmation(transaction),
              onDuplicate: () => _navigateToDuplicateTransaction(transaction),
              showActions: !_isSelectionMode,
              isSelected: isSelected,
              isSelectable: _isSelectionMode,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: EmptyStateWidget(
        iconData: Icons.receipt_long_outlined,
        title: 'transactions.noTransactions'.tr(),
        message: 'transactions.noTransactionsMessage'.tr(),
        actionText: 'transactions.addFirstTransaction'.tr(),
        onActionPressed: _navigateToAddTransaction,
      ),
    );
  }

  // Navigation methods
  void _navigateToAddTransaction() {
    context.push('/transactions/add');
  }

  void _navigateToTransactionDetail(Transaction transaction) {
    context.push('/transactions/${transaction.id}');
  }

  void _navigateToEditTransaction(Transaction transaction) {
    context.push('/transactions/edit/${transaction.id}');
  }

  void _navigateToDuplicateTransaction(Transaction transaction) {
    context.push('/transactions/add?duplicate=${transaction.id}');
  }

  // Action methods
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

  void _enterSelectionModeWithTransaction(String transactionId) {
    setState(() {
      _isSelectionMode = true;
      _selectedTransactions = {transactionId};
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTransactions.clear();
    });
  }

  void _toggleTransactionSelection(String transactionId) {
    setState(() {
      if (_selectedTransactions.contains(transactionId)) {
        _selectedTransactions.remove(transactionId);
      } else {
        _selectedTransactions.add(transactionId);
      }
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
        ),
      );
    }
  }

  Future<void> _bulkDeleteTransactions() async {
    if (_selectedTransactions.isEmpty) return;

    final result = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('transactions.deleteSelectedTransactions'.tr()),
        description: Text('transactions.deleteSelectedTransactionsConfirmation'
            .tr(namedArgs: {'count': _selectedTransactions.length.toString()})),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (result == true) {
      final notifier = ref.read(transactionListProvider.notifier);
      int deletedCount = 0;

      for (final transactionId in _selectedTransactions) {
        final success = await notifier.deleteTransaction(transactionId);
        if (success) deletedCount++;
      }

      _exitSelectionMode();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('transactions.transactionsDeleted'
                .tr(namedArgs: {'count': deletedCount.toString()})),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _bulkExportTransactions() async {
    // Implement bulk export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Feature coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _exportAllTransactions() async {
    // Implement export all functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  // Helper methods for transaction handling
  void _handleTransactionTap(Transaction transaction) {
    if (_isSelectionMode) {
      _toggleTransactionSelection(transaction.id);
    } else {
      _navigateToTransactionDetail(transaction);
    }
  }

  bool _hasActiveFilters() {
    final typeFilter = ref.read(transactionTypeFilterProvider);
    final dateRangeFilter = ref.read(transactionDateRangeFilterProvider);
    final categoryFilter = ref.read(transactionCategoryFilterProvider);
    final accountFilter = ref.read(transactionAccountFilterProvider);
    final searchQuery = ref.read(transactionSearchQueryProvider);

    return typeFilter != null ||
        dateRangeFilter != null ||
        (categoryFilter != null && categoryFilter.isNotEmpty) ||
        (accountFilter != null && accountFilter.isNotEmpty) ||
        searchQuery.isNotEmpty;
  }
}
