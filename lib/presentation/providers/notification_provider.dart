import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/services/notification_service.dart';

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

// Notification state provider
final notificationStateProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(ref.read(notificationServiceProvider)),
);

// Pending notifications provider
final pendingNotificationsProvider =
    FutureProvider<List<PendingNotificationRequest>>(
  (ref) async {
    final service = ref.read(notificationServiceProvider);
    return await service.getPendingNotifications();
  },
);

// Notifications enabled provider
final notificationsEnabledProvider = FutureProvider<bool>(
  (ref) async {
    final service = ref.read(notificationServiceProvider);
    return await service.areNotificationsEnabled();
  },
);

// Notification permission status provider
final notificationPermissionProvider =
    FutureProvider<NotificationPermissionStatus>(
  (ref) async {
    final service = ref.read(notificationServiceProvider);
    final isEnabled = await service.areNotificationsEnabled();
    return NotificationPermissionStatus(
      isGranted: isEnabled,
      shouldRequestPermission: !isEnabled,
    );
  },
);

// Notification state
class NotificationState {
  final bool isInitialized;
  final bool areEnabled;
  final String? error;
  final List<PendingNotificationRequest> pendingNotifications;
  final bool isLoading;

  const NotificationState({
    this.isInitialized = false,
    this.areEnabled = false,
    this.error,
    this.pendingNotifications = const [],
    this.isLoading = false,
  });

  NotificationState copyWith({
    bool? isInitialized,
    bool? areEnabled,
    String? error,
    List<PendingNotificationRequest>? pendingNotifications,
    bool? isLoading,
  }) {
    return NotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      areEnabled: areEnabled ?? this.areEnabled,
      error: error,
      pendingNotifications: pendingNotifications ?? this.pendingNotifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get pendingCount => pendingNotifications.length;

  bool get hasError => error != null;

  List<PendingNotificationRequest> get upcomingNotifications {
    // Sort by id (assuming higher ids are more recent)
    final sorted = List<PendingNotificationRequest>.from(pendingNotifications);
    sorted.sort((a, b) => a.id.compareTo(b.id));
    return sorted;
  }
}

// Notification notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;

  NotificationNotifier(this._service) : super(const NotificationState()) {
    _checkNotificationStatus();
  }

  // Check notification status
  Future<void> _checkNotificationStatus() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final areEnabled = await _service.areNotificationsEnabled();
      final pendingNotifications = await _service.getPendingNotifications();

      state = state.copyWith(
        isInitialized: true,
        areEnabled: areEnabled,
        pendingNotifications: pendingNotifications,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        error: 'Failed to check notification status: $e',
      );
    }
  }

  // Show budget alert
  Future<bool> showBudgetAlert({
    required String budgetName,
    required double spent,
    required double limit,
    required double percentage,
    String? budgetId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _service.showBudgetAlert(
        budgetName: budgetName,
        spent: spent,
        limit: limit,
        percentage: percentage,
        budgetId: budgetId,
      );

      await _updatePendingNotifications();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to show budget alert: $e',
      );
      return false;
    }
  }

  // Show recurring transaction reminder
  Future<bool> showRecurringTransactionReminder({
    required String transactionName,
    required double amount,
    required DateTime dueDate,
    String? transactionId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _service.showRecurringTransactionReminder(
        transactionName: transactionName,
        amount: amount,
        dueDate: dueDate,
        transactionId: transactionId,
      );

      await _updatePendingNotifications();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to show recurring transaction reminder: $e',
      );
      return false;
    }
  }

  // Show goal milestone
  Future<bool> showGoalMilestone({
    required String goalName,
    required double currentAmount,
    required double targetAmount,
    String? goalId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _service.showGoalMilestone(
        goalName: goalName,
        currentAmount: currentAmount,
        targetAmount: targetAmount,
        goalId: goalId,
      );

      await _updatePendingNotifications();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to show goal milestone: $e',
      );
      return false;
    }
  }

  // Show backup reminder
  Future<bool> showBackupReminder() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _service.showBackupReminder();

      await _updatePendingNotifications();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to show backup reminder: $e',
      );
      return false;
    }
  }

  // Schedule notification
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String channelId = 'default',
    String channelName = 'Default',
    String channelDescription = 'Default notifications',
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _service.scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
      );

      await _updatePendingNotifications();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to schedule notification: $e',
      );
      return false;
    }
  }

  // Cancel notification
  Future<bool> cancelNotification(int id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _service.cancelNotification(id);

      await _updatePendingNotifications();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel notification: $e',
      );
      return false;
    }
  }

  // Cancel all notifications
  Future<bool> cancelAllNotifications() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _service.cancelAllNotifications();

      await _updatePendingNotifications();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel all notifications: $e',
      );
      return false;
    }
  }

  // Test notification
  Future<bool> testNotification() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _service.scheduleNotification(
        id: 999999,
        title: 'Test Notification',
        body: 'This is a test notification from Money Manager',
        scheduledDate: DateTime.now().add(const Duration(seconds: 2)),
        channelId: 'test',
        channelName: 'Test Notifications',
        channelDescription: 'Test notifications for debugging',
      );

      await _updatePendingNotifications();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send test notification: $e',
      );
      return false;
    }
  }

  // Update pending notifications list
  Future<void> _updatePendingNotifications() async {
    try {
      final pendingNotifications = await _service.getPendingNotifications();
      state = state.copyWith(pendingNotifications: pendingNotifications);
    } catch (e) {
      // Don't update error state for this internal operation
      // Just log the error if needed
    }
  }

  // Refresh notification status
  Future<void> refresh() async {
    await _checkNotificationStatus();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Get notification statistics
  NotificationStatistics getStatistics() {
    final pending = state.pendingNotifications;
    final budgetAlerts = pending
        .where((n) => n.payload?.contains('budget_alert') == true)
        .length;
    final recurringReminders = pending
        .where((n) => n.payload?.contains('recurring_transaction') == true)
        .length;
    final goalMilestones = pending
        .where((n) => n.payload?.contains('goal_milestone') == true)
        .length;
    final backupReminders = pending
        .where((n) => n.payload?.contains('backup_reminder') == true)
        .length;

    return NotificationStatistics(
      totalPending: pending.length,
      budgetAlerts: budgetAlerts,
      recurringReminders: recurringReminders,
      goalMilestones: goalMilestones,
      backupReminders: backupReminders,
      otherNotifications: pending.length -
          budgetAlerts -
          recurringReminders -
          goalMilestones -
          backupReminders,
    );
  }
}

// Helper classes
class NotificationPermissionStatus {
  final bool isGranted;
  final bool shouldRequestPermission;

  const NotificationPermissionStatus({
    required this.isGranted,
    required this.shouldRequestPermission,
  });
}

class NotificationStatistics {
  final int totalPending;
  final int budgetAlerts;
  final int recurringReminders;
  final int goalMilestones;
  final int backupReminders;
  final int otherNotifications;

  const NotificationStatistics({
    required this.totalPending,
    required this.budgetAlerts,
    required this.recurringReminders,
    required this.goalMilestones,
    required this.backupReminders,
    required this.otherNotifications,
  });

  bool get hasAnyPending => totalPending > 0;

  String get summary {
    if (totalPending == 0) return 'No pending notifications';
    if (totalPending == 1) return '1 pending notification';
    return '$totalPending pending notifications';
  }
}
