import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/transaction_form.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  final TransactionType? defaultType;
  final String? defaultAccountId;
  final String? defaultCategoryId;

  const AddEditTransactionScreen({
    super.key,
    this.transactionId,
    this.defaultType,
    this.defaultAccountId,
    this.defaultCategoryId,
  });

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  bool _isLoading = false;
  final _uuid = const Uuid();

  bool get isEditing => widget.transactionId != null;

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      final transactionAsync =
          ref.watch(transactionProvider(widget.transactionId!));

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

    return _buildScreen(null);
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'transactions.editTransaction'.tr(),
        showBackButton: true,
      ),
      body: const Center(
        child: ShimmerLoading(
          child: SkeletonLoader(height: 400, width: double.infinity),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(Object error) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'transactions.editTransaction'.tr(),
        showBackButton: true,
      ),
      body: Center(
        child: CustomErrorWidget(
          title: 'errors.loadingTransaction'.tr(),
          message: error.toString(),
          actionText: 'common.retry'.tr(),
          onActionPressed: () =>
              ref.refresh(transactionProvider(widget.transactionId!)),
        ),
      ),
    );
  }

  Widget _buildNotFoundScreen() {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'transactions.editTransaction'.tr(),
        showBackButton: true,
      ),
      body: const Center(
        child: EmptyStateWidget(
          iconData: Icons.receipt_outlined,
          title: 'Transaction not found',
          message: 'The transaction you are trying to edit could not be found.',
        ),
      ),
    );
  }

  Widget _buildScreen(Transaction? transaction) {
    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing
            ? 'transactions.editTransaction'.tr()
            : 'transactions.addTransaction'.tr(),
        showBackButton: true,
        actions: [
          if (isEditing && transaction != null)
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              _buildHeader(transaction),
              const SizedBox(height: AppDimensions.spacingL),

              // Form
              TransactionForm(
                transaction: transaction,
                defaultType: widget.defaultType,
                defaultAccountId: widget.defaultAccountId,
                defaultCategoryId: widget.defaultCategoryId,
                enabled: !_isLoading,
                isLoading: _isLoading,
                onSubmit: _handleSubmit,
                onCancel: _handleCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Transaction? transaction) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          isEditing
              ? 'transactions.editTransactionTitle'.tr()
              : 'transactions.addTransactionTitle'.tr(),
          style: theme.textTheme.h2,
        ),
        const SizedBox(height: AppDimensions.spacingS),

        // Subtitle
        Text(
          isEditing
              ? 'transactions.editTransactionSubtitle'.tr()
              : 'transactions.addTransactionSubtitle'.tr(),
          style: theme.textTheme.p.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),

        // Quick action tips (only for new transactions)
        if (!isEditing) ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildQuickTips(),
        ],
      ],
    );
  }

  Widget _buildQuickTips() {
    final theme = ShadTheme.of(context);

    final tips = [
      {
        'icon': Icons.camera_alt_outlined,
        'text': 'transactions.tipCamera'.tr(),
      },
      {
        'icon': Icons.mic_outlined,
        'text': 'transactions.tipVoice'.tr(),
      },
      {
        'icon': Icons.calculate_outlined,
        'text': 'transactions.tipCalculator'.tr(),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: AppDimensions.spacingXs),
              Text(
                'transactions.quickTips'.tr(),
                style: theme.textTheme.h4.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingXs),
                child: Row(
                  children: [
                    Icon(
                      tip['icon'] as IconData,
                      color: AppColors.primary.withOpacity(0.7),
                      size: 14,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Text(
                        tip['text'] as String,
                        style: theme.textTheme.small.copyWith(
                          color: AppColors.primary.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(Transaction transaction) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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

  Future<void> _handleSubmit(TransactionFormData formData) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(transactionListProvider.notifier);

      if (isEditing) {
        // Update existing transaction
        final updatedTransaction = widget.transactionId != null
            ? ref
                .read(transactionProvider(widget.transactionId!))
                .value
                ?.copyWith(
                  amount: formData.amount,
                  categoryId: formData.categoryId,
                  date: formData.date,
                  notes: formData.notes,
                  type: formData.type,
                  imagePath: formData.imagePath,
                  accountId: formData.accountId,
                  currency: formData.currency,
                  transferToAccountId: formData.transferToAccountId,
                  metadata: formData.metadata,
                  updatedAt: DateTime.now(),
                )
            : null;

        if (updatedTransaction != null) {
          final success = await notifier.updateTransaction(updatedTransaction);
          if (success) {
            _showSuccessAndNavigateBack('transactions.transactionUpdated'.tr());
          } else {
            _showError('transactions.errorUpdatingTransaction'.tr());
          }
        }
      } else {
        // Create new transaction
        final newTransaction = Transaction(
          id: _uuid.v4(),
          amount: formData.amount,
          categoryId: formData.categoryId,
          date: formData.date,
          notes: formData.notes,
          type: formData.type,
          imagePath: formData.imagePath,
          accountId: formData.accountId,
          currency: formData.currency,
          transferToAccountId: formData.transferToAccountId,
          metadata: formData.metadata,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final transactionId = await notifier.addTransaction(newTransaction);
        if (transactionId != null) {
          _showSuccessAndNavigateBack('transactions.transactionCreated'.tr());
        } else {
          _showError('transactions.errorCreatingTransaction'.tr());
        }
      }
    } catch (e) {
      _showError(isEditing
          ? 'transactions.errorUpdatingTransaction'.tr()
          : 'transactions.errorCreatingTransaction'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleCancel() {
    if (_isLoading) return;
    context.pop();
  }

  void _duplicateTransaction(Transaction transaction) {
    // Navigate to add transaction screen with prefilled data
    context.push(
      '/transactions/add?'
      'type=${transaction.type.name}&'
      'account=${transaction.accountId}&'
      'category=${transaction.categoryId}&'
      'amount=${transaction.amount}',
    );
  }

  void _shareTransaction(Transaction transaction) {
    // Implement transaction sharing functionality
    // This could generate a text summary and use the share_plus package
    final shareText = '''
${_getTypeDisplayName(transaction.type)}: ${transaction.amount} ${transaction.currency}
Date: ${DateFormat.yMMMd().format(transaction.date)}
${transaction.notes != null ? 'Notes: ${transaction.notes}' : ''}
    '''
        .trim();

    // Share functionality would go here
    // Share.share(shareText);
  }

  void _showDeleteConfirmation(Transaction transaction) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('transactions.deleteTransaction'.tr()),
        description: Text(
          'transactions.deleteTransactionConfirmation'.tr(),
        ),
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

      if (success) {
        _showSuccessAndNavigateBack('transactions.transactionDeleted'.tr());
      } else {
        _showError('transactions.errorDeletingTransaction'.tr());
      }
    } catch (e) {
      _showError('transactions.errorDeletingTransaction'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessAndNavigateBack(String message) {
    if (!mounted) return;

    ShadSonner.of(context).show(
      ShadToast.raw(
        variant: ShadToastVariant.primary,
        description: Text(message),
        backgroundColor: AppColors.success,
       
      ),
    );

    context.pop();
  }

  void _showError(String message) {
    if (!mounted) return;

    ShadSonner.of(context).show(
      ShadToast.raw(
        variant: ShadToastVariant.primary,
        description: Text(message),
        backgroundColor: AppColors.error,
       
      ),
    );
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
}
