import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/account.dart';
import '../../providers/account_provider.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/account_balance_card.dart';
import 'widgets/account_item.dart';

class AccountListScreen extends ConsumerStatefulWidget {
  const AccountListScreen({super.key});

  @override
  ConsumerState<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends ConsumerState<AccountListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  AccountType? _filterType;
  bool _showOnlyActive = true;

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
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'accounts.title'.tr(),
        actions: [
          // Search Button
          ShadButton.ghost(
            onPressed: _showSearchDialog,
            child: const Icon(Icons.search),
          ),

          // Filter Button
          ShadButton.ghost(
            onPressed: _showFilterDialog,
            child: const Icon(Icons.filter_list),
          ),

          // More Options
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('common.refresh'.tr()),
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
          // Total Balance Section
          _buildTotalBalanceSection(),

          // Tab Bar
          Container(
            margin:
                const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
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
                Tab(text: 'List View'),
                Tab(text: 'Card View'),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListView(),
                _buildCardView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/accounts/add'),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTotalBalanceSection() {
    final totalBalanceAsync = ref.watch(totalBalanceProvider('USD'));
    final theme = ShadTheme.of(context);

    return Container(
      margin: const EdgeInsets.all(AppDimensions.spacingM),
      child: ShadCard(
        padding: const EdgeInsets.all(AppDimensions.paddingS),
        backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            children: [
              Text(
                'accounts.totalBalance'.tr(),
                style: theme.textTheme.h4.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              totalBalanceAsync.when(
                loading: () => const ShimmerLoading(
                  child: SkeletonLoader(height: 32, width: 200),
                ),
                error: (error, _) => Text(
                  'Error loading balance',
                  style: theme.textTheme.h2.copyWith(color: AppColors.error),
                ),
                data: (balance) => Text(
                  _formatCurrency(balance, 'USD'),
                  style: theme.textTheme.h1.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    final accountsAsync = ref.watch(accountListProvider);

    return accountsAsync.when(
      loading: () => const Center(
        child: ShimmerLoading(
          child: SkeletonLoader(height: 400, width: double.infinity),
        ),
      ),
      error: (error, _) => Center(
        child: CustomErrorWidget(
          title: 'Error loading accounts',
          message: error.toString(),
          actionText: 'common.retry'.tr(),
          onActionPressed: () => ref.refresh(accountListProvider),
        ),
      ),
      data: (accounts) {
        final filteredAccounts = _filterAccounts(accounts);

        if (filteredAccounts.isEmpty) {
          return accounts.isEmpty
              ? AccountsEmptyState(
                  onAddAccount: () => context.go('/accounts/add'),
                )
              : const EmptyStateWidget(
                  title: 'No accounts match your filters',
                  message: 'Try adjusting your search or filter criteria',
                );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(accountListProvider);
          },
          child: ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
            itemCount: filteredAccounts.length,
            itemBuilder: (context, index) {
              final account = filteredAccounts[index];
              return AccountItem(
                account: account,
                onTap: () => context.go('/accounts/${account.id}'),
                onEdit: () => context.go('/accounts/edit/${account.id}'),
                onTransfer: () => context.go('/transfer?from=${account.id}'),
                onDelete: () => _showDeleteConfirmation(account),
                margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCardView() {
    final accountsAsync = ref.watch(accountListProvider);

    return accountsAsync.when(
      loading: () => const Center(
        child: ShimmerLoading(
          child: SkeletonLoader(height: 400, width: double.infinity),
        ),
      ),
      error: (error, _) => Center(
        child: CustomErrorWidget(
          title: 'Error loading accounts',
          message: error.toString(),
          actionText: 'common.retry'.tr(),
          onActionPressed: () => ref.refresh(accountListProvider),
        ),
      ),
      data: (accounts) {
        final filteredAccounts = _filterAccounts(accounts);

        if (filteredAccounts.isEmpty) {
          return accounts.isEmpty
              ? AccountsEmptyState(
                  onAddAccount: () => context.go('/accounts/add'),
                )
              : const EmptyStateWidget(
                  title: 'No accounts match your filters',
                  message: 'Try adjusting your search or filter criteria',
                );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(accountListProvider);
          },
          child: GridView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: AppDimensions.spacingS,
              mainAxisSpacing: AppDimensions.spacingS,
            ),
            itemCount: filteredAccounts.length,
            itemBuilder: (context, index) {
              final account = filteredAccounts[index];
              return AccountBalanceCard(
                account: account,
                showDetails: true,
                showActions: true,
                onTap: () => context.go('/accounts/${account.id}'),
                onTransferTap: () => context.go('/transfer?from=${account.id}'),
                onEditTap: () => context.go('/accounts/edit/${account.id}'),
                margin: EdgeInsets.zero,
              );
            },
          ),
        );
      },
    );
  }

  List<Account> _filterAccounts(List<Account> accounts) {
    return accounts.where((account) {
      // Filter by active status
      if (_showOnlyActive && !account.isActive) return false;

      // Filter by type
      if (_filterType != null && account.type != _filterType) return false;

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return account.name.toLowerCase().contains(query) ||
            (account.description?.toLowerCase().contains(query) ?? false) ||
            (account.bankName?.toLowerCase().contains(query) ?? false);
      }

      return true;
    }).toList();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search Accounts',
                style: ShadTheme.of(context).textTheme.h3,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              ShadInput(
                placeholder: Text('Search by name, description, or bank...'),
                initialValue: _searchQuery,
                onChanged: (value) => _searchQuery = value,
                autofocus: true,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              Row(
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      onPressed: () {
                        setState(() => _searchQuery = '');
                        Navigator.of(context).pop();
                      },
                      child: Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: ShadButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.of(context).pop();
                      },
                      child: Text('Search'),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Accounts',
                style: ShadTheme.of(context).textTheme.h3,
              ),
              const SizedBox(height: AppDimensions.spacingM),

              // Account Type Filter
              Text('Account Type', style: ShadTheme.of(context).textTheme.h4),
              const SizedBox(height: AppDimensions.spacingS),
              DropdownButton<AccountType?>(
                value: _filterType,
                isExpanded: true,
                hint: Text('All Types'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Types')),
                  ...AccountType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text('accounts.types.${type.name}'.tr()),
                      )),
                ],
                onChanged: (value) => setState(() => _filterType = value),
              ),

              const SizedBox(height: AppDimensions.spacingM),

              // Status Filter
              SwitchListTile(
                title: Text('Show only active accounts'),
                value: _showOnlyActive,
                onChanged: (value) => setState(() => _showOnlyActive = value),
              ),

              const SizedBox(height: AppDimensions.spacingL),

              Row(
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      onPressed: () {
                        setState(() {
                          _filterType = null;
                          _showOnlyActive = true;
                        });
                        Navigator.of(context).pop();
                      },
                      child: Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: ShadButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Apply'),
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

  void _handleMenuAction(String? action) {
    switch (action) {
      case 'refresh':
        ref.refresh(accountListProvider);
        break;
      case 'export':
        _exportAccounts();
        break;
    }
  }

  void _exportAccounts() {
    // TODO: Implement export functionality
    final sonner = ShadSonner.of(context);
    sonner.show(ShadToast(
      description: Text('Export functionality coming soon'),
    ));
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
      final sonner = ShadSonner.of(context);
      sonner.show(ShadToast(
        description: Text('Account "${account.name}" deleted successfully'),
      ));
    }
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
