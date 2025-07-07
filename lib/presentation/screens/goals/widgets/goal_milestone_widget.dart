import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:money_manager/data/models/goal.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/common/currency_display_widget.dart';

class GoalMilestoneWidget extends ConsumerStatefulWidget {
  final Goal goal;
  final Function(Goal)? onGoalUpdated;
  final bool showProgress;
  final bool allowEdit;

  const GoalMilestoneWidget({
    super.key,
    required this.goal,
    this.onGoalUpdated,
    this.showProgress = true,
    this.allowEdit = true,
  });

  @override
  ConsumerState<GoalMilestoneWidget> createState() =>
      _GoalMilestoneWidgetState();
}

class _GoalMilestoneWidgetState extends ConsumerState<GoalMilestoneWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final currency = ref.watch(baseCurrencyProvider);
    final milestones = widget.goal.milestones ?? [];

    if (milestones.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: AppDimensions.spacingM),
        _buildMilestonesList(milestones, currency, theme),
        if (widget.showProgress) ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildOverallProgress(milestones, currency, theme),
        ],
      ],
    );
  }

  Widget _buildHeader(ShadThemeData theme) {
    final completedCount =
        (widget.goal.milestones ?? []).where((m) => m.isCompleted).length;
    final totalCount = widget.goal.milestones?.length ?? 0;

    return Row(
      children: [
        Icon(
          Icons.flag_outlined,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'goals.milestones'.tr(),
                style: theme.textTheme.h4.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(
                'goals.milestonesProgress'.tr(
                    args: [completedCount.toString(), totalCount.toString()]),
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        if (widget.allowEdit)
          ShadButton.outline(
            onPressed: _isLoading ? null : _addMilestone,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 16),
                const SizedBox(width: AppDimensions.spacingXs),
                Text('common.add'.tr()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMilestonesList(
      List<GoalMilestone> milestones, String currency, ShadThemeData theme) {
    // Sort milestones by target amount
    final sortedMilestones = List<GoalMilestone>.from(milestones)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    return Column(
      children: sortedMilestones.asMap().entries.map((entry) {
        final index = entry.key;
        final milestone = entry.value;
        final isLast = index == sortedMilestones.length - 1;

        return _buildMilestoneItem(
          milestone,
          currency,
          theme,
          isLast,
          index,
        );
      }).toList(),
    );
  }

  Widget _buildMilestoneItem(
    GoalMilestone milestone,
    String currency,
    ShadThemeData theme,
    bool isLast,
    int index,
  ) {
    final isAchievable = widget.goal.currentAmount >= milestone.amount;
    final canToggle =
        widget.allowEdit && (isAchievable || milestone.isCompleted);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline connector
        Column(
          children: [
            // Milestone indicator
            GestureDetector(
              onTap: canToggle ? () => _toggleMilestone(milestone) : null,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getMilestoneColor(milestone, isAchievable)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(
                    color: _getMilestoneColor(milestone, isAchievable),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getMilestoneIcon(milestone, isAchievable),
                  size: 16,
                  color: _getMilestoneColor(milestone, isAchievable),
                ),
              ),
            ),
            // Connecting line
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: AppDimensions.spacingM),

        // Milestone content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: milestone.isCompleted
                  ? AppColors.success.withOpacity(0.05)
                  : theme.colorScheme.muted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: milestone.isCompleted
                  ? Border.all(color: AppColors.success.withOpacity(0.3))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        milestone.name,
                        style: theme.textTheme.p.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: milestone.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: milestone.isCompleted
                              ? theme.colorScheme.mutedForeground
                              : null,
                        ),
                      ),
                    ),
                    if (widget.allowEdit) ...[
                      IconButton(
                        onPressed: _isLoading
                            ? null
                            : () => _editMilestone(milestone, index),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                      IconButton(
                        onPressed: _isLoading
                            ? null
                            : () => _deleteMilestone(milestone, index),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingXs),

                Row(
                  children: [
                    CurrencyDisplayMedium(
                      amount: milestone.amount,
                      currency: currency,
                      autoColor: false,
                    ),
                    const Spacer(),
                    if (milestone.isCompleted && milestone.completedAt != null)
                      Text(
                        'goals.completedOn'.tr(args: [
                          DateFormat.yMMMd().format(milestone.completedAt!),
                        ]),
                        style: theme.textTheme.small.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (isAchievable && !milestone.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusXs),
                        ),
                        child: Text(
                          'goals.ready'.tr(),
                          style: theme.textTheme.small.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),

                // Progress to this milestone
                const SizedBox(height: AppDimensions.spacingS),
                _buildMilestoneProgress(milestone, currency, theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneProgress(
      GoalMilestone milestone, String currency, ShadThemeData theme) {
    final progressAmount =
        widget.goal.currentAmount.clamp(0.0, milestone.amount);
    final progressPercentage = milestone.amount > 0
        ? (progressAmount / milestone.amount * 100).clamp(0.0, 100.0)
        : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'goals.progress'.tr(),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            Text(
              '${progressPercentage.toInt()}%',
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w600,
                color: _getProgressColor(progressPercentage),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        LinearProgressIndicator(
          value: progressPercentage / 100,
          backgroundColor: theme.colorScheme.muted,
          valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progressPercentage)),
          minHeight: 4,
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CurrencyDisplaySmall(
              amount: progressAmount,
              currency: currency,
              autoColor: false,
            ),
            CurrencyDisplaySmall(
              amount: milestone.amount,
              currency: currency,
              autoColor: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverallProgress(
      List<GoalMilestone> milestones, String currency, ShadThemeData theme) {
    final completedCount = milestones.where((m) => m.isCompleted).length;
    final totalCount = milestones.length;
    final completionPercentage =
        totalCount > 0 ? (completedCount / totalCount * 100) : 0.0;

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  'goals.overallProgress'.tr(),
                  style: theme.textTheme.h4,
                ),
                const Spacer(),
                Text(
                  '${completionPercentage.toInt()}%',
                  style: theme.textTheme.h4.copyWith(
                    color: _getProgressColor(completionPercentage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingS),
            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: theme.colorScheme.muted,
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(completionPercentage)),
              minHeight: 6,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'goals.milestonesCompleted'
                  .tr(args: [completedCount.toString(), totalCount.toString()]),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ShadThemeData theme) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          children: [
            Icon(
              Icons.flag_outlined,
              size: 48,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'goals.noMilestones'.tr(),
              style: theme.textTheme.h4.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'goals.addMilestonesToTrackProgress'.tr(),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.allowEdit) ...[
              const SizedBox(height: AppDimensions.spacingM),
              ShadButton.outline(
                onPressed: _isLoading ? null : _addMilestone,
                child: Text('goals.addFirstMilestone'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getMilestoneColor(GoalMilestone milestone, bool isAchievable) {
    if (milestone.isCompleted) return AppColors.success;
    if (isAchievable) return AppColors.primary;
    return AppColors.mutedForeground;
  }

  IconData _getMilestoneIcon(GoalMilestone milestone, bool isAchievable) {
    if (milestone.isCompleted) return Icons.check_circle;
    if (isAchievable) return Icons.radio_button_unchecked;
    return Icons.flag_outlined;
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 100) return AppColors.success;
    if (percentage >= 75) return AppColors.primary;
    if (percentage >= 50) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _toggleMilestone(GoalMilestone milestone) async {
    setState(() => _isLoading = true);

    try {
      final updatedMilestones =
          List<GoalMilestone>.from(widget.goal.milestones ?? []);
      final index = updatedMilestones.indexWhere((m) => m.id == milestone.id);

      if (index != -1) {
        updatedMilestones[index] = milestone.copyWith(
          isCompleted: !milestone.isCompleted,
          completedAt: !milestone.isCompleted ? DateTime.now() : null,
        );

        final updatedGoal = widget.goal.copyWith(
          milestones: updatedMilestones,
          updatedAt: DateTime.now(),
        );

        widget.onGoalUpdated?.call(updatedGoal);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                milestone.isCompleted
                    ? 'goals.milestoneUncompleted'.tr()
                    : 'goals.milestoneCompleted'.tr(),
              ),
              backgroundColor:
                  milestone.isCompleted ? AppColors.warning : AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('goals.milestoneUpdateError'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addMilestone() async {
    final currency = ref.read(baseCurrencyProvider);

    final milestone = await showShadDialog<GoalMilestone>(
      context: context,
      builder: (context) => _MilestoneDialog(
        currency: currency,
        existingMilestones: widget.goal.milestones ?? [],
      ),
    );

    if (milestone != null) {
      setState(() => _isLoading = true);

      try {
        final updatedMilestones =
            List<GoalMilestone>.from(widget.goal.milestones ?? [])
              ..add(milestone)
              ..sort((a, b) => a.amount.compareTo(b.amount));

        final updatedGoal = widget.goal.copyWith(
          milestones: updatedMilestones,
          updatedAt: DateTime.now(),
        );

        widget.onGoalUpdated?.call(updatedGoal);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('goals.milestoneAdded'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('goals.milestoneAddError'.tr()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editMilestone(GoalMilestone milestone, int index) async {
    final currency = ref.read(baseCurrencyProvider);

    final updatedMilestone = await showShadDialog<GoalMilestone>(
      context: context,
      builder: (context) => _MilestoneDialog(
        currency: currency,
        existingMilestones: widget.goal.milestones ?? [],
        milestone: milestone,
      ),
    );

    if (updatedMilestone != null) {
      setState(() => _isLoading = true);

      try {
        final updatedMilestones =
            List<GoalMilestone>.from(widget.goal.milestones ?? []);
        updatedMilestones[index] = updatedMilestone;
        updatedMilestones
            .sort((a, b) => a.amount.compareTo(b.amount));

        final updatedGoal = widget.goal.copyWith(
          milestones: updatedMilestones,
          updatedAt: DateTime.now(),
        );

        widget.onGoalUpdated?.call(updatedGoal);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('goals.milestoneUpdated'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('goals.milestoneUpdateError'.tr()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteMilestone(GoalMilestone milestone, int index) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('goals.deleteMilestone'.tr()),
        description: Text(
            'goals.deleteMilestoneConfirmation'.tr(args: [milestone.name])),
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
      setState(() => _isLoading = true);

      try {
        final updatedMilestones =
            List<GoalMilestone>.from(widget.goal.milestones ?? [])
              ..removeAt(index);

        final updatedGoal = widget.goal.copyWith(
          milestones: updatedMilestones,
          updatedAt: DateTime.now(),
        );

        widget.onGoalUpdated?.call(updatedGoal);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('goals.milestoneDeleted'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('goals.milestoneDeleteError'.tr()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}

// Milestone dialog for adding/editing milestones
class _MilestoneDialog extends StatefulWidget {
  final String currency;
  final List<GoalMilestone> existingMilestones;
  final GoalMilestone? milestone;

  const _MilestoneDialog({
    required this.currency,
    required this.existingMilestones,
    this.milestone,
  });

  @override
  State<_MilestoneDialog> createState() => __MilestoneDialogState();
}

class __MilestoneDialogState extends State<_MilestoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.milestone != null) {
      _nameController.text = widget.milestone!.name;
      _amountController.text = widget.milestone!.amount.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.milestone != null;

    return ShadDialog(
      title: Text(
          isEditing ? 'goals.editMilestone'.tr() : 'goals.addMilestone'.tr()),
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
                if (value.trim().isEmpty) {
                  return 'validation.required'.tr();
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'validation.invalidAmount'.tr();
                }
                // Check for duplicate amounts (excluding current milestone when editing)
                final existingAmounts = widget.existingMilestones
                    .where((m) =>
                        widget.milestone == null ||
                        m.id != widget.milestone!.id)
                    .map((m) => m.amount)
                    .toList();
                if (existingAmounts.contains(amount)) {
                  return 'goals.duplicateMilestoneAmount'.tr();
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
                    child: Text(
                        isEditing ? 'common.update'.tr() : 'common.add'.tr()),
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

    final milestone = widget.milestone?.copyWith(
          name: _nameController.text.trim(),
          amount: double.parse(_amountController.text),
        ) ??
        GoalMilestone(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          amount: double.parse(_amountController.text),
          isCompleted: false,
          completedAt: null,
        );

    Navigator.of(context).pop(milestone);
  }
}
