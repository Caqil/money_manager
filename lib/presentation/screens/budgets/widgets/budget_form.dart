import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/validation_helper.dart';
import '../../../../data/models/budget.dart';
import '../../../../data/models/category.dart';
import '../../../../presentation/providers/category_provider.dart';
import '../../../../presentation/providers/account_provider.dart';
import '../../../widgets/forms/custom_text_field.dart';
import '../../../widgets/forms/custom_date_picker.dart';
import '../../../widgets/forms/custom_checkbox.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/error_widget.dart';

class BudgetForm extends ConsumerStatefulWidget {
  final Budget? initialBudget;
  final Function(BudgetFormData) onSubmit;
  final bool isLoading;
  final bool enabled;

  const BudgetForm({
    super.key,
    this.initialBudget,
    required this.onSubmit,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  ConsumerState<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _alertThresholdController;

  String? _selectedCategoryId;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isActive = true;
  bool _enableAlerts = true;
  BudgetRolloverType _rolloverType = BudgetRolloverType.reset;
  List<String> _selectedAccountIds = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeFormData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _limitController = TextEditingController();
    _descriptionController = TextEditingController();
    _alertThresholdController = TextEditingController(text: '80');
  }

  void _initializeFormData() {
    if (widget.initialBudget != null) {
      final budget = widget.initialBudget!;
      _nameController.text = budget.name;
      _limitController.text = budget.limit.toString();
      _descriptionController.text = budget.description ?? '';
      _alertThresholdController.text =
          (budget.alertThreshold * 100).toStringAsFixed(0);
      _selectedCategoryId = budget.categoryId;
      _selectedPeriod = budget.period;
      _startDate = budget.startDate;
      _endDate = budget.endDate;
      _isActive = budget.isActive;
      _enableAlerts = budget.enableAlerts;
      _rolloverType = budget.rolloverType;
      _selectedAccountIds = budget.accountIds?.toList() ?? [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _descriptionController.dispose();
    _alertThresholdController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      _showError('budgets.selectCategory'.tr());
      return;
    }

    // Set end date based on period if custom period isn't selected
    DateTime? endDate = _endDate;
    if (_selectedPeriod != BudgetPeriod.custom) {
      endDate = _calculateEndDate(_startDate, _selectedPeriod);
    }

    final formData = BudgetFormData(
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId!,
      limit: double.tryParse(_limitController.text.trim()) ?? 0.0,
      period: _selectedPeriod,
      startDate: _startDate,
      endDate: endDate,
      isActive: _isActive,
      alertThreshold:
          (double.tryParse(_alertThresholdController.text.trim()) ?? 80.0) /
              100.0,
      enableAlerts: _enableAlerts,
      accountIds: _selectedAccountIds.isEmpty ? null : _selectedAccountIds,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      rolloverType: _rolloverType,
    );

    widget.onSubmit(formData);
  }

  void _showError(String message) {
    ShadSonner.of(context).show(
      ShadToast.raw(
        variant: ShadToastVariant.destructive,
        description: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget Name
          CustomTextField(
            controller: _nameController,
            labelText: 'budgets.budgetName'.tr(),
            placeholder: 'budgets.enterBudgetName'.tr(),
            enabled: widget.enabled && !widget.isLoading,
            required: true,
            validator: (value) => ValidationHelper.getNameErrorMessage(
                value ?? '',
                fieldName: 'Name'),
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // Category Selection
          _buildCategorySelector(categoriesAsync),

          const SizedBox(height: AppDimensions.spacingM),

          // Budget Limit and Alert Threshold
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _limitController,
                  labelText: 'budgets.limit'.tr(),
                  placeholder: 'budgets.enterLimit'.tr(),
                  enabled: widget.enabled && !widget.isLoading,
                  required: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) =>
                      ValidationHelper.getPositiveAmountErrorMessage(
                          value ?? ''),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: CustomTextField(
                  controller: _alertThresholdController,
                  labelText: 'budgets.alertThreshold'.tr(),
                  placeholder: '80',
                  enabled: widget.enabled && !widget.isLoading,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final threshold = double.tryParse(value ?? '');
                    if (threshold == null || threshold < 0 || threshold > 100) {
                      return 'validation.invalidPercentage'.tr();
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  trailing: const Icon(Icons.percent),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // Period Selection
          _buildPeriodSelector(),

          const SizedBox(height: AppDimensions.spacingM),

          // Date Range
          _buildDateRange(),

          const SizedBox(height: AppDimensions.spacingM),

          // Rollover Type
          _buildRolloverTypeSelector(),

          const SizedBox(height: AppDimensions.spacingM),

          // Account Selection (Optional)
          _buildAccountSelector(),

          const SizedBox(height: AppDimensions.spacingM),

          // Description
          CustomTextField(
            controller: _descriptionController,
            labelText: 'budgets.description'.tr(),
            placeholder: 'budgets.enterDescription'.tr(),
            enabled: widget.enabled && !widget.isLoading,
            maxLines: 3,
            maxLength: 500,
            validator: (value) =>
                ValidationHelper.getNotesErrorMessage(value ?? ''),
            textInputAction: TextInputAction.newline,
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // Settings
          _buildSettings(),

          const SizedBox(height: AppDimensions.spacingXl),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed:
                  widget.enabled && !widget.isLoading ? _handleSubmit : null,
              size: ShadButtonSize.lg,
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.initialBudget != null
                      ? 'budgets.updateBudget'.tr()
                      : 'budgets.createBudget'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(AsyncValue<List<Category>> categoriesAsync) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'budgets.category'.tr(),
          style: theme.textTheme.small.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        categoriesAsync.when(
          loading: () => const ShimmerLoading(child: SizedBox()),
          error: (error, stack) => CustomErrorWidget(
            title: 'categories.loadError'.tr(),
            message: error.toString(),
            onActionPressed: () => ref.refresh(activeCategoriesProvider),
          ),
          data: (categories) {
            final expenseCategories = categories
                .where((cat) =>
                    cat.type == CategoryType.expense ||
                    cat.type == CategoryType.both)
                .toList();

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightBorder),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: ShadSelect<String>(
                placeholder: Text('budgets.selectCategory'.tr()),
                options: expenseCategories.map((category) {
                  return ShadOption(
                    value: category.id,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(category.color).withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusS),
                          ),
                          child: Icon(
                            _getCategoryIcon(category.iconName),
                            size: 16,
                            color: Color(category.color),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingM),
                        Expanded(
                          child: Text(category.name),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                selectedOptionBuilder: (context, value) {
                  final category =
                      expenseCategories.firstWhere((cat) => cat.id == value);
                  return Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(category.color).withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: Icon(
                          _getCategoryIcon(category.iconName),
                          size: 12,
                          color: Color(category.color),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text(category.name),
                    ],
                  );
                },
                onChanged: widget.enabled && !widget.isLoading
                    ? (value) => setState(() => _selectedCategoryId = value)
                    : null,
                initialValue: _selectedCategoryId,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'budgets.period'.tr(),
          style: theme.textTheme.small.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: BudgetPeriod.values.map((period) {
            final isSelected = _selectedPeriod == period;

            return ShadButton.ghost(
              onPressed: widget.enabled && !widget.isLoading
                  ? () => setState(() => _selectedPeriod = period)
                  : null,
              size: ShadButtonSize.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                  vertical: AppDimensions.paddingS,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: isSelected
                      ? Border.all(color: AppColors.primary, width: 1)
                      : null,
                ),
                child: Text(
                  _getPeriodLabel(period),
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : null,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRange() {
    return Column(
      children: [
        // Start Date
        CustomDatePicker(
          labelText: 'budgets.startDate'.tr(),
          selectedDate: _startDate,
          onChanged: widget.enabled && !widget.isLoading
              ? (date) => setState(() => _startDate = date!)
              : null,
          enabled: widget.enabled && !widget.isLoading,
        ),

        // End Date (only for custom period)
        if (_selectedPeriod == BudgetPeriod.custom) ...[
          const SizedBox(height: AppDimensions.spacingM),
          CustomDatePicker(
            labelText: 'budgets.endDate'.tr(),
            selectedDate: _endDate,
            onChanged: widget.enabled && !widget.isLoading
                ? (date) => setState(() => _endDate = date)
                : null,
            enabled: widget.enabled && !widget.isLoading,
          ),
        ],
      ],
    );
  }

  Widget _buildRolloverTypeSelector() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'budgets.rolloverType'.tr(),
          style: theme.textTheme.small.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightBorder),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: ShadSelect<BudgetRolloverType>(
            placeholder: Text('budgets.selectRolloverType'.tr()),
            options: BudgetRolloverType.values.map((type) {
              return ShadOption(
                value: type,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getRolloverTypeLabel(type)),
                    Text(
                      _getRolloverTypeDescription(type),
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            selectedOptionBuilder: (context, value) =>
                Text(_getRolloverTypeLabel(value)),
            onChanged: widget.enabled && !widget.isLoading
                ? (value) => setState(() => _rolloverType = value!)
                : null,
            initialValue: _rolloverType,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSelector() {
    final theme = ShadTheme.of(context);
    final accountsAsync = ref.watch(activeAccountsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'budgets.specificAccounts'.tr(),
          style: theme.textTheme.small.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'budgets.specificAccountsHint'.tr(),
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        accountsAsync.when(
          loading: () => const ShimmerLoading(child: SizedBox()),
          error: (error, stack) => CustomErrorWidget(
            title: 'accounts.loadError'.tr(),
            message: error.toString(),
            onActionPressed: () => ref.refresh(activeAccountsProvider),
          ),
          data: (accounts) {
            return Column(
              children: accounts.map((account) {
                final isSelected = _selectedAccountIds.contains(account.id);

                return CustomCheckbox(
                  value: isSelected,
                  onChanged: widget.enabled && !widget.isLoading
                      ? (value) {
                          setState(() {
                            if (value == true) {
                              _selectedAccountIds.add(account.id);
                            } else {
                              _selectedAccountIds.remove(account.id);
                            }
                          });
                        }
                      : null,
                  labelText: account.name,
                  sublabelText: account.description,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return Column(
      children: [
        CustomCheckbox(
          value: _isActive,
          onChanged: widget.enabled && !widget.isLoading
              ? (value) => setState(() => _isActive = value ?? true)
              : null,
          labelText: 'budgets.isActive'.tr(),
          sublabelText: 'budgets.isActiveHint'.tr(),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        CustomCheckbox(
          value: _enableAlerts,
          onChanged: widget.enabled && !widget.isLoading
              ? (value) => setState(() => _enableAlerts = value ?? true)
              : null,
          labelText: 'budgets.enableAlerts'.tr(),
          sublabelText: 'budgets.enableAlertsHint'.tr(),
        ),
      ],
    );
  }

  DateTime _calculateEndDate(DateTime startDate, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 6));
      case BudgetPeriod.monthly:
        return DateTime(startDate.year, startDate.month + 1, 0);
      case BudgetPeriod.quarterly:
        return DateTime(startDate.year, startDate.month + 3, 0);
      case BudgetPeriod.yearly:
        return DateTime(startDate.year, 12, 31);
      case BudgetPeriod.custom:
        return startDate.add(const Duration(days: 30)); // Default fallback
    }
  }

  String _getPeriodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'budgets.periods.weekly'.tr();
      case BudgetPeriod.monthly:
        return 'budgets.periods.monthly'.tr();
      case BudgetPeriod.quarterly:
        return 'budgets.periods.quarterly'.tr();
      case BudgetPeriod.yearly:
        return 'budgets.periods.yearly'.tr();
      case BudgetPeriod.custom:
        return 'budgets.periods.custom'.tr();
    }
  }

  String _getRolloverTypeLabel(BudgetRolloverType type) {
    switch (type) {
      case BudgetRolloverType.reset:
        return 'budgets.rollover.reset'.tr();
      case BudgetRolloverType.rollover:
        return 'budgets.rollover.rollover'.tr();
      case BudgetRolloverType.accumulate:
        return 'budgets.rollover.accumulate'.tr();
    }
  }

  String _getRolloverTypeDescription(BudgetRolloverType type) {
    switch (type) {
      case BudgetRolloverType.reset:
        return 'budgets.rollover.resetDesc'.tr();
      case BudgetRolloverType.rollover:
        return 'budgets.rollover.rolloverDesc'.tr();
      case BudgetRolloverType.accumulate:
        return 'budgets.rollover.accumulateDesc'.tr();
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'food':
      case 'restaurant':
        return Icons.restaurant;
      case 'transport':
      case 'car':
        return Icons.directions_car;
      case 'shopping':
      case 'shop':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'health':
      case 'medical':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'utilities':
        return Icons.electrical_services;
      case 'home':
      case 'house':
        return Icons.home;
      default:
        return Icons.category;
    }
  }
}

class BudgetFormData {
  final String name;
  final String categoryId;
  final double limit;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final double alertThreshold;
  final bool enableAlerts;
  final List<String>? accountIds;
  final String? description;
  final BudgetRolloverType rolloverType;

  const BudgetFormData({
    required this.name,
    required this.categoryId,
    required this.limit,
    required this.period,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.alertThreshold,
    required this.enableAlerts,
    this.accountIds,
    this.description,
    required this.rolloverType,
  });
}
