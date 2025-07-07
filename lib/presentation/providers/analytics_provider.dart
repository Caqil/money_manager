import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/models/transaction.dart';
import '../../data/models/budget.dart';
import '../../data/models/account.dart';
import '../../core/utils/date_utils.dart';
import '../screens/analytics/widgets/date_range_selector.dart';

// Repository providers
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(),
);

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(),
);

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepository(),
);

// Spending by category provider
final spendingByCategoryProvider =
    FutureProvider.family<Map<String, double>, DateRange?>(
  (ref, dateRange) async {
    final repository = ref.read(transactionRepositoryProvider);

    List<Transaction> transactions;
    if (dateRange != null) {
      transactions = await repository.getTransactionsByDateRange(
        dateRange.start,
        dateRange.end,
      );
    } else {
      transactions = await repository.getAllTransactions();
    }

    final expenses =
        transactions.where((t) => t.type == TransactionType.expense).toList();
    final categoryTotals = <String, double>{};

    for (final transaction in expenses) {
      categoryTotals[transaction.categoryId] =
          (categoryTotals[transaction.categoryId] ?? 0.0) + transaction.amount;
    }

    return categoryTotals;
  },
);

// Income vs expense over time provider
final incomeVsExpenseProvider =
    FutureProvider.family<List<FinancialDataPoint>, AnalyticsParams>(
  (ref, params) async {
    final repository = ref.read(transactionRepositoryProvider);
    final transactions = await repository.getTransactionsByDateRange(
      params.startDate,
      params.endDate,
    );

    final dataPoints = <FinancialDataPoint>[];
    final groupedData = _groupTransactionsByTime(transactions, params.grouping);

    for (final entry in groupedData.entries) {
      double income = 0.0;
      double expense = 0.0;

      for (final transaction in entry.value) {
        if (transaction.type == TransactionType.income) {
          income += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          expense += transaction.amount;
        }
      }

      dataPoints.add(FinancialDataPoint(
        date: entry.key,
        income: income,
        expense: expense,
        net: income - expense,
      ));
    }

    dataPoints.sort((a, b) => a.date.compareTo(b.date));
    return dataPoints;
  },
);

// Budget performance provider
final budgetPerformanceProvider = FutureProvider<List<BudgetPerformance>>(
  (ref) async {
    final budgetRepository = ref.read(budgetRepositoryProvider);
    final transactionRepository = ref.read(transactionRepositoryProvider);

    final budgets = await budgetRepository.getCurrentActiveBudgets();
    final performances = <BudgetPerformance>[];

    for (final budget in budgets) {
      // Calculate spent amount for this budget
      final spent =
          await _getSpentAmountForBudget(budget, transactionRepository);

      performances.add(BudgetPerformance(
        budget: budget,
        spentAmount: spent,
        remainingAmount: (budget.limit - spent).clamp(0.0, double.infinity),
        percentageUsed: budget.limit > 0 ? spent / budget.limit : 0.0,
        isOverBudget: spent > budget.limit,
      ));
    }

    return performances;
  },
);

// Goal analytics provider
final goalAnalyticsProvider = FutureProvider<GoalAnalytics>(
  (ref) async {
    final repository = ref.read(goalRepositoryProvider);
    final goals = await repository.getAllGoals();
    final activeGoals = goals.where((g) => g.isActive).toList();
    final completedGoals = goals.where((g) => g.isCompleted).toList();

    double totalTargetAmount = 0.0;
    double totalCurrentAmount = 0.0;
    double averageProgress = 0.0;

    for (final goal in activeGoals) {
      totalTargetAmount += goal.targetAmount;
      totalCurrentAmount += goal.currentAmount;
      averageProgress += goal.progressPercentage;
    }

    if (activeGoals.isNotEmpty) {
      averageProgress /= activeGoals.length;
    }

    return GoalAnalytics(
      totalGoals: goals.length,
      activeGoals: activeGoals.length,
      completedGoals: completedGoals.length,
      totalTargetAmount: totalTargetAmount,
      totalCurrentAmount: totalCurrentAmount,
      averageProgress: averageProgress,
      completionRate:
          goals.isNotEmpty ? completedGoals.length / goals.length : 0.0,
    );
  },
);

// Financial health score provider
final financialHealthScoreProvider = FutureProvider<FinancialHealthScore>(
  (ref) async {
    final transactionRepository = ref.read(transactionRepositoryProvider);
    final budgetRepository = ref.read(budgetRepositoryProvider);
    final goalRepository = ref.read(goalRepositoryProvider);
    final accountRepository = ref.read(accountRepositoryProvider);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    // Get this month's data
    final transactions = await transactionRepository.getTransactionsByDateRange(
        monthStart, monthEnd);
    final budgets = await budgetRepository.getCurrentActiveBudgets();
    final goals = await goalRepository.getActiveGoals();
    final accounts = await accountRepository.getActiveAccounts();

    // Calculate various metrics
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Savings rate (30 points max)
    final savingsRate = income > 0 ? (income - expenses) / income : 0.0;
    final savingsScore = (savingsRate * 30).clamp(0.0, 30.0);

    // Budget adherence (25 points max)
    double budgetScore = 0.0;
    if (budgets.isNotEmpty) {
      int budgetsOnTrack = 0;
      for (final budget in budgets) {
        final spent =
            await _getSpentAmountForBudget(budget, transactionRepository);
        if (spent <= budget.limit) budgetsOnTrack++;
      }
      budgetScore = (budgetsOnTrack / budgets.length * 25).clamp(0.0, 25.0);
    }

    // Goal progress (25 points max)
    double goalScore = 0.0;
    if (goals.isNotEmpty) {
      final averageProgress =
          goals.fold(0.0, (sum, g) => sum + g.progressPercentage) /
              goals.length;
      goalScore = (averageProgress * 25).clamp(0.0, 25.0);
    }

    // Account diversity (20 points max)
    final accountTypes = accounts.map((a) => a.type).toSet();
    final diversityScore =
        (accountTypes.length / AccountType.values.length * 20).clamp(0.0, 20.0);

    final totalScore = savingsScore + budgetScore + goalScore + diversityScore;

    return FinancialHealthScore(
      totalScore: totalScore,
      maxScore: 100.0,
      savingsScore: savingsScore,
      budgetScore: budgetScore,
      goalScore: goalScore,
      diversityScore: diversityScore,
      recommendations: _generateRecommendations(
          totalScore, savingsRate, budgets.length, goals.length),
    );
  },
);

// Net worth trend provider
final netWorthTrendProvider =
    FutureProvider.family<List<NetWorthDataPoint>, DateRange>(
  (ref, dateRange) async {
    final accountRepository = ref.read(accountRepositoryProvider);
    final transactionRepository = ref.read(transactionRepositoryProvider);

    final accounts = await accountRepository.getAllAccounts();
    final transactions = await transactionRepository.getTransactionsByDateRange(
      dateRange.start,
      dateRange.end,
    );

    final dataPoints = <NetWorthDataPoint>[];

    // Calculate net worth for each day
    var date = dateRange.start;
    while (
        date.isBefore(dateRange.end) || date.isAtSameMomentAs(dateRange.end)) {
      double netWorth = 0.0;

      // Calculate balance for each account up to this date
      for (final account in accounts) {
        if (!account.includeInTotal) continue;

        // Start with initial balance (assuming it's the current balance)
        double balance = account.balance;

        // Subtract transactions that happened after this date
        final futureTransactions = transactions
            .where((t) =>
                t.date.isAfter(date) &&
                (t.accountId == account.id ||
                    t.transferToAccountId == account.id))
            .toList();

        for (final transaction in futureTransactions) {
          if (transaction.accountId == account.id) {
            if (transaction.type == TransactionType.income) {
              balance -= transaction.amount;
            } else if (transaction.type == TransactionType.expense) {
              balance += transaction.amount;
            }
          }
          if (transaction.transferToAccountId == account.id) {
            balance -= transaction.amount;
          }
        }

        netWorth += balance;
      }

      dataPoints.add(NetWorthDataPoint(
        date: date,
        netWorth: netWorth,
      ));

      date = date.add(const Duration(days: 1));
    }

    return dataPoints;
  },
);

// Top spending categories provider
final topSpendingCategoriesProvider =
    FutureProvider.family<List<CategorySpending>, TopSpendingParams>(
  (ref, params) async {
    final categoryTotals = await ref.read(spendingByCategoryProvider(
      params.startDate != null && params.endDate != null
          ? DateRange(start: params.startDate!, end: params.endDate!)
          : null,
    ).future);

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories
        .take(params.limit)
        .map((entry) => CategorySpending(
              categoryId: entry.key,
              amount: entry.value,
            ))
        .toList();
  },
);

// Current month analytics provider
final currentMonthAnalyticsProvider = FutureProvider<MonthlyAnalytics>(
  (ref) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final dateRange = DateRange(start: startOfMonth, end: endOfMonth);

    final spendingByCategory =
        await ref.read(spendingByCategoryProvider(dateRange).future);

    final incomeVsExpense =
        await ref.read(incomeVsExpenseProvider(AnalyticsParams(
      startDate: startOfMonth,
      endDate: endOfMonth,
      grouping: TimeGrouping.daily,
    )).future);

    final topCategories =
        await ref.read(topSpendingCategoriesProvider(TopSpendingParams(
      startDate: startOfMonth,
      endDate: endOfMonth,
      limit: 5,
    )).future);

    return MonthlyAnalytics(
      spendingByCategory: spendingByCategory,
      incomeVsExpense: incomeVsExpense,
      topCategories: topCategories,
      period: dateRange,
    );
  },
);

// Analytics for dashboard widget
final dashboardAnalyticsProvider = FutureProvider<DashboardAnalytics>(
  (ref) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final dateRange = DateRange(start: startOfMonth, end: endOfMonth);

    // Get this month's data
    final spendingByCategory =
        await ref.read(spendingByCategoryProvider(dateRange).future);
    final budgetPerformance = await ref.read(budgetPerformanceProvider.future);
    final goalAnalytics = await ref.read(goalAnalyticsProvider.future);
    final financialHealth = await ref.read(financialHealthScoreProvider.future);

    // Calculate totals
    final totalSpent =
        spendingByCategory.values.fold(0.0, (sum, amount) => sum + amount);
    final totalBudget =
        budgetPerformance.fold(0.0, (sum, bp) => sum + bp.budget.limit);

    return DashboardAnalytics(
      totalSpentThisMonth: totalSpent,
      totalBudgetThisMonth: totalBudget,
      budgetUsagePercentage: totalBudget > 0 ? totalSpent / totalBudget : 0.0,
      activeGoalsCount: goalAnalytics.activeGoals,
      averageGoalProgress: goalAnalytics.averageProgress,
      financialHealthScore: financialHealth.totalScore,
      financialHealthGrade: financialHealth.grade,
      topSpendingCategory: spendingByCategory.isNotEmpty
          ? spendingByCategory.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
          : null,
    );
  },
);

// Helper functions
Map<DateTime, List<Transaction>> _groupTransactionsByTime(
  List<Transaction> transactions,
  TimeGrouping grouping,
) {
  final grouped = <DateTime, List<Transaction>>{};

  for (final transaction in transactions) {
    DateTime key;

    switch (grouping) {
      case TimeGrouping.daily:
        key = DateTime(transaction.date.year, transaction.date.month,
            transaction.date.day);
        break;
      case TimeGrouping.weekly:
        key = AppDateUtils.startOfWeek(transaction.date);
        break;
      case TimeGrouping.monthly:
        key = DateTime(transaction.date.year, transaction.date.month);
        break;
      case TimeGrouping.yearly:
        key = DateTime(transaction.date.year);
        break;
    }

    grouped.putIfAbsent(key, () => []).add(transaction);
  }

  return grouped;
}

Future<double> _getSpentAmountForBudget(
    Budget budget, TransactionRepository repository) async {
  // Get transactions for the budget period
  final now = DateTime.now();
  DateTime periodStart;
  DateTime periodEnd;

  switch (budget.period) {
    case BudgetPeriod.weekly:
      periodStart = AppDateUtils.startOfWeek(now);
      periodEnd = periodStart.add(const Duration(days: 6));
      break;
    case BudgetPeriod.monthly:
      periodStart = DateTime(now.year, now.month, 1);
      periodEnd = DateTime(now.year, now.month + 1, 0);
      break;
    case BudgetPeriod.quarterly:
      final quarter = ((now.month - 1) / 3).floor();
      periodStart = DateTime(now.year, quarter * 3 + 1, 1);
      periodEnd = DateTime(now.year, quarter * 3 + 4, 0);
      break;
    case BudgetPeriod.yearly:
      periodStart = DateTime(now.year, 1, 1);
      periodEnd = DateTime(now.year, 12, 31);
      break;
    case BudgetPeriod.custom:
      periodStart = budget.startDate;
      periodEnd = budget.endDate ?? now;
      break;
  }

  final transactions =
      await repository.getTransactionsByDateRange(periodStart, periodEnd);

  final filteredTransactions = transactions
      .where((t) =>
          t.type == TransactionType.expense &&
          t.categoryId == budget.categoryId)
      .toList();

  return filteredTransactions.fold<double>(0.0, (sum, t) => sum + t.amount);
}

List<String> _generateRecommendations(
  double totalScore,
  double savingsRate,
  int budgetCount,
  int goalCount,
) {
  final recommendations = <String>[];

  if (totalScore < 50) {
    recommendations.add(
        'Your financial health needs attention. Consider reviewing your spending habits.');
  }

  if (savingsRate < 0.1) {
    recommendations.add('Try to save at least 10% of your income each month.');
  }

  if (budgetCount == 0) {
    recommendations.add(
        'Create budgets for your main spending categories to better control expenses.');
  }

  if (goalCount == 0) {
    recommendations
        .add('Set financial goals to stay motivated and track your progress.');
  }

  if (totalScore >= 80) {
    recommendations
        .add('Great job! Your financial health is excellent. Keep it up!');
  }

  return recommendations;
}

class AnalyticsParams {
  final DateTime startDate;
  final DateTime endDate;
  final TimeGrouping grouping;

  const AnalyticsParams({
    required this.startDate,
    required this.endDate,
    required this.grouping,
  });
}

class TopSpendingParams {
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;

  const TopSpendingParams({
    this.startDate,
    this.endDate,
    this.limit = 5,
  });
}

class MonthlyAnalytics {
  final Map<String, double> spendingByCategory;
  final List<FinancialDataPoint> incomeVsExpense;
  final List<CategorySpending> topCategories;
  final DateRange period;

  const MonthlyAnalytics({
    required this.spendingByCategory,
    required this.incomeVsExpense,
    required this.topCategories,
    required this.period,
  });
}

class DashboardAnalytics {
  final double totalSpentThisMonth;
  final double totalBudgetThisMonth;
  final double budgetUsagePercentage;
  final int activeGoalsCount;
  final double averageGoalProgress;
  final double financialHealthScore;
  final String financialHealthGrade;
  final String? topSpendingCategory;

  const DashboardAnalytics({
    required this.totalSpentThisMonth,
    required this.totalBudgetThisMonth,
    required this.budgetUsagePercentage,
    required this.activeGoalsCount,
    required this.averageGoalProgress,
    required this.financialHealthScore,
    required this.financialHealthGrade,
    this.topSpendingCategory,
  });
}

class FinancialDataPoint {
  final DateTime date;
  final double income;
  final double expense;
  final double net;

  const FinancialDataPoint({
    required this.date,
    required this.income,
    required this.expense,
    required this.net,
  });
}

class BudgetPerformance {
  final Budget budget;
  final double spentAmount;
  final double remainingAmount;
  final double percentageUsed;
  final bool isOverBudget;

  const BudgetPerformance({
    required this.budget,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentageUsed,
    required this.isOverBudget,
  });
}

class GoalAnalytics {
  final int totalGoals;
  final int activeGoals;
  final int completedGoals;
  final double totalTargetAmount;
  final double totalCurrentAmount;
  final double averageProgress;
  final double completionRate;

  const GoalAnalytics({
    required this.totalGoals,
    required this.activeGoals,
    required this.completedGoals,
    required this.totalTargetAmount,
    required this.totalCurrentAmount,
    required this.averageProgress,
    required this.completionRate,
  });
}

class NetWorthDataPoint {
  final DateTime date;
  final double netWorth;

  const NetWorthDataPoint({
    required this.date,
    required this.netWorth,
  });
}

class FinancialHealthScore {
  final double totalScore;
  final double maxScore;
  final double savingsScore;
  final double budgetScore;
  final double goalScore;
  final double diversityScore;
  final List<String> recommendations;

  const FinancialHealthScore({
    required this.totalScore,
    required this.maxScore,
    required this.savingsScore,
    required this.budgetScore,
    required this.goalScore,
    required this.diversityScore,
    required this.recommendations,
  });

  double get percentage => totalScore / maxScore;

  String get grade {
    final percentage = this.percentage;
    if (percentage >= 0.9) return 'A';
    if (percentage >= 0.8) return 'B';
    if (percentage >= 0.7) return 'C';
    if (percentage >= 0.6) return 'D';
    return 'F';
  }
}

class CategorySpending {
  final String categoryId;
  final double amount;

  const CategorySpending({
    required this.categoryId,
    required this.amount,
  });
}

enum TimeGrouping { daily, weekly, monthly, yearly }
