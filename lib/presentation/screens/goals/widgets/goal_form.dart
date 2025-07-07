import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/goal.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/forms/custom_date_picker.dart';
import '../../../widgets/forms/custom_dropdown.dart';

class GoalForm extends ConsumerStatefulWidget {
  final Goal? goal;
  final bool enabled;
  final bool isLoading;
  final VoidCallback? onCancel;
  final Function(GoalFormData)? onSubmit;

  const GoalForm({
    super.key,
    this.goal,
    this.enabled = true,
    this.isLoading = false,
    this.onCancel,
    this.onSubmit,
  });

  @override
  ConsumerState<GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<GoalForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  final _monthlyTargetController = TextEditingController();

  GoalType _selectedType = GoalType.savings;
  GoalPriority _selectedPriority = GoalPriority.medium;
  DateTime? _targetDate;
  String? _selectedCategoryId;
  List<String> _selectedAccountIds = [];
  String? _selectedIcon;
  int? _selectedColor;
  bool _enableNotifications = true;
  bool _autoCalculateMonthly = true;
  List<GoalMilestone> _milestones = [];

  // Goal type options
  static const List<DropdownItem<GoalType>> _goalTypeOptions = [
    DropdownItem(
      value: GoalType.savings,
      text: 'Savings Goal',
      icon: Icon(Icons.savings, size: 20),
    ),
    DropdownItem(
      value: GoalType.debtPayoff,
      text: 'Debt Payoff',
      icon: Icon(Icons.credit_card_off, size: 20),
    ),
    DropdownItem(
      value: GoalType.emergency,
      text: 'Emergency Fund',
      icon: Icon(Icons.security, size: 20),
    ),
    DropdownItem(
      value: GoalType.investment,
      text: 'Investment Goal',
      icon: Icon(Icons.trending_up, size: 20),
    ),
    DropdownItem(
      value: GoalType.vacation,
      text: 'Vacation Fund',
      icon: Icon(Icons.flight, size: 20),
    ),
    DropdownItem(
      value: GoalType.education,
      text: 'Education Fund',
      icon: Icon(Icons.school, size: 20),
    ),
    DropdownItem(
      value: GoalType.retirement,
      text: 'Retirement Savings',
      icon: Icon(Icons.elderly, size: 20),
    ),
    DropdownItem(
      value: GoalType.other,
      text: 'Other Goal',
      icon: Icon(Icons.flag, size: 20),
    ),
  ];

  // Priority options
  static const List<DropdownItem<GoalPriority>> _priorityOptions = [
    DropdownItem(
      value: GoalPriority.low,
      text: 'Low Priority',
      icon: Icon(Icons.keyboard_arrow_down,
          color: AppColors.mutedForeground, size: 20),
    ),
    DropdownItem(
      value: GoalPriority.medium,
      text: 'Medium Priority',
      icon: Icon(Icons.remove, color: AppColors.warning, size: 20),
    ),
    DropdownItem(
      value: GoalPriority.high,
      text: 'High Priority',
      icon: Icon(Icons.keyboard_arrow_up, color: AppColors.primary, size: 20),
    ),
    DropdownItem(
      value: GoalPriority.urgent,
      text: 'Urgent',
      icon: Icon(Icons.priority_high, color: AppColors.error, size: 20),
    ),
  ];

  // Goal icons
  static const List<String> _goalIcons = [
    'savings',
    'house',
    'car',
    'flight',
    'school',
    'credit_card',
    'investment',
    'retirement',
    'emergency',
    'gift',
    'fitness',
    'health',
    'family',
    'work',
    'hobby',
  ];

  // Goal colors
  static const List<Color> _goalColors = [
    AppColors.primary,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    AppColors.info,
    Colors.purple,
    Colors.pink,
    Colors.orange,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _monthlyTargetController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.goal != null) {
      final goal = widget.goal!;
      _nameController.text = goal.name;
      _descriptionController.text = goal.description ?? '';
      _targetAmountController.text = goal.targetAmount.toString();
      _currentAmountController.text = goal.currentAmount.toString();
      _monthlyTargetController.text = goal.monthlyTarget.toString();
      _selectedType = goal.type;
      _selectedPriority = goal.priority;
      _targetDate = goal.targetDate;
      _selectedCategoryId = goal.categoryId;
      _selectedAccountIds = goal.accountIds ?? [];
      _selectedIcon = goal.iconName;
      _selectedColor = goal.color;
      _enableNotifications = goal.enableNotifications;
      _milestones = goal.milestones ?? [];
      _autoCalculateMonthly = goal.monthlyTarget == 0.0;
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
            _buildAmountFields(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildGoalSettings(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildAppearanceSettings(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildMilestonesSection(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildAdvancedSettings(),
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
          'goals.basicInformation'.tr(),
          style: ShadTheme.of(context).textTheme.h3,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Goal name
        ShadInputFormField(
          controller: _nameController,
          label: Text('goals.goalName'.tr()),
          placeholder: Text('goals.enterGoalName'.tr()),
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

        // Description
        ShadInputFormField(
          controller: _descriptionController,
          label: Text('goals.description'.tr()),
          placeholder: Text('goals.enterDescription'.tr()),
          enabled: widget.enabled && !widget.isLoading,
          maxLines: 3,
          validator: (value) {
            if (value != null && value.trim().length > 500) {
              return 'validation.tooLong'.tr(args: ['500']);
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Goal type and priority
        Row(
          children: [
            Expanded(
              child: CustomDropdown<GoalType>(
                labelText: 'goals.type'.tr(),
                value: _selectedType,
                items: _goalTypeOptions,
                onChanged: widget.enabled && !widget.isLoading
                    ? (value) => setState(() => _selectedType = value!)
                    : null,
                required: true,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: CustomDropdown<GoalPriority>(
                labelText: 'goals.priority'.tr(),
                value: _selectedPriority,
                items: _priorityOptions,
                onChanged: widget.enabled && !widget.isLoading
                    ? (value) => setState(() => _selectedPriority = value!)
                    : null,
                required: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountFields() {
    final currency = ref.watch(baseCurrencyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'goals.amounts'.tr(),
          style: ShadTheme.of(context).textTheme.h3,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Target amount
        ShadInputFormField(
          controller: _targetAmountController,
          label: Text('goals.targetAmount'.tr()),
          placeholder: Text('goals.enterTargetAmount'.tr()),
          enabled: widget.enabled && !widget.isLoading,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          leading: Text(CurrencyFormatter.getSymbol(currency)),
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
          onChanged: _autoCalculateMonthly ? _calculateMonthlyTarget : null,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Current amount
        ShadInputFormField(
          controller: _currentAmountController,
          label: Text('goals.currentAmount'.tr()),
          placeholder: Text('goals.enterCurrentAmount'.tr()),
          enabled: widget.enabled && !widget.isLoading,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          leading: Text(CurrencyFormatter.getSymbol(currency)),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'validation.required'.tr();
            }
            final amount = double.tryParse(value);
            if (amount == null || amount < 0) {
              return 'validation.invalidAmount'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Monthly target
        Row(
          children: [
            Expanded(
              child: ShadInputFormField(
                controller: _monthlyTargetController,
                label: Text('goals.monthlyTarget'.tr()),
                placeholder: Text('goals.enterMonthlyTarget'.tr()),
                enabled: widget.enabled &&
                    !widget.isLoading &&
                    !_autoCalculateMonthly,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                leading: Text(CurrencyFormatter.getSymbol(currency)),
                validator: (value) {
                  if (!_autoCalculateMonthly &&
                      (value == null || value.trim().isEmpty)) {
                    return 'validation.required'.tr();
                  }
                  if (value.trim().isNotEmpty) {
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 0) {
                      return 'validation.invalidAmount'.tr();
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            ShadButton.outline(
              onPressed: widget.enabled && !widget.isLoading
                  ? () => setState(
                      () => _autoCalculateMonthly = !_autoCalculateMonthly)
                  : null,
              child: Text(_autoCalculateMonthly
                  ? 'goals.manual'.tr()
                  : 'goals.auto'.tr()),
            ),
          ],
        ),
        if (_autoCalculateMonthly && _targetDate != null) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            'goals.autoCalculatedBasedOnDate'.tr(),
            style: ShadTheme.of(context).textTheme.small.copyWith(
                  color: ShadTheme.of(context).colorScheme.mutedForeground,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildGoalSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'goals.settings'.tr(),
          style: ShadTheme.of(context).textTheme.h3,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Target date
        CustomDatePicker(
          labelText: 'goals.targetDate'.tr(),
          selectedDate: _targetDate,
          onChanged: widget.enabled && !widget.isLoading
              ? (date) {
                  setState(() => _targetDate = date);
                  if (_autoCalculateMonthly) _calculateMonthlyTarget();
                }
              : null,
          fromMonth: DateTime.now(),
          toMonth: DateTime.now().add(const Duration(days: 365 * 10)),
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Category selection
        _buildCategorySelection(),
        const SizedBox(height: AppDimensions.spacingM),

        // Notifications toggle
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'goals.enableNotifications'.tr(),
                    style: ShadTheme.of(context).textTheme.h4,
                  ),
                  Text(
                    'goals.notificationDescription'.tr(),
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
      ],
    );
  }

  Widget _buildCategorySelection() {
    final categories = ref.watch(categoryListProvider);

    return categories.when(
      data: (categoryList) {
        final dropdownItems = categoryList
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
          labelText: 'goals.category'.tr(),
          placeholder: 'goals.selectCategory'.tr(),
          value: _selectedCategoryId,
          items: dropdownItems,
          onChanged: widget.enabled && !widget.isLoading
              ? (value) => setState(() => _selectedCategoryId = value)
              : null,
          allowDeselection: true,
        );
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('Error loading categories: $error'),
    );
  }

  Widget _buildAppearanceSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'goals.appearance'.tr(),
          style: ShadTheme.of(context).textTheme.h3,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Icon selection
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'goals.icon'.tr(),
              style: ShadTheme.of(context).textTheme.h4,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Wrap(
              spacing: AppDimensions.spacingS,
              runSpacing: AppDimensions.spacingS,
              children: _goalIcons
                  .map((iconName) => GestureDetector(
                        onTap: widget.enabled && !widget.isLoading
                            ? () => setState(() => _selectedIcon = iconName)
                            : null,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _selectedIcon == iconName
                                ? AppColors.primary.withOpacity(0.1)
                                : ShadTheme.of(context)
                                    .colorScheme
                                    .muted
                                    .withOpacity(0.3),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusS),
                            border: _selectedIcon == iconName
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
                          ),
                          child: Icon(
                            _getIconData(iconName),
                            color: _selectedIcon == iconName
                                ? AppColors.primary
                                : null,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Color selection
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'goals.color'.tr(),
              style: ShadTheme.of(context).textTheme.h4,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Wrap(
              spacing: AppDimensions.spacingS,
              runSpacing: AppDimensions.spacingS,
              children: _goalColors
                  .map((color) => GestureDetector(
                        onTap: widget.enabled && !widget.isLoading
                            ? () => setState(() => _selectedColor = color.value)
                            : null,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusS),
                            border: _selectedColor == color.value
                                ? Border.all(
                                    color: ShadTheme.of(context)
                                        .colorScheme
                                        .foreground,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: _selectedColor == color.value
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMilestonesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'goals.milestones'.tr(),
                style: ShadTheme.of(context).textTheme.h3,
              ),
            ),
            ShadButton.outline(
              onPressed:
                  widget.enabled && !widget.isLoading ? _addMilestone : null,
              child: Text('goals.addMilestone'.tr()),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        if (_milestones.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: ShadTheme.of(context).colorScheme.muted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 48,
                  color: ShadTheme.of(context).colorScheme.mutedForeground,
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  'goals.noMilestones'.tr(),
                  style: ShadTheme.of(context).textTheme.h4.copyWith(
                        color:
                            ShadTheme.of(context).colorScheme.mutedForeground,
                      ),
                ),
                Text(
                  'goals.addMilestonesToTrack'.tr(),
                  style: ShadTheme.of(context).textTheme.small.copyWith(
                        color:
                            ShadTheme.of(context).colorScheme.mutedForeground,
                      ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _milestones.asMap().entries.map((entry) {
              final index = entry.key;
              final milestone = entry.value;
              return _buildMilestoneItem(milestone, index);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildMilestoneItem(GoalMilestone milestone, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: milestone.isCompleted
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  milestone.isCompleted ? Icons.check_circle : Icons.flag,
                  color: milestone.isCompleted
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone.name,
                      style: ShadTheme.of(context).textTheme.p.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      CurrencyFormatter.format(
                        milestone.amount,
                        currency: ref.watch(baseCurrencyProvider),
                      ),
                      style: ShadTheme.of(context).textTheme.small.copyWith(
                            color: ShadTheme.of(context)
                                .colorScheme
                                .mutedForeground,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.enabled && !widget.isLoading
                    ? () => _removeMilestone(index)
                    : null,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'goals.advanced'.tr(),
          style: ShadTheme.of(context).textTheme.h3,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Account tracking (placeholder)
        Text(
          'goals.accountTracking'.tr(),
          style: ShadTheme.of(context).textTheme.h4,
        ),
        Text(
          'goals.accountTrackingDescription'.tr(),
          style: ShadTheme.of(context).textTheme.small.copyWith(
                color: ShadTheme.of(context).colorScheme.mutedForeground,
              ),
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
                : Text(widget.goal != null
                    ? 'goals.updateGoal'.tr()
                    : 'goals.createGoal'.tr()),
          ),
        ),
      ],
    );
  }

  void _calculateMonthlyTarget([String? value]) {
    if (!_autoCalculateMonthly || _targetDate == null) return;

    final targetAmount = double.tryParse(_targetAmountController.text);
    final currentAmount = double.tryParse(_currentAmountController.text) ?? 0.0;

    if (targetAmount == null || targetAmount <= currentAmount) return;

    final remainingAmount = targetAmount - currentAmount;
    final monthsRemaining =
        _targetDate!.difference(DateTime.now()).inDays / 30.44;

    if (monthsRemaining > 0) {
      final monthlyTarget = remainingAmount / monthsRemaining;
      _monthlyTargetController.text = monthlyTarget.toStringAsFixed(2);
    }
  }

  void _addMilestone() {
    showShadDialog(
      context: context,
      builder: (context) => _MilestoneDialog(
        currency: ref.read(baseCurrencyProvider),
        onSubmit: (milestone) {
          setState(() {
            _milestones.add(milestone);
            _milestones
                .sort((a, b) => a.amount.compareTo(b.amount));
          });
        },
      ),
    );
  }

  void _removeMilestone(int index) {
    setState(() {
      _milestones.removeAt(index);
    });
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'savings':
        return Icons.savings;
      case 'house':
        return Icons.house;
      case 'car':
        return Icons.directions_car;
      case 'flight':
        return Icons.flight;
      case 'school':
        return Icons.school;
      case 'credit_card':
        return Icons.credit_card;
      case 'investment':
        return Icons.trending_up;
      case 'retirement':
        return Icons.elderly;
      case 'emergency':
        return Icons.security;
      case 'gift':
        return Icons.card_giftcard;
      case 'fitness':
        return Icons.fitness_center;
      case 'health':
        return Icons.local_hospital;
      case 'family':
        return Icons.family_restroom;
      case 'work':
        return Icons.work;
      case 'hobby':
        return Icons.palette;
      default:
        return Icons.flag;
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final formData = GoalFormData(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      targetAmount: double.parse(_targetAmountController.text),
      currentAmount: double.parse(_currentAmountController.text),
      monthlyTarget: double.parse(_monthlyTargetController.text.isNotEmpty
          ? _monthlyTargetController.text
          : '0.0'),
      type: _selectedType,
      priority: _selectedPriority,
      targetDate: _targetDate,
      categoryId: _selectedCategoryId,
      accountIds: _selectedAccountIds,
      iconName: _selectedIcon,
      color: _selectedColor,
      enableNotifications: _enableNotifications,
      milestones: _milestones,
    );

    widget.onSubmit?.call(formData);
  }
}

// Data class for form submission
class GoalFormData {
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final double monthlyTarget;
  final GoalType type;
  final GoalPriority priority;
  final DateTime? targetDate;
  final String? categoryId;
  final List<String> accountIds;
  final String? iconName;
  final int? color;
  final bool enableNotifications;
  final List<GoalMilestone> milestones;

  const GoalFormData({
    required this.name,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.monthlyTarget,
    required this.type,
    required this.priority,
    this.targetDate,
    this.categoryId,
    required this.accountIds,
    this.iconName,
    this.color,
    required this.enableNotifications,
    required this.milestones,
  });
}

// Milestone dialog
class _MilestoneDialog extends StatefulWidget {
  final String currency;
  final Function(GoalMilestone) onSubmit;

  const _MilestoneDialog({
    required this.currency,
    required this.onSubmit,
  });

  @override
  State<_MilestoneDialog> createState() => __MilestoneDialogState();
}

class __MilestoneDialogState extends State<_MilestoneDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: Text('goals.addMilestone'.tr()),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShadInputFormField(
              controller: _nameController,
              label: Text('goals.milestoneName'.tr()),
              placeholder: Text('goals.enterMilestoneName'.tr()),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'validation.required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.spacingM),
            ShadInputFormField(
              controller: _amountController,
              label: Text('goals.milestoneAmount'.tr()),
              placeholder: Text('goals.enterMilestoneAmount'.tr()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              leading: Text(CurrencyFormatter.getSymbol(widget.currency)),
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
            const SizedBox(height: AppDimensions.spacingL),
            Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('common.cancel'.tr()),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: ShadButton(
                    onPressed: _handleSubmit,
                    child: Text('common.add'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final milestone = GoalMilestone(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text),
      isCompleted: false,
      completedAt: null,
    );

    widget.onSubmit(milestone);
    Navigator.of(context).pop();
  }
}
