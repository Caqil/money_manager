import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/goal.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/common/currency_display_widget.dart';
import 'goal_progress_card.dart';

class GoalItem extends ConsumerWidget {
  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleComplete;
  final bool showActions;
  final bool compact;

  const GoalItem({
    super.key,
    required this.goal,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleComplete,
    this.showActions = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final currency = ref.watch(baseCurrencyProvider);

    return ShadCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: EdgeInsets.all(
              compact ? AppDimensions.paddingM : AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              if (!compact) ...[
                const SizedBox(height: AppDimensions.spacingM),
                _buildDescription(theme),
                const SizedBox(height: AppDimensions.spacingM),
                _buildProgressSection(currency),
                const SizedBox(height: AppDimensions.spacingM),
                _buildMetadata(theme, currency),
                if (showActions) ...[
                  const SizedBox(height: AppDimensions.spacingM),
                  _buildActions(theme),
                ],
              ] else ...[
                const SizedBox(height: AppDimensions.spacingS),
                _buildCompactProgress(context, currency),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ShadThemeData theme) {
    return Row(
      children: [
        // Goal icon
        Container(
          width: compact ? 40 : 48,
          height: compact ? 40 : 48,
          decoration: BoxDecoration(
            color: goal.color != null
                ? Color(goal.color!).withOpacity(0.1)
                : _getTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            _getGoalIcon(),
            color: goal.color != null ? Color(goal.color!) : _getTypeColor(),
            size: compact ? 20 : 24,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),

        // Goal info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: (compact ? theme.textTheme.p : theme.textTheme.h4)
                          .copyWith(
                        fontWeight: FontWeight.w600,
                        color: goal.isCompleted
                            ? theme.colorScheme.mutedForeground
                            : null,
                        decoration: goal.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (goal.isCompleted) ...[
                    const SizedBox(width: AppDimensions.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusXs),
                      ),
                      child: Text(
                        'goals.completed'.tr(),
                        style: theme.textTheme.small.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  _buildTypeChip(theme),
                  const SizedBox(width: AppDimensions.spacingS),
                  _buildPriorityChip(theme),
                  if (goal.targetDate != null && !goal.isCompleted) ...[
                    const SizedBox(width: AppDimensions.spacingS),
                    _buildDeadlineChip(theme),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
      ),
      child: Text(
        _getTypeDisplayName(),
        style: theme.textTheme.small.copyWith(
          color: _getTypeColor(),
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(ShadThemeData theme) {
    final priorityColor = _getPriorityColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
      ),
      child: Text(
        _getPriorityDisplayName(),
        style: theme.textTheme.small.copyWith(
          color: priorityColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDeadlineChip(ShadThemeData theme) {
    final daysRemaining = goal.targetDate!.difference(DateTime.now()).inDays;
    final isOverdue = daysRemaining < 0;
    final isUrgent = daysRemaining <= 30 && daysRemaining >= 0;

    Color chipColor;
    String chipText;

    if (isOverdue) {
      chipColor = AppColors.error;
      chipText = 'goals.overdue'.tr();
    } else if (isUrgent) {
      chipColor = AppColors.warning;
      chipText = '${daysRemaining}d';
    } else {
      chipColor = AppColors.mutedForeground;
      chipText = '${daysRemaining}d';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning : Icons.schedule,
            size: 10,
            color: chipColor,
          ),
          const SizedBox(width: 2),
          Text(
            chipText,
            style: theme.textTheme.small.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ShadThemeData theme) {
    if (goal.description == null || goal.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      goal.description!,
      style: theme.textTheme.small.copyWith(
        color: theme.colorScheme.mutedForeground,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgressSection(String currency) {
    return GoalProgressCard(
      goal: goal,
      showTitle: false,
      compact: true,
    );
  }

  Widget _buildCompactProgress(BuildContext context, String currency) {
    final progressPercentage = goal.progressPercentage;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CurrencyDisplaySmall(
              amount: goal.currentAmount,
              currency: currency,
              autoColor: false,
            ),
            Text(
              '${progressPercentage.toInt()}%',
              style: ShadTheme.of(context).textTheme.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getProgressColor(progressPercentage),
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        LinearProgressIndicator(
          value: progressPercentage / 100,
          backgroundColor: ShadTheme.of(context).colorScheme.muted,
          valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progressPercentage)),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildMetadata(ShadThemeData theme, String currency) {
    return Row(
      children: [
        // Target date
        if (goal.targetDate != null) ...[
          Icon(
            Icons.event,
            size: 14,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat.yMMMd().format(goal.targetDate!),
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],

        // Monthly target
        if (goal.monthlyTarget > 0) ...[
          if (goal.targetDate != null) ...[
            const SizedBox(width: AppDimensions.spacingM),
            Container(
              width: 1,
              height: 12,
              color: theme.colorScheme.border,
            ),
            const SizedBox(width: AppDimensions.spacingM),
          ],
          Icon(
            Icons.trending_up,
            size: 14,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(width: 4),
          Text(
            '${CurrencyFormatter.format(goal.monthlyTarget, currency: currency)}/mo',
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],

        const Spacer(),

        // Completion status
        if (goal.isCompleted)
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.success,
          )
        else if (goal.targetDate != null &&
            goal.targetDate!.isBefore(DateTime.now()))
          Icon(
            Icons.warning,
            size: 16,
            color: AppColors.error,
          ),
      ],
    );
  }

  Widget _buildActions(ShadThemeData theme) {
    return Row(
      children: [
        if (onToggleComplete != null && !goal.isCompleted) ...[
          ShadButton.outline(
            onPressed: onToggleComplete,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 16),
                const SizedBox(width: AppDimensions.spacingXs),
                Text('goals.markComplete'.tr()),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
        ],
        const Spacer(),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'goals.editGoal'.tr(),
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'goals.deleteGoal'.tr(),
          ),
      ],
    );
  }

  IconData _getGoalIcon() {
    if (goal.iconName != null) {
      return _getIconFromName(goal.iconName!);
    }

    switch (goal.type) {
      case GoalType.savings:
        return Icons.savings;
      case GoalType.debtPayoff:
        return Icons.credit_card_off;
      case GoalType.emergency:
        return Icons.security;
      case GoalType.investment:
        return Icons.trending_up;
      case GoalType.vacation:
        return Icons.flight;
      case GoalType.education:
        return Icons.school;
      case GoalType.retirement:
        return Icons.elderly;
      case GoalType.other:
        return Icons.flag;
      case GoalType.purchase:
        return Icons.money;
    }
  }

  IconData _getIconFromName(String iconName) {
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

  Color _getTypeColor() {
    switch (goal.type) {
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

  String _getTypeDisplayName() {
    switch (goal.type) {
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

  Color _getPriorityColor() {
    switch (goal.priority) {
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

  String _getPriorityDisplayName() {
    switch (goal.priority) {
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

  Color _getProgressColor(double percentage) {
    if (percentage >= 100) return AppColors.success;
    if (percentage >= 75) return AppColors.primary;
    if (percentage >= 50) return AppColors.warning;
    return AppColors.error;
  }
}

// Compact goal item for lists
class CompactGoalItem extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  final bool showProgress;

  const CompactGoalItem({
    super.key,
    required this.goal,
    this.onTap,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return GoalItem(
      goal: goal,
      onTap: onTap,
      compact: true,
      showActions: false,
    );
  }
}

// Goal list item with swipe actions
class SwipeableGoalItem extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleComplete;

  const SwipeableGoalItem({
    super.key,
    required this.goal,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.horizontal,
      background: _buildSwipeBackground(
        context,
        Alignment.centerLeft,
        AppColors.primary,
        Icons.edit,
        'goals.edit'.tr(),
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        Alignment.centerRight,
        AppColors.error,
        Icons.delete,
        'goals.delete'.tr(),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit?.call();
          return false;
        } else if (direction == DismissDirection.endToStart) {
          return await _confirmDelete(context);
        }
        return false;
      },
      child: GoalItem(
        goal: goal,
        onTap: onTap,
        onEdit: onEdit,
        onDelete: onDelete,
        onToggleComplete: onToggleComplete,
        showActions: false,
      ),
    );
  }

  Widget _buildSwipeBackground(
    BuildContext context,
    Alignment alignment,
    Color color,
    IconData icon,
    String text,
  ) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      color: color.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            text,
            style: ShadTheme.of(context).textTheme.small.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showShadDialog<bool>(
          context: context,
          builder: (context) => ShadDialog(
            title: Text('goals.deleteGoal'.tr()),
            description: Text('goals.deleteConfirmation'.tr(args: [goal.name])),
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
        ) ??
        false;
  }
}
