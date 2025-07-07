import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/account.dart';
import '../../../../data/models/transaction.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/transaction_provider.dart';

class TransactionFilters extends ConsumerStatefulWidget {
  final VoidCallback? onFiltersChanged;

  const TransactionFilters({
    super.key,
    this.onFiltersChanged,
  });

  @override
  ConsumerState<TransactionFilters> createState() => _TransactionFiltersState();
}

class _TransactionFiltersState extends ConsumerState<TransactionFilters> {
  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final typeFilter = ref.watch(transactionTypeFilterProvider);
    final dateRangeFilter = ref.watch(transactionDateRangeFilterProvider);
    final categoryFilter = ref.watch(transactionCategoryFilterProvider);
    final accountFilter = ref.watch(transactionAccountFilterProvider);

    final hasActiveFilters = typeFilter != null || 
                           dateRangeFilter != null || 
                           categoryFilter != null || 
                           accountFilter != null;

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 20,
                  color: theme.colorScheme.foreground,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  'transactions.filters'.tr(),
                  style: theme.textTheme.h4,
                ),
                const Spacer(),
                if (hasActiveFilters)
                  ShadButton.ghost(
                    size: ShadButtonSize.sm,
                    onPressed: _clearAllFilters,
                    child: Text(
                      'common.clearAll'.tr(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            
            if (hasActiveFilters) ...[
              const SizedBox(height: AppDimensions.spacingM),
              _buildActiveFilters(),
            ],

            const SizedBox(height: AppDimensions.spacingM),

            // Filter Options
            Wrap(
              spacing: AppDimensions.spacingS,
              runSpacing: AppDimensions.spacingS,
              children: [
                _buildTypeFilterChip(),
                _buildDateRangeFilterChip(),
                _buildCategoryFilterChip(categoryFilter ?? ''),
                _buildAccountFilterChip(accountFilter ?? ''),
                _buildAmountRangeFilterChip(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    final typeFilter = ref.watch(transactionTypeFilterProvider);
    final dateRangeFilter = ref.watch(transactionDateRangeFilterProvider);
    final categoryFilter = ref.watch(transactionCategoryFilterProvider);
    final accountFilter = ref.watch(transactionAccountFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'transactions.activeFilters'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: AppColors.lightOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingXs,
          children: [
            if (typeFilter != null)
              _buildActiveFilterChip(
                label: _getTypeDisplayName(typeFilter),
                onRemove: () => _clearTypeFilter(),
              ),
            if (dateRangeFilter != null)
              _buildActiveFilterChip(
                label: _formatDateRange(dateRangeFilter),
                onRemove: () => _clearDateRangeFilter(),
              ),
            if (categoryFilter != null)
              _buildCategoryFilterChip(categoryFilter),
            if (accountFilter != null)
              _buildAccountFilterChip(accountFilter),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onRemove,
    Widget? leading,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: AppDimensions.spacingXs),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChip(String categoryId) {
    final categoryAsync = ref.watch(categoryProvider(categoryId));
    
    return categoryAsync.when(
      loading: () => _buildActiveFilterChip(
        label: 'Loading...',
        onRemove: () => _clearCategoryFilter(),
      ),
      error: (_, __) => _buildActiveFilterChip(
        label: 'Unknown Category',
        onRemove: () => _clearCategoryFilter(),
      ),
      data: (category) {
        if (category == null) {
          return _buildActiveFilterChip(
            label: 'Unknown Category',
            onRemove: () => _clearCategoryFilter(),
          );
        }
        
        return _buildActiveFilterChip(
          label: category.name,
          onRemove: () => _clearCategoryFilter(),
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(category.color),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountFilterChip(String accountId) {
    final accountAsync = ref.watch(accountProvider(accountId));
    
    return accountAsync.when(
      loading: () => _buildActiveFilterChip(
        label: 'Loading...',
        onRemove: () => _clearAccountFilter(),
      ),
      error: (_, __) => _buildActiveFilterChip(
        label: 'Unknown Account',
        onRemove: () => _clearAccountFilter(),
      ),
      data: (account) {
        if (account == null) {
          return _buildActiveFilterChip(
            label: 'Unknown Account',
            onRemove: () => _clearAccountFilter(),
          );
        }
        
        return _buildActiveFilterChip(
          label: account.name,
          onRemove: () => _clearAccountFilter(),
          leading: Icon(
            _getAccountIcon(account.type),
            size: 12,
            color: AppColors.primary,
          ),
        );
      },
    );
  }

  Widget _buildTypeFilterChip() {
    return _buildFilterChip(
      label: 'transactions.type'.tr(),
      icon: Icons.swap_vert,
      onTap: _showTypeFilterDialog,
    );
  }

  Widget _buildDateRangeFilterChip() {
    return _buildFilterChip(
      label: 'transactions.dateRange'.tr(),
      icon: Icons.date_range,
      onTap: _showDateRangeFilterDialog,
    );
  }


  Widget _buildAmountRangeFilterChip() {
    return _buildFilterChip(
      label: 'transactions.amountRange'.tr(),
      icon: Icons.attach_money,
      onTap: _showAmountRangeFilterDialog,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: AppDimensions.spacingXs),
          Text(label),
        ],
      ),
    );
  }

  void _showTypeFilterDialog() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('transactions.selectType'.tr()),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: TransactionType.values.map((type) => ListTile(
            leading: Icon(_getTypeIcon(type), color: _getTypeColor(type)),
            title: Text(_getTypeDisplayName(type)),
            onTap: () {
              ref.read(transactionTypeFilterProvider.notifier).state = type;
              Navigator.of(context).pop();
              widget.onFiltersChanged?.call();
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showDateRangeFilterDialog() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('transactions.selectDateRange'.tr()),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('transactions.today'.tr()),
              onTap: () => _setDateRangeFilter(_getTodayRange()),
            ),
            ListTile(
              title: Text('transactions.thisWeek'.tr()),
              onTap: () => _setDateRangeFilter(_getThisWeekRange()),
            ),
            ListTile(
              title: Text('transactions.thisMonth'.tr()),
              onTap: () => _setDateRangeFilter(_getThisMonthRange()),
            ),
            ListTile(
              title: Text('transactions.lastMonth'.tr()),
              onTap: () => _setDateRangeFilter(_getLastMonthRange()),
            ),
            ListTile(
              title: Text('transactions.custom'.tr()),
              onTap: () => _showCustomDateRangePicker(),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilterDialog() {
    final categoriesAsync = ref.read(activeCategoriesProvider);
    
    categoriesAsync.when(
      loading: () {},
      error: (_, __) {},
      data: (categories) {
        showShadDialog(
          context: context,
          builder: (context) => ShadDialog(
            title: Text('transactions.selectCategory'.tr()),
            child: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    leading: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color(category.color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: Text(category.name),
                    onTap: () {
                      ref.read(transactionCategoryFilterProvider.notifier).state = category.id;
                      Navigator.of(context).pop();
                      widget.onFiltersChanged?.call();
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAccountFilterDialog() {
    final accountsAsync = ref.read(activeAccountsProvider);
    
    accountsAsync.when(
      loading: () {},
      error: (_, __) {},
      data: (accounts) {
        showShadDialog(
          context: context,
          builder: (context) => ShadDialog(
            title: Text('transactions.selectAccount'.tr()),
            child: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return ListTile(
                    leading: Icon(_getAccountIcon(account.type)),
                    title: Text(account.name),
                    subtitle: Text(CurrencyFormatter.format(
                      account.balance,
                      currency: account.currency,
                    )),
                    onTap: () {
                      ref.read(transactionAccountFilterProvider.notifier).state = account.id;
                      Navigator.of(context).pop();
                      widget.onFiltersChanged?.call();
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAmountRangeFilterDialog() {
    // Implementation for amount range filter
    // This could include min/max amount inputs
  }

  void _showCustomDateRangePicker() async {
    Navigator.of(context).pop(); // Close current dialog
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: ref.read(transactionDateRangeFilterProvider),
    );

    if (picked != null) {
      ref.read(transactionDateRangeFilterProvider.notifier).state = picked;
      widget.onFiltersChanged?.call();
    }
  }

  void _setDateRangeFilter(DateTimeRange range) {
    Navigator.of(context).pop();
    ref.read(transactionDateRangeFilterProvider.notifier).state = range;
    widget.onFiltersChanged?.call();
  }

  void _clearAllFilters() {
    ref.read(transactionTypeFilterProvider.notifier).state = null;
    ref.read(transactionDateRangeFilterProvider.notifier).state = null;
    ref.read(transactionCategoryFilterProvider.notifier).state = null;
    ref.read(transactionAccountFilterProvider.notifier).state = null;
    widget.onFiltersChanged?.call();
  }

  void _clearTypeFilter() {
    ref.read(transactionTypeFilterProvider.notifier).state = null;
    widget.onFiltersChanged?.call();
  }

  void _clearDateRangeFilter() {
    ref.read(transactionDateRangeFilterProvider.notifier).state = null;
    widget.onFiltersChanged?.call();
  }

  void _clearCategoryFilter() {
    ref.read(transactionCategoryFilterProvider.notifier).state = null;
    widget.onFiltersChanged?.call();
  }

  void _clearAccountFilter() {
    ref.read(transactionAccountFilterProvider.notifier).state = null;
    widget.onFiltersChanged?.call();
  }

  DateTimeRange _getTodayRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: today, end: today);
  }

  DateTimeRange _getThisWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return DateTimeRange(start: startOfWeek, end: endOfWeek);
  }

  DateTimeRange _getThisMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return DateTimeRange(start: startOfMonth, end: endOfMonth);
  }

  DateTimeRange _getLastMonthRange() {
    final now = DateTime.now();
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);
    return DateTimeRange(start: startOfLastMonth, end: endOfLastMonth);
  }

  String _formatDateRange(DateTimeRange range) {
    final formatter = DateFormat.MMMd();
    if (range.start == range.end) {
      return formatter.format(range.start);
    }
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  String _getTypeDisplayName(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'transactions.income'.tr();
      case TransactionType.expense:
        return 'transactions.expense'.tr();
      case TransactionType.transfer:
        return 'transactions.transfer'.tr();
    }
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_upward;
      case TransactionType.expense:
        return Icons.arrow_downward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments;
      case AccountType.checking:
        return Icons.account_balance;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.loan:
        return Icons.money_off;
      case AccountType.other:
        return Icons.account_balance_wallet;
    }
  }
}