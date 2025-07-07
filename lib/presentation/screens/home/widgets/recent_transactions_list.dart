import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/transaction.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/error_widget.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider(5));

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: AppDimensions.spacingM),

            // Content
            recentTransactionsAsync.when(
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error, ref),
              data: (transactions) => _buildContent(context, transactions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingS),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            Icons.history,
            color: AppColors.primary,
            size: AppDimensions.iconM,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Text(
            'dashboard.recentActivity'.tr(),
            style: theme.textTheme.h4.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ShadButton.outline(
          onPressed: () => context.push('/transactions'),
          size: ShadButtonSize.sm,
          child: Text('common.viewAll'.tr()),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ShimmerLoading(
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index < 2 ? AppDimensions.spacingS : 0,
            ),
            child: const Row(
              children: [
                SkeletonLoader(height: 40, width: 40),
                SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(height: 16, width: 120),
                      SizedBox(height: AppDimensions.spacingXs),
                      SkeletonLoader(height: 12, width: 80),
                    ],
                  ),
                ),
                SkeletonLoader(height: 16, width: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error, WidgetRef ref) {
    return CustomErrorWidget(
      title: 'Error loading transactions',
      message: error.toString(),
      actionText: 'common.retry'.tr(),
      onActionPressed: () => ref.refresh(recentTransactionsProvider(5)),
    );
  }

  Widget _buildContent(BuildContext context, List<Transaction> transactions) {
    final theme = ShadTheme.of(context);

    if (transactions.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        ...transactions.asMap().entries.map((entry) {
          final index = entry.key;
          final transaction = entry.value;
          final isLast = index == transactions.length - 1;

          return Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : AppDimensions.spacingS,
            ),
            child: _buildTransactionItem(context, transaction),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 48,
          color: theme.colorScheme.mutedForeground.withOpacity(0.5),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          'dashboard.noRecentActivity'.tr(),
          style: theme.textTheme.p.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          'dashboard.addFirstTransaction'.tr(),
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        ShadButton(
          onPressed: () => context.push('/transactions/add'),
          size: ShadButtonSize.sm,
          child: Text('quickActions.addExpense'.tr()),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction) {
    final theme = ShadTheme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/transactions/${transaction.id}'),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          child: Row(
            children: [
              // Transaction Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      _getTransactionColor(transaction.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  _getTransactionIcon(transaction.type),
                  color: _getTransactionColor(transaction.type),
                  size: AppDimensions.iconM,
                ),
              ),

              const SizedBox(width: AppDimensions.spacingM),

              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTransactionTitle(transaction),
                      style: theme.textTheme.p.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: theme.colorScheme.mutedForeground,
                        ),
                        const SizedBox(width: AppDimensions.spacingXs),
                        Text(
                          _formatDate(transaction.date),
                          style: theme.textTheme.small.copyWith(
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Transaction Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAmount(transaction),
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getTransactionColor(transaction.type),
                    ),
                  ),
                  if (transaction.notes?.isNotEmpty ?? false) ...[
                    const SizedBox(height: AppDimensions.spacingXs),
                    Icon(
                      Icons.note_outlined,
                      size: 12,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_upward;
      case TransactionType.expense:
        return Icons.arrow_downward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  String _getTransactionTitle(Transaction transaction) {
    // For now, return a generic title based on type
    // In a real app, you might want to get category name or custom title
    switch (transaction.type) {
      case TransactionType.income:
        return transaction.notes?.isEmpty ?? true
            ? 'Income Transaction'
            : transaction.notes!;
      case TransactionType.expense:
        return transaction.notes?.isEmpty ?? true
            ? 'Expense Transaction'
            : transaction.notes!;
      case TransactionType.transfer:
        return transaction.notes?.isEmpty ?? true
            ? 'Transfer Transaction'
            : transaction.notes!;
    }
  }

  String _formatAmount(Transaction transaction) {
    final amount = transaction.amount;
    final prefix = transaction.type == TransactionType.expense ? '-' : '+';
    return '$prefix${CurrencyFormatter.format(amount, currency: transaction.currency)}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'dateTime.today'.tr();
    } else if (difference == 1) {
      return 'dateTime.yesterday'.tr();
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}
