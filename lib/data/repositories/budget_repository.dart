import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/budget.dart';
import '../services/hive_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/enums/budget_period.dart';

class BudgetRepository {
  static const _uuid = Uuid();
  late final HiveService _hiveService;

  BudgetRepository({HiveService? hiveService}) {
    _hiveService = hiveService ?? HiveService();
  }

  Future<Box<Budget>> get _budgetsBox async {
    return await _hiveService.getBox<Budget>(AppConstants.hiveBoxBudgets);
  }

  // Add budget
  Future<String> addBudget(Budget budget) async {
    try {
      final box = await _budgetsBox;
      final id = budget.id.isEmpty ? _uuid.v4() : budget.id;
      final now = DateTime.now();

      final newBudget = budget.copyWith(
        id: id,
        createdAt: budget.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
            ? now
            : budget.createdAt,
        updatedAt: now,
      );

      await box.put(id, newBudget);
      return id;
    } catch (e) {
      throw DatabaseException(message: 'Failed to add budget: $e');
    }
  }

  // Update budget
  Future<void> updateBudget(Budget budget) async {
    try {
      final box = await _budgetsBox;

      if (!box.containsKey(budget.id)) {
        throw BudgetNotFoundException(budgetId: budget.id);
      }

      final updatedBudget = budget.copyWith(updatedAt: DateTime.now());
      await box.put(budget.id, updatedBudget);
    } catch (e) {
      if (e is BudgetNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to update budget: $e');
    }
  }

  // Delete budget
  Future<void> deleteBudget(String id) async {
    try {
      final box = await _budgetsBox;

      if (!box.containsKey(id)) {
        throw BudgetNotFoundException(budgetId: id);
      }

      await box.delete(id);
    } catch (e) {
      if (e is BudgetNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to delete budget: $e');
    }
  }

  // Get budget by ID
  Future<Budget?> getBudgetById(String id) async {
    try {
      final box = await _budgetsBox;
      return box.get(id);
    } catch (e) {
      throw DatabaseException(message: 'Failed to get budget: $e');
    }
  }

  // Get all budgets
  Future<List<Budget>> getAllBudgets() async {
    try {
      final box = await _budgetsBox;
      final budgets = box.values.toList();

      // Sort by creation date (newest first)
      budgets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return budgets;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get budgets: $e');
    }
  }

  // Get active budgets
  Future<List<Budget>> getActiveBudgets() async {
    try {
      final allBudgets = await getAllBudgets();
      return allBudgets.where((budget) => budget.isActive).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get active budgets: $e');
    }
  }

  // Get budgets by category
  Future<List<Budget>> getBudgetsByCategory(String categoryId) async {
    try {
      final allBudgets = await getAllBudgets();
      return allBudgets
          .where((budget) => budget.categoryId == categoryId)
          .toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get budgets by category: $e');
    }
  }

  // Get budgets by period
  Future<List<Budget>> getBudgetsByPeriod(BudgetPeriod period) async {
    try {
      final allBudgets = await getAllBudgets();
      return allBudgets.where((budget) => budget.period == period).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get budgets by period: $e');
    }
  }

  // Get current active budgets (within date range)
  Future<List<Budget>> getCurrentActiveBudgets() async {
    try {
      final activeBudgets = await getActiveBudgets();
      final now = DateTime.now();

      return activeBudgets.where((budget) {
        final isAfterStart = now.isAfter(budget.startDate) ||
            now.isAtSameMomentAs(budget.startDate);
        final isBeforeEnd = budget.endDate == null ||
            now.isBefore(budget.endDate!) ||
            now.isAtSameMomentAs(budget.endDate!);

        return isAfterStart && isBeforeEnd;
      }).toList();
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to get current active budgets: $e');
    }
  }

  // Deactivate budget
  Future<void> deactivateBudget(String id) async {
    try {
      final budget = await getBudgetById(id);
      if (budget == null) {
        throw BudgetNotFoundException(budgetId: id);
      }

      final deactivatedBudget = budget.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await updateBudget(deactivatedBudget);
    } catch (e) {
      if (e is BudgetNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to deactivate budget: $e');
    }
  }

  // Activate budget
  Future<void> activateBudget(String id) async {
    try {
      final budget = await getBudgetById(id);
      if (budget == null) {
        throw BudgetNotFoundException(budgetId: id);
      }

      final activatedBudget = budget.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );

      await updateBudget(activatedBudget);
    } catch (e) {
      if (e is BudgetNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to activate budget: $e');
    }
  }

  // Clear all budgets
  Future<void> clearAllBudgets() async {
    try {
      final box = await _budgetsBox;
      await box.clear();
    } catch (e) {
      throw DatabaseException(message: 'Failed to clear budgets: $e');
    }
  }

  // Get budgets count
  Future<int> getBudgetsCount() async {
    try {
      final box = await _budgetsBox;
      return box.length;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get budgets count: $e');
    }
  }

  // Batch operations
  Future<void> addBudgetsBatch(List<Budget> budgets) async {
    try {
      final box = await _budgetsBox;
      final budgetsMap = <String, Budget>{};

      for (final budget in budgets) {
        final id = budget.id.isEmpty ? _uuid.v4() : budget.id;
        final now = DateTime.now();

        final newBudget = budget.copyWith(
          id: id,
          createdAt: budget.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
              ? now
              : budget.createdAt,
          updatedAt: now,
        );

        budgetsMap[id] = newBudget;
      }

      await box.putAll(budgetsMap);
    } catch (e) {
      throw DatabaseException(message: 'Failed to add budgets batch: $e');
    }
  }
}
