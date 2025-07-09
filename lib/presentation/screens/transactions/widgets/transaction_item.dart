// lib/presentation/screens/transactions/widgets/transaction_item.dart
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
import '../../../widgets/common/currency_display_widget.dart';

class TransactionItem extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onLongPress;
  final bool showAccount;
  final bool showCategory;
  final bool showActions;
  final bool compact;
  final bool isSelectable;
  final bool isSelected;

  TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onLongPress,
    this.showAccount = true,
    this.showCategory = true,
    this.showActions = true,
    this.compact = false,
    this.isSelectable = false,
    this.isSelected = false,
  });
  final ShadPopoverController _moreActionsController = ShadPopoverController();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Padding(
              padding: EdgeInsets.all(
                  compact ? AppDimensions.paddingM : AppDimensions.paddingL),
              child: Row(
                children: [
                  // Selection indicator
                  if (isSelectable) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.withOpacity(0.4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                  ],

                  // Transaction Icon
                  _buildTransactionIcon(ref),
                  const SizedBox(width: AppDimensions.spacingM),

                  // Transaction Details
                  Expanded(
                    child: _buildTransactionInfo(ref),
                  ),

                  // Amount and Actions
                  _buildTrailingSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(WidgetRef ref) {
    final Color iconColor;
    final IconData iconData;
    final Color backgroundColor;

    switch (transaction.type) {
      case TransactionType.income:
        iconColor = AppColors.income;
        iconData = Icons.arrow_upward_rounded;
        backgroundColor = AppColors.income.withOpacity(0.1);
        break;
      case TransactionType.expense:
        iconColor = AppColors.expense;
        iconData = Icons.arrow_downward_rounded;
        backgroundColor = AppColors.expense.withOpacity(0.1);
        break;
      case TransactionType.transfer:
        iconColor = AppColors.transfer;
        iconData = Icons.swap_horiz_rounded;
        backgroundColor = AppColors.transfer.withOpacity(0.1);
        break;
    }

    return Container(
      width: compact ? 36 : 44,
      height: compact ? 36 : 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: compact ? 18 : 20,
      ),
    );
  }

  Widget _buildTransactionInfo(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category or Notes
        Row(
          children: [
            Expanded(
              child: Text(
                _getCategoryDisplayName(ref),
                style: TextStyle(
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 2),

        // Date and account info
        Row(
          children: [
            Text(
              DateFormat('MMM dd').format(transaction.date),
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showAccount && transaction.accountId != null) ...[
              Text(
                ' • ',
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  color: Colors.grey[400],
                ),
              ),
              Expanded(
                child: _buildAccountName(ref),
              ),
            ],
          ],
        ),

        // Notes (if available and space allows)
        if (!compact &&
            transaction.notes != null &&
            transaction.notes!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            transaction.notes!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildTrailingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Amount
        CurrencyDisplayWidget(
          amount: transaction.amount,
          style: TextStyle(
            fontSize: compact ? 15 : 16,
            fontWeight: FontWeight.w700,
            color: _getAmountColor(),
          ),
          autoColor: false,
        ),

        // Actions menu (if enabled)
        if (showActions && !isSelectable) ...[
          const SizedBox(height: 4),
          _buildActionsButton(context),
        ],
      ],
    );
  }

  Widget _buildActionsButton(BuildContext context) {
    return ShadPopover(
      controller: _moreActionsController,
      popover: (context) => _buildActionsMenu(context),
      child: IconButton(
        onPressed: () {},
        icon: Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: Colors.grey[400],
        ),
        iconSize: 16,
        constraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return ShadCard(
      width: 160,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionMenuItem(
            icon: Icons.edit_rounded,
            title: 'common.edit'.tr(),
            onTap: onEdit,
          ),
          _buildActionMenuItem(
            icon: Icons.copy_rounded,
            title: 'common.duplicate'.tr(),
            onTap: onDuplicate,
          ),
          _buildActionMenuItem(
            icon: Icons.delete_rounded,
            title: 'common.delete'.tr(),
            onTap: onDelete,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isDestructive ? AppColors.error : null,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isDestructive ? AppColors.error : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountName(WidgetRef ref) {
    if (transaction.accountId == null) {
      return const SizedBox.shrink();
    }

    final accountAsync = ref.watch(accountProvider(transaction.accountId!));

    return accountAsync.when(
      data: (account) => Text(
        account?.name ?? 'Unknown Account',
        style: TextStyle(
          fontSize: compact ? 12 : 13,
          color: Colors.grey[600],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      loading: () => const SizedBox(
        width: 60,
        height: 12,
        child: LoadingWidget(),
      ),
      error: (_, __) => Text(
        'Unknown Account',
        style: TextStyle(
          fontSize: compact ? 12 : 13,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(WidgetRef ref) {
    if (transaction.categoryId == null) {
      return transaction.notes ?? 'Uncategorized';
    }

    final categoryAsync = ref.watch(categoryProvider(transaction.categoryId!));

    return categoryAsync.when(
      data: (category) => category?.name ?? 'Uncategorized',
      loading: () => 'Loading...',
      error: (_, __) => 'Uncategorized',
    );
  }

  Color _getAmountColor() {
    switch (transaction.type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }
}
