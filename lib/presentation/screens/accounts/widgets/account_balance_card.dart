import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../data/models/account.dart';
import '../../../providers/account_provider.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/common/loading_widget.dart';

class AccountBalanceCard extends ConsumerWidget {
  final Account account;
  final bool showDetails;
  final bool showActions;
  final VoidCallback? onTap;
  final VoidCallback? onTransferTap;
  final VoidCallback? onEditTap;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const AccountBalanceCard({
    super.key,
    required this.account,
    this.showDetails = true,
    this.showActions = false,
    this.onTap,
    this.onTransferTap,
    this.onEditTap,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final balanceAsync = ref.watch(accountBalanceProvider(account.id));
    final availableBalanceAsync =
        ref.watch(availableBalanceProvider(account.id));

    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(AppDimensions.spacingS),
      child: ShadCard(
        padding: const EdgeInsets.all(AppDimensions.paddingS),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Header
                Row(
                  children: [
                    // Account Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: account.color != null
                            ? Color(account.color!)
                            : _getAccountTypeColor(account.type),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Icon(
                        _getAccountTypeIcon(account.type),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    // Account Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: theme.textTheme.h4,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (showDetails) ...[
                            SizedBox(height: AppDimensions.spacingXs),
                            Text(
                              'accounts.types.${account.type.name}'.tr(),
                              style: theme.textTheme.muted,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Status indicator
                    if (!account.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingS,
                          vertical: AppDimensions.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusXs),
                        ),
                        child: Text(
                          'common.disable'.tr(),
                          style: theme.textTheme.small.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),

                if (showDetails) ...[
                  const SizedBox(height: AppDimensions.spacingM),

                  // Balance Information
                  balanceAsync.when(
                    loading: () => const ShimmerLoading(
                      child: SkeletonLoader(height: 20, width: 100),
                    ),
                    error: (error, _) => CustomErrorWidget(
                      title: 'Error loading balance',
                    ),
                    data: (balance) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Balance
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'accounts.balance'.tr(),
                              style: theme.textTheme.muted,
                            ),
                            Text(
                              _formatCurrency(balance, account.currency),
                              style: theme.textTheme.h3.copyWith(
                                color: _getBalanceColor(balance, account.type),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        // Available Balance (for credit cards)
                        if (account.type == AccountType.creditCard) ...[
                          const SizedBox(height: AppDimensions.spacingS),
                          availableBalanceAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (availableBalance) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'accounts.availableBalance'.tr(),
                                  style: theme.textTheme.muted,
                                ),
                                Text(
                                  _formatCurrency(
                                      availableBalance, account.currency),
                                  style: theme.textTheme.small.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Credit Limit (for credit cards)
                        if (account.type == AccountType.creditCard &&
                            account.creditLimit != null) ...[
                          const SizedBox(height: AppDimensions.spacingS),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'accounts.creditLimit'.tr(),
                                style: theme.textTheme.muted,
                              ),
                              Text(
                                _formatCurrency(
                                    account.creditLimit!, account.currency),
                                style: theme.textTheme.small.copyWith(
                                  color: theme.colorScheme.mutedForeground,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Actions
                if (showActions) ...[
                  const SizedBox(height: AppDimensions.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: ShadButton.outline(
                          onPressed: onTransferTap,
                          size: ShadButtonSize.sm,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.swap_horiz, size: 16),
                              const SizedBox(width: AppDimensions.spacingS),
                              Text('accounts.transferFunds'.tr()),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      ShadButton.outline(
                        onPressed: onEditTap,
                        size: ShadButtonSize.sm,
                        child: const Icon(Icons.edit, size: 16),
                      ),
                    ],
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
