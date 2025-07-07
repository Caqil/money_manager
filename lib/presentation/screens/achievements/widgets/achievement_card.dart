import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../data/models/badge.dart' as badge;
import '../../../providers/badge_provider.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/common/loading_widget.dart';
import 'badge_item.dart';
import 'progress_ring.dart';

class AchievementCard extends ConsumerStatefulWidget {
  final badge.BadgeCategory? category;
  final AchievementCardType type;
  final String? title;
  final String? subtitle;
  final int? maxBadges;
  final VoidCallback? onViewAll;

  const AchievementCard({
    super.key,
    this.category,
    this.type = AchievementCardType.recent,
    this.title,
    this.subtitle,
    this.maxBadges,
    this.onViewAll,
  });

  @override
  ConsumerState<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends ConsumerState<AchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final badgesAsync = _getBadgesProvider();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ShadCard(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),

                    const SizedBox(height: AppDimensions.spacingM),

                    // Content
                    badgesAsync.when(
                      loading: () => _buildLoadingState(),
                      error: (error, stack) => _buildErrorState(error),
                      data: (badges) => _buildContent(badges),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final theme = ShadTheme.of(context);
    final title = widget.title ?? _getDefaultTitle();
    final subtitle = widget.subtitle ?? _getDefaultSubtitle();

    return Row(
      children: [
        // Category icon
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingS),
          decoration: BoxDecoration(
            color: _getCategoryColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            _getCategoryIcon(),
            color: _getCategoryColor(),
            size: AppDimensions.iconM,
          ),
        ),

        const SizedBox(width: AppDimensions.spacingM),

        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  subtitle,
                  style: theme.textTheme.muted,
                ),
              ],
            ],
          ),
        ),

        // View all button
        if (widget.onViewAll != null)
          ShadButton.outline(
            onPressed: widget.onViewAll,
            size: ShadButtonSize.sm,
            child: Text('common.viewAll'.tr()),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const ShimmerLoading(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: SkeletonLoader(height: 80, width: double.infinity)),
              SizedBox(width: AppDimensions.spacingS),
              Expanded(
                  child: SkeletonLoader(height: 80, width: double.infinity)),
            ],
          ),
          SizedBox(height: AppDimensions.spacingM),
          SkeletonLoader(height: 100, width: double.infinity),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return CustomErrorWidget(
      title: 'Error loading achievements',
      message: error.toString(),
      actionText: 'common.retry'.tr(),
      onActionPressed: () => ref.refresh(_getBadgesProvider()),
    );
  }

  Widget _buildContent(List<badge.Badge> badges) {
    if (badges.isEmpty) {
      return _buildEmptyState();
    }

    final displayBadges = _getDisplayBadges(badges);

    switch (widget.type) {
      case AchievementCardType.recent:
        return _buildRecentAchievements(displayBadges);
      case AchievementCardType.progress:
        return _buildProgressOverview(displayBadges);
      case AchievementCardType.category:
        return _buildCategoryOverview(displayBadges);
      case AchievementCardType.stats:
        return _buildStatsOverview(displayBadges);
    }
  }

  Widget _buildRecentAchievements(List<badge.Badge> badges) {
    final earnedBadges = badges.where((b) => b.isEarned).take(3).toList();
    final inProgressBadges = badges
        .where((b) =>
            !b.isEarned &&
            b.targetValue != null &&
            b.currentValue != null &&
            b.currentValue! > 0)
        .take(2)
        .toList();

    return Column(
      children: [
        // Recent earned badges
        if (earnedBadges.isNotEmpty) ...[
          ...earnedBadges.map((badge) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
              child: CompactBadgeItem(
                badge: badge,
                onTap: () => context.push('/achievements/${badge.id}'),
              ),
            );
          }),
        ],

        // In progress badges
        if (inProgressBadges.isNotEmpty) ...[
          if (earnedBadges.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingS),
            const Divider(),
            const SizedBox(height: AppDimensions.spacingS),
          ],
          Text(
            'badges.inProgress'.tr(),
            style: ShadTheme.of(context).textTheme.p.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ...inProgressBadges.map((badge) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
              child: CompactBadgeItem(
                badge: badge,
                onTap: () => context.push('/achievements/${badge.id}'),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildProgressOverview(List<badge.Badge> badges) {
    final theme = ShadTheme.of(context);
    final earnedCount = badges.where((b) => b.isEarned).length;
    final totalCount = badges.length;
    final progress = totalCount > 0 ? earnedCount / totalCount : 0.0;

    return Column(
      children: [
        // Overall progress
        Row(
          children: [
            AchievementProgressRing(
              progress: progress,
              size: 60.0,
              isCompleted: progress == 1.0,
              child: Text(
                '$earnedCount',
                style: theme.textTheme.p.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'badges.earned'.tr(),
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$earnedCount of $totalCount badges',
                    style: theme.textTheme.muted,
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor:
                        theme.colorScheme.secondary.withOpacity(0.2),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_getCategoryColor()),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // Badge grid
        if (badges.isNotEmpty) _buildBadgeGrid(badges.take(4).toList()),
      ],
    );
  }

  Widget _buildCategoryOverview(List<badge.Badge> badges) {
    final earnedBadges = badges.where((b) => b.isEarned).toList();
    final inProgressBadges = badges
        .where((b) =>
            !b.isEarned && b.targetValue != null && b.currentValue != null)
        .toList();

    return Column(
      children: [
        // Stats row
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.emoji_events,
                label: 'badges.earned'.tr(),
                value: earnedBadges.length.toString(),
                color: AppColors.success,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.trending_up,
                label: 'badges.inProgress'.tr(),
                value: inProgressBadges.length.toString(),
                color: AppColors.info,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.stars,
                label: 'badges.points'.tr(),
                value: earnedBadges
                    .fold<int>(0, (sum, b) => sum + b.points)
                    .toString(),
                color: AppColors.warning,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // Badge showcase
        if (badges.isNotEmpty) _buildBadgeGrid(badges.take(6).toList()),
      ],
    );
  }

  Widget _buildStatsOverview(List<badge.Badge> badges) {
    final theme = ShadTheme.of(context);
    final earnedBadges = badges.where((b) => b.isEarned).toList();
    final totalPoints = earnedBadges.fold<int>(0, (sum, b) => sum + b.points);
    final avgDifficulty = earnedBadges.isNotEmpty
        ? earnedBadges.fold<double>(0, (sum, b) => sum + b.difficulty) /
            earnedBadges.length
        : 0.0;

    return Column(
      children: [
        // Main stats
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Column(
                  children: [
                    Text(
                      totalPoints.toString(),
                      style: theme.textTheme.h2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'badges.totalPoints'.tr(),
                      style: theme.textTheme.small,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Column(
                  children: [
                    Text(
                      earnedBadges.length.toString(),
                      style: theme.textTheme.h2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'badges.completed'.tr(),
                      style: theme.textTheme.small,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // Recent badges
        if (earnedBadges.isNotEmpty) ...[
          Text(
            'badges.recentlyEarned'.tr(),
            style: theme.textTheme.p.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          _buildBadgeGrid(earnedBadges.take(4).toList()),
        ],
      ],
    );
  }

  Widget _buildBadgeGrid(List<badge.Badge> badges) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: AppDimensions.spacingS,
        mainAxisSpacing: AppDimensions.spacingS,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return GridBadgeItem(
          badge: badge,
          onTap: () => context.push('/achievements/${badge.id}'),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppDimensions.iconM),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            value,
            style: theme.textTheme.p.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.small,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        Icon(
          Icons.emoji_events_outlined,
          size: 64,
          color: theme.colorScheme.mutedForeground.withOpacity(0.5),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          'badges.noBadges'.tr(),
          style: theme.textTheme.p.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          'badges.startEarning'.tr(),
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Helper methods
  AsyncValue<List<badge.Badge>> _getBadgesProvider() {
    switch (widget.type) {
      case AchievementCardType.recent:
        return ref.watch(recentBadgesProvider(widget.maxBadges ?? 5));
      case AchievementCardType.progress:
        return widget.category != null
            ? ref.watch(badgesByCategoryProvider(widget.category!))
            : ref.watch(badgeListProvider);
      case AchievementCardType.category:
        return widget.category != null
            ? ref.watch(badgesByCategoryProvider(widget.category!))
            : ref.watch(badgeListProvider);
      case AchievementCardType.stats:
        return ref.watch(badgeListProvider);
    }
  }

  List<badge.Badge> _getDisplayBadges(List<badge.Badge> badges) {
    var displayBadges = badges;

    // Sort based on type
    switch (widget.type) {
      case AchievementCardType.recent:
        displayBadges.sort((a, b) {
          if (a.isEarned && !b.isEarned) return -1;
          if (!a.isEarned && b.isEarned) return 1;
          if (a.isEarned && b.isEarned) {
            return (b.earnedAt ?? DateTime.now())
                .compareTo(a.earnedAt ?? DateTime.now());
          }
          return b.progressPercentage.compareTo(a.progressPercentage);
        });
        break;
      case AchievementCardType.progress:
        displayBadges.sort(
            (a, b) => b.progressPercentage.compareTo(a.progressPercentage));
        break;
      case AchievementCardType.category:
        displayBadges.sort((a, b) => b.points.compareTo(a.points));
        break;
      case AchievementCardType.stats:
        displayBadges.sort((a, b) => b.difficulty.compareTo(a.difficulty));
        break;
    }

    // Limit badges if specified
    if (widget.maxBadges != null) {
      displayBadges = displayBadges.take(widget.maxBadges!).toList();
    }

    return displayBadges;
  }

  String _getDefaultTitle() {
    switch (widget.type) {
      case AchievementCardType.recent:
        return 'badges.recentAchievements'.tr();
      case AchievementCardType.progress:
        return 'badges.progress'.tr();
      case AchievementCardType.category:
        return widget.category != null
            ? 'badges.categories.${widget.category!.name}'.tr()
            : 'badges.achievements'.tr();
      case AchievementCardType.stats:
        return 'badges.statistics'.tr();
    }
  }

  String _getDefaultSubtitle() {
    switch (widget.type) {
      case AchievementCardType.recent:
        return 'badges.latestProgress'.tr();
      case AchievementCardType.progress:
        return 'badges.yourProgress'.tr();
      case AchievementCardType.category:
        return 'badges.categoryProgress'.tr();
      case AchievementCardType.stats:
        return 'badges.overallStats'.tr();
    }
  }

  Color _getCategoryColor() {
    if (widget.category == null) return AppColors.primary;

    const categoryColors = {
      badge.BadgeCategory.savings: AppColors.success,
      badge.BadgeCategory.budgeting: AppColors.info,
      badge.BadgeCategory.transactions: AppColors.primary,
      badge.BadgeCategory.goals: AppColors.warning,
      badge.BadgeCategory.consistency: AppColors.secondary,
      badge.BadgeCategory.exploration: AppColors.accent,
      badge.BadgeCategory.social: AppColors.info,
      badge.BadgeCategory.special: AppColors.primary,
    };

    return categoryColors[widget.category] ?? AppColors.primary;
  }

  IconData _getCategoryIcon() {
    if (widget.category == null) return Icons.emoji_events;

    const categoryIcons = {
      badge.BadgeCategory.savings: Icons.savings,
      badge.BadgeCategory.budgeting: Icons.pie_chart,
      badge.BadgeCategory.transactions: Icons.receipt_long,
      badge.BadgeCategory.goals: Icons.flag,
      badge.BadgeCategory.consistency: Icons.timeline,
      badge.BadgeCategory.exploration: Icons.explore,
      badge.BadgeCategory.social: Icons.group,
      badge.BadgeCategory.special: Icons.auto_awesome,
    };

    return categoryIcons[widget.category] ?? Icons.emoji_events;
  }
}

enum AchievementCardType {
  recent,
  progress,
  category,
  stats,
}
