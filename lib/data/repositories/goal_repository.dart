import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/goal.dart';
import '../services/hive_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

class GoalRepository {
  static const _uuid = Uuid();
  late final HiveService _hiveService;

  GoalRepository({HiveService? hiveService}) {
    _hiveService = hiveService ?? HiveService();
  }

  Future<Box<Goal>> get _goalsBox async {
    return await _hiveService.getBox<Goal>(AppConstants.hiveBoxGoals);
  }

  // Add goal
  Future<String> addGoal(Goal goal) async {
    try {
      final box = await _goalsBox;
      final id = goal.id.isEmpty ? _uuid.v4() : goal.id;
      final now = DateTime.now();

      final newGoal = goal.copyWith(
        id: id,
        createdAt: goal.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
            ? now
            : goal.createdAt,
        updatedAt: now,
      );

      await box.put(id, newGoal);
      return id;
    } catch (e) {
      throw DatabaseException(message: 'Failed to add goal: $e');
    }
  }

  // Update goal
  Future<void> updateGoal(Goal goal) async {
    try {
      final box = await _goalsBox;

      if (!box.containsKey(goal.id)) {
        throw DatabaseException(message: 'Goal not found');
      }

      final updatedGoal = goal.copyWith(updatedAt: DateTime.now());
      await box.put(goal.id, updatedGoal);
    } catch (e) {
      throw DatabaseException(message: 'Failed to update goal: $e');
    }
  }

  // Delete goal
  Future<void> deleteGoal(String id) async {
    try {
      final box = await _goalsBox;

      if (!box.containsKey(id)) {
        throw DatabaseException(message: 'Goal not found');
      }

      await box.delete(id);
    } catch (e) {
      throw DatabaseException(message: 'Failed to delete goal: $e');
    }
  }

  // Get goal by ID
  Future<Goal?> getGoalById(String id) async {
    try {
      final box = await _goalsBox;
      return box.get(id);
    } catch (e) {
      throw DatabaseException(message: 'Failed to get goal: $e');
    }
  }

  // Get all goals
  Future<List<Goal>> getAllGoals() async {
    try {
      final box = await _goalsBox;
      final goals = box.values.toList();

      // Sort by priority and creation date
      goals.sort((a, b) {
        final priorityComparison = b.priority.index.compareTo(a.priority.index);
        if (priorityComparison != 0) return priorityComparison;
        return b.createdAt.compareTo(a.createdAt);
      });

      return goals;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get goals: $e');
    }
  }

  // Get active goals
  Future<List<Goal>> getActiveGoals() async {
    try {
      final allGoals = await getAllGoals();
      return allGoals.where((goal) => goal.isActive).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get active goals: $e');
    }
  }

  // Get goals by type
  Future<List<Goal>> getGoalsByType(GoalType type) async {
    try {
      final allGoals = await getAllGoals();
      return allGoals.where((goal) => goal.type == type).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get goals by type: $e');
    }
  }

  // Get goals by priority
  Future<List<Goal>> getGoalsByPriority(GoalPriority priority) async {
    try {
      final allGoals = await getAllGoals();
      return allGoals.where((goal) => goal.priority == priority).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get goals by priority: $e');
    }
  }

  // Get completed goals
  Future<List<Goal>> getCompletedGoals() async {
    try {
      final allGoals = await getAllGoals();
      return allGoals.where((goal) => goal.isCompleted).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get completed goals: $e');
    }
  }

  // Get goals near deadline
  Future<List<Goal>> getGoalsNearDeadline({int daysAhead = 30}) async {
    try {
      final allGoals = await getAllGoals();
      final deadline = DateTime.now().add(Duration(days: daysAhead));

      return allGoals.where((goal) {
        return goal.isActive &&
            !goal.isCompleted &&
            goal.targetDate != null &&
            goal.targetDate!.isBefore(deadline);
      }).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get goals near deadline: $e');
    }
  }

  // Update goal progress
  Future<void> updateGoalProgress(String goalId, double newAmount) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) {
        throw DatabaseException(message: 'Goal not found');
      }

      final updatedGoal = goal.copyWith(
        currentAmount: newAmount,
        updatedAt: DateTime.now(),
      );

      await updateGoal(updatedGoal);
    } catch (e) {
      throw DatabaseException(message: 'Failed to update goal progress: $e');
    }
  }

  // Add to goal progress
  Future<void> addToGoalProgress(String goalId, double amount) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) {
        throw DatabaseException(message: 'Goal not found');
      }

      final newAmount =
          (goal.currentAmount + amount).clamp(0.0, goal.targetAmount);
      await updateGoalProgress(goalId, newAmount);
    } catch (e) {
      throw DatabaseException(message: 'Failed to add to goal progress: $e');
    }
  }

  // Complete goal
  Future<void> completeGoal(String goalId) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) {
        throw DatabaseException(message: 'Goal not found');
      }

      final completedGoal = goal.copyWith(
        currentAmount: goal.targetAmount,
        updatedAt: DateTime.now(),
      );

      await updateGoal(completedGoal);
    } catch (e) {
      throw DatabaseException(message: 'Failed to complete goal: $e');
    }
  }

  // Deactivate goal
  Future<void> deactivateGoal(String id) async {
    try {
      final goal = await getGoalById(id);
      if (goal == null) {
        throw DatabaseException(message: 'Goal not found');
      }

      final deactivatedGoal = goal.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await updateGoal(deactivatedGoal);
    } catch (e) {
      throw DatabaseException(message: 'Failed to deactivate goal: $e');
    }
  }

  // Activate goal
  Future<void> activateGoal(String id) async {
    try {
      final goal = await getGoalById(id);
      if (goal == null) {
        throw DatabaseException(message: 'Goal not found');
      }

      final activatedGoal = goal.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );

      await updateGoal(activatedGoal);
    } catch (e) {
      throw DatabaseException(message: 'Failed to activate goal: $e');
    }
  }

  // Clear all goals
  Future<void> clearAllGoals() async {
    try {
      final box = await _goalsBox;
      await box.clear();
    } catch (e) {
      throw DatabaseException(message: 'Failed to clear goals: $e');
    }
  }

  // Get goals count
  Future<int> getGoalsCount() async {
    try {
      final box = await _goalsBox;
      return box.length;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get goals count: $e');
    }
  }

  // Get total target amount
  Future<double> getTotalTargetAmount() async {
    try {
      final allGoals = await getAllGoals();
      return allGoals.fold<double>(0.0, (sum, goal) => sum + goal.targetAmount);
    } catch (e) {
      throw DatabaseException(message: 'Failed to get total target amount: $e');
    }
  }

  // Get total current amount
  Future<double> getTotalCurrentAmount() async {
    try {
      final allGoals = await getAllGoals();
      return allGoals.fold<double>(0.0, (sum, goal) => sum + goal.currentAmount);
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to get total current amount: $e');
    }
  }

  // Batch operations
  Future<void> addGoalsBatch(List<Goal> goals) async {
    try {
      final box = await _goalsBox;
      final goalsMap = <String, Goal>{};

      for (final goal in goals) {
        final id = goal.id.isEmpty ? _uuid.v4() : goal.id;
        final now = DateTime.now();

        final newGoal = goal.copyWith(
          id: id,
          createdAt: goal.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
              ? now
              : goal.createdAt,
          updatedAt: now,
        );

        goalsMap[id] = newGoal;
      }

      await box.putAll(goalsMap);
    } catch (e) {
      throw DatabaseException(message: 'Failed to add goals batch: $e');
    }
  }
}
