// lib/presentation/screens/analytics/financial_health_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/charts/pie_chart_widget.dart';
import '../../widgets/charts/line_chart_widget.dart';

class FinancialHealthScreen extends ConsumerStatefulWidget {
  const FinancialHealthScreen({super.key});

  @override
  ConsumerState<FinancialHealthScreen> createState() =>
      _FinancialHealthScreenState();
}

class _FinancialHealthScreenState extends ConsumerState<FinancialHealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  HealthTimeframe _selectedTimeframe = HealthTimeframe.current;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'analytics.financialHealth'.tr(),
        actions: [
          PopupMenuButton<HealthTimeframe>(
            onSelected: (timeframe) {
              setState(() {
                _selectedTimeframe = timeframe;
              });
            },
            itemBuilder: (context) => HealthTimeframe.values
                .map(
                  (timeframe) => PopupMenuItem(
                    value: timeframe,
                    child: Row(
                      children: [
                        Icon(_getTimeframeIcon(timeframe), size: 16),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text(_getTimeframeLabel(timeframe)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'improve',
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('financialHealth.improveScore'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'benchmark',
                child: Row(
                  children: [
                    const Icon(Icons.compare, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('financialHealth.benchmark'.tr()),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.download, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('common.export'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHealthScoreHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDetailedScoreTab(),
                _buildRecommendationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreHeader() {
    final healthDataAsync =
        ref.watch(financialHealthProvider(_selectedTimeframe));

    return healthDataAsync.when(
      loading: () => Container(
        height: 200,
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        child: const LoadingWidget(),
      ),
      error: (error, _) => Container(
        height: 200,
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        child: CustomErrorWidget(
          message: 'financialHealth.errorLoadingData'.tr(),
          onActionPressed: () =>
              ref.refresh(financialHealthProvider(_selectedTimeframe)),
        ),
      ),
      data: (data) => Container(
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getScoreColor(data.score),
              _getScoreColor(data.score).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'financialHealth.yourScore'.tr(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            data.score.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '/100',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingS,
                          vertical: AppDimensions.paddingXs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: Text(
                          _getGradeDescription(data.grade),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      child: Stack(
                        children: [
                          CircularProgressIndicator(
                            value: data.score / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  data.grade,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'financialHealth.grade'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Row(
                      children: [
                        Icon(
                          data.trend == HealthTrend.improving
                              ? Icons.trending_up
                              : data.trend == HealthTrend.declining
                                  ? Icons.trending_down
                                  : Icons.trending_flat,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: AppDimensions.spacingXs),
                        Text(
                          _getTrendLabel(data.trend),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildQuickMetric(
                    'financialHealth.savingsRate'.tr(),
                    '${data.savingsRate.toStringAsFixed(1)}%',
                    Icons.savings,
                  ),
                ),
                Expanded(
                  child: _buildQuickMetric(
                    'financialHealth.debtRatio'.tr(),
                    '${data.debtToIncomeRatio.toStringAsFixed(1)}%',
                    Icons.credit_card,
                  ),
                ),
                Expanded(
                  child: _buildQuickMetric(
                    'financialHealth.emergencyFund'.tr(),
                    '${data.emergencyFundMonths.toStringAsFixed(1)}M',
                    Icons.security,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: 'financialHealth.overview'.tr()),
        Tab(text: 'financialHealth.detailed'.tr()),
        Tab(text: 'financialHealth.recommendations'.tr()),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final healthDataAsync =
        ref.watch(financialHealthProvider(_selectedTimeframe));

    return healthDataAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'financialHealth.errorLoadingData'.tr(),
        onActionPressed: () =>
            ref.refresh(financialHealthProvider(_selectedTimeframe)),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreBreakdownCard(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildHealthTrendChart(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildKeyMetricsCard(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildQuickActionsCard(data),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedScoreTab() {
    final detailedDataAsync =
        ref.watch(detailedHealthScoreProvider(_selectedTimeframe));

    return detailedDataAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'financialHealth.errorLoadingData'.tr(),
        onActionPressed: () =>
            ref.refresh(detailedHealthScoreProvider(_selectedTimeframe)),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreComponentsCard(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildBenchmarkComparison(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildScoreHistory(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildGoalsImpactCard(data),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    final recommendationsAsync =
        ref.watch(healthRecommendationsProvider(_selectedTimeframe));

    return recommendationsAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => CustomErrorWidget(
        message: 'financialHealth.errorLoadingData'.tr(),
        onActionPressed: () =>
            ref.refresh(healthRecommendationsProvider(_selectedTimeframe)),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPriorityRecommendations(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildActionPlan(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildLongTermGoals(data),
            const SizedBox(height: AppDimensions.spacingL),
            _buildEducationalResources(data),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdownCard(FinancialHealthData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financialHealth.scoreBreakdown'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ...data.scoreComponents.map((component) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingS),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getComponentIcon(component.category),
                            color: _getComponentColor(component.score),
                            size: 20,
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          Expanded(
                            child: Text(
                              _getComponentTitle(component.category),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${component.score}/${component.maxScore}',
                            style: TextStyle(
                              color: _getComponentColor(component.score),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      LinearProgressIndicator(
                        value: component.score / component.maxScore,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getComponentColor(component.score),
                        ),
                      ),
                      if (component.description.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text(
                          component.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTrendChart(FinancialHealthData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financialHealth.healthTrend'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 250,
              child: const Placeholder(), // Replace with actual line chart
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsCard(FinancialHealthData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financialHealth.keyMetrics'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: AppDimensions.spacingM,
              mainAxisSpacing: AppDimensions.spacingM,
              children: [
                _buildMetricTile(
                  'financialHealth.monthlyIncome'.tr(),
                  CurrencyFormatter.format(data.monthlyIncome),
                  Icons.trending_up,
                  AppColors.success,
                ),
                _buildMetricTile(
                  'financialHealth.monthlyExpenses'.tr(),
                  CurrencyFormatter.format(data.monthlyExpenses),
                  Icons.trending_down,
                  AppColors.error,
                ),
                _buildMetricTile(
                  'financialHealth.netWorth'.tr(),
                  CurrencyFormatter.format(data.netWorth),
                  Icons.account_balance,
                  AppColors.primary,
                ),
                _buildMetricTile(
                  'financialHealth.totalDebt'.tr(),
                  CurrencyFormatter.format(data.totalDebt),
                  Icons.credit_card,
                  AppColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.info_outline, color: color, size: 12),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(FinancialHealthData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financialHealth.quickActions'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ...data.quickActions.map((action) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingS),
                  child: ShadButton.outline(
                    onPressed: () => _handleQuickAction(action),
                    child: Row(
                      children: [
                        Icon(
                          _getActionIcon(action.type),
                          size: 16,
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        Expanded(
                          child: Text(action.title),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreComponentsCard(DetailedHealthScore data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financialHealth.scoreComponents'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 300,
              child: const Placeholder(), // Replace with actual pie chart
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkComparison(DetailedHealthScore data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financialHealth.benchmarkComparison'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ...data.benchmarks.map((benchmark) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingS),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              benchmark.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            'You: ${benchmark.userValue.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: benchmark.userValue / 100,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                benchmark.userValue >= benchmark.averageValue
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          Text(
                            'Avg: ${benchmark.averageValue.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHistory(DetailedHealthScore data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financialHealth.scoreHistory'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              height: 200,
              child: const Placeholder(), // Replace with actual line chart
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsImpactCard(DetailedHealthScore data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financialHealth.goalsImpact'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text('Goals impact analysis placeholder'),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityRecommendations(HealthRecommendations data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financialHealth.priorityRecommendations'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ...data.priorityRecommendations.map((recommendation) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingM),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(recommendation.priority)
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(
                        color: _getPriorityColor(recommendation.priority)
                            .withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.paddingS,
                                vertical: AppDimensions.paddingXs,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _getPriorityColor(recommendation.priority),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusS),
                              ),
                              child: Text(
                                _getPriorityLabel(recommendation.priority),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '+${recommendation.potentialImpact} pts',
                              style: TextStyle(
                                color:
                                    _getPriorityColor(recommendation.priority),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingS),
                        Text(
                          recommendation.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text(
                          recommendation.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        if (recommendation.actionSteps.isNotEmpty) ...[
                          const SizedBox(height: AppDimensions.spacingS),
                          ...recommendation.actionSteps.take(3).map((step) =>
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ',
                                      style: TextStyle(
                                        color: _getPriorityColor(
                                            recommendation.priority),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        step,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPlan(HealthRecommendations data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financialHealth.actionPlan'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text('Action plan placeholder'),
          ],
        ),
      ),
    );
  }

  Widget _buildLongTermGoals(HealthRecommendations data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financialHealth.longTermGoals'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text('Long term goals placeholder'),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationalResources(HealthRecommendations data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financialHealth.educationalResources'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ...data.educationalResources.map((resource) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingS),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _getResourceIcon(resource.type),
                      color: AppColors.primary,
                    ),
                    title: Text(resource.title),
                    subtitle: Text(resource.description),
                    trailing: const Icon(Icons.open_in_new, size: 16),
                    onTap: () => _openResource(resource),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    if (score >= 40) return AppColors.primary;
    return AppColors.error;
  }

  String _getGradeDescription(String grade) {
    switch (grade) {
      case 'A':
        return 'financialHealth.excellent'.tr();
      case 'B':
        return 'financialHealth.good'.tr();
      case 'C':
        return 'financialHealth.fair'.tr();
      case 'D':
        return 'financialHealth.poor'.tr();
      case 'F':
        return 'financialHealth.failing'.tr();
      default:
        return grade;
    }
  }

  String _getTrendLabel(HealthTrend trend) {
    switch (trend) {
      case HealthTrend.improving:
        return 'financialHealth.improving'.tr();
      case HealthTrend.stable:
        return 'financialHealth.stable'.tr();
      case HealthTrend.declining:
        return 'financialHealth.declining'.tr();
    }
  }

  IconData _getTimeframeIcon(HealthTimeframe timeframe) {
    switch (timeframe) {
      case HealthTimeframe.current:
        return Icons.today;
      case HealthTimeframe.quarterly:
        return Icons.calendar_view_month;
      case HealthTimeframe.yearly:
        return Icons.calendar_today;
    }
  }

  String _getTimeframeLabel(HealthTimeframe timeframe) {
    switch (timeframe) {
      case HealthTimeframe.current:
        return 'financialHealth.current'.tr();
      case HealthTimeframe.quarterly:
        return 'financialHealth.quarterly'.tr();
      case HealthTimeframe.yearly:
        return 'financialHealth.yearly'.tr();
    }
  }

  IconData _getComponentIcon(HealthCategory category) {
    switch (category) {
      case HealthCategory.savings:
        return Icons.savings;
      case HealthCategory.debt:
        return Icons.credit_card;
      case HealthCategory.emergency:
        return Icons.security;
      case HealthCategory.investment:
        return Icons.trending_up;
      case HealthCategory.budget:
        return Icons.account_balance_wallet;
    }
  }

  Color _getComponentColor(int score) {
    if (score >= 16) return AppColors.success;
    if (score >= 12) return AppColors.warning;
    return AppColors.error;
  }

  String _getComponentTitle(HealthCategory category) {
    switch (category) {
      case HealthCategory.savings:
        return 'financialHealth.savingsScore'.tr();
      case HealthCategory.debt:
        return 'financialHealth.debtScore'.tr();
      case HealthCategory.emergency:
        return 'financialHealth.emergencyScore'.tr();
      case HealthCategory.investment:
        return 'financialHealth.investmentScore'.tr();
      case HealthCategory.budget:
        return 'financialHealth.budgetScore'.tr();
    }
  }

  IconData _getActionIcon(QuickActionType type) {
    switch (type) {
      case QuickActionType.createBudget:
        return Icons.add_circle;
      case QuickActionType.setGoal:
        return Icons.flag;
      case QuickActionType.payDebt:
        return Icons.payment;
      case QuickActionType.buildEmergencyFund:
        return Icons.security;
      case QuickActionType.reviewExpenses:
        return Icons.analytics;
    }
  }

  Color _getPriorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.high:
        return AppColors.error;
      case RecommendationPriority.medium:
        return AppColors.warning;
      case RecommendationPriority.low:
        return AppColors.info;
    }
  }

  String _getPriorityLabel(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.high:
        return 'financialHealth.highPriority'.tr();
      case RecommendationPriority.medium:
        return 'financialHealth.mediumPriority'.tr();
      case RecommendationPriority.low:
        return 'financialHealth.lowPriority'.tr();
    }
  }

  IconData _getResourceIcon(ResourceType type) {
    switch (type) {
      case ResourceType.article:
        return Icons.article;
      case ResourceType.video:
        return Icons.play_circle;
      case ResourceType.calculator:
        return Icons.calculate;
      case ResourceType.guide:
        return Icons.menu_book;
    }
  }

  void _handleQuickAction(QuickAction action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('financialHealth.actionFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _openResource(EducationalResource resource) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('financialHealth.resourceFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'improve':
        _showImproveTips();
        break;
      case 'benchmark':
        _showBenchmarkInfo();
        break;
      case 'export':
        _exportHealthReport();
        break;
    }
  }

  void _showImproveTips() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('financialHealth.improveTipsFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showBenchmarkInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('financialHealth.benchmarkFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _exportHealthReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('financialHealth.exportFeatureComingSoon'.tr()),
        backgroundColor: AppColors.info,
      ),
    );
  }
}

// Data models
class FinancialHealthData {
  final int score;
  final String grade;
  final HealthTrend trend;
  final double savingsRate;
  final double debtToIncomeRatio;
  final double emergencyFundMonths;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double netWorth;
  final double totalDebt;
  final List<ScoreComponent> scoreComponents;
  final List<QuickAction> quickActions;

  const FinancialHealthData({
    required this.score,
    required this.grade,
    required this.trend,
    required this.savingsRate,
    required this.debtToIncomeRatio,
    required this.emergencyFundMonths,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.netWorth,
    required this.totalDebt,
    required this.scoreComponents,
    required this.quickActions,
  });
}

class ScoreComponent {
  final HealthCategory category;
  final int score;
  final int maxScore;
  final String description;

  const ScoreComponent({
    required this.category,
    required this.score,
    required this.maxScore,
    required this.description,
  });
}

class QuickAction {
  final QuickActionType type;
  final String title;
  final String description;

  const QuickAction({
    required this.type,
    required this.title,
    required this.description,
  });
}

class DetailedHealthScore {
  final List<ComponentBreakdown> components;
  final List<BenchmarkComparison> benchmarks;
  final List<ScoreHistoryPoint> history;

  const DetailedHealthScore({
    required this.components,
    required this.benchmarks,
    required this.history,
  });
}

class ComponentBreakdown {
  final HealthCategory category;
  final int score;
  final int maxScore;
  final double percentage;

  const ComponentBreakdown({
    required this.category,
    required this.score,
    required this.maxScore,
    required this.percentage,
  });
}

class BenchmarkComparison {
  final String category;
  final double userValue;
  final double averageValue;
  final double percentile;

  const BenchmarkComparison({
    required this.category,
    required this.userValue,
    required this.averageValue,
    required this.percentile,
  });
}

class ScoreHistoryPoint {
  final DateTime date;
  final int score;

  const ScoreHistoryPoint({
    required this.date,
    required this.score,
  });
}

class HealthRecommendations {
  final List<PriorityRecommendation> priorityRecommendations;
  final List<ActionPlanItem> actionPlan;
  final List<LongTermGoal> longTermGoals;
  final List<EducationalResource> educationalResources;

  const HealthRecommendations({
    required this.priorityRecommendations,
    required this.actionPlan,
    required this.longTermGoals,
    required this.educationalResources,
  });
}

class PriorityRecommendation {
  final String title;
  final String description;
  final RecommendationPriority priority;
  final int potentialImpact;
  final List<String> actionSteps;

  const PriorityRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.potentialImpact,
    required this.actionSteps,
  });
}

class ActionPlanItem {
  final String title;
  final String description;
  final DateTime deadline;
  final bool isCompleted;

  const ActionPlanItem({
    required this.title,
    required this.description,
    required this.deadline,
    required this.isCompleted,
  });
}

class LongTermGoal {
  final String title;
  final String description;
  final DateTime targetDate;
  final double progress;

  const LongTermGoal({
    required this.title,
    required this.description,
    required this.targetDate,
    required this.progress,
  });
}

class EducationalResource {
  final String title;
  final String description;
  final ResourceType type;
  final String url;

  const EducationalResource({
    required this.title,
    required this.description,
    required this.type,
    required this.url,
  });
}

enum HealthTimeframe { current, quarterly, yearly }

enum HealthTrend { improving, stable, declining }

enum HealthCategory { savings, debt, emergency, investment, budget }

enum QuickActionType {
  createBudget,
  setGoal,
  payDebt,
  buildEmergencyFund,
  reviewExpenses
}

enum RecommendationPriority { high, medium, low }

enum ResourceType { article, video, calculator, guide }

// Providers
final financialHealthProvider =
    FutureProvider.family<FinancialHealthData, HealthTimeframe>(
  (ref, timeframe) async {
    await Future.delayed(const Duration(seconds: 1));
    return const FinancialHealthData(
      score: 75,
      grade: 'B',
      trend: HealthTrend.improving,
      savingsRate: 15.5,
      debtToIncomeRatio: 25.0,
      emergencyFundMonths: 3.5,
      monthlyIncome: 5000.0,
      monthlyExpenses: 4200.0,
      netWorth: 45000.0,
      totalDebt: 15000.0,
      scoreComponents: [],
      quickActions: [],
    );
  },
);

final detailedHealthScoreProvider =
    FutureProvider.family<DetailedHealthScore, HealthTimeframe>(
  (ref, timeframe) async {
    await Future.delayed(const Duration(seconds: 1));
    return const DetailedHealthScore(
      components: [],
      benchmarks: [],
      history: [],
    );
  },
);

final healthRecommendationsProvider =
    FutureProvider.family<HealthRecommendations, HealthTimeframe>(
  (ref, timeframe) async {
    await Future.delayed(const Duration(seconds: 1));
    return const HealthRecommendations(
      priorityRecommendations: [],
      actionPlan: [],
      longTermGoals: [],
      educationalResources: [],
    );
  },
);
