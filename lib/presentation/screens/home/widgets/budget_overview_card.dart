import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../providers/analytics_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/common/progress_indicator_widget.dart';

class BudgetOverviewCard extends ConsumerStatefulWidget {
  const BudgetOverviewCard({super.key});

  @override
  ConsumerState<BudgetOverviewCard> createState() => _BudgetOverviewCardState();
}

class _BudgetOverviewCardState extends ConsumerState<BudgetOverviewCard>
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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
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
    final budgetPerformanceAsync = ref.watch(budgetPerformanceProvider);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ShadCard(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: AppDimensions.spacingM),

                    // Content
                    budgetPerformanceAsync.when(
                      loading: () => _buildLoadingState(),
                      error: (error, stack) => _buildErrorState(error),
                      data: (budgetPerformances) =>
                          _buildContent(budgetPerformances),
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

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingS),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            Icons.pie_chart,
            color: AppColors.secondary,
            size: AppDimensions.iconM,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'budgets.overview'.tr(),
                style: theme.textTheme.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'dashboard.thisMonth'.tr(),
                style: theme.textTheme.muted,
              ),
            ],
          ),
        ),
        ShadButton.outline(
          onPressed: () => context.push('/budgets'),
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
      title: 'Error loading budgets',
      message: error.toString(),
      actionText: 'common.retry'.tr(),
      onActionPressed: () => ref.refresh(budgetPerformanceProvider),
    );
  }

  Widget _buildContent(List<BudgetPerformance> budgetPerformances) {
    final theme = ShadTheme.of(context);
    const defaultCurrency = AppConstants.defaultCurrency;

    if (budgetPerformances.isEmpty) {
      return _buildEmptyState();
    }

    // Calculate overall statistics
    final totalBudget = budgetPerformances.fold<double>(
        0.0, (sum, bp) => sum + bp.budget.limit);
    final totalSpent =
        budgetPerformances.fold<double>(0.0, (sum, bp) => sum + bp.spentAmount);
    final totalRemaining = totalBudget - totalSpent;
    final overallProgress = totalBudget > 0 ? totalSpent / totalBudget : 0.0;

    // Categorize budgets
    final onTrackBudgets =
        budgetPerformances.where((bp) => bp.percentageUsed <= 0.8).length;
    final nearLimitBudgets = budgetPerformances
        .where((bp) => bp.percentageUsed > 0.8 && bp.percentageUsed <= 1.0)
        .length;
    final overBudgetBudgets =
        budgetPerformances.where((bp) => bp.percentageUsed > 1.0).length;

    return Column(
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.trending_up,
                label: 'budgets.spent'.tr(),
                value: totalSpent,
                currency: defaultCurrency,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.savings,
                label: 'budgets.remaining'.tr(),
                value: totalRemaining,
                currency: defaultCurrency,
                color:
                    totalRemaining >= 0 ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // Overall Progress
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(
              color: theme.colorScheme.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'budgets.progress'.tr(),
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(overallProgress * 100).toInt()}%',
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getProgressColor(overallProgress),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),
              ProgressIndicatorWidget(
                value: overallProgress,
                height: 8.0,
                valueColor: _getProgressColor(overallProgress),
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                showAnimation: true,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.format(totalSpent,
                        currency: defaultCurrency),
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(totalBudget,
                        currency: defaultCurrency),
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // Budget Status Summary
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                label: 'budgets.onTrack'.tr(),
                count: onTrackBudgets,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingXs),
            Expanded(
              child: _buildStatusCard(
                label: 'budgets.nearLimit'.tr(),
                count: nearLimitBudgets,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingXs),
            Expanded(
              child: _buildStatusCard(
                label: 'budgets.overBudget'.tr(),
                count: overBudgetBudgets,
                color: AppColors.error,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // Top Budget Items
        if (budgetPerformances.isNotEmpty) ...[
          Text(
            'Top Budget Categories',
            style: theme.textTheme.p.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ...budgetPerformances.take(3).map((bp) => _buildBudgetItem(bp)),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = ShadTheme.of(context);

    return Center(
        child: Column(
      children: [
        Icon(
          Icons.pie_chart_outline,
          size: 64,
          color: theme.colorScheme.mutedForeground.withOpacity(0.5),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          'budgets.noBudgets'.tr(),
          style: theme.textTheme.h4,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          'budgets.createFirstBudget'.tr(),
          style: theme.textTheme.muted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        ShadButton(
          onPressed: () => context.push('/budgets/add'),
          child: Text('budgets.addBudget'.tr()),
        ),
      ],
    ));
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required double value,
    required String currency,
    required Color color,
  }) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: AppDimensions.iconS),
              const SizedBox(width: AppDimensions.spacingXs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            CurrencyFormatter.format(value, currency: currency),
            style: theme.textTheme.p.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String label,
    required int count,
    required Color color,
  }) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingS,
        vertical: AppDimensions.paddingXs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: theme.textTheme.p.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItem(BudgetPerformance bp) {
    final theme = ShadTheme.of(context);
    const defaultCurrency = AppConstants.defaultCurrency;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getBudgetColor(bp.percentageUsed),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bp.budget.name,
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${CurrencyFormatter.format(bp.spentAmount, currency: defaultCurrency)} / ${CurrencyFormatter.format(bp.budget.limit, currency: defaultCurrency)}',
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(bp.percentageUsed * 100).toInt()}%',
            style: theme.textTheme.small.copyWith(
              fontWeight: FontWeight.w600,
              color: _getBudgetColor(bp.percentageUsed),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress > 1.0) return AppColors.error;
    if (progress > 0.8) return AppColors.warning;
    return AppColors.success;
  }

  Color _getBudgetColor(double percentageUsed) {
    if (percentageUsed > 1.0) return AppColors.error;
    if (percentageUsed > 0.8) return AppColors.warning;
    return AppColors.success;
  }
}
