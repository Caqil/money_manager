import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/account_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final transactionAsync =
        ref.watch(transactionProvider(widget.transactionId));

    return transactionAsync.when(
      loading: () => _buildLoadingScreen(),
      error: (error, _) => _buildErrorScreen(error),
      data: (transaction) {
        if (transaction == null) {
          return _buildNotFoundScreen();
        }
        return _buildScreen(transaction);
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'transactions.transactionDetails'.tr(),
        showBackButton: true,
      ),
      body: const Center(
        child: ShimmerLoading(
          child: Column(
            children: [
              SizedBox(height: AppDimensions.spacingL),
              SkeletonLoader(height: 120, width: double.infinity),
              SizedBox(height: AppDimensions.spacingM),
              SkeletonLoader(height: 200, width: double.infinity),
              SizedBox(height: AppDimensions.spacingM),
              SkeletonLoader(height: 100, width: double.infinity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(Object error) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'transactions.transactionDetails'.tr(),
        showBackButton: true,
      ),
      body: Center(
        child: CustomErrorWidget(
          title: 'errors.loadingTransaction'.tr(),
          message: error.toString(),
          actionText: 'common.retry'.tr(),
          onActionPressed: () =>
              ref.refresh(transactionProvider(widget.transactionId)),
        ),
      ),
    );
  }

  Widget _buildNotFoundScreen() {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'transactions.transactionDetails'.tr(),
        showBackButton: true,
      ),
      body: const Center(
        child: EmptyStateWidget(
          iconData: Icons.receipt_outlined,
          title: 'Transaction not found',
          message: 'The transaction you are looking for could not be found.',
        ),
      ),
    );
  }

  Widget _buildScreen(Transaction transaction) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'transactions.transactionDetails'.tr(),
        showBackButton: true,
        actions: [
          ShadPopover(
            popover: (context) => _buildActionsMenu(transaction),
            child: IconButton(
              onPressed: _isLoading ? null : () {},
              icon: Icon(
                Icons.more_vert,
                color: _isLoading ? AppColors.lightDisabled : null,
              ),
              tooltip: 'common.moreActions'.tr(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction header with amount
            _buildTransactionHeader(transaction),
            const SizedBox(height: AppDimensions.spacingL),

            // Transaction details
            _buildTransactionDetails(transaction),
            const SizedBox(height: AppDimensions.spacingL),

            // Receipt image (if available)
            if (transaction.imagePath != null) ...[
              _buildReceiptSection(transaction),
              const SizedBox(height: AppDimensions.spacingL),
            ],

            // Related information
            _buildRelatedInformation(transaction),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : () => _editTransaction(transaction),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildTransactionHeader(Transaction transaction) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          children: [
            // Type icon and amount
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getTransactionTypeColor(transaction.type),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(
                    _getTransactionTypeIcon(transaction.type),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeDisplayName(transaction.type),
                        style: theme.textTheme.h3,
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      Text(
                        _formatTransactionAmount(transaction),
                        style: theme.textTheme.h1.copyWith(
                          color: _getTransactionTypeColor(transaction.type),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Date and time
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: theme.colorScheme.muted.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text(
                    DateFormat.yMMMMEEEEd().format(transaction.date),
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat.jm().format(transaction.date),
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(Transaction transaction) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'transactions.details'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // Account information
            _buildDetailItem(
              icon: Icons.account_balance_wallet,
              label: transaction.type == TransactionType.transfer
                  ? 'transactions.fromAccount'.tr()
                  : 'transactions.account'.tr(),
              value: _buildAccountValue(transaction.accountId),
            ),

            // Transfer to account (for transfers)
            if (transaction.type == TransactionType.transfer &&
                transaction.transferToAccountId != null) ...[
              const SizedBox(height: AppDimensions.spacingM),
              _buildDetailItem(
                icon: Icons.arrow_forward,
                label: 'transactions.toAccount'.tr(),
                value: _buildAccountValue(transaction.transferToAccountId!),
              ),
            ],

            // Category (for income/expense)
            if (transaction.type != TransactionType.transfer) ...[
              const SizedBox(height: AppDimensions.spacingM),
              _buildDetailItem(
                icon: Icons.category,
                label: 'transactions.category'.tr(),
                value: _buildCategoryValue(transaction.categoryId),
              ),
            ],

            // Currency
            const SizedBox(height: AppDimensions.spacingM),
            _buildDetailItem(
              icon: Icons.attach_money,
              label: 'transactions.currency'.tr(),
              value: Text(transaction.currency),
            ),

            // Notes (if available)
            if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spacingM),
              _buildDetailItem(
                icon: Icons.note,
                label: 'transactions.notes'.tr(),
                value: Text(
                  transaction.notes!,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required Widget value,
  }) {
    final theme = ShadTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.muted,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            icon,
            size: 16,
            color: theme.colorScheme.foreground,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              value,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountValue(String accountId) {
    final accountAsync = ref.watch(accountProvider(accountId));

    return accountAsync.when(
      loading: () => const ShimmerLoading(
        child: SkeletonLoader(height: 16, width: 100),
      ),
      error: (_, __) => Text('transactions.unknownAccount'.tr()),
      data: (account) => Text(
        account?.name ?? 'transactions.unknownAccount'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCategoryValue(String categoryId) {
    final categoryAsync = ref.watch(categoryProvider(categoryId));

    return categoryAsync.when(
      loading: () => const ShimmerLoading(
        child: SkeletonLoader(height: 16, width: 100),
      ),
      error: (_, __) => Text('transactions.unknownCategory'.tr()),
      data: (category) => Row(
        children: [
          if (category != null) ...[
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Color(category.color),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
          ],
          Text(
            category?.name ?? 'transactions.unknownCategory'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSection(Transaction transaction) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'transactions.receiptImage'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  onPressed: () => _viewFullImage(transaction.imagePath!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.zoom_in, size: 16),
                      const SizedBox(width: AppDimensions.spacingXs),
                      Text('common.view'.tr()),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.file(
                  File(transaction.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: theme.colorScheme.muted,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: theme.colorScheme.mutedForeground,
                          ),
                          const SizedBox(height: AppDimensions.spacingS),
                          Text(
                            'transactions.imageLoadError'.tr(),
                            style: theme.textTheme.small.copyWith(
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedInformation(Transaction transaction) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'transactions.relatedInfo'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // Creation info
            _buildInfoRow(
              'transactions.createdAt'.tr(),
              DateFormat.yMMMd().add_jm().format(transaction.createdAt),
            ),

            // Last updated
            if (transaction.updatedAt != transaction.createdAt) ...[
              const SizedBox(height: AppDimensions.spacingS),
              _buildInfoRow(
                'transactions.lastUpdated'.tr(),
                DateFormat.yMMMd().add_jm().format(transaction.updatedAt),
              ),
            ],

            // Transaction ID
            const SizedBox(height: AppDimensions.spacingS),
            _buildInfoRow(
              'transactions.transactionId'.tr(),
              transaction.id,
              copyable: true,
            ),

            // Recurring info (if applicable)
            if (transaction.isRecurring) ...[
              const SizedBox(height: AppDimensions.spacingS),
              _buildInfoRow(
                'transactions.recurringTransaction'.tr(),
                'transactions.yes'.tr(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool copyable = false}) {
    final theme = ShadTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.small,
                ),
              ),
              if (copyable)
                ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  onPressed: () => _copyToClipboard(value),
                  child: const Icon(Icons.copy, size: 14),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsMenu(Transaction transaction) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.edit, size: 18),
          title: Text('common.edit'.tr()),
          onTap: () {
            Navigator.of(context).pop();
            _editTransaction(transaction);
          },
        ),
        ListTile(
          leading: const Icon(Icons.copy, size: 18),
          title: Text('transactions.duplicate'.tr()),
          onTap: () {
            Navigator.of(context).pop();
            _duplicateTransaction(transaction);
          },
        ),
        ListTile(
          leading: const Icon(Icons.share, size: 18),
          title: Text('common.share'.tr()),
          onTap: () {
            Navigator.of(context).pop();
            _shareTransaction(transaction);
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete, size: 18, color: AppColors.error),
          title: Text(
            'common.delete'.tr(),
            style: const TextStyle(color: AppColors.error),
          ),
          onTap: () {
            Navigator.of(context).pop();
            _showDeleteConfirmation(transaction);
          },
        ),
      ],
    );
  }

  void _editTransaction(Transaction transaction) {
    context.push('/transactions/edit/${transaction.id}');
  }

  void _duplicateTransaction(Transaction transaction) {
    context.push(
      '/transactions/add?'
      'type=${transaction.type.name}&'
      'account=${transaction.accountId}&'
      'category=${transaction.categoryId}&'
      'amount=${transaction.amount}',
    );
  }

  void _shareTransaction(Transaction transaction) {
    // Implement sharing functionality
  }

  void _viewFullImage(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullImageViewer(imagePath: imagePath),
      ),
    );
  }

  void _copyToClipboard(String text) {
    // Implement clipboard copy functionality
    // Clipboard.setData(ClipboardData(text: text));

    ShadSonner.of(context).show(
      ShadToast.raw(
        variant: ShadToastVariant.primary,
        description: Text('common.copiedToClipboard'.tr()),
       
      ),
    );
  }

  void _showDeleteConfirmation(Transaction transaction) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('transactions.deleteTransaction'.tr()),
        description: Text('transactions.deleteTransactionConfirmation'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton.destructive(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTransaction(transaction);
            },
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(transactionListProvider.notifier);
      final success = await notifier.deleteTransaction(transaction.id);

      if (success && mounted) {
        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text('transactions.transactionDeleted'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text('transactions.errorDeletingTransaction'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTransactionAmount(Transaction transaction) {
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
}

class _FullImageViewer extends StatelessWidget {
  final String imagePath;

  const _FullImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'transactions.receiptImage'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
