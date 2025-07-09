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
  final ShadPopoverController _moreActionsController = ShadPopoverController();

  @override
  void dispose() {
    _moreActionsController.dispose();
    super.dispose();
  }

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
    return Scaffold(
      appBar: CustomAppBar(
        title: 'transactions.transactionDetails'.tr(),
        showBackButton: true,
        actions: [
          ShadPopover(
            controller: _moreActionsController,
            popover: (context) => _buildActionsMenu(transaction),
            child: IconButton(
              onPressed:
                  _isLoading ? null : () => _moreActionsController.toggle(),
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
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction header with amount
            _buildTransactionHeader(transaction),

            // Transaction details
            _buildTransactionDetails(transaction),

            // Receipt image (if available)
            if (transaction.imagePath != null) ...[
              _buildReceiptSection(transaction),
            ],

            // Related information
            _buildRelatedInformation(transaction),

            // Add some space at the bottom for the FAB
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _isLoading ? null : () => _editTransaction(transaction),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildTransactionHeader(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: _getTransactionTypeColor(transaction.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: _getTransactionTypeColor(transaction.type).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Amount and type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTypeDisplayName(transaction.type),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getTransactionTypeColor(transaction.type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      _formatTransactionAmount(transaction),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getTransactionTypeColor(transaction.type),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTransactionTypeColor(transaction.type),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  _getTransactionTypeIcon(transaction.type),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),

          // Date
          const SizedBox(height: AppDimensions.spacingM),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingS,
              vertical: AppDimensions.paddingXs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  DateFormat.yMMMd().format(transaction.date),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat.jm().format(transaction.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            const SizedBox(height: AppDimensions.spacingS),
            _buildDetailItem(
              icon: Icons.arrow_forward,
              label: 'transactions.toAccount'.tr(),
              value: _buildAccountValue(transaction.transferToAccountId!),
            ),
          ],

          // Category (for income/expense)
          if (transaction.type != TransactionType.transfer) ...[
            const SizedBox(height: AppDimensions.spacingS),
            _buildDetailItem(
              icon: Icons.category,
              label: 'transactions.category'.tr(),
              value: _buildCategoryValue(transaction.categoryId),
            ),
          ],

          // Currency
          const SizedBox(height: AppDimensions.spacingS),
          _buildDetailItem(
            icon: Icons.attach_money,
            label: 'transactions.currency'.tr(),
            value: Text(
              transaction.currency,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          // Notes (if available)
          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingS),
            _buildDetailItem(
              icon: Icons.note_alt,
              label: 'transactions.notes'.tr(),
              value: Text(
                transaction.notes!,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required Widget value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
            ),
            child: Icon(
              icon,
              size: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  child: value,
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'transactions.receiptImage'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _viewFullImage(transaction.imagePath!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingS,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.zoom_in,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'common.view'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.file(
                File(transaction.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[100],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text(
                          'transactions.imageLoadError'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
    );
  }

  Widget _buildRelatedInformation(Transaction transaction) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'transactions.relatedInfo'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
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

          // Transaction ID (shortened for UI)
          const SizedBox(height: AppDimensions.spacingS),
          _buildInfoRow(
            'transactions.transactionId'.tr(),
            '${transaction.id.substring(0, 8)}...',
            copyable: true,
            fullValue: transaction.id,
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
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool copyable = false, String? fullValue}) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (copyable)
                GestureDetector(
                  onTap: () => _copyToClipboard(fullValue ?? value),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.copy,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsMenu(Transaction transaction) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionMenuItem(
            icon: Icons.edit,
            title: 'common.edit'.tr(),
            onTap: () {
              _moreActionsController.hide();
              _editTransaction(transaction);
            },
          ),
          _buildActionMenuItem(
            icon: Icons.copy,
            title: 'transactions.duplicate'.tr(),
            onTap: () {
              _moreActionsController.hide();
              _duplicateTransaction(transaction);
            },
          ),
          _buildActionMenuItem(
            icon: Icons.share,
            title: 'common.share'.tr(),
            onTap: () {
              _moreActionsController.hide();
              _shareTransaction(transaction);
            },
          ),
          Container(
            height: 1,
            margin:
                const EdgeInsets.symmetric(horizontal: AppDimensions.paddingS),
            color: Colors.grey[200],
          ),
          _buildActionMenuItem(
            icon: Icons.delete,
            title: 'common.delete'.tr(),
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () {
              _moreActionsController.hide();
              _showDeleteConfirmation(transaction);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: iconColor ?? Colors.grey[600],
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: textColor ?? Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
