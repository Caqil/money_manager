import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validation_helper.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import 'widgets/account_selector.dart';

class DuplicateTransactionScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const DuplicateTransactionScreen({
    super.key,
    required this.transactionId,
  });

  @override
  ConsumerState<DuplicateTransactionScreen> createState() =>
      _DuplicateTransactionScreenState();
}

class _DuplicateTransactionScreenState
    extends ConsumerState<DuplicateTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _uuid = const Uuid();

  Transaction? _originalTransaction;
  Account? _selectedAccount;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.expense;
  bool _isLoading = false;

  // Duplication options
  bool _duplicateAsRecurring = false;
  bool _updateAmount = false;
  bool _updateDate = true;
  bool _updateAccount = false;
  bool _updateCategory = false;
  bool _updateNotes = false;

  @override
  void initState() {
    super.initState();
    _loadOriginalTransaction();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadOriginalTransaction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionAsync =
          ref.read(transactionProvider(widget.transactionId));
      transactionAsync.whenData((transaction) {
        if (transaction != null) {
          _initializeFromOriginal(transaction);
        }
      });
    });
  }

  void _initializeFromOriginal(Transaction transaction) {
    setState(() {
      _originalTransaction = transaction;
      _amountController.text = transaction.amount.toString();
      _notesController.text = transaction.notes ?? '';
      _selectedDate = DateTime.now(); // Default to today for duplicate
      _selectedType = transaction.type;
    });

    // Load account and category
    final accountsAsync = ref.read(accountListProvider);
    accountsAsync.whenData((accounts) {
      final account = accounts.firstWhere(
        (acc) => acc.id == transaction.accountId,
        orElse: () => accounts.first,
      );
      setState(() {
        _selectedAccount = account;
      });
    });

    if (transaction.type != TransactionType.transfer) {
      final categoriesAsync = ref.read(categoryListProvider);
      categoriesAsync.whenData((categories) {
        final category = categories.firstWhere(
          (cat) => cat.id == transaction.categoryId,
          orElse: () => categories.first,
        );
        setState(() {
          _selectedCategory = category;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionAsync =
        ref.watch(transactionProvider(widget.transactionId));

    return transactionAsync.when(
      loading: () => Scaffold(
        appBar: CustomAppBar(
          title: 'transactions.duplicateTransaction'.tr(),
          showBackButton: true,
        ),
        body: const Center(child: LoadingWidget()),
      ),
      error: (error, _) => Scaffold(
        appBar: CustomAppBar(
          title: 'transactions.duplicateTransaction'.tr(),
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
              title: 'transactions.duplicateTransaction'.tr(),
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

        return _buildDuplicateScreen(context, transaction);
      },
    );
  }

  Widget _buildDuplicateScreen(BuildContext context, Transaction transaction) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'transactions.duplicateTransaction'.tr(),
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with original transaction info
              _buildOriginalTransactionCard(transaction),

              const SizedBox(height: AppDimensions.spacingL),

              // Duplication options
              _buildDuplicationOptions(),

              const SizedBox(height: AppDimensions.spacingL),

              // Editable fields
              _buildEditableFields(),

              const SizedBox(height: AppDimensions.spacingXl),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalTransactionCard(Transaction transaction) {
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
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
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
                  _getTransactionTypeIcon(transaction.type),
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
                      'transactions.originalTransaction'.tr(),
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
                      'transactions.type'.tr(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'transactions.${transaction.type.name}'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
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
            ],
          ),

          if (transaction.notes != null) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              transaction.notes!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDuplicationOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'transactions.duplicationOptions'.tr(),
          style: ShadTheme.of(context).textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: ShadTheme.of(context).colorScheme.border),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: Text('transactions.updateDate'.tr()),
                subtitle: Text('transactions.updateDateDesc'.tr()),
                value: _updateDate,
                onChanged: (value) => setState(() => _updateDate = value),
                dense: true,
              ),
              SwitchListTile(
                title: Text('transactions.updateAmount'.tr()),
                subtitle: Text('transactions.updateAmountDesc'.tr()),
                value: _updateAmount,
                onChanged: (value) => setState(() => _updateAmount = value),
                dense: true,
              ),
              SwitchListTile(
                title: Text('transactions.updateAccount'.tr()),
                subtitle: Text('transactions.updateAccountDesc'.tr()),
                value: _updateAccount,
                onChanged: (value) => setState(() => _updateAccount = value),
                dense: true,
              ),
              if (_originalTransaction?.type != TransactionType.transfer)
                SwitchListTile(
                  title: Text('transactions.updateCategory'.tr()),
                  subtitle: Text('transactions.updateCategoryDesc'.tr()),
                  value: _updateCategory,
                  onChanged: (value) => setState(() => _updateCategory = value),
                  dense: true,
                ),
              SwitchListTile(
                title: Text('transactions.updateNotes'.tr()),
                subtitle: Text('transactions.updateNotesDesc'.tr()),
                value: _updateNotes,
                onChanged: (value) => setState(() => _updateNotes = value),
                dense: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'transactions.newTransactionDetails'.tr(),
          style: ShadTheme.of(context).textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Amount field (if enabled)
        if (_updateAmount) ...[
          Text(
            'transactions.amount'.tr(),
            style: ShadTheme.of(context).textTheme.muted,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ShadInputFormField(
            controller: _amountController,
            placeholder: Text('forms.enterAmount'.tr()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_isLoading,
            validator: (value) => ValidationHelper.getAmountErrorMessage(value),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            leading: Text(
              _selectedAccount?.currency ?? 'USD',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],

        // Date field (if enabled)
        if (_updateDate) ...[
          Text(
            'transactions.date'.tr(),
            style: ShadTheme.of(context).textTheme.muted,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          InkWell(
            onTap: _isLoading ? null : _selectDate,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                border:
                    Border.all(color: ShadTheme.of(context).colorScheme.border),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text(
                    DateFormat.yMMMd().format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],

        // Account field (if enabled)
        if (_updateAccount) ...[
          Text(
            'accounts.account'.tr(),
            style: ShadTheme.of(context).textTheme.muted,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          AccountSelector(
            selectedAccountId: _selectedAccount?.id,
            onAccountSelected: (account) {
              setState(() {
                _selectedAccount = account;
              });
            },
            enabled: !_isLoading,
            showBalance: true,
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],

        // Category field (if enabled and not transfer)
        if (_updateCategory &&
            _originalTransaction?.type != TransactionType.transfer) ...[
          Text(
            'categories.category'.tr(),
            style: ShadTheme.of(context).textTheme.muted,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          // Category selector would go here
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              border:
                  Border.all(color: ShadTheme.of(context).colorScheme.border),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Text(
              _selectedCategory?.name ?? 'transactions.selectCategory'.tr(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],

        // Notes field (if enabled)
        if (_updateNotes) ...[
          Text(
            'transactions.notes'.tr(),
            style: ShadTheme.of(context).textTheme.muted,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ShadInputFormField(
            controller: _notesController,
            placeholder: Text('transactions.addNotes'.tr()),
            maxLines: 3,
            enabled: !_isLoading,
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],

        // Preview of changes
        _buildChangesPreview(),
      ],
    );
  }

  Widget _buildChangesPreview() {
    if (!_hasChanges()) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'transactions.changesPreview'.tr(),
                style: ShadTheme.of(context).textTheme.h4.copyWith(
                      color: AppColors.info,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          if (_updateAmount)
            _buildChangeRow(
              'transactions.amount'.tr(),
              CurrencyFormatter.format(_originalTransaction!.amount,
                  currency: _originalTransaction!.currency),
              CurrencyFormatter.format(
                  double.tryParse(_amountController.text) ?? 0,
                  currency: _selectedAccount?.currency ?? 'USD'),
            ),
          if (_updateDate)
            _buildChangeRow(
              'transactions.date'.tr(),
              DateFormat.yMMMd().format(_originalTransaction!.date),
              DateFormat.yMMMd().format(_selectedDate),
            ),
          if (_updateNotes &&
              _notesController.text != _originalTransaction!.notes)
            _buildChangeRow(
              'transactions.notes'.tr(),
              _originalTransaction!.notes ?? 'common.none'.tr(),
              _notesController.text.isEmpty
                  ? 'common.none'.tr()
                  : _notesController.text,
            ),
        ],
      ),
    );
  }

  Widget _buildChangeRow(String field, String oldValue, String newValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$field:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    oldValue,
                    style: TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Icon(
                  Icons.arrow_forward,
                  size: 12,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    newValue,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canDuplicate = _originalTransaction != null && !_isLoading;

    return Row(
      children: [
        Expanded(
          child: ShadButton.outline(
            onPressed: _isLoading ? null : () => context.pop(),
            child: Text('common.cancel'.tr()),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          flex: 2,
          child: ShadButton(
            onPressed: canDuplicate ? _duplicateTransaction : null,
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text('common.duplicating'.tr()),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.content_copy, size: 18, color: Colors.white),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text('transactions.duplicateTransaction'.tr()),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  bool _hasChanges() {
    if (_originalTransaction == null) return false;

    return (_updateAmount &&
            _amountController.text !=
                _originalTransaction!.amount.toString()) ||
        (_updateDate && _selectedDate != _originalTransaction!.date) ||
        (_updateNotes &&
            _notesController.text != (_originalTransaction!.notes ?? ''));
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _duplicateTransaction() async {
    if (!_formKey.currentState!.validate() || _originalTransaction == null)
      return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create the duplicate transaction
      final duplicateTransaction = _originalTransaction!.copyWith(
        id: _uuid.v4(),
        amount: _updateAmount
            ? (double.tryParse(_amountController.text) ??
                _originalTransaction!.amount)
            : _originalTransaction!.amount,
        date: _updateDate ? _selectedDate : _originalTransaction!.date,
        accountId: _updateAccount
            ? (_selectedAccount?.id ?? _originalTransaction!.accountId)
            : _originalTransaction!.accountId,
        categoryId: _updateCategory
            ? (_selectedCategory?.id ?? _originalTransaction!.categoryId)
            : _originalTransaction!.categoryId,
        notes: _updateNotes
            ? (_notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim())
            : _originalTransaction!.notes,
        currency: _updateAccount
            ? (_selectedAccount?.currency ?? _originalTransaction!.currency)
            : _originalTransaction!.currency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final transactionId = await ref
          .read(transactionListProvider.notifier)
          .addTransaction(duplicateTransaction);

      if (transactionId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('transactions.transactionDuplicated'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        throw Exception('transactions.duplicateTransactionError'.tr());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${'transactions.duplicateTransactionError'.tr()}: ${e.toString()}'),
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
}
