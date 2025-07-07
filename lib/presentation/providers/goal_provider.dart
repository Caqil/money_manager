import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/goal.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/services/notification_service.dart';
import 'notification_provider.dart';

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

  void _safeSetState(AsyncValue<List<Goal>> newState) {
    if (mounted) {
      state = newState;
    }
  }

  Future<void> loadGoals() async {
    try {
      _safeSetState(const AsyncValue.loading());
      final goals = await _repository.getAllGoals();
      _safeSetState(AsyncValue.data(goals));
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
    }
  }

  Future<String?> addGoal(Goal goal) async {
    if (!mounted) return null;

    try {
      final id = await _repository.addGoal(goal);
      if (mounted) {
        await loadGoals();
      }
      return id;
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
      return null;
    }
  }

  Future<bool> updateGoal(Goal goal) async {
    if (!mounted) return false;

    try {
      await _repository.updateGoal(goal);
      if (mounted) {
        await loadGoals();
      }
      return true;
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
      return false;
    }
  }

  Future<bool> deleteGoal(String id) async {
    if (!mounted) return false;

    try {
      await _repository.deleteGoal(id);
      if (mounted) {
        await loadGoals();
      }
      return true;
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
      return false;
    }
  }

  Future<bool> updateGoalProgress(String goalId, double newAmount) async {
    if (!mounted) return false;

    try {
      await _repository.updateGoalProgress(goalId, newAmount);
      if (mounted) {
        await loadGoals();
      }
      return true;
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
      return false;
    }
  }
}

// 3. NotificationNotifier Fix (if it extends StateNotifier)
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;

  NotificationNotifier(this._service) : super(const NotificationState()) {
    _checkNotificationStatus();
  }

  void _safeSetState(NotificationState newState) {
    if (mounted) {
      state = newState;
    }
  }

  Future<void> _checkNotificationStatus() async {
    try {
      _safeSetState(state.copyWith(isLoading: true, error: null));

      final areEnabled = await _service.areNotificationsEnabled();
      final pendingNotifications = await _service.getPendingNotifications();

      _safeSetState(state.copyWith(
        isInitialized: true,
        areEnabled: areEnabled,
        pendingNotifications: pendingNotifications,
        isLoading: false,
      ));
    } catch (e) {
      _safeSetState(state.copyWith(
        isInitialized: true,
        isLoading: false,
        error: 'Failed to check notification status: $e',
      ));
    }
  }

  Future<bool> showBudgetAlert({
    required String budgetName,
    required double spent,
    required double limit,
    required double percentage,
    String? budgetId,
  }) async {
    if (!mounted) return false;

    try {
      _safeSetState(state.copyWith(isLoading: true, error: null));

      await _service.showBudgetAlert(
        budgetName: budgetName,
        spent: spent,
        limit: limit,
        percentage: percentage,
        budgetId: budgetId,
      );

      if (mounted) {
        await _updatePendingNotifications();
        _safeSetState(state.copyWith(isLoading: false));
      }
      return true;
    } catch (e) {
      _safeSetState(state.copyWith(
        isLoading: false,
        error: 'Failed to show budget alert: $e',
      ));
      return false;
    }
  }

  Future<void> _updatePendingNotifications() async {
    if (!mounted) return;

    try {
      final pendingNotifications = await _service.getPendingNotifications();
      _safeSetState(state.copyWith(pendingNotifications: pendingNotifications));
    } catch (e) {
      // Log error but don't update state with error for this background operation
      print('Failed to update pending notifications: $e');
    }
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
