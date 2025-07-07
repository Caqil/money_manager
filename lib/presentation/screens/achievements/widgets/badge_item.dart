import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:money_manager/data/models/badge.dart' show Badge, BadgeCategory;
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';

/// Compact horizontal badge item for lists
class CompactBadgeItem extends StatelessWidget {
  final Badge badge;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool showPoints;

  const CompactBadgeItem({
    super.key,
    required this.badge,
    this.onTap,
    this.showProgress = true,
    this.showPoints = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              // Badge Icon
              _buildBadgeIcon(),
              const SizedBox(width: AppDimensions.spacingM),

              // Badge Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge name and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            badge.name,
                            style: theme.textTheme.p.copyWith(
                              fontWeight: FontWeight.w600,
                              color: badge.isEarned
                                  ? AppColors.success
                                  : theme.colorScheme.foreground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge.isEarned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingS,
                              vertical: AppDimensions.spacingXs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusS),
                            ),
                            child: Text(
                              'badges.earned'.tr(),
                              style: theme.textTheme.small.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.spacingXs),

                    // Description
                    Text(
                      badge.description,
                      style: theme.textTheme.muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppDimensions.spacingS),

                    // Progress or Points
                    if (!badge.isEarned && showProgress && _hasProgress()) ...[
                      _buildProgressBar(context),
                    ] else if (showPoints) ...[
                      _buildPointsRow(context),
                    ],
                  ],
                ),
              ),

              // Arrow if tappable
              if (onTap != null) ...[
                const SizedBox(width: AppDimensions.spacingS),
                Icon(
                  Icons.chevron_right,
                  size: AppDimensions.iconS,
                  color: theme.colorScheme.mutedForeground,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeIcon() {
    final color = Color(badge.color);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: badge.isEarned
            ? color.withOpacity(0.2)
            : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: badge.isEarned
            ? Border.all(color: color.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Icon(
        _getBadgeIcon(),
        size: AppDimensions.iconM,
        color: badge.isEarned ? color : AppColors.lightOnSurfaceVariant,
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final theme = ShadTheme.of(context);
    final progress = badge.progressPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'badges.progress'.tr(),
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4,
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        if (badge.currentValue != null && badge.targetValue != null)
          Text(
            '${badge.currentValue!.toInt()}/${badge.targetValue!.toInt()} ${badge.unit ?? ''}',
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
      ],
    );
  }

  Widget _buildPointsRow(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Row(
      children: [
        Icon(
          Icons.stars,
          size: AppDimensions.iconS,
          color: AppColors.warning,
        ),
        const SizedBox(width: AppDimensions.spacingXs),
        Text(
          '${badge.points} ${'badges.points'.tr()}',
          style: theme.textTheme.small.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.warning,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
            vertical: AppDimensions.spacingXs,
          ),
          decoration: BoxDecoration(
            color: _getDifficultyColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.trending_up,
                size: 12,
                color: _getDifficultyColor(),
              ),
              const SizedBox(width: 2),
              Text(
                '${'badges.difficulty'.tr()} ${badge.difficulty}',
                style: theme.textTheme.small.copyWith(
                  color: _getDifficultyColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasProgress() {
    return badge.targetValue != null &&
        badge.currentValue != null &&
        badge.targetValue! > 0;
  }

  IconData _getBadgeIcon() {
    // Map iconName to actual icons or use category-based icons
    switch (badge.category) {
      case BadgeCategory.savings:
        return Icons.savings;
      case BadgeCategory.budgeting:
        return Icons.pie_chart;
      case BadgeCategory.transactions:
        return Icons.receipt_long;
      case BadgeCategory.goals:
        return Icons.flag;
      case BadgeCategory.consistency:
        return Icons.timeline;
      case BadgeCategory.exploration:
        return Icons.explore;
      case BadgeCategory.social:
        return Icons.group;
      case BadgeCategory.special:
        return Icons.auto_awesome;
    }
  }

  Color _getDifficultyColor() {
    switch (badge.difficulty) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.info;
      case 3:
        return AppColors.warning;
      case 4:
        return AppColors.error;
      case 5:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}

/// Grid badge item for grid displays
class GridBadgeItem extends StatelessWidget {
  final Badge badge;
  final VoidCallback? onTap;
  final bool showLabel;
  final bool showProgress;

  const GridBadgeItem({
    super.key,
    required this.badge,
    this.onTap,
    this.showLabel = true,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge Icon
              _buildBadgeIcon(),

              if (showLabel) ...[
                const SizedBox(height: AppDimensions.spacingS),

                // Badge Name
                Text(
                  badge.name,
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: badge.isEarned
                        ? AppColors.success
                        : theme.colorScheme.foreground,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Progress or Status
              if (!badge.isEarned && showProgress && _hasProgress()) ...[
                const SizedBox(height: AppDimensions.spacingS),
                _buildProgressIndicator(context),
              ] else if (badge.isEarned) ...[
                const SizedBox(height: AppDimensions.spacingXs),
                Icon(
                  Icons.check_circle,
                  size: AppDimensions.iconS,
                  color: AppColors.success,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeIcon() {
    final color = Color(badge.color);
    final size = 40.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badge.isEarned
            ? color.withOpacity(0.2)
            : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: badge.isEarned
            ? Border.all(color: color.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              _getBadgeIcon(),
              size: AppDimensions.iconM,
              color: badge.isEarned ? color : AppColors.lightOnSurfaceVariant,
            ),
          ),

          // Earned overlay
          if (badge.isEarned)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  Icons.check,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final theme = ShadTheme.of(context);
    final progress = badge.progressPercentage;

    return Column(
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          '${(progress * 100).toInt()}%',
          style: theme.textTheme.small.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  bool _hasProgress() {
    return badge.targetValue != null &&
        badge.currentValue != null &&
        badge.targetValue! > 0;
  }

  IconData _getBadgeIcon() {
    // Map iconName to actual icons or use category-based icons
    switch (badge.category) {
      case BadgeCategory.savings:
        return Icons.savings;
      case BadgeCategory.budgeting:
        return Icons.pie_chart;
      case BadgeCategory.transactions:
        return Icons.receipt_long;
      case BadgeCategory.goals:
        return Icons.flag;
      case BadgeCategory.consistency:
        return Icons.timeline;
      case BadgeCategory.exploration:
        return Icons.explore;
      case BadgeCategory.social:
        return Icons.group;
      case BadgeCategory.special:
        return Icons.auto_awesome;
    }
  }
}
