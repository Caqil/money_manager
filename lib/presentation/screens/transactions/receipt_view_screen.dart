import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:io';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';

class ReceiptViewScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const ReceiptViewScreen({
    super.key,
    required this.transactionId,
  });

  @override
  ConsumerState<ReceiptViewScreen> createState() => _ReceiptViewScreenState();
}

class _ReceiptViewScreenState extends ConsumerState<ReceiptViewScreen> {
  bool _isImageLoading = true;
  bool _hasImageError = false;

  @override
  Widget build(BuildContext context) {
    final transactionAsync =
        ref.watch(transactionProvider(widget.transactionId));

    return transactionAsync.when(
      loading: () => Scaffold(
        appBar: CustomAppBar(
          title: 'transactions.receiptView'.tr(),
          showBackButton: true,
        ),
        body: const Center(child: LoadingWidget()),
      ),
      error: (error, _) => Scaffold(
        appBar: CustomAppBar(
          title: 'transactions.receiptView'.tr(),
          showBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                'transactions.errorLoadingTransaction'.tr(),
                style: ShadTheme.of(context).textTheme.h4,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(error.toString()),
              const SizedBox(height: AppDimensions.spacingL),
              ShadButton.outline(
                onPressed: () =>
                    ref.refresh(transactionProvider(widget.transactionId)),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      ),
      data: (transaction) {
        if (transaction == null) {
          return Scaffold(
            appBar: CustomAppBar(
              title: 'transactions.receiptView'.tr(),
              showBackButton: true,
            ),
            body: Center(
              child: EmptyStateWidget(
                title: 'transactions.transactionNotFound'.tr(),
                message: 'transactions.transactionNotFoundMessage'.tr(),
                icon: Icon(Icons.receipt_outlined),
              ),
            ),
          );
        }

        return _buildReceiptView(context, transaction);
      },
    );
  }

  Widget _buildReceiptView(BuildContext context, Transaction transaction) {
    final hasReceipt =
        transaction.imagePath != null && transaction.imagePath!.isNotEmpty;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'transactions.receiptView'.tr(),
        showBackButton: true,
        actions: [
          if (hasReceipt) ...[
            IconButton(
              onPressed: () => _shareReceipt(transaction),
              icon: const Icon(Icons.share),
              tooltip: 'common.share'.tr(),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, transaction),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view_fullscreen',
                  child: Row(
                    children: [
                      const Icon(Icons.fullscreen, size: 16),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text('transactions.viewFullscreen'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'save_to_gallery',
                  child: Row(
                    children: [
                      const Icon(Icons.save_alt, size: 16),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text('transactions.saveToGallery'.tr()),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'remove_receipt',
                  child: Row(
                    children: [
                      const Icon(Icons.delete,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text(
                        'transactions.removeReceipt'.tr(),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: hasReceipt
          ? _buildReceiptContent(transaction)
          : _buildNoReceiptView(transaction),
    );
  }

  Widget _buildReceiptContent(Transaction transaction) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Transaction summary header
          _buildTransactionSummary(transaction),

          // Receipt image
          _buildReceiptImage(transaction.imagePath!),

          // Receipt details and actions
          _buildReceiptDetails(transaction),
        ],
      ),
    );
  }

  Widget _buildTransactionSummary(Transaction transaction) {
    final typeColor = _getTransactionTypeColor(transaction.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor,
            typeColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(
                  Icons.receipt,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'transactions.receiptFor'.tr(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(
                        transaction.amount,
                        currency: transaction.currency,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingS,
                  vertical: AppDimensions.paddingXs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  'transactions.${transaction.type.name}'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // Transaction details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'transactions.date'.tr(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().format(transaction.date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (transaction.notes != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'transactions.notes'.tr(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        transaction.notes!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptImage(String imagePath) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 400,
        maxHeight: 600,
      ),
      margin: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Stack(
          children: [
            // Receipt image
            if (!_hasImageError)
              Image.file(
                File(imagePath),
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _hasImageError = true;
                        _isImageLoading = false;
                      });
                    }
                  });
                  return _buildImageError();
                },
              ),

            // Error state
            if (_hasImageError) _buildImageError(),

            // Loading state
            if (_isImageLoading) _buildImageLoading(),

            // Zoom indicator
            if (!_isImageLoading && !_hasImageError)
              Positioned(
                top: AppDimensions.paddingM,
                right: AppDimensions.paddingM,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: AppDimensions.spacingXs),
                      Text(
                        'transactions.tapToZoom'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLoading() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            'transactions.loadingReceipt'.tr(),
            style: ShadTheme.of(context).textTheme.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            'transactions.receiptLoadError'.tr(),
            style: ShadTheme.of(context).textTheme.h4.copyWith(
                  color: AppColors.error,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            'transactions.receiptLoadErrorDesc'.tr(),
            style: ShadTheme.of(context).textTheme.muted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          ShadButton.outline(
            onPressed: () {
              setState(() {
                _hasImageError = false;
                _isImageLoading = true;
              });
            },
            child: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptDetails(Transaction transaction) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'transactions.receiptDetails'.tr(),
            style: ShadTheme.of(context).textTheme.h4,
          ),
          const SizedBox(height: AppDimensions.spacingM),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border:
                  Border.all(color: ShadTheme.of(context).colorScheme.border),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                    'transactions.amount'.tr(),
                    CurrencyFormatter.format(transaction.amount,
                        currency: transaction.currency)),
                _buildDetailRow('transactions.date'.tr(),
                    DateFormat.yMMMEd().format(transaction.date)),
                _buildDetailRow('transactions.type'.tr(),
                    'transactions.${transaction.type.name}'.tr()),
                if (transaction.notes != null)
                  _buildDetailRow(
                      'transactions.notes'.tr(), transaction.notes!),
                _buildDetailRow('transactions.createdAt'.tr(),
                    DateFormat.yMMMEd().add_jm().format(transaction.createdAt)),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Action buttons
          _buildActionButtons(transaction),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: ShadTheme.of(context).textTheme.muted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Transaction transaction) {
    return Row(
      children: [
        Expanded(
          child: ShadButton.outline(
            onPressed: () => _editTransaction(transaction),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit, size: 18),
                const SizedBox(width: AppDimensions.spacingS),
                Text('common.edit'.tr()),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: ShadButton(
            onPressed: () => _viewFullscreen(transaction.imagePath!),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fullscreen, size: 18, color: Colors.white),
                const SizedBox(width: AppDimensions.spacingS),
                Text('transactions.viewFullscreen'.tr()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoReceiptView(Transaction transaction) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Transaction summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingXl),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border:
                    Border.all(color: ShadTheme.of(context).colorScheme.border),
              ),
              child: Column(
                children: [
                  Icon(
                    _getTransactionTypeIcon(transaction.type),
                    size: 48,
                    color: _getTransactionTypeColor(transaction.type),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    CurrencyFormatter.format(
                      transaction.amount,
                      currency: transaction.currency,
                    ),
                    style: ShadTheme.of(context).textTheme.h2.copyWith(
                          color: _getTransactionTypeColor(transaction.type),
                        ),
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    DateFormat.yMMMEd().format(transaction.date),
                    style: ShadTheme.of(context).textTheme.muted,
                  ),
                  if (transaction.notes != null) ...[
                    const SizedBox(height: AppDimensions.spacingS),
                    Text(
                      transaction.notes!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            // No receipt message
            Icon(
              Icons.receipt_outlined,
              size: 64,
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'transactions.noReceiptAttached'.tr(),
              style: ShadTheme.of(context).textTheme.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'transactions.noReceiptDesc'.tr(),
              style: ShadTheme.of(context).textTheme.muted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingL),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () => _addReceipt(transaction),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt, size: 18),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text('transactions.addReceipt'.tr()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: ShadButton(
                    onPressed: () => _editTransaction(transaction),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit, size: 18, color: Colors.white),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text('common.edit'.tr()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTransactionTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.success;
      case TransactionType.expense:
        return AppColors.error;
      case TransactionType.transfer:
        return AppColors.primary;
    }
  }

  IconData _getTransactionTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.trending_up;
      case TransactionType.expense:
        return Icons.trending_down;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  void _handleMenuAction(String action, Transaction transaction) {
    switch (action) {
      case 'view_fullscreen':
        _viewFullscreen(transaction.imagePath!);
        break;
      case 'save_to_gallery':
        _saveToGallery(transaction.imagePath!);
        break;
      case 'remove_receipt':
        _showRemoveReceiptConfirmation(transaction);
        break;
    }
  }

  void _viewFullscreen(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenImageView(imagePath: imagePath),
      ),
    );
  }

  void _shareReceipt(Transaction transaction) {
    // Placeholder for share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('transactions.shareFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _saveToGallery(String imagePath) {
    // Placeholder for save to gallery functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('transactions.saveToGalleryFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _addReceipt(Transaction transaction) {
    // Placeholder for add receipt functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('transactions.addReceiptFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _editTransaction(Transaction transaction) {
    context.go('/transactions/${transaction.id}/edit');
  }

  void _showRemoveReceiptConfirmation(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('transactions.removeReceipt'.tr()),
        content: Text('transactions.removeReceiptConfirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeReceipt(transaction);
            },
            child: Text(
              'common.remove'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _removeReceipt(Transaction transaction) {
    // Placeholder for remove receipt functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('transactions.receiptRemoved'.tr()),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

// Fullscreen image view widget
class _FullscreenImageView extends StatelessWidget {
  final String imagePath;

  const _FullscreenImageView({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              // Share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('transactions.shareFeatureComingSoon'.tr()),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    'transactions.receiptLoadError'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
