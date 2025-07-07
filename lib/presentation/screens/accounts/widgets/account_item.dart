import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../data/models/account.dart';
import '../../../providers/account_provider.dart';
import '../../../widgets/common/loading_widget.dart';

class AccountItem extends ConsumerWidget {
  final Account account;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTransfer;
  final bool showBalance;
  final bool showActions;
  final bool showSubtitle;
  final bool isSelectable;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AccountItem({
    super.key,
    required this.account,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onTransfer,
    this.showBalance = true,
    this.showActions = true,
    this.showSubtitle = true,
    this.isSelectable = false,
    this.isSelected = false,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final balanceAsync = ref.watch(accountBalanceProvider(account.id));

    return Container(
      margin: margin,
      child: ShadCard(
        padding: const EdgeInsets.all(AppDimensions.paddingS),
        backgroundColor:
            isSelected ? theme.colorScheme.accent.withOpacity(0.1) : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              children: [
                // Account Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: account.color != null
                        ? Color(account.color!)
                        : _getAccountTypeColor(account.type),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    _getAccountTypeIcon(account.type),
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: AppDimensions.spacingM),

                // Account Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Name
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              account.name,
                              style: theme.textTheme.h4,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Status indicators
                          if (!account.isActive) ...[
                            const SizedBox(width: AppDimensions.spacingS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.spacingS,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusXs),
                              ),
                              child: Text(
                                'Inactive',
                                style: theme.textTheme.small.copyWith(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],

                          if (isSelectable)
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.mutedForeground,
                              size: 20,
                            ),
                        ],
                      ),

                      if (showSubtitle) ...[
                        const SizedBox(height: AppDimensions.spacingXs),
                        Row(
                          children: [
                            Text(
                              'accounts.types.${account.type.name}'.tr(),
                              style: theme.textTheme.muted,
                            ),
                            if (account.bankName != null) ...[
                              Text(
                                ' • ${account.bankName}',
                                style: theme.textTheme.muted,
                              ),
                            ],
                            if (account.accountNumber != null) ...[
                              Text(
                                ' ••••${account.accountNumber}',
                                style: theme.textTheme.muted,
                              ),
                            ],
                          ],
                        ),
                      ],

                      if (showBalance) ...[
                        const SizedBox(height: AppDimensions.spacingS),
                        balanceAsync.when(
                          loading: () => const ShimmerLoading(
                            child: SkeletonLoader(height: 16, width: 80),
                          ),
                          error: (error, _) => Text(
                            'Error loading balance',
                            style: theme.textTheme.small.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          data: (balance) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatCurrency(balance, account.currency),
                                style: theme.textTheme.h3.copyWith(
                                  color:
                                      _getBalanceColor(balance, account.type),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              // Available balance for credit cards
                              if (account.type == AccountType.creditCard &&
                                  account.creditLimit != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${'accounts.availableBalance'.tr()}: ${_formatCurrency(account.availableBalance, account.currency)}',
                                  style: theme.textTheme.small.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                if (showActions && !isSelectable) ...[
                  const SizedBox(width: AppDimensions.spacingS),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'transfer':
                          onTransfer?.call();
                          break;
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (onTransfer != null)
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
                      if (onEdit != null)
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
                      if (onDelete != null)
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
                    child: ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      child: const Icon(Icons.more_vert, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAccountTypeColor(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return AppColors.success;
      case AccountType.checking:
        return AppColors.primary;
      case AccountType.savings:
        return AppColors.secondary;
      case AccountType.creditCard:
        return AppColors.warning;
      case AccountType.investment:
        return AppColors.accent;
      case AccountType.loan:
        return AppColors.error;
      case AccountType.other:
        return AppColors.categoryColors[0];
    }
  }

  IconData _getAccountTypeIcon(AccountType type) {
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

  Color _getBalanceColor(double balance, AccountType type) {
    if (type == AccountType.creditCard || type == AccountType.loan) {
      return balance <= 0 ? AppColors.success : AppColors.error;
    }
    return balance >= 0 ? AppColors.success : AppColors.error;
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

/// Compact version for use in dropdowns or selection lists
class AccountItemCompact extends ConsumerWidget {
  final Account account;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showBalance;

  const AccountItemCompact({
    super.key,
    required this.account,
    this.onTap,
    this.isSelected = false,
    this.showBalance = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final balanceAsync = ref.watch(accountBalanceProvider(account.id));

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        child: Row(
          children: [
            // Account Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: account.color != null
                    ? Color(account.color!)
                    : _getAccountTypeColor(account.type),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              ),
              child: Icon(
                _getAccountTypeIcon(account.type),
                color: Colors.white,
                size: 16,
              ),
            ),

            const SizedBox(width: AppDimensions.spacingS),

            // Account Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: theme.textTheme.p,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showBalance)
                    balanceAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (balance) => Text(
                        _formatCurrency(balance, account.currency),
                        style: theme.textTheme.small.copyWith(
                          color: _getBalanceColor(balance, account.type),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (isSelected)
              const Icon(
                Icons.check,
                color: AppColors.success,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Color _getAccountTypeColor(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return AppColors.success;
      case AccountType.checking:
        return AppColors.primary;
      case AccountType.savings:
        return AppColors.secondary;
      case AccountType.creditCard:
        return AppColors.warning;
      case AccountType.investment:
        return AppColors.accent;
      case AccountType.loan:
        return AppColors.error;
      case AccountType.other:
        return AppColors.categoryColors[0];
    }
  }

  IconData _getAccountTypeIcon(AccountType type) {
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

  Color _getBalanceColor(double balance, AccountType type) {
    if (type == AccountType.creditCard || type == AccountType.loan) {
      return balance <= 0 ? AppColors.success : AppColors.error;
    }
    return balance >= 0 ? AppColors.success : AppColors.error;
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
