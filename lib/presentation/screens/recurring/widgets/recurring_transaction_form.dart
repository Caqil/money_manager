import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/recurring_transaction.dart';
import '../../../../data/models/transaction.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/forms/custom_date_picker.dart';
import '../../../widgets/forms/custom_dropdown.dart';
import 'frequency_selector.dart';

class RecurringTransactionForm extends ConsumerStatefulWidget {
  final RecurringTransaction? recurringTransaction;
  final TransactionType? defaultType;
  final String? defaultAccountId;
  final String? defaultCategoryId;
  final bool enabled;
  final bool isLoading;
  final Function(RecurringTransactionFormData)? onSubmit;
  final VoidCallback? onCancel;

  const RecurringTransactionForm({
    super.key,
    this.recurringTransaction,
    this.defaultType,
    this.defaultAccountId,
    this.defaultCategoryId,
    this.enabled = true,
    this.isLoading = false,
    this.onSubmit,
    this.onCancel,
  });

  @override
  ConsumerState<RecurringTransactionForm> createState() =>
      _RecurringTransactionFormState();
}

class _RecurringTransactionFormState
    extends ConsumerState<RecurringTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  // Form fields
  TransactionType _type = TransactionType.expense;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _transferToAccountId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  int _intervalValue = 1;
  List<int>? _weekdays;
  int? _dayOfMonth;
  List<int>? _monthsOfYear;
  bool _enableNotifications = true;
  int _notificationDaysBefore = 1;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.recurringTransaction != null) {
      final transaction = widget.recurringTransaction!;
      _nameController.text = transaction.name;
      _amountController.text = transaction.amount.toString();
      _notesController.text = transaction.notes ?? '';
      _type = transaction.type;
      _selectedAccountId = transaction.accountId;
      _selectedCategoryId = transaction.categoryId;
      _transferToAccountId = transaction.transferToAccountId;
      _startDate = transaction.startDate;
      _endDate = transaction.endDate;
      _frequency = transaction.frequency;
      _intervalValue = transaction.intervalValue;
      _weekdays = transaction.weekdays;
      _dayOfMonth = transaction.dayOfMonth;
      _monthsOfYear = transaction.monthsOfYear;
      _enableNotifications = transaction.enableNotifications;
      _notificationDaysBefore = transaction.notificationDaysBefore;
    } else {
      // Set defaults
      _type = widget.defaultType ?? TransactionType.expense;
      _selectedAccountId = widget.defaultAccountId;
      _selectedCategoryId = widget.defaultCategoryId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfo(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildTransactionDetails(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildFrequencySection(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildScheduleSection(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildNotificationSettings(),
            const SizedBox(height: AppDimensions.spacingXl),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recurring.basicInformation'.tr(),
          style: ShadTheme.of(context).textTheme.h3,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Transaction name
        ShadInputFormField(
          controller: _nameController,
          label: Text('recurring.transactionName'.tr()),
          placeholder: Text('recurring.enterTransactionName'.tr()),
          enabled: widget.enabled && !widget.isLoading,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'validation.required'.tr();
            }
            if (value.trim().length < 2) {
              return 'validation.tooShort'.tr(args: ['2']);
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Transaction type
        _buildTypeSelector(),
        const SizedBox(height: AppDimensions.spacingM),

        // Amount
        Row(
          children: [
            Expanded(
              child: ShadInputFormField(
                controller: _amountController,
                label: Text('recurring.amount'.tr()),
                placeholder: Text('recurring.enterAmount'.tr()),
                enabled: widget.enabled && !widget.isLoading,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                leading: Text(CurrencyFormatter.getSymbol(
                    ref.watch(baseCurrencyProvider))),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'validation.required'.tr();
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'validation.invalidAmount'.tr();
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recurring.transactionDetails'.tr(),
          style: ShadTheme.of(context).textTheme.h3,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Account selection
        _buildAccountSelector(),
        const SizedBox(height: AppDimensions.spacingM),

        // Transfer to account (if transfer)
        if (_type == TransactionType.transfer) ...[
          _buildTransferAccountSelector(),
          const SizedBox(height: AppDimensions.spacingM),
        ],

        // Category selection (not for transfers)
        if (_type != TransactionType.transfer) ...[
          _buildCategorySelector(),
          const SizedBox(height: AppDimensions.spacingM),
        ],

        // Notes
        ShadInputFormField(
          controller: _notesController,
          label: Text('recurring.notes'.tr()),
          placeholder: Text('recurring.enterNotes'.tr()),
          enabled: widget.enabled && !widget.isLoading,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recurring.schedule'.tr(),
          style: ShadTheme.of(context).textTheme.h3,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        FrequencySelector(
          selectedFrequency: _frequency,
          intervalValue: _intervalValue,
          weekdays: _weekdays,
          dayOfMonth: _dayOfMonth,
          monthsOfYear: _monthsOfYear,
          onFrequencyChanged: (data) {
            setState(() {
              _frequency = data.frequency;
              _intervalValue = data.intervalValue;
              _weekdays = data.weekdays;
              _dayOfMonth = data.dayOfMonth;
              _monthsOfYear = data.monthsOfYear;
            });
          },
          enabled: widget.enabled && !widget.isLoading,
          labelText: 'recurring.frequency'.tr(),
          required: true,
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recurring.dateRange'.tr(),
          style: ShadTheme.of(context).textTheme.h3,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Start date
        CustomDatePicker(
          labelText: 'recurring.startDate'.tr(),
          selectedDate: _startDate,
          onChanged: widget.enabled && !widget.isLoading
              ? (date) => setState(() => _startDate = date ?? _startDate)
              : null,
          required: true,
          fromMonth: DateTime.now().subtract(const Duration(days: 365)),
          toMonth: DateTime.now().add(const Duration(days: 365 * 5)),
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // End date (optional)
        CustomDatePicker(
          labelText: 'recurring.endDate'.tr(),
          selectedDate: _endDate,
          onChanged: widget.enabled && !widget.isLoading
              ? (date) => setState(() => _endDate = date)
              : null,
          fromMonth: _startDate.add(const Duration(days: 1)),
          toMonth: DateTime.now().add(const Duration(days: 365 * 10)),
        ),

        if (_endDate == null) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    'recurring.noEndDateNote'.tr(),
                    style: ShadTheme.of(context).textTheme.small.copyWith(
                          color: AppColors.info,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recurring.notifications'.tr(),
          style: ShadTheme.of(context).textTheme.h3,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Enable notifications toggle
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'recurring.enableNotifications'.tr(),
                    style: ShadTheme.of(context).textTheme.h4,
                  ),
                  Text(
                    'recurring.notificationDescription'.tr(),
                    style: ShadTheme.of(context).textTheme.small.copyWith(
                          color:
                              ShadTheme.of(context).colorScheme.mutedForeground,
                        ),
                  ),
                ],
              ),
            ),
            ShadSwitch(
              value: _enableNotifications,
              onChanged: widget.enabled && !widget.isLoading
                  ? (value) => setState(() => _enableNotifications = value)
                  : null,
            ),
          ],
        ),

        if (_enableNotifications) ...[
          const SizedBox(height: AppDimensions.spacingM),

          // Notification days before
          Row(
            children: [
              Text(
                'recurring.notifyDaysBefore'.tr(),
                style: ShadTheme.of(context).textTheme.p,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              SizedBox(
                width: 80,
                child: ShadInput(
                  initialValue: _notificationDaysBefore.toString(),
                  keyboardType: TextInputType.number,
                  enabled: widget.enabled && !widget.isLoading,
                  onChanged: (value) {
                    final days = int.tryParse(value);
                    if (days != null && days >= 0 && days <= 30) {
                      setState(() {
                        _notificationDaysBefore = days;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                _notificationDaysBefore == 1 ? 'day' : 'days',
                style: ShadTheme.of(context).textTheme.p,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTypeSelector() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recurring.transactionType'.tr(),
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
                child: ShadButton.raw(
                  onPressed: widget.enabled && !widget.isLoading
                      ? () => _selectType(type)
                      : null,
                  variant: isSelected
                      ? ShadButtonVariant.primary
                      : ShadButtonVariant.outline,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getTypeIcon(type),
                        size: 16,
                        color: isSelected ? Colors.white : _getTypeColor(type),
                      ),
                      const SizedBox(width: AppDimensions.spacingXs),
                      Text(
                        _getTypeDisplayName(type),
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : _getTypeColor(type),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAccountSelector() {
    final accounts = ref.watch(accountListProvider);

    return accounts.when(
      data: (accountList) {
        final dropdownItems = accountList
            .map((account) => DropdownItem<String>(
                  value: account.id,
                  text: account.name,
                  subtitle: CurrencyFormatter.format(
                    account.balance,
                    currency: account.currency,
                  ),
                  icon: Icon(
                    Icons.account_balance_wallet,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ))
            .toList();

        return CustomDropdown<String>(
          labelText: 'recurring.account'.tr(),
          placeholder: 'recurring.selectAccount'.tr(),
          value: _selectedAccountId,
          items: dropdownItems,
          onChanged: widget.enabled && !widget.isLoading
              ? (value) => setState(() => _selectedAccountId = value)
              : null,
          required: true,
        );
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('Error loading accounts: $error'),
    );
  }

  Widget _buildTransferAccountSelector() {
    final accounts = ref.watch(accountListProvider);

    return accounts.when(
      data: (accountList) {
        final filteredAccounts = accountList
            .where((account) => account.id != _selectedAccountId)
            .toList();

        final dropdownItems = filteredAccounts
            .map((account) => DropdownItem<String>(
                  value: account.id,
                  text: account.name,
                  subtitle: CurrencyFormatter.format(
                    account.balance,
                    currency: account.currency,
                  ),
                  icon: Icon(
                    Icons.account_balance_wallet,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ))
            .toList();

        return CustomDropdown<String>(
          labelText: 'recurring.transferToAccount'.tr(),
          placeholder: 'recurring.selectTransferAccount'.tr(),
          value: _transferToAccountId,
          items: dropdownItems,
          onChanged: widget.enabled && !widget.isLoading
              ? (value) => setState(() => _transferToAccountId = value)
              : null,
          required: true,
        );
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('Error loading accounts: $error'),
    );
  }

  Widget _buildCategorySelector() {
    final categories = ref.watch(categoryListProvider);

    return categories.when(
      data: (categoryList) {
        final filteredCategories = categoryList
            .where((category) =>
                (category.type == CategoryType.both) ||
                (_type == TransactionType.income &&
                    category.type == CategoryType.income) ||
                (_type == TransactionType.expense &&
                    category.type == CategoryType.expense))
            .toList();

        final dropdownItems = filteredCategories
            .map((category) => DropdownItem<String>(
                  value: category.id,
                  text: category.name,
                  icon: Icon(
                    Icons.category,
                    size: 20,
                    color: Color(category.color ?? AppColors.primary.value),
                  ),
                ))
            .toList();

        return CustomDropdown<String>(
          labelText: 'recurring.category'.tr(),
          placeholder: 'recurring.selectCategory'.tr(),
          value: _selectedCategoryId,
          items: dropdownItems,
          onChanged: widget.enabled && !widget.isLoading
              ? (value) => setState(() => _selectedCategoryId = value)
              : null,
          required: true,
        );
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('Error loading categories: $error'),
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
            onPressed:
                widget.enabled && !widget.isLoading && widget.onSubmit != null
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
                : Text(widget.recurringTransaction != null
                    ? 'recurring.updateRecurring'.tr()
                    : 'recurring.createRecurring'.tr()),
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
      }

      // Clear transfer account if switching away from transfer
      if (type != TransactionType.transfer) {
        _transferToAccountId = null;
      }
    });
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.add;
      case TransactionType.expense:
        return Icons.remove;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.success;
      case TransactionType.expense:
        return AppColors.error;
      case TransactionType.transfer:
        return AppColors.primary;
    }
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

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final formData = RecurringTransactionFormData(
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text),
      type: _type,
      accountId: _selectedAccountId!,
      categoryId: _selectedCategoryId,
      transferToAccountId: _transferToAccountId,
      frequency: _frequency,
      intervalValue: _intervalValue,
      weekdays: _weekdays,
      dayOfMonth: _dayOfMonth,
      monthsOfYear: _monthsOfYear,
      startDate: _startDate,
      endDate: _endDate,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      enableNotifications: _enableNotifications,
      notificationDaysBefore: _notificationDaysBefore,
    );

    widget.onSubmit?.call(formData);
  }
}

// Data class for form submission
class RecurringTransactionFormData {
  final String name;
  final double amount;
  final TransactionType type;
  final String accountId;
  final String? categoryId;
  final String? transferToAccountId;
  final RecurrenceFrequency frequency;
  final int intervalValue;
  final List<int>? weekdays;
  final int? dayOfMonth;
  final List<int>? monthsOfYear;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool enableNotifications;
  final int notificationDaysBefore;

  const RecurringTransactionFormData({
    required this.name,
    required this.amount,
    required this.type,
    required this.accountId,
    this.categoryId,
    this.transferToAccountId,
    required this.frequency,
    required this.intervalValue,
    this.weekdays,
    this.dayOfMonth,
    this.monthsOfYear,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.enableNotifications,
    required this.notificationDaysBefore,
  });
}
