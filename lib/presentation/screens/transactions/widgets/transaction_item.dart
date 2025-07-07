import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/transaction.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../widgets/common/loading_widget.dart';

class TransactionItem extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final bool showAccount;
  final bool showCategory;
  final bool showActions;
  final bool compact;
  final bool isSelectable;
  final bool isSelected;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.showAccount = true,
    this.showCategory = true,
    this.showActions = true,
    this.compact = false,
    this.isSelectable = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: EdgeInsets.all(
            compact ? AppDimensions.paddingS : AppDimensions.paddingM,
          ),
          child: Row(
            children: [
              // Selection indicator
              if (isSelectable) ...[
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? AppColors.primary : AppColors.lightDisabled,
                  size: compact ? 20 : 24,
                ),
                SizedBox(width: compact ? AppDimensions.spacingS : AppDimensions.spacingM),
              ],

              // Transaction Icon/Category
              _buildTransactionIcon(ref),
              SizedBox(width: compact ? AppDimensions.spacingS : AppDimensions.spacingM),

              // Transaction Details
              Expanded(
                child: _buildTransactionInfo(ref, theme),
              ),

              // Amount and Actions
              _buildTrailingSection(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(WidgetRef ref) {
    if (transaction.type == TransactionType.transfer) {
      return Container(
        width: compact ? 36 : 48,
        height: compact ? 36 : 48,
        decoration: BoxDecoration(
          color: AppColors.transfer,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: Icon(
          Icons.swap_horiz,
          color: Colors.white,
          size: compact ? 18 : 24,
        ),
      );
    }

    // For income/expense, show category icon
    final categoryAsync = ref.watch(categoryProvider(transaction.categoryId));
    
    return categoryAsync.when(
      loading: () => ShimmerLoading(
        child: SkeletonLoader(
          width: compact ? 36 : 48,
          height: compact ? 36 : 48,
        ),
      ),
      error: (_, __) => Container(
        width: compact ? 36 : 48,
        height: compact ? 36 : 48,
        decoration: BoxDecoration(
          color: AppColors.lightDisabled,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: Icon(
          Icons.category,
          color: Colors.white,
          size: compact ? 18 : 24,
        ),
      ),
      data: (category) {
        final color = category != null 
            ? Color(category.color)
            : _getTransactionTypeColor(transaction.type);
        
        final icon = category != null
            ? _getIconData(category.iconName)
            : _getTransactionTypeIcon(transaction.type);

        return Container(
          width: compact ? 36 : 48,
          height: compact ? 36 : 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: compact ? 18 : 24,
          ),
        );
      },
    );
  }

  Widget _buildTransactionInfo(WidgetRef ref, ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Transaction description/category name
        Row(
          children: [
            Expanded(
              child: _buildTransactionTitle(ref, theme),
            ),
            if (!compact && transaction.imagePath != null) ...[
              const SizedBox(width: AppDimensions.spacingXs),
              Icon(
                Icons.attachment,
                size: 16,
                color: theme.colorScheme.mutedForeground,
              ),
            ],
          ],
        ),

        // Secondary info (account, date, notes)
        if (!compact) ...[
          const SizedBox(height: 4),
          _buildSecondaryInfo(ref, theme),
        ],

        // Notes (if available and not compact)
        if (!compact && transaction.notes != null && transaction.notes!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            transaction.notes!,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildTransactionTitle(WidgetRef ref, ShadThemeData theme) {
    if (transaction.type == TransactionType.transfer) {
      final fromAccountAsync = ref.watch(accountProvider(transaction.accountId));
      final toAccountAsync = transaction.transferToAccountId != null
          ? ref.watch(accountProvider(transaction.transferToAccountId!))
          : null;

      return Row(
        children: [
          Expanded(
            child: Text(
              'transactions.transfer'.tr(),
              style: compact
                  ? theme.textTheme.p.copyWith(fontWeight: FontWeight.w600)
                  : theme.textTheme.h4,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!compact && fromAccountAsync != null && toAccountAsync != null) ...[
            fromAccountAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (fromAccount) => toAccountAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (toAccount) => Text(
                  '${fromAccount?.name ?? 'Unknown'} → ${toAccount?.name ?? 'Unknown'}',
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // For income/expense, show category name
    final categoryAsync = ref.watch(categoryProvider(transaction.categoryId));
    
    return categoryAsync.when(
      loading: () => ShimmerLoading(
        child: SkeletonLoader(
          height: compact ? 16 : 20,
          width: 100,
        ),
      ),
      error: (_, __) => Text(
        'transactions.unknownCategory'.tr(),
        style: compact
            ? theme.textTheme.p.copyWith(fontWeight: FontWeight.w600)
            : theme.textTheme.h4,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      data: (category) => Text(
        category?.name ?? 'transactions.unknownCategory'.tr(),
        style: compact
            ? theme.textTheme.p.copyWith(fontWeight: FontWeight.w600)
            : theme.textTheme.h4,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSecondaryInfo(WidgetRef ref, ShadThemeData theme) {
    final List<Widget> infoWidgets = [];

    // Account info (if showing account and not transfer)
    if (showAccount && transaction.type != TransactionType.transfer) {
      final accountAsync = ref.watch(accountProvider(transaction.accountId));
      accountAsync.when(
        loading: () => infoWidgets.add(
          const ShimmerLoading(
            child: SkeletonLoader(height: 12, width: 60),
          ),
        ),
        error: (_, __) => infoWidgets.add(
          Text(
            'transactions.unknownAccount'.tr(),
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ),
        data: (account) => infoWidgets.add(
          Text(
            account?.name ?? 'transactions.unknownAccount'.tr(),
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ),
      );
    }

    // Date
    infoWidgets.add(
      Text(
        _formatTransactionDate(transaction.date),
        style: theme.textTheme.small.copyWith(
          color: theme.colorScheme.mutedForeground,
        ),
      ),
    );

    return Wrap(
      spacing: AppDimensions.spacingS,
      children: infoWidgets.map((widget) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget,
          if (widget != infoWidgets.last) ...[
            const SizedBox(width: AppDimensions.spacingXs),
            Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(
                color: theme.colorScheme.mutedForeground,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      )).toList(),
    );
  }

  Widget _buildTrailingSection(BuildContext context, ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Amount
        Text(
          _formatTransactionAmount(),
          style: compact
              ? theme.textTheme.p.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getTransactionTypeColor(transaction.type),
                )
              : theme.textTheme.h4.copyWith(
                  color: _getTransactionTypeColor(transaction.type),
                ),
        ),

        // Actions menu (if not compact and actions enabled)
        if (!compact && showActions) ...[
          const SizedBox(height: AppDimensions.spacingXs),
          ShadPopover(
            popover: (context) => _buildActionsPopover(context),
            child: ShadButton.ghost(
              size: ShadButtonSize.sm,
              onPressed: () {},
              child: const Icon(Icons.more_horiz, size: 18),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionsPopover(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          ListTile(
            leading: const Icon(Icons.edit, size: 18),
            title: Text('common.edit'.tr()),
            onTap: () {
              Navigator.of(context).pop();
              onEdit?.call();
            },
          ),
        if (onDuplicate != null)
          ListTile(
            leading: const Icon(Icons.copy, size: 18),
            title: Text('transactions.duplicate'.tr()),
            onTap: () {
              Navigator.of(context).pop();
              onDuplicate?.call();
            },
          ),
        if (onDelete != null)
          ListTile(
            leading: const Icon(Icons.delete, size: 18, color: AppColors.error),
            title: Text(
              'common.delete'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
          ),
      ],
    );
  }

  String _formatTransactionAmount() {
    String prefix = '';
    if (transaction.type == TransactionType.income) {
      prefix = '+';
    } else if (transaction.type == TransactionType.expense) {
      prefix = '-';
    }

    return '$prefix${CurrencyFormatter.format(
      transaction.amount,
      currency: transaction.currency,
    )}';
  }

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'transactions.today'.tr();
    } else if (transactionDate == yesterday) {
      return 'transactions.yesterday'.tr();
    } else if (now.difference(date).inDays < 7) {
      return DateFormat.E().format(date); // Day of week
    } else {
      return DateFormat.MMMd().format(date); // Month and day
    }
  }

  Color _getTransactionTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }

  IconData _getTransactionTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_upward;
      case TransactionType.expense:
        return Icons.arrow_downward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  IconData _getIconData(String iconName) {
    // This should match your existing icon mapping logic
    switch (iconName) {
      case 'category':
        return Icons.category;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'movie':
        return Icons.movie;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'business_center':
        return Icons.business_center;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }
}