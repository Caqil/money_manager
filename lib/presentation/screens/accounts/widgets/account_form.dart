import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/validation_helper.dart';
import '../../../../data/models/account.dart';
import '../../../widgets/forms/custom_checkbox.dart';
import '../../../widgets/forms/custom_text_field.dart';

class AccountForm extends ConsumerStatefulWidget {
  final Account? initialAccount;
  final Function(AccountFormData) onSubmit;
  final bool isLoading;
  final bool enabled;

  const AccountForm({
    super.key,
    this.initialAccount,
    required this.onSubmit,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _balanceController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;

  AccountType _selectedType = AccountType.checking;
  String _selectedCurrency = 'USD';
  bool _isActive = true;
  bool _includeInTotal = true;
  Color _selectedColor = AppColors.primary;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeFormData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _balanceController = TextEditingController();
    _creditLimitController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountNumberController = TextEditingController();
  }

  void _initializeFormData() {
    if (widget.initialAccount != null) {
      final account = widget.initialAccount!;
      _nameController.text = account.name;
      _descriptionController.text = account.description ?? '';
      _balanceController.text = account.balance.toString();
      _creditLimitController.text = account.creditLimit?.toString() ?? '';
      _bankNameController.text = account.bankName ?? '';
      _accountNumberController.text = account.accountNumber ?? '';
      _selectedType = account.type;
      _selectedCurrency = account.currency;
      _isActive = account.isActive;
      _includeInTotal = account.includeInTotal;
      _selectedColor = account.color != null ? Color(account.color!) : AppColors.primary;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final formData = AccountFormData(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      balance: double.tryParse(_balanceController.text.trim()) ?? 0.0,
      type: _selectedType,
      currency: _selectedCurrency,
      isActive: _isActive,
      includeInTotal: _includeInTotal,
      color: _selectedColor.value,
      creditLimit: _creditLimitController.text.trim().isEmpty
          ? null
          : double.tryParse(_creditLimitController.text.trim()),
      bankName: _bankNameController.text.trim().isEmpty
          ? null
          : _bankNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim().isEmpty
          ? null
          : _accountNumberController.text.trim(),
    );

    widget.onSubmit(formData);
  }

  @override
  Widget build(BuildContext context) {

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Name
          CustomTextField(
            controller: _nameController,
            labelText: 'accounts.accountName'.tr(),
            placeholder: 'Enter account name',
            enabled: widget.enabled && !widget.isLoading,
            required: true,
            validator: (value) => ValidationHelper.getAccountNameErrorMessage(value ?? ''),
            textInputAction: TextInputAction.next,
          ),
          
          const SizedBox(height: AppDimensions.spacingM),

          // Account Type
          ShadSelect<AccountType>(
            placeholder: Text('accounts.accountType'.tr()),
            options: AccountType.values.map((type) => ShadOption(
              value: type,
              child: Row(
                children: [
                  Icon(_getAccountTypeIcon(type), size: 16),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text('accounts.types.${type.name}'.tr()),
                ],
              ),
            )).toList(),
            selectedOptionBuilder: (context, value) => Row(
              children: [
                Icon(_getAccountTypeIcon(value), size: 16),
                const SizedBox(width: AppDimensions.spacingS),
                Text('accounts.types.${value.name}'.tr()),
              ],
            ),
            onChanged: widget.enabled && !widget.isLoading ? (type) {
              if (type != null) {
                setState(() {
                  _selectedType = type;
                  _selectedColor = _getAccountTypeColor(type);
                });
              }
            } : null,
            initialValue: _selectedType,
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // Balance and Currency Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Initial Balance
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _balanceController,
                  labelText: 'accounts.balance'.tr(),
                  placeholder: 'forms.enterAmount'.tr(),
                  enabled: widget.enabled && !widget.isLoading,
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => ValidationHelper.getAmountErrorMessage(value ?? ''),
                  textInputAction: TextInputAction.next,
                ),
              ),
              
              const SizedBox(width: AppDimensions.spacingM),
              
              // Currency
              Expanded(
                child: ShadSelect<String>(
                  placeholder: Text('common.currency'.tr()),
                  options: ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'INR']
                      .map((currency) => ShadOption(
                        value: currency,
                        child: Text('currency.$currency'.tr()),
                      )).toList(),
                  selectedOptionBuilder: (context, value) => Text('currency.$value'.tr()),
                  onChanged: widget.enabled && !widget.isLoading ? (currency) {
                    if (currency != null) {
                      setState(() => _selectedCurrency = currency);
                    }
                  } : null,
                  initialValue: _selectedCurrency,
                ),
              ),
            ],
          ),

          // Credit Limit (only for credit cards)
          if (_selectedType == AccountType.creditCard) ...[
            const SizedBox(height: AppDimensions.spacingM),
            CustomTextField(
              controller: _creditLimitController,
              labelText: 'accounts.creditLimit'.tr(),
              placeholder: 'forms.enterAmount'.tr(),
              enabled: widget.enabled && !widget.isLoading,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  return ValidationHelper.getPositiveAmountErrorMessage(value);
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
          ],

          const SizedBox(height: AppDimensions.spacingM),

          // Bank Information (optional)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _bankNameController,
                  labelText: 'accounts.bankName'.tr(),
                  placeholder: 'Enter bank name',
                  enabled: widget.enabled && !widget.isLoading,
                  textInputAction: TextInputAction.next,
                ),
              ),
              
              const SizedBox(width: AppDimensions.spacingM),
              
              Expanded(
                child: CustomTextField(
                  controller: _accountNumberController,
                  labelText: 'accounts.accountNumber'.tr(),
                  placeholder: 'Last 4 digits',
                  enabled: widget.enabled && !widget.isLoading,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // Description
          CustomTextField(
            controller: _descriptionController,
            labelText: 'accounts.description'.tr(),
            placeholder: 'Optional description',
            enabled: widget.enabled && !widget.isLoading,
            maxLines: 3,
            maxLength: 500,
            validator: (value) => ValidationHelper.getNotesErrorMessage(value ?? ''),
            textInputAction: TextInputAction.done,
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // Color Selection
          _buildColorSelector(),

          const SizedBox(height: AppDimensions.spacingM),

          // Options
          Column(
            children: [
              CustomCheckbox(
                value: _isActive,
                onChanged: widget.enabled && !widget.isLoading
                    ? (value) => setState(() => _isActive = value)
                    : null,
                labelText: 'accounts.isActive'.tr(),
                sublabelText: 'Include this account in calculations and displays',
              ),
              
              const SizedBox(height: AppDimensions.spacingS),
              
              CustomCheckbox(
                value: _includeInTotal,
                onChanged: widget.enabled && !widget.isLoading
                    ? (value) => setState(() => _includeInTotal = value )
                    : null,
                labelText: 'accounts.includeInTotal'.tr(),
                sublabelText: 'Include this account balance in total calculations',
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingXl),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed: widget.enabled && !widget.isLoading ? _handleSubmit : null,
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
                        Text('common.loading'.tr()),
                      ],
                    )
                  : Text(widget.initialAccount != null 
                      ? 'common.update'.tr() 
                      : 'common.create'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    final theme = ShadTheme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: [
            _getAccountTypeColor(_selectedType),
            ...AppColors.categoryColors,
          ].map((color) => GestureDetector(
            onTap: widget.enabled && !widget.isLoading
                ? () => setState(() => _selectedColor = color)
                : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: _selectedColor == color
                    ? Border.all(
                        color: theme.colorScheme.foreground,
                        width: 2,
                      )
                    : null,
              ),
              child: _selectedColor == color
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          )).toList(),
        ),
      ],
    );
  }

  Color _getAccountTypeColor(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return AppColors.success;
      case AccountType.checking:
        return AppColors.primary;
      case AccountType.savings:
        return AppColors.secondary;
      case AccountType.creditCard:
        return AppColors.warning;
      case AccountType.investment:
        return AppColors.accent;
      case AccountType.loan:
        return AppColors.error;
      case AccountType.other:
        return AppColors.categoryColors[0];
    }
  }

  IconData _getAccountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments;
      case AccountType.checking:
        return Icons.account_balance;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.loan:
        return Icons.money_off;
      case AccountType.other:
        return Icons.account_balance_wallet;
    }
  }
}

class AccountFormData {
  final String name;
  final String? description;
  final double balance;
  final AccountType type;
  final String currency;
  final bool isActive;
  final bool includeInTotal;
  final int color;
  final double? creditLimit;
  final String? bankName;
  final String? accountNumber;

  const AccountFormData({
    required this.name,
    this.description,
    required this.balance,
    required this.type,
    required this.currency,
    required this.isActive,
    required this.includeInTotal,
    required this.color,
    this.creditLimit,
    this.bankName,
    this.accountNumber,
  });

  Account toAccount({required String id}) {
    final now = DateTime.now();
    return Account(
      id: id,
      name: name,
      description: description,
      balance: balance,
      type: type,
      currency: currency,
      isActive: isActive,
      includeInTotal: includeInTotal,
      color: color,
      creditLimit: creditLimit,
      bankName: bankName,
      accountNumber: accountNumber,
      createdAt: now,
      updatedAt: now,
    );
  }

  Account updateAccount(Account existing) {
    return existing.copyWith(
      name: name,
      description: description,
      balance: balance,
      type: type,
      currency: currency,
      isActive: isActive,
      includeInTotal: includeInTotal,
      color: color,
      creditLimit: creditLimit,
      bankName: bankName,
      accountNumber: accountNumber,
      updatedAt: DateTime.now(),
    );
  }
}