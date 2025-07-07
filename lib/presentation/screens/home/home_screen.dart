import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import 'widgets/balance_card.dart';
import 'widgets/budget_overview_card.dart';
import 'widgets/quick_action_buttons.dart';
import 'widgets/recent_transactions_list.dart';
import 'widgets/spending_chart_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showScrollToTop = _scrollController.offset > 200;
    if (showScrollToTop != _showScrollToTop) {
      setState(() => _showScrollToTop = showScrollToTop);
    }
  }

  Future<void> _refreshData() async {
    // Refresh all providers
    ref.refresh(accountListProvider);
    ref.refresh(recentTransactionsProvider(10));
    ref.refresh(budgetListProvider);
    ref.refresh(dashboardAnalyticsProvider);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = ShadTheme.of(context);
    final dashboardWidgets = _getDashboardWidgets();

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Welcome Header
            SliverToBoxAdapter(
              child: _buildWelcomeHeader(),
            ),

            // Main Content
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Balance Card
                  if (dashboardWidgets.contains('balance_card'))
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppDimensions.spacingM),
                      child: BalanceCard(),
                    ),

                  // Quick Actions
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppDimensions.spacingM),
                    child: QuickActionButtons(),
                  ),

                  // Budget Overview
                  if (dashboardWidgets.contains('budget_overview'))
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppDimensions.spacingM),
                      child: BudgetOverviewCard(),
                    ),

                  // Spending Chart
                  if (dashboardWidgets.contains('spending_chart'))
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppDimensions.spacingM),
                      child: SpendingChartWidget(),
                    ),

                  // Recent Transactions
                  if (dashboardWidgets.contains('recent_transactions'))
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppDimensions.spacingXl),
                      child: RecentTransactionsList(),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              mini: true,
              child: const Icon(Icons.keyboard_arrow_up),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: 'dashboard.welcome'.tr(),
      showBackButton: false,
      actions: [
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'notifications.title'.tr(),
        ),
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'settings.title'.tr(),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    final theme = ShadTheme.of(context);
    final currentHour = DateTime.now().hour;

    String greeting;
    if (currentHour < 12) {
      greeting = 'Good Morning';
    } else if (currentHour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: theme.textTheme.large.copyWith(
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      Text(
                        'dashboard.welcome'.tr(),
                        style: theme.textTheme.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingS),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: theme.colorScheme.primary,
                    size: AppDimensions.iconL,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getDashboardWidgets() {
    // Default dashboard widgets order
    return [
      'balance_card',
      'recent_transactions',
      'budget_overview',
      'spending_chart',
    ];
  }
}
