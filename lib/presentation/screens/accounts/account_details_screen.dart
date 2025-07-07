// lib/presentation/screens/accounts/account_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/confirmation_dialog.dart';

class AccountDetailsScreen extends ConsumerStatefulWidget {
  final String accountId;

  const AccountDetailsScreen({
    super.key,
    required this.accountId,
  });

  @override
  ConsumerState<AccountDetailsScreen> createState() =>
      _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(accountProvider(widget.accountId));

    return accountAsync.when(
      loading: () => Scaffold(
        appBar: CustomAppBar(
          title: 'accounts.accountDetails'.tr(),
          showBackButton: true,
        ),
        body: const Center(child: LoadingWidget()),
      ),
      error: (error, _) => Scaffold(
        appBar: CustomAppBar(
          title: 'accounts.accountDetails'.tr(),
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
              title: 'accounts.accountDetails'.tr(),
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

        return _buildAccountDetails(context, account);
      },
    );
  }

  Widget _buildAccountDetails(BuildContext context, Account account) {
    return Scaffold(
      appBar: CustomAppBar(
        title: account.name,
        showBackButton: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value, account),
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
                value: 'transfer',
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('accounts.transferFunds'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'transactions',
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('All Transactions'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: account.isActive ? 'deactivate' : 'activate',
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
                    const Icon(Icons.delete, size: 16, color: AppColors.error),
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
          // Account Header
          _buildAccountHeader(account),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: ShadTheme.of(context).colorScheme.background,
              border: Border(
                bottom: BorderSide(
                  color: ShadTheme.of(context).colorScheme.border,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Recent Transactions'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(account),
                _buildTransactionsTab(account),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/transactions/add?account=${account.id}'),
        icon: const Icon(Icons.add),
        label: Text('Add Transaction'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildAccountHeader(Account account) {
    return Container(
      width: double.infinity,
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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Type and Status
              Row(
                children: [
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
                      'accounts.types.${account.type.name}'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!account.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingS,
                        vertical: AppDimensions.paddingXs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppDimensions.spacingL),

              // Balance
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
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              if (account.type == AccountType.creditCard &&
                  account.creditLimit != null) ...[
                const SizedBox(height: AppDimensions.spacingM),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Credit',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      CurrencyFormatter.format(
                        account.availableBalance,
                        currency: account.currency,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],

              if (account.accountNumber != null) ...[
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  '•••• •••• •••• ${account.accountNumber}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Account account) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          _buildQuickActions(account),

          const SizedBox(height: AppDimensions.spacingL),

          // Account Information
          _buildAccountInfo(account),

          const SizedBox(height: AppDimensions.spacingL),

          // Statistics (placeholder)
          _buildAccountStatistics(account),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Account account) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: ShadTheme.of(context).textTheme.h4,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () => context.go(
                        '/transactions/add?account=${account.id}&type=income'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: AppColors.success),
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text('Add Income'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () => context.go(
                        '/transactions/add?account=${account.id}&type=expense'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.remove, color: AppColors.error),
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text('Add Expense'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () =>
                        context.go('/accounts/transfer?from=${account.id}'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz, color: AppColors.primary),
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text('Transfer'),
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

  Widget _buildAccountInfo(Account account) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: ShadTheme.of(context).textTheme.h4,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            _buildInfoRow('Name', account.name),
            _buildInfoRow('Type', 'accounts.types.${account.type.name}'.tr()),
            _buildInfoRow('Currency', account.currency),
            if (account.bankName != null)
              _buildInfoRow('Bank', account.bankName!),
            if (account.description != null)
              _buildInfoRow('Description', account.description!),
            _buildInfoRow(
                'Created', DateFormat.yMMMd().format(account.createdAt)),
            _buildInfoRow(
                'Last Updated', DateFormat.yMMMd().format(account.updatedAt)),
            _buildInfoRow('Status', account.isActive ? 'Active' : 'Inactive'),
            _buildInfoRow(
                'Include in Total', account.includeInTotal ? 'Yes' : 'No'),
            if (account.creditLimit != null)
              _buildInfoRow(
                'Credit Limit',
                CurrencyFormatter.format(account.creditLimit!,
                    currency: account.currency),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: ShadTheme.of(context).textTheme.muted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStatistics(Account account) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: ShadTheme.of(context).textTheme.h4,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            // Placeholder for statistics
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.darkOnSurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: const Center(
                child: Text('Statistics coming soon'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(Account account) {
    // This would use a transaction provider filtered by account
    return const Center(
      child: Text('Recent transactions will be shown here'),
    );
  }

  void _handleMenuAction(BuildContext context, String action, Account account) {
    switch (action) {
      case 'edit':
        context.go('/accounts/${account.id}/edit');
        break;
      case 'transfer':
        context.go('/accounts/transfer?from=${account.id}');
        break;
      case 'transactions':
        context.go('/accounts/${account.id}/transactions');
        break;
      case 'activate':
      case 'deactivate':
        _toggleAccountStatus(account);
        break;
      case 'delete':
        _showDeleteConfirmation(context, account);
        break;
    }
  }

  Future<void> _toggleAccountStatus(Account account) async {
    final success =
        await ref.read(accountListProvider.notifier).toggleAccountStatus(
              account.id,
              !account.isActive,
            );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            account.isActive
                ? 'Account deactivated successfully'
                : 'Account activated successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Account',
        message:
            'Are you sure you want to delete "${account.name}"? This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        onConfirm: () => _deleteAccount(account),
      ),
    );
  }

  Future<void> _deleteAccount(Account account) async {
    final success =
        await ref.read(accountListProvider.notifier).deleteAccount(account.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account "${account.name}" deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/accounts');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
