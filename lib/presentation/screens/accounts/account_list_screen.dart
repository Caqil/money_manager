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

class AccountListScreen extends ConsumerStatefulWidget {
  const AccountListScreen({super.key});

  @override
  ConsumerState<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends ConsumerState<AccountListScreen>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  AccountType? _selectedFilter;

  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _listAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _headerAnimationController, curve: Curves.easeOutCubic),
    );
    _listAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _listAnimationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _listAnimationController, curve: Curves.easeOutCubic));

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _listAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: CustomAppBar(
        title: 'accounts.title'.tr(),
        actions: [
          // Animated search toggle
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: IconButton(
              key: ValueKey(_showSearch),
              icon: Icon(_showSearch ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                });
              },
            ),
          ),

          // Filter button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: _showFilterSheet,
              ),
              if (_selectedFilter != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Animated search bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showSearch ? 80 : 0,
            curve: Curves.easeInOut,
            child: _showSearch ? _buildAnimatedSearchBar(theme) : null,
          ),

          // Animated header with balance
          FadeTransition(
            opacity: _headerAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.3),
                end: Offset.zero,
              ).animate(_headerAnimation),
              child: _buildModernBalanceCard(),
            ),
          ),

          // Filter chips
          _buildFilterChips(),

          // Animated account list
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _listAnimation,
                child: _buildAccountList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _listAnimation,
        child: ShadButton(
          onPressed: () => context.go('/accounts/add'),
          size: ShadButtonSize.lg,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSearchBar(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ShadInput(
        controller: _searchController,
        placeholder: Text('accounts.searchPlaceholder'.tr()),
        leading: const Icon(Icons.search, size: 20),
        trailing: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _searchQuery.isNotEmpty ? 1.0 : 0.0,
          child: IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
        ),
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        autofocus: true,
      ),
    );
  }

  Widget _buildModernBalanceCard() {
    final totalBalanceAsync = ref.watch(totalBalanceProvider('USD'));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
              AppColors.accent.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'accounts.totalBalance'.tr(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      totalBalanceAsync.when(
                        loading: () => _buildShimmerBalance(),
                        error: (_, __) => Text(
                          'accounts.errorLoadingBalance'.tr(),
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        data: (balance) => TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween(begin: 0, end: balance),
                          builder: (context, value, child) {
                            return Text(
                              _formatCurrency(value, 'USD'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+2.5%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.add,
                    label: 'accounts.addMoney'.tr(),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.send,
                    label: 'accounts.transfer'.tr(),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.history,
                    label: 'accounts.history'.tr(),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBalance() {
    return Container(
      height: 38,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const SizedBox(),
    );
  }

  Widget _buildFilterChips() {
    final accountTypes = AccountType.values;

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: accountTypes.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilterChip(
              label: 'common.all'.tr(),
              isSelected: _selectedFilter == null,
              onTap: () => setState(() => _selectedFilter = null),
            );
          }

          final type = accountTypes[index - 1];
          return _buildFilterChip(
            label: type.name.capitalize(),
            isSelected: _selectedFilter == type,
            onTap: () => setState(() => _selectedFilter = type),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ShadButton.outline(
          onPressed: onTap,
          size: ShadButtonSize.sm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountList() {
    final accountsAsync = ref.watch(accountListProvider);

    return accountsAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => Center(
        child: CustomErrorWidget(
          title: 'accounts.errorLoadingAccounts'.tr(),
          message: error.toString(),
          actionText: 'common.retry'.tr(),
          onActionPressed: () => ref.refresh(accountListProvider),
        ),
      ),
      data: (accounts) {
        final filteredAccounts = _filterAccounts(accounts);

        if (filteredAccounts.isEmpty) {
          return _buildEmptyState(accounts.isEmpty);
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(accountListProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: filteredAccounts.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: _buildModernAccountCard(filteredAccounts[index]),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildModernAccountCard(Account account) {
    final theme = ShadTheme.of(context);
    final typeColor = _getAccountTypeColor(account.type);

    return ShadCard(
      shadows: [
        BoxShadow(
          color: typeColor.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      child: InkWell(
        onTap: () => context.go('/accounts/${account.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Row(
              children: [
                // Animated account icon
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [typeColor, typeColor.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: typeColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getAccountTypeIcon(account.type),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),

                // Account info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: theme.textTheme.h4.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          account.type.name.toUpperCase(),
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (account.bankName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          account.bankName!,
                          style: theme.textTheme.small.copyWith(
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0, end: account.balance),
                      builder: (context, value, child) {
                        return Text(
                          _formatCurrency(value, account.currency),
                          style: theme.textTheme.h3.copyWith(
                            fontWeight: FontWeight.w800,
                            color: account.balance >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'accounts.available'.tr(),
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () => context.go('/accounts/edit/${account.id}'),
                    size: ShadButtonSize.sm,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 16),
                        const SizedBox(width: 8),
                        Text('common.edit'.tr()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () => context.go('/transfer?from=${account.id}'),
                    size: ShadButtonSize.sm,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send, size: 16),
                        const SizedBox(width: 8),
                        Text('accounts.transfer'.tr()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ShadButton.outline(
                  onPressed: () => _showDeleteConfirmation(account),
                  size: ShadButtonSize.sm,
                  child: Icon(Icons.delete, size: 16, color: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isCompletelyEmpty) {
    if (isCompletelyEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 60,
                color: AppColors.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'accounts.emptyState.title'.tr(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'accounts.emptyState.subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ShadButton(
              onPressed: () => context.go('/accounts/add'),
              size: ShadButtonSize.lg,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 20),
                  const SizedBox(width: 8),
                  Text('accounts.createAccount'.tr()),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('accounts.noAccountsFound'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Text('accounts.adjustFilters'.tr()),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ShadTheme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'accounts.filterTitle'.tr(),
              style: ShadTheme.of(context).textTheme.h3,
            ),
            const SizedBox(height: 24),
            // Filter options here
            ShadButton(
              onPressed: () => Navigator.pop(context),
              child: Text('accounts.applyFilters'.tr()),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<Account> _filterAccounts(List<Account> accounts) {
    var filtered = accounts.where((account) {
      // Filter by type
      if (_selectedFilter != null && account.type != _selectedFilter) {
        return false;
      }

      // Filter by search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return account.name.toLowerCase().contains(query) ||
            (account.description?.toLowerCase().contains(query) ?? false) ||
            (account.bankName?.toLowerCase().contains(query) ?? false) ||
            account.type.name.toLowerCase().contains(query);
      }

      return true;
    }).toList();

    // Sort by balance (highest first)
    filtered.sort((a, b) => b.balance.compareTo(a.balance));
    return filtered;
  }

  Color _getAccountTypeColor(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return const Color(0xFF3B82F6);
      case AccountType.savings:
        return const Color(0xFF10B981);
      case AccountType.creditCard:
        return const Color(0xFFF59E0B);
      case AccountType.investment:
        return const Color(0xFF8B5CF6);
      case AccountType.cash:
        return const Color(0xFF6366F1);
      default:
        return AppColors.primary;
    }
  }

  IconData _getAccountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return Icons.account_balance;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.cash:
        return Icons.payments;
      default:
        return Icons.account_balance_wallet;
    }
  }

  void _showDeleteConfirmation(Account account) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'accounts.deleteTitle'.tr(),
        message: 'accounts.deleteConfirm'.tr(args: [account.name]),
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
      ShadSonner.of(context).show(
        ShadToast(
          description: Text('accounts.deleteSuccessMessage'.tr()),
          backgroundColor: AppColors.success,
        ),
      );
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

extension StringCapitalize on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
