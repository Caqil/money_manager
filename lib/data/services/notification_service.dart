import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/currency_formatter.dart';

class NotificationService {
  static NotificationService? _instance;
  late final FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  NotificationService._internal();

  factory NotificationService() {
    _instance ??= NotificationService._internal();
    return _instance!;
  }

  // Initialize notification service
  static Future<NotificationService> init() async {
    final instance = NotificationService();
    await instance._initialize();
    return instance;
  }

  Future<void> _initialize() async {
    try {
      _notifications = FlutterLocalNotificationsPlugin();

      // Android initialization
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize notification service: $e');
    }
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'budget_alerts',
        'Budget Alerts',
        description: 'Notifications about budget limits and spending',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
      AndroidNotificationChannel(
        'recurring_transactions',
        'Recurring Transactions',
        description: 'Reminders for upcoming recurring transactions',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'goal_milestones',
        'Goal Milestones',
        description: 'Notifications about goal achievements and progress',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'backup_reminders',
        'Backup Reminders',
        description: 'Reminders to backup your financial data',
        importance: Importance.low,
      ),
      AndroidNotificationChannel(
        'default',
        'General',
        description: 'General notifications',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      if (!_isInitialized) await _initialize();

      // Check system permission
      final status = await Permission.notification.status;
      if (status != PermissionStatus.granted) {
        return false;
      }

      // Check plugin permission
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();

      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Request notification permission
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      if (!_isInitialized) await _initialize();
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      return [];
    }
  }

  // Show budget alert notification
  Future<void> showBudgetAlert({
    required String budgetName,
    required double spent,
    required double limit,
    required double percentage,
    String? budgetId,
  }) async {
    try {
      if (!await areNotificationsEnabled()) return;

      final spentFormatted = CurrencyFormatter.format(spent);
      final limitFormatted = CurrencyFormatter.format(limit);
      final percentageFormatted = (percentage * 100).toStringAsFixed(0);

      final title = 'Budget Alert: $budgetName';
      final body =
          'You\'ve spent $spentFormatted of $limitFormatted ($percentageFormatted%)';

      await _notifications.show(
        AppConstants.budgetAlertNotificationId + (budgetId?.hashCode ?? 0),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'budget_alerts',
            'Budget Alerts',
            channelDescription:
                'Notifications about budget limits and spending',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'budget_alert:$budgetId',
      );
    } catch (e) {
      throw Exception('Failed to show budget alert: $e');
    }
  }

  // Show recurring transaction reminder
  Future<void> showRecurringTransactionReminder({
    required String transactionName,
    required double amount,
    required DateTime dueDate,
    String? transactionId,
  }) async {
    try {
      if (!await areNotificationsEnabled()) return;

      final amountFormatted = CurrencyFormatter.format(amount);
      final title = 'Recurring Transaction Due';
      final body = '$transactionName ($amountFormatted) is due today';

      await _notifications.show(
        AppConstants.recurringTransactionNotificationId +
            (transactionId?.hashCode ?? 0),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'recurring_transactions',
            'Recurring Transactions',
            channelDescription: 'Reminders for upcoming recurring transactions',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'recurring_transaction:$transactionId',
      );
    } catch (e) {
      throw Exception('Failed to show recurring transaction reminder: $e');
    }
  }

  // Show goal milestone notification
  Future<void> showGoalMilestone({
    required String goalName,
    required double currentAmount,
    required double targetAmount,
    String? goalId,
  }) async {
    try {
      if (!await areNotificationsEnabled()) return;

      final currentFormatted = CurrencyFormatter.format(currentAmount);
      final targetFormatted = CurrencyFormatter.format(targetAmount);
      final percentage =
          ((currentAmount / targetAmount) * 100).toStringAsFixed(0);

      final title = 'Goal Progress: $goalName';
      final body =
          'You\'ve reached $currentFormatted of $targetFormatted ($percentage%)';

      await _notifications.show(
        AppConstants.goalMilestoneNotificationId + (goalId?.hashCode ?? 0),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'goal_milestones',
            'Goal Milestones',
            channelDescription:
                'Notifications about goal achievements and progress',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'goal_milestone:$goalId',
      );
    } catch (e) {
      throw Exception('Failed to show goal milestone: $e');
    }
  }

  // Show backup reminder
  Future<void> showBackupReminder() async {
    try {
      if (!await areNotificationsEnabled()) return;

      const title = 'Backup Reminder';
      const body = 'It\'s time to backup your financial data to keep it safe';

      await _notifications.show(
        AppConstants.backupReminderNotificationId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'backup_reminders',
            'Backup Reminders',
            channelDescription: 'Reminders to backup your financial data',
            importance: Importance.low,
            priority: Priority.low,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        ),
        payload: 'backup_reminder',
      );
    } catch (e) {
      throw Exception('Failed to show backup reminder: $e');
    }
  }

  // Schedule a notification
  Future<void> scheduleNotification({
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
      if (!await areNotificationsEnabled()) return;

      // For now, use simple scheduled notifications
      // In a production app, you'd want to add timezone package for proper timezone handling
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        // Convert scheduledDate to TZDateTime for proper scheduling
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      throw Exception('Failed to schedule notification: $e');
    }
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      throw Exception('Failed to cancel notification: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      throw Exception('Failed to cancel all notifications: $e');
    }
  }

  // Schedule budget check notifications
  Future<void> scheduleBudgetChecks(List<String> budgetIds) async {
    try {
      for (final budgetId in budgetIds) {
        // Schedule daily check at 6 PM
        final now = DateTime.now();
        final scheduledTime = DateTime(now.year, now.month, now.day, 18, 0);
        final nextCheck = scheduledTime.isBefore(now)
            ? scheduledTime.add(const Duration(days: 1))
            : scheduledTime;

        await scheduleNotification(
          id: 5000 + budgetId.hashCode,
          title: 'Budget Check',
          body: 'Time to review your spending today',
          scheduledDate: nextCheck,
          payload: 'budget_check:$budgetId',
          channelId: 'budget_alerts',
          channelName: 'Budget Alerts',
          channelDescription: 'Daily budget monitoring',
        );
      }
    } catch (e) {
      throw Exception('Failed to schedule budget checks: $e');
    }
  }

  // Schedule recurring transaction reminders
  Future<void> scheduleRecurringTransactionReminders(
    List<Map<String, dynamic>> transactions,
  ) async {
    try {
      for (final transaction in transactions) {
        final id = transaction['id'] as String;
        final name = transaction['name'] as String;
        final amount = transaction['amount'] as double;
        final dueDate = transaction['dueDate'] as DateTime;

        // Schedule reminder 1 day before
        final reminderDate = dueDate.subtract(const Duration(days: 1));

        if (reminderDate.isAfter(DateTime.now())) {
          await scheduleNotification(
            id: 6000 + id.hashCode,
            title: 'Upcoming Transaction',
            body: '$name (${CurrencyFormatter.format(amount)}) is due tomorrow',
            scheduledDate: reminderDate,
            payload: 'recurring_reminder:$id',
            channelId: 'recurring_transactions',
            channelName: 'Recurring Transactions',
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to schedule recurring transaction reminders: $e');
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    // Handle notification tap
    try {
      final parts = payload.split(':');
      final type = parts[0];
      final id = parts.length > 1 ? parts[1] : null;

      switch (type) {
        case 'budget_alert':
          // Navigate to budget detail screen
          break;
        case 'recurring_transaction':
          // Navigate to recurring transaction screen
          break;
        case 'goal_milestone':
          // Navigate to goal detail screen
          break;
        case 'backup_reminder':
          // Navigate to backup screen
          break;
        default:
          // Handle generic notification
          break;
      }
    } catch (e) {
      // Log error but don't crash
    }
  }

  // Get notification statistics
  Future<NotificationStats> getNotificationStats() async {
    try {
      final pending = await getPendingNotifications();

      final budgetAlerts = pending
          .where((n) => n.payload?.startsWith('budget_alert') == true)
          .length;
      final recurringReminders = pending
          .where((n) => n.payload?.startsWith('recurring_transaction') == true)
          .length;
      final goalMilestones = pending
          .where((n) => n.payload?.startsWith('goal_milestone') == true)
          .length;
      final backupReminders = pending
          .where((n) => n.payload?.startsWith('backup_reminder') == true)
          .length;

      return NotificationStats(
        total: pending.length,
        budgetAlerts: budgetAlerts,
        recurringReminders: recurringReminders,
        goalMilestones: goalMilestones,
        backupReminders: backupReminders,
      );
    } catch (e) {
      return const NotificationStats(
        total: 0,
        budgetAlerts: 0,
        recurringReminders: 0,
        goalMilestones: 0,
        backupReminders: 0,
      );
    }
  }

  // Check if initialized
  bool get isInitialized => _isInitialized;

  // Dispose service
  void dispose() {
    // Clean up resources if needed
  }
}

// Notification statistics model
class NotificationStats {
  final int total;
  final int budgetAlerts;
  final int recurringReminders;
  final int goalMilestones;
  final int backupReminders;

  const NotificationStats({
    required this.total,
    required this.budgetAlerts,
    required this.recurringReminders,
    required this.goalMilestones,
    required this.backupReminders,
  });
}
