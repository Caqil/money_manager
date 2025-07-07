import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/account.dart';
import '../../../providers/account_provider.dart';
import '../../../widgets/common/loading_widget.dart';

class AccountSelector extends ConsumerStatefulWidget {
  final String? selectedAccountId;
  final Function(Account?) onAccountSelected;
  final String? label;
  final String? placeholder;
  final bool enabled;
  final bool showBalance;
  final bool required;
  final List<String>? excludeAccountIds;
  final AccountType? filterByType;
  final String? errorText;

  const AccountSelector({
    super.key,
    this.selectedAccountId,
    required this.onAccountSelected,
    this.label,
    this.placeholder,
    this.enabled = true,
    this.showBalance = true,
    this.required = false,
    this.excludeAccountIds,
    this.filterByType,
    this.errorText,
  });

  @override
  ConsumerState<AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends ConsumerState<AccountSelector> {
  Account? _selectedAccount;

  @override
  void initState() {
    super.initState();
    if (widget.selectedAccountId != null) {
      _loadSelectedAccount();
    }
  }

  @override
  void didUpdateWidget(AccountSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAccountId != oldWidget.selectedAccountId) {
      if (widget.selectedAccountId != null) {
        _loadSelectedAccount();
      } else {
        setState(() {
          _selectedAccount = null;
        });
      }
    }
  }

  void _loadSelectedAccount() {
    if (widget.selectedAccountId != null) {
      final accountAsync = ref.read(accountProvider(widget.selectedAccountId!));
      accountAsync.whenData((account) {
        if (mounted && account != null) {
          setState(() {
            _selectedAccount = account;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final activeAccountsAsync = ref.watch(activeAccountsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: theme.textTheme.h4,
              ),
              if (widget.required)
                Text(
                  ' *',
                  style: theme.textTheme.h4.copyWith(
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
        ],
        activeAccountsAsync.when(
          loading: () => _buildLoadingSelector(theme),
          error: (error, _) => _buildErrorSelector(theme, error),
          data: (accounts) => _buildAccountSelector(theme, accounts),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            widget.errorText!,
            style: theme.textTheme.small.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingSelector(ShadThemeData theme) {
    return const ShimmerLoading(
      child: SkeletonLoader(
        height: 48,
        width: double.infinity,
      ),
    );
  }

  Widget _buildErrorSelector(ShadThemeData theme, Object error) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.error),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              'accounts.errorLoadingAccounts'.tr(),
              style: theme.textTheme.small.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: () => ref.invalidate(activeAccountsProvider),
            child: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSelector(ShadThemeData theme, List<Account> allAccounts) {
    // Filter accounts based on criteria
    final filteredAccounts = _filterAccounts(allAccounts);

    if (filteredAccounts.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ShadSelectFormField<String>(
      enabled: widget.enabled,
      placeholder: Text(widget.placeholder ?? 'forms.selectAccount'.tr()),
      options: filteredAccounts
          .map((account) => ShadOption(
                value: account.id,
                child: _buildAccountOption(account),
              ))
          .toList(),
      selectedOptionBuilder: (context, value) {
        if (value == null) {
          return Text(widget.placeholder ?? 'forms.selectAccount'.tr());
        }
        final account = filteredAccounts.firstWhere((acc) => acc.id == value);
        return _buildSelectedAccountDisplay(account);
      },
      onChanged: widget.enabled
          ? (String? accountId) {
              final account = accountId != null
                  ? filteredAccounts.firstWhere((acc) => acc.id == accountId)
                  : null;
              setState(() {
                _selectedAccount = account;
              });
              widget.onAccountSelected(account);
            }
          : null,
      initialValue: widget.selectedAccountId,
    );
  }

  Widget _buildAccountOption(Account account) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXs),
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

          // Account Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.showBalance) ...[
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(
                      account.balance,
                      currency: account.currency,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.lightOnSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Status indicator
          if (!account.isActive)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              ),
              child: Text(
                'common.inactive'.tr(),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedAccountDisplay(Account account) {
    return Row(
      children: [
        // Account Icon
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: account.color != null
                ? Color(account.color!)
                : _getAccountTypeColor(account.type),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
          ),
          child: Icon(
            _getAccountTypeIcon(account.type),
            color: Colors.white,
            size: 12,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),

        // Account Name
        Expanded(
          child: Text(
            account.name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Balance (if showing)
        if (widget.showBalance)
          Text(
            CurrencyFormatter.format(
              account.balance,
              currency: account.currency,
            ),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.lightOnSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.lightDisabled,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              'accounts.noAccountsAvailable'.tr(),
              style: theme.textTheme.small.copyWith(
                color: AppColors.lightDisabled,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Account> _filterAccounts(List<Account> accounts) {
    return accounts.where((account) {
      // Exclude specified accounts
      if (widget.excludeAccountIds?.contains(account.id) == true) {
        return false;
      }

      // Filter by type if specified
      if (widget.filterByType != null && account.type != widget.filterByType) {
        return false;
      }

      // Only show active accounts by default
      if (!account.isActive) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
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
}
