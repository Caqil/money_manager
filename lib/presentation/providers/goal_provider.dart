import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/goal.dart';
import '../../data/repositories/goal_repository.dart';

// Repository provider
final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepository(),
);

// Goal list provider
final goalListProvider =
    StateNotifierProvider<GoalNotifier, AsyncValue<List<Goal>>>(
  (ref) => GoalNotifier(ref.read(goalRepositoryProvider)),
);

// Active goals provider
final activeGoalsProvider = Provider<AsyncValue<List<Goal>>>(
  (ref) {
    final goals = ref.watch(goalListProvider);
    return goals.when(
      data: (list) =>
          AsyncValue.data(list.where((goal) => goal.isActive).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Completed goals provider
final completedGoalsProvider = Provider<AsyncValue<List<Goal>>>(
  (ref) {
    final goals = ref.watch(goalListProvider);
    return goals.when(
      data: (list) =>
          AsyncValue.data(list.where((goal) => goal.isCompleted).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Goals by type provider
final goalsByTypeProvider = Provider.family<AsyncValue<List<Goal>>, GoalType>(
  (ref, type) {
    final goals = ref.watch(goalListProvider);
    return goals.when(
      data: (list) =>
          AsyncValue.data(list.where((goal) => goal.type == type).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Goals by priority provider
final goalsByPriorityProvider =
    Provider.family<AsyncValue<List<Goal>>, GoalPriority>(
  (ref, priority) {
    final goals = ref.watch(goalListProvider);
    return goals.when(
      data: (list) => AsyncValue.data(
          list.where((goal) => goal.priority == priority).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Goals near deadline provider
final goalsNearDeadlineProvider = FutureProvider.family<List<Goal>, int>(
  (ref, daysAhead) async {
    final repository = ref.read(goalRepositoryProvider);
    return await repository.getGoalsNearDeadline(daysAhead: daysAhead);
  },
);

// Single goal provider
final goalProvider = Provider.family<AsyncValue<Goal?>, String>(
  (ref, goalId) {
    final goals = ref.watch(goalListProvider);
    return goals.when(
      data: (list) {
        try {
          final goal = list.firstWhere((goal) => goal.id == goalId);
          return AsyncValue.data(goal);
        } catch (e) {
          return const AsyncValue.data(null);
        }
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Total goal progress provider
final totalGoalProgressProvider = Provider<AsyncValue<GoalProgress>>(
  (ref) {
    final goals = ref.watch(activeGoalsProvider);
    return goals.when(
      data: (list) {
        if (list.isEmpty) {
          return const AsyncValue.data(GoalProgress(
            totalTargetAmount: 0.0,
            totalCurrentAmount: 0.0,
            averageProgress: 0.0,
            completedGoalsCount: 0,
            totalGoalsCount: 0,
          ));
        }

        final totalTarget =
            list.fold(0.0, (sum, goal) => sum + goal.targetAmount);
        final totalCurrent =
            list.fold(0.0, (sum, goal) => sum + goal.currentAmount);
        final averageProgress =
            list.fold(0.0, (sum, goal) => sum + goal.progressPercentage) /
                list.length;
        final completedCount = list.where((goal) => goal.isCompleted).length;

        return AsyncValue.data(GoalProgress(
          totalTargetAmount: totalTarget,
          totalCurrentAmount: totalCurrent,
          averageProgress: averageProgress,
          completedGoalsCount: completedCount,
          totalGoalsCount: list.length,
        ));
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Goal operations state
class GoalNotifier extends StateNotifier<AsyncValue<List<Goal>>> {
  final GoalRepository _repository;

  GoalNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  // Load all goals
  Future<void> loadGoals() async {
    try {
      state = const AsyncValue.loading();
      final goals = await _repository.getAllGoals();
      state = AsyncValue.data(goals);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Add goal
  Future<String?> addGoal(Goal goal) async {
    try {
      final id = await _repository.addGoal(goal);
      await loadGoals(); // Refresh list
      return id;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  // Update goal
  Future<bool> updateGoal(Goal goal) async {
    try {
      await _repository.updateGoal(goal);
      await loadGoals(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Delete goal
  Future<bool> deleteGoal(String id) async {
    try {
      await _repository.deleteGoal(id);
      await loadGoals(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Update goal progress
  Future<bool> updateGoalProgress(String goalId, double newAmount) async {
    try {
      await _repository.updateGoalProgress(goalId, newAmount);
      await loadGoals(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Add to goal progress
  Future<bool> addToGoalProgress(String goalId, double amount) async {
    try {
      await _repository.addToGoalProgress(goalId, amount);
      await loadGoals(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Complete goal
  Future<bool> completeGoal(String goalId) async {
    try {
      await _repository.completeGoal(goalId);
      await loadGoals(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Toggle goal status
  Future<bool> toggleGoalStatus(String id, bool isActive) async {
    try {
      if (isActive) {
        await _repository.activateGoal(id);
      } else {
        await _repository.deactivateGoal(id);
      }
      await loadGoals(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Refresh goals
  Future<void> refresh() async {
    await loadGoals();
  }
}

// Goal progress data class
class GoalProgress {
  final double totalTargetAmount;
  final double totalCurrentAmount;
  final double averageProgress;
  final int completedGoalsCount;
  final int totalGoalsCount;

  const GoalProgress({
    required this.totalTargetAmount,
    required this.totalCurrentAmount,
    required this.averageProgress,
    required this.completedGoalsCount,
    required this.totalGoalsCount,
  });

  double get overallProgress =>
      totalTargetAmount > 0 ? totalCurrentAmount / totalTargetAmount : 0.0;

  double get completionRate =>
      totalGoalsCount > 0 ? completedGoalsCount / totalGoalsCount : 0.0;
}
