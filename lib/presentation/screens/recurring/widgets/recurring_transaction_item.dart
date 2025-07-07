import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../data/models/recurring_transaction.dart';
import '../../../../data/models/transaction.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/common/currency_display_widget.dart';

class RecurringTransactionItem extends ConsumerWidget {
  final RecurringTransaction recurringTransaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;
  final VoidCallback? onExecuteNow;
  final bool showActions;
  final bool compact;

  const RecurringTransactionItem({
    super.key,
    required this.recurringTransaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
    this.onExecuteNow,
    this.showActions = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final currency = ref.watch(baseCurrencyProvider);
    
    return ShadCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppDimensions.paddingM : AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, currency),
              if (!compact) ...[
                const SizedBox(height: AppDimensions.spacingM),
                _buildDetails(theme, ref),
                const SizedBox(height: AppDimensions.spacingM),
                _buildScheduleInfo(theme),
                if (showActions) ...[
                  const SizedBox(height: AppDimensions.spacingM),
                  _buildActions(theme),
                ],
              ] else ...[
                const SizedBox(height: AppDimensions.spacingS),
                _buildCompactInfo(theme, ref),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ShadThemeData theme, String currency) {
    return Row(
      children: [
        // Transaction icon
        Container(
          width: compact ? 40 : 48,
          height: compact ? 40 : 48,
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            _getTypeIcon(),
            color: _getTypeColor(),
            size: compact ? 20 : 24,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        
        // Transaction info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recurringTransaction.name,
                      style: (compact ? theme.textTheme.p : theme.textTheme.h4).copyWith(
                        fontWeight: FontWeight.w600,
                        color: !recurringTransaction.isActive 
                            ? theme.colorScheme.mutedForeground 
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!recurringTransaction.isActive) ...[
                    const SizedBox(width: AppDimensions.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mutedForeground.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                      ),
                      child: Text(
                        'recurring.inactive'.tr(),
                        style: theme.textTheme.small.copyWith(
                          color: AppColors.mutedForeground,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  _buildFrequencyChip(theme),
                  const SizedBox(width: AppDimensions.spacingS),
                  if (_isDueOrOverdue())
                    _buildDueChip(theme),
                ],
              ),
            ],
          ),
        ),
        
        // Amount
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CurrencyDisplayMedium(
              amount: recurringTransaction.amount,
              currency: currency,
              autoColor: true,
            ),
            if (!compact && recurringTransaction.nextExecution != null) ...[
              const SizedBox(height: 2),
              Text(
                _getNextExecutionText(),
                style: theme.textTheme.small.copyWith(
                  color: _getNextExecutionColor(theme),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencyChip(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
      ),
      child: Text(
        _getFrequencyDisplayText(),
        style: theme.textTheme.small.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDueChip(ShadThemeData theme) {
    final isOverdue = _isOverdue();
    final chipColor = isOverdue ? AppColors.error : AppColors.warning;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning : Icons.schedule,
            size: 10,
            color: chipColor,
          ),
          const SizedBox(width: 2),
          Text(
            isOverdue ? 'recurring.overdue'.tr() : 'recurring.due'.tr(),
            style: theme.textTheme.small.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(ShadThemeData theme, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account and category info
        Row(
          children: [
            Expanded(
              child: _buildAccountInfo(ref, theme),
            ),
            if (recurringTransaction.type != TransactionType.transfer) ...[
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: _buildCategoryInfo(ref, theme),
              ),
            ],
          ],
        ),
        
        // Transfer destination (if transfer)
        if (recurringTransaction.type == TransactionType.transfer &&
            recurringTransaction.transferToAccountId != null) ...[
          const SizedBox(height: AppDimensions.spacingS),
          _buildTransferInfo(ref, theme),
        ],
        
        // Notes
        if (recurringTransaction.notes != null && recurringTransaction.notes!.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            recurringTransaction.notes!,
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

  Widget _buildAccountInfo(WidgetRef ref, ShadThemeData theme) {
    final accountAsync = ref.watch(accountProvider(recurringTransaction.accountId));
    
    return accountAsync.when(
      data: (account) => Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 14,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              account?.name ?? 'Unknown Account',
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      loading: () => const SizedBox(height: 18),
      error: (_, __) => Text(
        'Error loading account',
        style: theme.textTheme.small.copyWith(
          color: AppColors.error,
        ),
      ),
    );
  }

  Widget _buildCategoryInfo(WidgetRef ref, ShadThemeData theme) {
    final categoryAsync = ref.watch(categoryProvider(recurringTransaction.categoryId));
    
    return categoryAsync.when(
      data: (category) => Row(
        children: [
          Icon(
            Icons.category,
            size: 14,
            color: category != null ? Color(category.color) : theme.colorScheme.mutedForeground,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              category?.name ?? 'Unknown Category',
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      loading: () => const SizedBox(height: 18),
      error: (_, __) => Text(
        'Error loading category',
        style: theme.textTheme.small.copyWith(
          color: AppColors.error,
        ),
      ),
    );
  }

  Widget _buildTransferInfo(WidgetRef ref, ShadThemeData theme) {
    final toAccountAsync = ref.watch(accountProvider(recurringTransaction.transferToAccountId!));
    
    return toAccountAsync.when(
      data: (toAccount) => Row(
        children: [
          Icon(
            Icons.arrow_forward,
            size: 14,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(width: 4),
          Text(
            'recurring.transferTo'.tr(args: [toAccount?.name ?? 'Unknown Account']),
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ),
      loading: () => const SizedBox(height: 18),
      error: (_, __) => Text(
        'Error loading transfer account',
        style: theme.textTheme.small.copyWith(
          color: AppColors.error,
        ),
      ),
    );
  }

  Widget _buildScheduleInfo(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  'recurring.schedule'.tr(),
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'recurring.startDate'.tr(),
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().format(recurringTransaction.startDate),
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (recurringTransaction.endDate != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'recurring.endDate'.tr(),
                        style: theme.textTheme.small.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd().format(recurringTransaction.endDate!),
                        style: theme.textTheme.small.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (recurringTransaction.nextExecution != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'recurring.nextExecution'.tr(),
                        style: theme.textTheme.small.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        DateFormat.yMMMd().format(recurringTransaction.nextExecution!),
                        style: theme.textTheme.small.copyWith(
                          fontWeight: FontWeight.w500,
                          color: _getNextExecutionColor(theme),
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          if (recurringTransaction.lastExecuted != null) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'recurring.lastExecuted'.tr(args: [
                    DateFormat.yMMMd().format(recurringTransaction.lastExecuted!)
                  ]),
                  style: theme.textTheme.small.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactInfo(ShadThemeData theme, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _buildAccountInfo(ref, theme),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        if (recurringTransaction.nextExecution != null)
          Text(
            _getNextExecutionText(),
            style: theme.textTheme.small.copyWith(
              color: _getNextExecutionColor(theme),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildActions(ShadThemeData theme) {
    return Row(
      children: [
        if (onExecuteNow != null && recurringTransaction.isActive) ...[
          ShadButton.outline(
            onPressed: onExecuteNow,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow, size: 16),
                const SizedBox(width: AppDimensions.spacingXs),
                Text('recurring.executeNow'.tr()),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
        ],
        
        if (onToggleActive != null) ...[
          ShadButton.outline(
            onPressed: onToggleActive,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  recurringTransaction.isActive ? Icons.pause : Icons.play_arrow,
                  size: 16,
                ),
                const SizedBox(width: AppDimensions.spacingXs),
                Text(recurringTransaction.isActive 
                    ? 'recurring.pause'.tr()
                    : 'recurring.resume'.tr()),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
        ],
        
        const Spacer(),
        
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'recurring.editRecurring'.tr(),
          ),
        
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'recurring.deleteRecurring'.tr(),
          ),
      ],
    );
  }

  IconData _getTypeIcon() {
    switch (recurringTransaction.type) {
      case TransactionType.income:
        return Icons.trending_up;
      case TransactionType.expense:
        return Icons.trending_down;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  Color _getTypeColor() {
    switch (recurringTransaction.type) {
      case TransactionType.income:
        return AppColors.success;
      case TransactionType.expense:
        return AppColors.error;
      case TransactionType.transfer:
        return AppColors.primary;
    }
  }

  String _getFrequencyDisplayText() {
    final frequency = recurringTransaction.frequency;
    final interval = recurringTransaction.intervalValue;
    
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return interval == 1 ? 'Daily' : 'Every $interval days';
      case RecurrenceFrequency.weekly:
        return interval == 1 ? 'Weekly' : 'Every $interval weeks';
      case RecurrenceFrequency.monthly:
        return interval == 1 ? 'Monthly' : 'Every $interval months';
      case RecurrenceFrequency.quarterly:
        return interval == 1 ? 'Quarterly' : 'Every $interval quarters';
      case RecurrenceFrequency.yearly:
        return interval == 1 ? 'Yearly' : 'Every $interval years';
      case RecurrenceFrequency.custom:
        return 'Custom';
    }
  }

  bool _isDueOrOverdue() {
    if (!recurringTransaction.isActive || recurringTransaction.nextExecution == null) {
      return false;
    }
    
    final now = DateTime.now();
    return recurringTransaction.nextExecution!.isBefore(now) ||
           recurringTransaction.nextExecution!.isAtSameMomentAs(now);
  }

  bool _isOverdue() {
    if (!recurringTransaction.isActive || recurringTransaction.nextExecution == null) {
      return false;
    }
    
    final now = DateTime.now();
    return recurringTransaction.nextExecution!.isBefore(now);
  }

  String _getNextExecutionText() {
    if (recurringTransaction.nextExecution == null) {
      return 'recurring.noNextExecution'.tr();
    }
    
    final now = DateTime.now();
    final nextExecution = recurringTransaction.nextExecution!;
    final difference = nextExecution.difference(now).inDays;
    
    if (difference < 0) {
      return 'recurring.overdue'.tr();
    } else if (difference == 0) {
      return 'recurring.dueToday'.tr();
    } else if (difference == 1) {
      return 'recurring.dueTomorrow'.tr();
    } else {
      return 'recurring.dueInDays'.tr(args: [difference.toString()]);
    }
  }

  Color _getNextExecutionColor(ShadThemeData theme) {
    if (recurringTransaction.nextExecution == null) {
      return theme.colorScheme.mutedForeground;
    }
    
    final now = DateTime.now();
    final nextExecution = recurringTransaction.nextExecution!;
    final difference = nextExecution.difference(now).inDays;
    
    if (difference < 0) {
      return AppColors.error;
    } else if (difference <= 1) {
      return AppColors.warning;
    } else {
      return theme.colorScheme.mutedForeground;
    }
  }
}

// Compact version for lists
class CompactRecurringTransactionItem extends StatelessWidget {
  final RecurringTransaction recurringTransaction;
  final VoidCallback? onTap;

  const CompactRecurringTransactionItem({
    super.key,
    required this.recurringTransaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RecurringTransactionItem(
      recurringTransaction: recurringTransaction,
      onTap: onTap,
      compact: true,
      showActions: false,
    );
  }
}