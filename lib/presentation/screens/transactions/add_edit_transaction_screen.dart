import 'dart:async';

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
  Timer? _submitDebounceTimer;

  bool get isEditing => widget.transactionId != null;

  @override
  void dispose() {
    _submitDebounceTimer?.cancel();
    super.dispose();
  }

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
              const SizedBox(height: AppDimensions.spacingL),
              _buildQuickTips(),
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
    // Prevent multiple rapid submissions
    if (_isLoading) return;

    print('🔄 Transaction submission started');
    setState(() {
      _isLoading = true;
    });

    // Use scheduleMicrotask to ensure UI updates immediately
    scheduleMicrotask(() async {
      final stopwatch = Stopwatch()..start();

      try {
        print('📝 Creating transaction object...');
        final notifier = ref.read(transactionListProvider.notifier);

        if (isEditing && widget.transactionId != null) {
          // Get the current transaction properly from the AsyncValue
          final transactionAsync =
              ref.read(transactionProvider(widget.transactionId!));

          Transaction? currentTransaction;
          transactionAsync.when(
            data: (transaction) => currentTransaction = transaction,
            loading: () => currentTransaction = null,
            error: (_, __) => currentTransaction = null,
          );

          if (currentTransaction == null) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _showError('transactions.transactionNotFound'.tr());
            return;
          }

          // Update existing transaction
          final updatedTransaction = currentTransaction!.copyWith(
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
          );

          print('💾 Updating transaction in database...');
          // Run database operation in background using compute if needed
          final success = await notifier.updateTransaction(updatedTransaction);
          print(
              '✅ Transaction update completed in ${stopwatch.elapsedMilliseconds}ms');

          if (mounted) {
            if (success) {
              _showSuccessAndNavigateBack(
                  'transactions.transactionUpdated'.tr());
            } else {
              setState(() {
                _isLoading = false;
              });
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
          print('💾 Adding transaction to database...');
          // Run database operation in background
          final transactionId = await notifier.addTransaction(newTransaction);
          print(
              '✅ Transaction add completed in ${stopwatch.elapsedMilliseconds}ms');
          print('📋 Returned transaction ID: $transactionId');

          if (mounted) {
            if (transactionId != null && transactionId.isNotEmpty) {
              print('🎉 Transaction creation successful, navigating back');
              _showSuccessAndNavigateBack(
                  'transactions.transactionCreated'.tr());
            } else {
              print('❌ Transaction creation failed - empty or null ID');
              setState(() {
                _isLoading = false;
              });
              _showError('transactions.errorCreatingTransaction'.tr() +
                  ' (ID: $transactionId)');
            }
          }
        }
      } catch (e) {
        print('❌ Transaction submission error: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showError(isEditing
              ? 'transactions.errorUpdatingTransaction'.tr()
              : 'transactions.errorCreatingTransaction'.tr());
        }
      } finally {
        stopwatch.stop();
        print(
            '🏁 Transaction submission finished in ${stopwatch.elapsedMilliseconds}ms');
      }
    });
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
    final typeNames = {
      TransactionType.income: 'transactions.income'.tr(),
      TransactionType.expense: 'transactions.expense'.tr(),
      TransactionType.transfer: 'transactions.transfer'.tr(),
    };

    final shareText = '''
${typeNames[transaction.type]}: ${transaction.amount} ${transaction.currency}
Date: ${DateFormat.yMMMd().format(transaction.date)}
${transaction.notes != null ? 'Notes: ${transaction.notes}' : ''}
    '''
        .trim();

    // TODO: Implement actual share functionality with share_plus package
    // Share.share(shareText);
    _showError('Feature coming soon: $shareText');
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

    // Schedule the navigation to happen after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text(message),
            backgroundColor: AppColors.success,
          ),
        );

        context.pop();
      }
    });
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
}
