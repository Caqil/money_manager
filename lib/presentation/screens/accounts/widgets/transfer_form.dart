import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/validation_helper.dart';
import '../../../../data/models/account.dart';
import '../../../providers/account_provider.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/forms/custom_date_picker.dart';
import '../../../widgets/forms/custom_text_field.dart';
import '../widgets/account_item.dart';

class TransferForm extends ConsumerStatefulWidget {
  final Account? fromAccount;
  final Account? toAccount;
  final Function(TransferFormData) onSubmit;
  final bool isLoading;
  final bool enabled;

  const TransferForm({
    super.key,
    this.fromAccount,
    this.toAccount,
    required this.onSubmit,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  ConsumerState<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends ConsumerState<TransferForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  Account? _fromAccount;
  Account? _toAccount;
  DateTime _transferDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _fromAccount = widget.fromAccount;
    _toAccount = widget.toAccount;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (_fromAccount == null) {
      _showError('Please select a source account');
      return;
    }

    if (_toAccount == null) {
      _showError('Please select a destination account');
      return;
    }

    if (_fromAccount!.id == _toAccount!.id) {
      _showError('Source and destination accounts must be different');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    // Check insufficient funds for non-credit accounts
    if (_fromAccount!.type != AccountType.creditCard &&
        _fromAccount!.balance < amount) {
      _showError('Insufficient funds in ${_fromAccount!.name}');
      return;
    }

    final formData = TransferFormData(
      fromAccountId: _fromAccount!.id,
      toAccountId: _toAccount!.id,
      amount: amount,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      transferDate: _transferDate,
    );

    widget.onSubmit(formData);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _swapAccounts() {
    if (_fromAccount != null && _toAccount != null) {
      setState(() {
        final temp = _fromAccount;
        _fromAccount = _toAccount;
        _toAccount = temp;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final accountsAsync = ref.watch(activeAccountsProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transfer Direction Header
          Row(
            children: [
              const Icon(Icons.arrow_forward, color: AppColors.primary),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'accounts.transferFunds'.tr(),
                style: theme.textTheme.h3,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Account Selection Section
          accountsAsync.when(
            loading: () => const ShimmerLoading(
              child: SkeletonLoader(height: 200, width: double.infinity),
            ),
            error: (error, _) => CustomErrorWidget(
              title: 'Error loading accounts',
              message: error.toString(),
            ),
            data: (accounts) => _buildAccountSelection(accounts),
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Transfer Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _amountController,
                  labelText: 'accounts.transferAmount'.tr(),
                  placeholder: 'forms.enterAmount'.tr(),
                  enabled: widget.enabled && !widget.isLoading,
                  required: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) =>
                      ValidationHelper.getPositiveAmountErrorMessage(
                          value ?? ''),
                  textInputAction: TextInputAction.next,
                  leading: const Icon(Icons.attach_money),
                ),
              ),

              const SizedBox(width: AppDimensions.spacingM),

              // Quick Amount Buttons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick amounts',
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    if (_fromAccount != null) ...[
                      _buildQuickAmountButton(
                          '25%', _fromAccount!.balance * 0.25),
                      const SizedBox(height: AppDimensions.spacingXs),
                      _buildQuickAmountButton(
                          '50%', _fromAccount!.balance * 0.5),
                      const SizedBox(height: AppDimensions.spacingXs),
                      _buildQuickAmountButton('All', _fromAccount!.balance),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Transfer Date
          CustomDatePicker(
            labelText: 'transactions.date'.tr(),
            selectedDate: _transferDate,
            enabled: widget.enabled && !widget.isLoading,
            required: true,
            onChanged: (date) {
              if (date != null) {
                setState(() => _transferDate = date);
              }
            },
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // Notes
          CustomTextField(
            controller: _notesController,
            labelText: 'transactions.notes'.tr(),
            placeholder: 'Optional transfer notes',
            enabled: widget.enabled && !widget.isLoading,
            maxLines: 3,
            maxLength: 500,
            validator: (value) =>
                ValidationHelper.getNotesErrorMessage(value ?? ''),
            textInputAction: TextInputAction.done,
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Transfer Summary
          if (_fromAccount != null && _toAccount != null) ...[
            _buildTransferSummary(),
            const SizedBox(height: AppDimensions.spacingL),
          ],

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed:
                  widget.enabled && !widget.isLoading ? _handleSubmit : null,
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.swap_horiz, size: 18),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text('Execute Transfer'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSelection(List<Account> accounts) {
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        // From Account
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'accounts.fromAccount'.tr(),
              style: theme.textTheme.h4,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            _fromAccount != null
                ? AccountItemCompact(
                    account: _fromAccount!,
                    showBalance: true,
                    onTap: widget.enabled && !widget.isLoading
                        ? () => _showAccountSelector(true, accounts)
                        : null,
                  )
                : ShadButton.outline(
                    onPressed: widget.enabled && !widget.isLoading
                        ? () => _showAccountSelector(true, accounts)
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 18),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text('forms.selectAccount'.tr()),
                      ],
                    ),
                  ),
          ],
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // Swap Button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShadButton.ghost(
              onPressed:
                  widget.enabled && !widget.isLoading ? _swapAccounts : null,
              child: const Icon(Icons.swap_vert, size: 24),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // To Account
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'accounts.toAccount'.tr(),
              style: theme.textTheme.h4,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            _toAccount != null
                ? AccountItemCompact(
                    account: _toAccount!,
                    showBalance: true,
                    onTap: widget.enabled && !widget.isLoading
                        ? () => _showAccountSelector(false, accounts)
                        : null,
                  )
                : ShadButton.outline(
                    onPressed: widget.enabled && !widget.isLoading
                        ? () => _showAccountSelector(false, accounts)
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 18),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text('forms.selectAccount'.tr()),
                      ],
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmountButton(String label, double amount) {
    return SizedBox(
      width: double.infinity,
      child: ShadButton.outline(
        onPressed: widget.enabled && !widget.isLoading
            ? () => _amountController.text = amount.toStringAsFixed(2)
            : null,
        size: ShadButtonSize.sm,
        child: Text(label),
      ),
    );
  }

  Widget _buildTransferSummary() {
    final theme = ShadTheme.of(context);
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      backgroundColor: theme.colorScheme.accent.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transfer Summary',
              style: theme.textTheme.h4,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'From',
                        style: theme.textTheme.muted,
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      Text(
                        _fromAccount!.name,
                        style: theme.textTheme.p,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        _formatCurrency(
                            _fromAccount!.balance, _fromAccount!.currency),
                        style: theme.textTheme.small.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: AppColors.primary),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'To',
                        style: theme.textTheme.muted,
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      Text(
                        _toAccount!.name,
                        style: theme.textTheme.p,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        _formatCurrency(
                            _toAccount!.balance, _toAccount!.currency),
                        style: theme.textTheme.small.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (amount > 0) ...[
              const SizedBox(height: AppDimensions.spacingM),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Column(
                  children: [
                    Text(
                      'Transfer Amount',
                      style: theme.textTheme.muted,
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      _formatCurrency(amount, _fromAccount!.currency),
                      style: theme.textTheme.h2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAccountSelector(bool isFromAccount, List<Account> accounts) {
    final excludeAccount = isFromAccount ? _toAccount : _fromAccount;
    final availableAccounts =
        accounts.where((account) => account.id != excludeAccount?.id).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            children: [
              Text(
                isFromAccount
                    ? 'Select Source Account'
                    : 'Select Destination Account',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: availableAccounts.length,
                  itemBuilder: (context, index) => AccountItemCompact(
                    account: availableAccounts[index],
                    showBalance: true,
                    onTap: () {
                      setState(() {
                        if (isFromAccount) {
                          _fromAccount = availableAccounts[index];
                        } else {
                          _toAccount = availableAccounts[index];
                        }
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount, String currency) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'CHF':
        return 'CHF';
      case 'CNY':
        return '¥';
      case 'INR':
        return '₹';
      default:
        return currency;
    }
  }
}

class TransferFormData {
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final String? notes;
  final DateTime transferDate;

  const TransferFormData({
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.notes,
    required this.transferDate,
  });
}
