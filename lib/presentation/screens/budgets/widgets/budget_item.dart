import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/budget.dart';
import '../../../../presentation/providers/analytics_provider.dart';
import '../../../../presentation/providers/category_provider.dart';

class BudgetItem extends ConsumerStatefulWidget {
  final Budget budget;
  final double? spentAmount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;
  final bool showActions;
  final bool showProgress;

  const BudgetItem({
    super.key,
    required this.budget,
    this.spentAmount,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
    this.showActions = true,
    this.showProgress = true,
  });

  @override
  ConsumerState<BudgetItem> createState() => _BudgetItemState();
}

class _BudgetItemState extends ConsumerState<BudgetItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final spentAmount = widget.spentAmount ?? 0.0;
    final percentage =
        widget.budget.limit > 0 ? (spentAmount / widget.budget.limit) : 0.0;
    final remaining =
        (widget.budget.limit - spentAmount).clamp(0.0, double.infinity);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            onTap: widget.onTap ??
                () => context.push('/budgets/${widget.budget.id}'),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
              child: ShadCard(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                child: Column(
                  children: [
                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          _buildHeader(context, percentage),

                          const SizedBox(height: AppDimensions.spacingM),

                          // Budget details
                          _buildBudgetDetails(context, spentAmount, remaining),

                          if (widget.showProgress) ...[
                            const SizedBox(height: AppDimensions.spacingM),
                            _buildProgressBar(context, percentage),
                          ],
                        ],
                      ),
                    ),

                    // Actions (expandable)
                    if (widget.showActions) _buildActions(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, double percentage) {
    final theme = ShadTheme.of(context);
    final categoryAsync = ref.watch(categoryProvider(widget.budget.categoryId));

    return Row(
      children: [
        // Category icon
        categoryAsync.when(
          data: (category) {
            final color =
                category != null ? Color(category.color) : AppColors.primary;
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                _getCategoryIcon(category?.iconName),
                color: color,
                size: AppDimensions.iconM,
              ),
            );
          },
          loading: () => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: const Icon(Icons.category),
          ),
          error: (_, __) => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: const Icon(Icons.category),
          ),
        ),

        const SizedBox(width: AppDimensions.spacingM),

        // Budget info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.budget.name,
                      style: theme.textTheme.p.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(context, percentage),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              categoryAsync.when(
                data: (category) => Text(
                  category?.name ?? 'budgets.unknownCategory'.tr(),
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Text(
                    _getPeriodLabel(widget.budget.period),
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                  if (!widget.budget.isActive) ...[
                    const SizedBox(width: AppDimensions.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingS,
                        vertical: AppDimensions.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightOnSurfaceVariant.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Text(
                        'budgets.inactive'.tr(),
                        style: theme.textTheme.small.copyWith(
                          color: AppColors.lightOnSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // More options
        if (widget.showActions)
          ShadButton.ghost(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            size: ShadButtonSize.sm,
            child: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              size: AppDimensions.iconS,
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, double percentage) {
    final theme = ShadTheme.of(context);

    Color color;
    String status;
    IconData icon;

    if (percentage >= 1.0) {
      color = AppColors.error;
      status = 'budgets.overBudget'.tr();
      icon = Icons.error;
    } else if (percentage >= widget.budget.alertThreshold) {
      color = AppColors.warning;
      status = 'budgets.nearLimit'.tr();
      icon = Icons.warning;
    } else {
      color = AppColors.success;
      status = 'budgets.onTrack'.tr();
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          Text(
            status,
            style: theme.textTheme.small.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetDetails(
      BuildContext context, double spentAmount, double remaining) {
    final theme = ShadTheme.of(context);

    return Row(
      children: [
        Expanded(
          child: _buildDetailColumn(
            context,
            'budgets.spent'.tr(),
            CurrencyFormatter.format(spentAmount),
            AppColors.error,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: _buildDetailColumn(
            context,
            'budgets.remaining'.tr(),
            CurrencyFormatter.format(remaining),
            AppColors.success,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: _buildDetailColumn(
            context,
            'budgets.limit'.tr(),
            CurrencyFormatter.format(widget.budget.limit),
            AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailColumn(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          value,
          style: theme.textTheme.small.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, double percentage) {
    final theme = ShadTheme.of(context);

    Color progressColor;
    if (percentage >= 1.0) {
      progressColor = AppColors.error;
    } else if (percentage >= widget.budget.alertThreshold) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.success;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'budgets.progress'.tr(),
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  boxShadow: [
                    BoxShadow(
                      color: progressColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    if (!_isExpanded) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusM),
          bottomRight: Radius.circular(AppDimensions.radiusM),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ShadButton.outline(
              onPressed: widget.onEdit ??
                  () {
                    context.push('/budgets/${widget.budget.id}/edit');
                  },
              size: ShadButtonSize.sm,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: AppDimensions.iconS),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Text('common.edit'.tr()),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: ShadButton.outline(
              onPressed: widget.onToggleActive ??
                  () {
                    _showToggleActiveDialog(context);
                  },
              size: ShadButtonSize.sm,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.budget.isActive ? Icons.pause : Icons.play_arrow,
                    size: AppDimensions.iconS,
                  ),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Text(widget.budget.isActive
                      ? 'budgets.deactivate'.tr()
                      : 'budgets.activate'.tr()),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          ShadButton.ghost(
            onPressed: widget.onDelete ??
                () {
                  _showDeleteDialog(context);
                },
            size: ShadButtonSize.sm,
            child: Icon(
              Icons.delete,
              size: AppDimensions.iconS,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _showToggleActiveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.budget.isActive
            ? 'budgets.deactivateBudget'.tr()
            : 'budgets.activateBudget'.tr()),
        content: Text(widget.budget.isActive
            ? 'budgets.deactivateConfirmation'.tr()
            : 'budgets.activateConfirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.onToggleActive != null) {
                widget.onToggleActive!();
              }
            },
            child: Text('common.confirm'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('budgets.deleteBudget'.tr()),
        content: Text('budgets.deleteConfirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.onDelete != null) {
                widget.onDelete!();
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
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

  IconData _getCategoryIcon(String? iconName) {
    if (iconName == null) return Icons.category;

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
