import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/budget.dart';
import '../../data/repositories/budget_repository.dart';

// Repository provider
final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(),
);

// Budget list provider
final budgetListProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<List<Budget>>>(
  (ref) => BudgetNotifier(ref.read(budgetRepositoryProvider)),
);

// Active budgets provider
final activeBudgetsProvider = Provider<AsyncValue<List<Budget>>>(
  (ref) {
    final budgets = ref.watch(budgetListProvider);
    return budgets.when(
      data: (list) =>
          AsyncValue.data(list.where((budget) => budget.isActive).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Current active budgets provider
final currentActiveBudgetsProvider = FutureProvider<List<Budget>>(
  (ref) async {
    final repository = ref.read(budgetRepositoryProvider);
    return await repository.getCurrentActiveBudgets();
  },
);

// Budgets by category provider
final budgetsByCategoryProvider =
    Provider.family<AsyncValue<List<Budget>>, String>(
  (ref, categoryId) {
    final budgets = ref.watch(budgetListProvider);
    return budgets.when(
      data: (list) => AsyncValue.data(
          list.where((budget) => budget.categoryId == categoryId).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Budgets by period provider
final budgetsByPeriodProvider =
    Provider.family<AsyncValue<List<Budget>>, BudgetPeriod>(
  (ref, period) {
    final budgets = ref.watch(budgetListProvider);
    return budgets.when(
      data: (list) => AsyncValue.data(
          list.where((budget) => budget.period == period).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Single budget provider
final budgetProvider = Provider.family<AsyncValue<Budget?>, String>(
  (ref, budgetId) {
    final budgets = ref.watch(budgetListProvider);
    return budgets.when(
      data: (list) {
        try {
          final budget = list.firstWhere((budget) => budget.id == budgetId);
          return AsyncValue.data(budget);
        } catch (e) {
          return const AsyncValue.data(null);
        }
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Budget progress provider (requires transaction data)
final budgetProgressProvider = FutureProvider.family<BudgetProgress, String>(
  (ref, budgetId) async {
    // This would need to integrate with transaction provider
    // For now, return a placeholder
    return const BudgetProgress(
      budgetId: '',
      spentAmount: 0.0,
      remainingAmount: 0.0,
      progressPercentage: 0.0,
      isOverBudget: false,
    );
  },
);

// Budget operations state
class BudgetNotifier extends StateNotifier<AsyncValue<List<Budget>>> {
  final BudgetRepository _repository;

  BudgetNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBudgets();
  }

  void _safeSetState(AsyncValue<List<Budget>> newState) {
    if (mounted) {
      state = newState;
    }
  } // Toggle budget status

  Future<bool> toggleBudgetStatus(String id, bool isActive) async {
    try {
      if (isActive) {
        await _repository.activateBudget(id);
      } else {
        await _repository.deactivateBudget(id);
      }
      await loadBudgets(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<void> loadBudgets() async {
    try {
      _safeSetState(const AsyncValue.loading());
      final budgets = await _repository.getAllBudgets();
      _safeSetState(AsyncValue.data(budgets));
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
    }
  }

  Future<String?> addBudget(Budget budget) async {
    if (!mounted) return null;

    try {
      final id = await _repository.addBudget(budget);
      if (mounted) {
        await loadBudgets();
      }
      return id;
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
      return null;
    }
  }

  Future<bool> updateBudget(Budget budget) async {
    if (!mounted) return false;

    try {
      await _repository.updateBudget(budget);
      if (mounted) {
        await loadBudgets();
      }
      return true;
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    if (!mounted) return false;

    try {
      await _repository.deleteBudget(id);
      if (mounted) {
        await loadBudgets();
      }
      return true;
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
      return false;
    }
  }
}

// Budget progress data class
class BudgetProgress {
  final String budgetId;
  final double spentAmount;
  final double remainingAmount;
  final double progressPercentage;
  final bool isOverBudget;

  const BudgetProgress({
    required this.budgetId,
    required this.spentAmount,
    required this.remainingAmount,
    required this.progressPercentage,
    required this.isOverBudget,
  });
}
