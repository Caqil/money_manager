import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/account.dart';
import '../../../providers/account_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/common/error_widget.dart';

class BalanceCard extends ConsumerStatefulWidget {
  const BalanceCard({super.key});

  @override
  ConsumerState<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<BalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showDetails = false;

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
      begin: const Offset(0, 0.5),
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

  void _toggleDetails() {
    setState(() => _showDetails = !_showDetails);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final accountsAsync = ref.watch(accountListProvider);
    const defaultCurrency = AppConstants.defaultCurrency;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ShadCard(
              child: accountsAsync.when(
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(error),
                data: (accounts) => _buildContent(accounts, defaultCurrency),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(AppDimensions.paddingM),
      child: ShimmerLoading(
        child: Column(
          children: [
            SkeletonLoader(height: 24, width: 120),
            SizedBox(height: AppDimensions.spacingS),
            SkeletonLoader(height: 32, width: 200),
            SizedBox(height: AppDimensions.spacingM),
            Row(
              children: [
                Expanded(
                    child: SkeletonLoader(height: 60, width: double.infinity)),
                SizedBox(width: AppDimensions.spacingS),
                Expanded(
                    child: SkeletonLoader(height: 60, width: double.infinity)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: CustomErrorWidget(
        title: 'Error loading balance',
        message: error.toString(),
        actionText: 'common.retry'.tr(),
        onActionPressed: () => ref.refresh(accountListProvider),
      ),
    );
  }

  Widget _buildContent(List<Account> accounts, String defaultCurrency) {
    final theme = ShadTheme.of(context);
    final activeAccounts =
        accounts.where((a) => a.isActive && a.includeInTotal).toList();

    // Calculate totals
    final totals = _calculateTotals(activeAccounts);
    final totalBalance = totals['total'] ?? 0.0;
    final liquidBalance = totals['liquid'] ?? 0.0;
    final creditAvailable = totals['credit'] ?? 0.0;
    final investmentValue = totals['investment'] ?? 0.0;

    return InkWell(
      onTap: _toggleDetails,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primary,
                    size: AppDimensions.iconM,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'dashboard.totalBalance'.tr(),
                        style: theme.textTheme.muted,
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      Text(
                        CurrencyFormatter.format(
                          totalBalance,
                          currency: defaultCurrency,
                        ),
                        style: theme.textTheme.h2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getBalanceColor(totalBalance),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showDetails ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.mutedForeground,
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spacingM),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.water_drop,
                    label: 'Liquid',
                    value: liquidBalance,
                    currency: defaultCurrency,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.credit_card,
                    label: 'Credit Available',
                    value: creditAvailable,
                    currency: defaultCurrency,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),

            // Detailed View
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showDetails ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showDetails ? 1.0 : 0.0,
                child: _showDetails
                    ? _buildDetailedView(
                        activeAccounts,
                        investmentValue,
                        defaultCurrency,
                      )
                    : const SizedBox(),
              ),
            ),

            // Actions
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    onPressed: () => context.push('/accounts'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance,
                            size: AppDimensions.iconS),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text('accounts.title'.tr()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: ShadButton(
                    onPressed: () => context.push('/transactions/add'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: AppDimensions.iconS),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text('quickActions.addExpense'.tr()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
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
            CurrencyFormatter.format(
              value,
              currency: currency,
            ),
            style: theme.textTheme.p.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedView(
    List<Account> accounts,
    double investmentValue,
    String defaultCurrency,
  ) {
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        const SizedBox(height: AppDimensions.spacingM),
        const Divider(),
        const SizedBox(height: AppDimensions.spacingM),

        // Account Breakdown
        Row(
          children: [
            Icon(
              Icons.pie_chart,
              size: AppDimensions.iconS,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              'Account Breakdown',
              style: theme.textTheme.p.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),

        ...accounts.take(3).map((account) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingXs),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: account.color != null
                          ? Color(account.color!)
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      account.name,
                      style: theme.textTheme.small,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(
                      account.balance,
                      currency: account.currency,
                    ),
                    style: theme.textTheme.small.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),

        if (accounts.length > 3) ...[
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            '+${accounts.length - 3} more accounts',
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }

  Map<String, double> _calculateTotals(List<Account> accounts) {
    double total = 0.0;
    double liquid = 0.0;
    double credit = 0.0;
    double investment = 0.0;

    for (final account in accounts) {
      total += account.balance;

      switch (account.type) {
        case AccountType.checking:
        case AccountType.savings:
        case AccountType.cash:
          liquid += account.balance;
          break;
        case AccountType.creditCard:
          credit += account.availableBalance;
          break;
        case AccountType.investment:
          investment += account.balance;
          break;
        case AccountType.loan:
        case AccountType.other:
          // These are included in total but not categorized
          break;
      }
    }

    return {
      'total': total,
      'liquid': liquid,
      'credit': credit,
      'investment': investment,
    };
  }

  Color _getBalanceColor(double balance) {
    if (balance > 0) {
      return AppColors.success;
    } else if (balance < 0) {
      return AppColors.error;
    } else {
      return AppColors.warning;
    }
  }
}
