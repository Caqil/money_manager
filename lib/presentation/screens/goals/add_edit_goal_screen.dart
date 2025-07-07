import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/goal.dart';
import '../../providers/goal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import 'widgets/goal_form.dart';

class AddEditGoalScreen extends ConsumerStatefulWidget {
  final String? goalId;

  const AddEditGoalScreen({
    super.key,
    this.goalId,
  });

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  bool _isLoading = false;
  bool _isSaving = false;
  Goal? _goal;
  String? _error;

  bool get isEditing => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadGoal();
    }
  }

  Future<void> _loadGoal() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final goalAsync = ref.read(goalProvider(widget.goalId!));
      goalAsync.when(
        data: (goal) {
          if (goal != null) {
            setState(() {
              _goal = goal;
              _isLoading = false;
            });
          } else {
            setState(() {
              _error = 'goals.goalNotFound'.tr();
              _isLoading = false;
            });
          }
        },
        loading: () {
          setState(() => _isLoading = true);
        },
        error: (error, stackTrace) {
          setState(() {
            _error = error.toString();
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing ? 'goals.editGoal'.tr() : 'goals.addGoal'.tr(),
        showBackButton: true,
        actions: [
          if (isEditing && _goal != null && !_isLoading)
            IconButton(
              onPressed: _isSaving ? null : _showDeleteConfirmation,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'goals.deleteGoal'.tr(),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ShadThemeData theme) {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return CustomErrorWidget(
        error: _error!,
        onActionPressed: isEditing ? _loadGoal : null,
      );
    }

    if (isEditing && _goal == null) {
      return CustomErrorWidget(
        error: 'goals.goalNotFound'.tr(),
        onActionPressed: () => context.pop(),
      );
    }

    return GoalForm(
      goal: _goal,
      enabled: !_isSaving,
      isLoading: _isSaving,
      onCancel: _handleCancel,
      onSubmit: _handleSubmit,
    );
  }

  Future<void> _handleSubmit(GoalFormData formData) async {
    setState(() => _isSaving = true);

    try {
      final currency = ref.read(baseCurrencyProvider);
      final now = DateTime.now();

      Goal goal;
      if (isEditing && _goal != null) {
        // Update existing goal
        goal = _goal!.copyWith(
          name: formData.name,
          description: formData.description,
          targetAmount: formData.targetAmount,
          currentAmount: formData.currentAmount,
          monthlyTarget: formData.monthlyTarget,
          type: formData.type,
          priority: formData.priority,
          targetDate: formData.targetDate,
          categoryId: formData.categoryId,
          accountIds: formData.accountIds,
          iconName: formData.iconName,
          color: formData.color,
          enableNotifications: formData.enableNotifications,
          milestones: formData.milestones,
          updatedAt: now,
        );

        final success =
            await ref.read(goalListProvider.notifier).updateGoal(goal);
        if (!success) {
          throw Exception('Failed to update goal');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('goals.goalUpdated'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Create new goal
        goal = Goal(
          id: const Uuid().v4(),
          name: formData.name,
          description: formData.description,
          targetAmount: formData.targetAmount,
          currentAmount: formData.currentAmount,
          monthlyTarget: formData.monthlyTarget,
          type: formData.type,
          priority: formData.priority,
          targetDate: formData.targetDate,
          categoryId: formData.categoryId,
          accountIds: formData.accountIds,
          iconName: formData.iconName,
          color: formData.color,
          enableNotifications: formData.enableNotifications,
          milestones: formData.milestones,
          currency: currency,
          createdAt: now,
          updatedAt: now,
        );

        final goalId = await ref.read(goalListProvider.notifier).addGoal(goal);
        if (goalId == null) {
          throw Exception('Failed to create goal');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('goals.goalCreated'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'goals.updateError'.tr()
                : 'goals.createError'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleCancel() {
    if (_isSaving) return;

    // Check if form has changes (simplified - in real app you'd track form state)
    context.pop();
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('goals.deleteGoal'.tr()),
        description: Text('goals.deleteConfirmation'.tr(args: [_goal!.name])),
        actions: [
          ShadButton.outline(
            child: Text('common.cancel'.tr()),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: Text('common.delete'.tr()),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteGoal();
    }
  }

  Future<void> _deleteGoal() async {
    if (_goal == null) return;

    setState(() => _isSaving = true);

    try {
      final success =
          await ref.read(goalListProvider.notifier).deleteGoal(_goal!.id);
      if (!success) {
        throw Exception('Failed to delete goal');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('goals.goalDeleted'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('goals.deleteError'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// Quick goal creation screen with templates
class QuickGoalCreationScreen extends ConsumerStatefulWidget {
  final GoalType? initialType;

  const QuickGoalCreationScreen({
    super.key,
    this.initialType,
  });

  @override
  ConsumerState<QuickGoalCreationScreen> createState() =>
      _QuickGoalCreationScreenState();
}

class _QuickGoalCreationScreenState
    extends ConsumerState<QuickGoalCreationScreen> {
  bool _isLoading = false;
  GoalType? _selectedType;

  // Goal templates
  static const List<GoalTemplate> _templates = [
    GoalTemplate(
      name: 'Emergency Fund',
      description: '3-6 months of expenses for financial security',
      type: GoalType.emergency,
      priority: GoalPriority.high,
      suggestedAmount: 10000,
      suggestedMonths: 12,
      icon: 'emergency',
    ),
    GoalTemplate(
      name: 'House Down Payment',
      description: 'Save for your dream home down payment',
      type: GoalType.savings,
      priority: GoalPriority.high,
      suggestedAmount: 50000,
      suggestedMonths: 36,
      icon: 'house',
    ),
    GoalTemplate(
      name: 'Vacation Fund',
      description: 'Save for that perfect getaway',
      type: GoalType.vacation,
      priority: GoalPriority.medium,
      suggestedAmount: 5000,
      suggestedMonths: 12,
      icon: 'flight',
    ),
    GoalTemplate(
      name: 'New Car',
      description: 'Save for a reliable vehicle',
      type: GoalType.savings,
      priority: GoalPriority.medium,
      suggestedAmount: 25000,
      suggestedMonths: 24,
      icon: 'car',
    ),
    GoalTemplate(
      name: 'Education Fund',
      description: 'Invest in your future education',
      type: GoalType.education,
      priority: GoalPriority.high,
      suggestedAmount: 20000,
      suggestedMonths: 48,
      icon: 'school',
    ),
    GoalTemplate(
      name: 'Retirement Savings',
      description: 'Secure your financial future',
      type: GoalType.retirement,
      priority: GoalPriority.high,
      suggestedAmount: 100000,
      suggestedMonths: 120,
      icon: 'retirement',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final currency = ref.watch(baseCurrencyProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'goals.quickCreate'.tr(),
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'goals.chooseTemplate'.tr(),
              style: theme.textTheme.h2,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'goals.templateDescription'.tr(),
              style: theme.textTheme.p.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),

            // Type filter
            _buildTypeFilter(theme),
            const SizedBox(height: AppDimensions.spacingL),

            // Templates grid
            _buildTemplatesGrid(currency, theme),
            const SizedBox(height: AppDimensions.spacingL),

            // Custom goal option
            _buildCustomGoalOption(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilter(ShadThemeData theme) {
    final types = [
      null, // All types
      ...GoalType.values,
    ];

    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingS,
      children: types.map((type) {
        final isSelected = _selectedType == type;
        return FilterChip(
          label: Text(
              type == null ? 'common.all'.tr() : _getTypeDisplayName(type)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedType = selected ? type : null;
            });
          },
          backgroundColor:
              isSelected ? AppColors.primary.withOpacity(0.1) : null,
          selectedColor: AppColors.primary.withOpacity(0.2),
        );
      }).toList(),
    );
  }

  Widget _buildTemplatesGrid(String currency, ShadThemeData theme) {
    final filteredTemplates = _selectedType == null
        ? _templates
        : _templates
            .where((template) => template.type == _selectedType)
            .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: AppDimensions.spacingM,
        mainAxisSpacing: AppDimensions.spacingM,
      ),
      itemCount: filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = filteredTemplates[index];
        return _buildTemplateCard(template, currency, theme);
      },
    );
  }

  Widget _buildTemplateCard(
      GoalTemplate template, String currency, ShadThemeData theme) {
    return ShadCard(
      child: InkWell(
        onTap: _isLoading ? null : () => _createGoalFromTemplate(template),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and type
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getTypeColor(template.type).withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Icon(
                      _getIconFromName(template.icon),
                      color: _getTypeColor(template.type),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          _getPriorityColor(template.priority).withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXs),
                    ),
                    child: Text(
                      _getPriorityDisplayName(template.priority),
                      style: theme.textTheme.small.copyWith(
                        color: _getPriorityColor(template.priority),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),

              // Title
              Text(
                template.name,
                style: theme.textTheme.h4,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimensions.spacingXs),

              // Description
              Expanded(
                child: Text(
                  template.description,
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),

              // Amount and timeline
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.format(template.suggestedAmount,
                        currency: currency),
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${template.suggestedMonths} ${tr('common.months')}',
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomGoalOption(ShadThemeData theme) {
    return ShadCard(
      child: InkWell(
        onTap: _isLoading ? null : _createCustomGoal,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'goals.createCustomGoal'.tr(),
                      style: theme.textTheme.h4,
                    ),
                    Text(
                      'goals.customGoalDescription'.tr(),
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createGoalFromTemplate(GoalTemplate template) async {
    setState(() => _isLoading = true);

    try {
      final currency = ref.read(baseCurrencyProvider);
      final now = DateTime.now();
      final targetDate = DateTime(
        now.year,
        now.month + template.suggestedMonths,
        now.day,
      );

      final goal = Goal(
        id: const Uuid().v4(),
        name: template.name,
        description: template.description,
        targetAmount: template.suggestedAmount,
        currentAmount: 0.0,
        monthlyTarget: template.suggestedAmount / template.suggestedMonths,
        type: template.type,
        priority: template.priority,
        targetDate: targetDate,
        iconName: template.icon,
        enableNotifications: true,
        currency: currency,
        createdAt: now,
        updatedAt: now,
      );

      final goalId = await ref.read(goalListProvider.notifier).addGoal(goal);
      if (goalId == null) {
        throw Exception('Failed to create goal');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('goals.goalCreated'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('goals.createError'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _createCustomGoal() {
    context.push('/goals/add');
  }

  String _getTypeDisplayName(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return 'goals.types.savings'.tr();
      case GoalType.debtPayoff:
        return 'goals.types.debt'.tr();
      case GoalType.emergency:
        return 'goals.types.emergency'.tr();
      case GoalType.investment:
        return 'goals.types.investment'.tr();
      case GoalType.vacation:
        return 'goals.types.vacation'.tr();
      case GoalType.education:
        return 'goals.types.education'.tr();
      case GoalType.retirement:
        return 'goals.types.retirement'.tr();
      case GoalType.other:
        return 'goals.types.other'.tr();
      case GoalType.purchase:
        return 'goals.types.purchase'.tr();
    }
  }

  String _getPriorityDisplayName(GoalPriority priority) {
    switch (priority) {
      case GoalPriority.low:
        return 'goals.priorities.low'.tr();
      case GoalPriority.medium:
        return 'goals.priorities.medium'.tr();
      case GoalPriority.high:
        return 'goals.priorities.high'.tr();
      case GoalPriority.urgent:
        return 'goals.priorities.urgent'.tr();
    }
  }

  Color _getTypeColor(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return AppColors.success;
      case GoalType.debtPayoff:
        return AppColors.error;
      case GoalType.emergency:
        return AppColors.warning;
      case GoalType.investment:
        return AppColors.primary;
      case GoalType.vacation:
        return Colors.purple;
      case GoalType.education:
        return Colors.orange;
      case GoalType.retirement:
        return Colors.teal;
      case GoalType.other:
        return AppColors.mutedForeground;
      case GoalType.purchase:
        return AppColors.income;
    }
  }

  Color _getPriorityColor(GoalPriority priority) {
    switch (priority) {
      case GoalPriority.low:
        return AppColors.mutedForeground;
      case GoalPriority.medium:
        return AppColors.warning;
      case GoalPriority.high:
        return AppColors.primary;
      case GoalPriority.urgent:
        return AppColors.error;
    }
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'emergency':
        return Icons.security;
      case 'house':
        return Icons.house;
      case 'flight':
        return Icons.flight;
      case 'car':
        return Icons.directions_car;
      case 'school':
        return Icons.school;
      case 'retirement':
        return Icons.elderly;
      default:
        return Icons.flag;
    }
  }
}

// Goal template class
class GoalTemplate {
  final String name;
  final String description;
  final GoalType type;
  final GoalPriority priority;
  final double suggestedAmount;
  final int suggestedMonths;
  final String icon;

  const GoalTemplate({
    required this.name,
    required this.description,
    required this.type,
    required this.priority,
    required this.suggestedAmount,
    required this.suggestedMonths,
    required this.icon,
  });
}
