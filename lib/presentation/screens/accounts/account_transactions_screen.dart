// lib/presentation/screens/accounts/account_transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account.dart';
import '../../../data/models/transaction.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';

class AccountTransactionsScreen extends ConsumerStatefulWidget {
  final String accountId;

  const AccountTransactionsScreen({
    super.key,
    required this.accountId,
  });

  @override
  ConsumerState<AccountTransactionsScreen> createState() =>
      _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState
    extends ConsumerState<AccountTransactionsScreen> {
  String _searchQuery = '';
  TransactionType? _filterType;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(accountProvider(widget.accountId));

    return accountAsync.when(
      loading: () => Scaffold(
        appBar: CustomAppBar(
          title: 'transactions.title'.tr(),
          showBackButton: true,
        ),
        body: const Center(child: LoadingWidget()),
      ),
      error: (error, _) => Scaffold(
        appBar: CustomAppBar(
          title: 'transactions.title'.tr(),
          showBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                'Error loading account',
                style: ShadTheme.of(context).textTheme.h4,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(error.toString()),
              const SizedBox(height: AppDimensions.spacingL),
              ShadButton.outline(
                onPressed: () => ref.refresh(accountProvider(widget.accountId)),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      ),
      data: (account) {
        if (account == null) {
          return Scaffold(
            appBar: CustomAppBar(
              title: 'transactions.title'.tr(),
              showBackButton: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    'Account not found',
                    style: ShadTheme.of(context).textTheme.h4,
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                  ShadButton(
                    onPressed: () => context.go('/accounts'),
                    child: Text('Back to Accounts'),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildAccountTransactions(context, account);
      },
    );
  }

  Widget _buildAccountTransactions(BuildContext context, Account account) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '${account.name} Transactions',
        showBackButton: true,
        actions: [
          // Search Button
          IconButton(
            onPressed: _showSearchDialog,
            icon: const Icon(Icons.search),
          ),

          // Filter Button
          IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              _hasActiveFilters()
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: _hasActiveFilters() ? AppColors.primary : null,
            ),
          ),

          // More Options
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value, account),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.download, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('Export Transactions'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'add_transaction',
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('Add Transaction'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Account Summary Header
          _buildAccountSummary(account),

          // Active Filters
          if (_hasActiveFilters()) _buildActiveFilters(),

          // Transactions List
          Expanded(
            child: _buildTransactionsList(account),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/transactions/add?account=${account.id}'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAccountSummary(Account account) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            account.color != null ? Color(account.color!) : AppColors.primary,
            account.color != null
                ? Color(account.color!).withOpacity(0.8)
                : AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    CurrencyFormatter.format(
                      account.balance,
                      currency: account.currency,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingS,
                  vertical: AppDimensions.paddingXs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  'accounts.types.${account.type.name}'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // Transaction Stats Row (placeholder)
          Row(
            children: [
              Expanded(
                child:
                    _buildStatCard('This Month', '0', 'Income', Colors.white24),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: _buildStatCard(
                    'This Month', '0', 'Expenses', Colors.white24),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: _buildStatCard(
                    'Total', '0', 'Transactions', Colors.white24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String period, String amount, String label, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Column(
        children: [
          Text(
            period,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      color: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Active Filters:',
                style: ShadTheme.of(context).textTheme.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearAllFilters,
                child: Text(
                  'Clear All',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Wrap(
            spacing: AppDimensions.spacingS,
            children: [
              if (_searchQuery.isNotEmpty)
                _buildFilterChip('Search: $_searchQuery', () {
                  setState(() {
                    _searchQuery = '';
                  });
                }),
              if (_filterType != null)
                _buildFilterChip('Type: ${_filterType!.name}', () {
                  setState(() {
                    _filterType = null;
                  });
                }),
              if (_dateRange != null)
                _buildFilterChip(
                  'Date: ${DateFormat.yMd().format(_dateRange!.start)} - ${DateFormat.yMd().format(_dateRange!.end)}',
                  () {
                    setState(() {
                      _dateRange = null;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      deleteIconColor: AppColors.primary,
    );
  }

  Widget _buildTransactionsList(Account account) {
    // Note: This would use a transaction provider filtered by account ID
    // For now, we'll show a placeholder
    return const Center(
      child: EmptyStateWidget(
        title: 'No transactions found',
        message: 'Transactions for this account will appear here',
        icon: Icon(Icons.receipt_long_outlined),
      ),
    );

    // Actual implementation would be something like:
    /*
    final transactionsAsync = ref.watch(transactionsByAccountProvider(account.id));
    
    return transactionsAsync.when(
      loading: () => const Center(child: LoadingWidget()),
      error: (error, _) => Center(
        child: Text('Error loading transactions: $error'),
      ),
      data: (transactions) {
        final filteredTransactions = _filterTransactions(transactions);
        
        if (filteredTransactions.isEmpty) {
          return const Center(
            child: EmptyStateWidget(
              title: 'No transactions found',
              message: 'Add your first transaction to get started',
              icon: Icons.receipt_long_outlined,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(transactionsByAccountProvider(account.id));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: filteredTransactions.length,
            itemBuilder: (context, index) {
              final transaction = filteredTransactions[index];
              return TransactionItem(
                transaction: transaction,
                onTap: () => context.go('/transactions/${transaction.id}'),
                margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
              );
            },
          ),
        );
      },
    );
    */
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty || _filterType != null || _dateRange != null;
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _filterType = null;
      _dateRange = null;
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Transactions'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter search terms...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Transactions'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Transaction Type Filter
              DropdownButtonFormField<TransactionType?>(
                decoration: const InputDecoration(
                  labelText: 'Transaction Type',
                  border: OutlineInputBorder(),
                ),
                value: _filterType,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Types'),
                  ),
                  ...TransactionType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterType = value;
                  });
                },
              ),

              const SizedBox(height: AppDimensions.spacingM),

              // Date Range Filter
              ListTile(
                title: Text('Date Range'),
                subtitle: Text(
                  _dateRange == null
                      ? 'All dates'
                      : '${DateFormat.yMd().format(_dateRange!.start)} - ${DateFormat.yMd().format(_dateRange!.end)}',
                ),
                trailing: const Icon(Icons.date_range),
                onTap: _selectDateRange,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterType = null;
                _dateRange = null;
              });
              Navigator.of(context).pop();
            },
            child: Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _handleMenuAction(BuildContext context, String action, Account account) {
    switch (action) {
      case 'export':
        _exportTransactions(account);
        break;
      case 'add_transaction':
        context.go('/transactions/add?account=${account.id}');
        break;
    }
  }

  void _exportTransactions(Account account) {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}

// Note: You'll need to define TransactionType enum if it doesn't exist
enum TransactionType {
  income,
  expense,
  transfer,
}
