import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../data/models/account.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/transaction.dart';
import '../../../providers/settings_provider.dart';
import 'account_selector.dart';
import 'amount_input_widget.dart';
import 'category_selector.dart';
import 'date_picker_widget.dart';
import 'receipt_image_picker.dart';
import 'voice_input_widget.dart';

typedef TransactionFormData = ({
  double amount,
  String categoryId,
  DateTime date,
  String? notes,
  TransactionType type,
  String? imagePath,
  String accountId,
  String currency,
  String? transferToAccountId,
  Map<String, dynamic>? metadata,
});

class TransactionForm extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final TransactionType? defaultType;
  final String? defaultAccountId;
  final String? defaultCategoryId;
  final bool enabled;
  final bool isLoading;
  final Function(TransactionFormData)? onSubmit;
  final VoidCallback? onCancel;

  const TransactionForm({
    super.key,
    this.transaction,
    this.defaultType,
    this.defaultAccountId,
    this.defaultCategoryId,
    this.enabled = true,
    this.isLoading = false,
    this.onSubmit,
    this.onCancel,
  });

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  // Form fields
  double? _amount;
  TransactionType _type = TransactionType.expense;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String? _imagePath;
  String? _transferToAccountId;
  String _currency = 'USD';

  // Validation errors
  String? _amountError;
  String? _accountError;
  String? _categoryError;
  String? _transferAccountError;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.transaction != null) {
      final transaction = widget.transaction!;
      _amount = transaction.amount;
      _type = transaction.type;
      _selectedAccountId = transaction.accountId;
      _selectedCategoryId = transaction.categoryId;
      _selectedDate = transaction.date;
      _imagePath = transaction.imagePath;
      _transferToAccountId = transaction.transferToAccountId;
      _currency = transaction.currency;
      _notesController.text = transaction.notes ?? '';
    } else {
      _type = widget.defaultType ?? TransactionType.expense;
      _selectedAccountId = widget.defaultAccountId;
      _selectedCategoryId = widget.defaultCategoryId;
      _selectedDate = DateTime.now();

      // Set default currency from settings
      final settings = ref.read(settingsStateProvider);
      _currency = settings.baseCurrency;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Type Selector
          _buildTypeSelector(),
          const SizedBox(height: AppDimensions.spacingM),

          // Amount Input
          AmountInputWidget(
            initialAmount: _amount,
            onAmountChanged: (amount) {
              _amount = amount;
              _amountError = _validateAmount(amount);
            },
            label: 'transactions.amount'.tr(),
            required: true,
            enabled: widget.enabled && !widget.isLoading,
            transactionType: _type,
            currency: _currency,
            errorText: _amountError,
            autofocus: widget.transaction == null,
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Account Selector
          AccountSelector(
            selectedAccountId: _selectedAccountId,
            onAccountSelected: (account) {
              setState(() {
                _selectedAccountId = account?.id;
                _accountError = _validateAccount(account);
                if (account != null) {
                  _currency = account.currency;
                }
              });
            },
            label: _type == TransactionType.transfer
                ? 'transactions.fromAccount'.tr()
                : 'transactions.account'.tr(),
            required: true,
            enabled: widget.enabled && !widget.isLoading,
            errorText: _accountError,
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Transfer To Account (only for transfers)
          if (_type == TransactionType.transfer) ...[
            AccountSelector(
              selectedAccountId: _transferToAccountId,
              onAccountSelected: (account) {
                setState(() {
                  _transferToAccountId = account?.id;
                  _transferAccountError = _validateTransferAccount(account);
                });
              },
              label: 'transactions.toAccount'.tr(),
              required: true,
              enabled: widget.enabled && !widget.isLoading,
              excludeAccountIds:
                  _selectedAccountId != null ? [_selectedAccountId!] : null,
              errorText: _transferAccountError,
            ),
            const SizedBox(height: AppDimensions.spacingM),
          ],

          // Category Selector (not needed for transfers)
          if (_type != TransactionType.transfer) ...[
            CategorySelector(
              selectedCategoryId: _selectedCategoryId,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategoryId = category?.id;
                  _categoryError = _validateCategory(category);
                });
              },
              transactionType: _type,
              label: 'transactions.category'.tr(),
              required: true,
              enabled: widget.enabled && !widget.isLoading,
              errorText: _categoryError,
            ),
            const SizedBox(height: AppDimensions.spacingM),
          ],

          // Date Picker
          DatePickerWidget(
            selectedDate: _selectedDate,
            onDateChanged: (date) {
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            label: 'transactions.date'.tr(),
            required: true,
            enabled: widget.enabled && !widget.isLoading,
            maxDate: DateTime.now().add(const Duration(days: 1)),
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Notes with Voice Input
          _buildNotesField(),
          const SizedBox(height: AppDimensions.spacingM),

          // Receipt Image
          ReceiptImagePicker(
            imagePath: _imagePath,
            onImageChanged: (imagePath) {
              setState(() {
                _imagePath = imagePath;
              });
            },
            label: 'transactions.receiptImage'.tr(),
            enabled: widget.enabled && !widget.isLoading,
          ),
          SizedBox(height: AppDimensions.spacingXl),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'transactions.type'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Row(
          children: TransactionType.values.map((type) {
            final isSelected = _type == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type != TransactionType.values.last
                      ? AppDimensions.spacingS
                      : 0,
                ),
                child: ShadButton.outline(
                  onPressed: widget.enabled && !widget.isLoading
                      ? () => _selectType(type)
                      : null,
                  backgroundColor:
                      isSelected ? _getTypeColor(type).withOpacity(0.1) : null,
                  child: Text(
                    _getTypeDisplayName(type),
                    style: TextStyle(
                      color: isSelected
                          ? _getTypeColor(type)
                          : theme.colorScheme.mutedForeground,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'transactions.notes'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4, // Give most space to the text field
              child: ShadInputFormField(
                controller: _notesController,
                placeholder: Text('transactions.enterNotes'.tr()),
                maxLines: 3,
                enabled: widget.enabled && !widget.isLoading,
                validator: (value) {
                  // Optional validation for notes
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Flexible(
              flex: 1, // Constrain voice input widget space
              child: VoiceInputWidget(
                onTextReceived: (text) {
                  setState(() {
                    _notesController.text = text;
                  });
                },
                enabled: widget.enabled && !widget.isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.onCancel != null) ...[
          Expanded(
            child: ShadButton.outline(
              onPressed:
                  widget.enabled && !widget.isLoading ? widget.onCancel : null,
              child: Text('common.cancel'.tr()),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
        ],
        Expanded(
          child: ShadButton(
            onPressed: widget.enabled && !widget.isLoading && _canSubmit()
                ? _handleSubmit
                : null,
            child: widget.isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text('common.saving'.tr()),
                    ],
                  )
                : Text(widget.transaction != null
                    ? 'transactions.updateTransaction'.tr()
                    : 'transactions.createTransaction'.tr()),
          ),
        ),
      ],
    );
  }

  void _selectType(TransactionType type) {
    setState(() {
      _type = type;
      // Clear category if switching to transfer
      if (type == TransactionType.transfer) {
        _selectedCategoryId = null;
        _categoryError = null;
      }
      // Clear transfer account if switching away from transfer
      if (type != TransactionType.transfer) {
        _transferToAccountId = null;
        _transferAccountError = null;
      }
    });
  }

  bool _canSubmit() {
    return _amount != null &&
        _amount! > 0 &&
        _selectedAccountId != null &&
        (_type == TransactionType.transfer
            ? _transferToAccountId != null
            : _selectedCategoryId != null) &&
        _amountError == null &&
        _accountError == null &&
        _categoryError == null &&
        _transferAccountError == null;
  }

  void _handleSubmit() {
    print('📝 Form submission started');

    // Prevent multiple submissions
    if (widget.isLoading) {
      print('⚠️ Already loading, skipping submission');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    if (!_canSubmit()) {
      print('❌ Cannot submit, validation failed');
      print('  - Amount: $_amount');
      print('  - Account ID: $_selectedAccountId');
      print('  - Category ID: $_selectedCategoryId');
      print('  - Transfer Account ID: $_transferToAccountId');
      print('  - Type: $_type');
      return;
    }

    // Additional validation
    if (_amount == null || _amount! <= 0) {
      print('❌ Invalid amount: $_amount');
      return;
    }

    if (_selectedAccountId == null || _selectedAccountId!.isEmpty) {
      print('❌ No account selected');
      return;
    }

    if (_type != TransactionType.transfer &&
        (_selectedCategoryId == null || _selectedCategoryId!.isEmpty)) {
      print('❌ No category selected for non-transfer transaction');
      return;
    }

    if (_type == TransactionType.transfer &&
        (_transferToAccountId == null || _transferToAccountId!.isEmpty)) {
      print('❌ No transfer account selected for transfer transaction');
      return;
    }

    print('✅ Form validation passed, creating form data');
    final formData = (
      amount: _amount!,
      categoryId: _selectedCategoryId ?? '',
      date: _selectedDate,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      type: _type,
      imagePath: _imagePath,
      accountId: _selectedAccountId!,
      currency: _currency,
      transferToAccountId: _transferToAccountId,
      metadata: null,
    );

    print('📤 Form data created:');
    print('  - Amount: ${formData.amount}');
    print('  - Account: ${formData.accountId}');
    print('  - Category: ${formData.categoryId}');
    print('  - Type: ${formData.type}');
    print('  - Currency: ${formData.currency}');
    print('  - Transfer To: ${formData.transferToAccountId}');

    print('📤 Calling parent submit handler');
    // Immediately call the parent callback to trigger loading state
    widget.onSubmit?.call(formData);
  }

  String? _validateAmount(double? amount) {
    if (amount == null || amount <= 0) {
      return 'validation.invalidAmount'.tr();
    }
    return null;
  }

  String? _validateAccount(Account? account) {
    if (account == null) {
      return 'validation.accountRequired'.tr();
    }
    return null;
  }

  String? _validateCategory(Category? category) {
    if (_type == TransactionType.transfer) return null;
    if (category == null) {
      return 'transactions.categoryRequired'.tr();
    }
    return null;
  }

  String? _validateTransferAccount(Account? account) {
    if (_type != TransactionType.transfer) return null;
    if (account == null) {
      return 'transactions.transferAccountRequired'.tr();
    }
    if (account.id == _selectedAccountId) {
      return 'transactions.transferAccountSameError'.tr();
    }
    return null;
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

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }
}
