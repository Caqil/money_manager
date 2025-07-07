import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/account.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/account_balance_card.dart';

class AccountDetailScreen extends ConsumerStatefulWidget {
  final String accountId;

  const AccountDetailScreen({
    super.key,
    required this.accountId,
  });

  @override
  ConsumerState<AccountDetailScreen> createState() =>
      _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen>
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
    final accountAsync = ref.watch(accountProvider(widget.accountId));

    return accountAsync.when(
      loading: () => const Scaffold(
        body: Center(
            child: ShimmerLoading(
                child: SkeletonLoader(height: 300, width: double.infinity))),
      ),
      error: (error, _) => Scaffold(
        appBar: CustomAppBar(
          title: 'accounts.accountDetails'.tr(),
          showBackButton: true,
        ),
        body: Center(
          child: CustomErrorWidget(
            title: 'Error loading account',
            message: error.toString(),
            actionText: 'common.retry'.tr(),
            onActionPressed: () =>
                ref.refresh(accountProvider(widget.accountId)),
          ),
        ),
      ),
      data: (account) {
        if (account == null) {
          return Scaffold(
            appBar: CustomAppBar(
              title: 'accounts.accountDetails'.tr(),
              showBackButton: true,
            ),
            body: const Center(
              child: EmptyStateWidget(
                title: 'Account not found',
                message: 'The requested account could not be found.',
              ),
            ),
          );
        }

        return Scaffold(
          appBar: CustomAppBar(
            title: account.name,
            showBackButton: true,
            actions: [
              // Transfer Button
              ShadButton.ghost(
                onPressed: () => _navigateToTransfer(account),
                child: const Icon(Icons.swap_horiz),
              ),

              // More Options
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, account),
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
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          account.isActive
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 16,
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text(account.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text(
                          'common.delete'.tr(),
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Account Balance Card
              AccountBalanceCard(
                account: account,
                showDetails: true,
                showActions: false,
                margin: const EdgeInsets.all(AppDimensions.spacingM),
              ),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingM),
                child: Row(
                  children: [
                    Expanded(
                      child: ShadButton.outline(
                        onPressed: () =>
                            _navigateToAddTransaction(account, 'income'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add,
                                size: 16, color: AppColors.success),
                            const SizedBox(width: AppDimensions.spacingS),
                            Text('Add Income'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: ShadButton.outline(
                        onPressed: () =>
                            _navigateToAddTransaction(account, 'expense'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.remove,
                                size: 16, color: AppColors.error),
                            const SizedBox(width: AppDimensions.spacingS),
                            Text('Add Expense'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: ShadButton.outline(
                        onPressed: () => _navigateToTransfer(account),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.swap_horiz,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: AppDimensions.spacingS),
                            Text('Transfer'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingM),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.colorScheme.foreground,
                  tabs: const [
                    Tab(text: 'Transactions'),
                    Tab(text: 'Details'),
                    Tab(text: 'Analytics'),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionsTab(account),
                    _buildDetailsTab(account),
                    _buildAnalyticsTab(account),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab(Account account) {
    // Use the transaction provider to get transactions for this account
    final transactionsAsync =
        ref.watch(transactionsByAccountProvider(account.id));

    return transactionsAsync.when(
      loading: () => const Center(
        child: ShimmerLoading(
          child: SkeletonLoader(height: 200, width: double.infinity),
        ),
      ),
      error: (error, _) => Center(
        child: CustomErrorWidget(
          title: 'Error loading transactions',
          message: error.toString(),
          actionText: 'common.retry'.tr(),
          onActionPressed: () =>
              ref.refresh(transactionsByAccountProvider(account.id)),
        ),
      ),
      data: (transactions) {
        if (transactions.isEmpty) {
          return TransactionsEmptyState(
            onAddTransaction: () =>
                _navigateToAddTransaction(account, 'expense'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(transactionsByAccountProvider(account.id));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _getTransactionColor(transaction.type.name),
                    child: Icon(
                      _getTransactionIcon(transaction.type.name),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text('Transaction'),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy').format(transaction.date),
                  ),
                  trailing: Text(
                    _formatAmount(transaction.amount, transaction.type.name),
                    style: TextStyle(
                      color: _getTransactionColor(transaction.type.name),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _navigateToTransactionDetail(transaction.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailsTab(Account account) {
    final theme = ShadTheme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      children: [
        // Account Information Card
        ShadCard(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Information',
                  style: theme.textTheme.h3,
                ),
                const SizedBox(height: AppDimensions.spacingM),
                _buildDetailRow('Name', account.name),
                _buildDetailRow(
                    'Type', 'accounts.types.${account.type.name}'.tr()),
                _buildDetailRow('Currency', account.currency),
                _buildDetailRow(
                    'Status', account.isActive ? 'Active' : 'Inactive'),
                _buildDetailRow(
                    'Include in Total', account.includeInTotal ? 'Yes' : 'No'),
                if (account.description != null)
                  _buildDetailRow('Description', account.description!),
                if (account.bankName != null)
                  _buildDetailRow('Bank', account.bankName!),
                if (account.accountNumber != null)
                  _buildDetailRow(
                      'Account Number', '••••${account.accountNumber}'),
                if (account.creditLimit != null)
                  _buildDetailRow('Credit Limit',
                      _formatCurrency(account.creditLimit!, account.currency)),
                _buildDetailRow('Created',
                    DateFormat('MMM dd, yyyy').format(account.createdAt)),
                _buildDetailRow('Last Updated',
                    DateFormat('MMM dd, yyyy').format(account.updatedAt)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab(Account account) {
    return const Center(
      child: ComingSoonEmptyState(
        title: 'Analytics Coming Soon',
        message: 'Account analytics and insights will be available here.',
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.muted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.p,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String? action, Account account) {
    switch (action) {
      case 'edit':
        _navigateToEditAccount(account);
        break;
      case 'toggle_status':
        _toggleAccountStatus(account);
        break;
      case 'delete':
        _showDeleteConfirmation(account);
        break;
    }
  }

  void _navigateToEditAccount(Account account) {
    context.go('/accounts/edit/${account.id}');
  }

  void _navigateToTransfer(Account account) {
    context.go('/transfer?from=${account.id}');
  }

  void _navigateToAddTransaction(Account account, String type) {
    context.go('/transactions/add?account=${account.id}&type=$type');
  }

  void _navigateToTransactionDetail(String transactionId) {
    context.go('/transactions/$transactionId');
  }

  Future<void> _toggleAccountStatus(Account account) async {
    final notifier = ref.read(accountListProvider.notifier);
    final success =
        await notifier.toggleAccountStatus(account.id, !account.isActive);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              account.isActive ? 'Account deactivated' : 'Account activated'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showDeleteConfirmation(Account account) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Account',
        message:
            'Are you sure you want to delete "${account.name}"? This action cannot be undone.',
        destructive: true,
        confirmText: 'common.delete'.tr(),
        cancelText: 'common.cancel'.tr(),
        onConfirm: () {
          Navigator.of(context).pop();
          _deleteAccount(account);
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _deleteAccount(Account account) async {
    final notifier = ref.read(accountListProvider.notifier);
    final success = await notifier.deleteAccount(account.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/accounts');
    }
  }

  Color _getTransactionColor(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return AppColors.success;
      case 'expense':
        return AppColors.error;
      case 'transfer':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return Icons.arrow_upward;
      case 'expense':
        return Icons.arrow_downward;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.attach_money;
    }
  }

  String _formatAmount(double amount, String type) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final prefix = type.toLowerCase() == 'expense' ? '-' : '+';
    return '$prefix${formatter.format(amount.abs())}';
  }

  String _formatCurrency(double amount, String currency) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'CHF':
        return 'CHF';
      case 'CNY':
        return '¥';
      case 'INR':
        return '₹';
      default:
        return currency;
    }
  }
}
