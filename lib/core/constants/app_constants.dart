// ==========================================
// 1. lib/core/constants/app_constants.dart
// ==========================================

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Money Manager';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Complete offline money management solution';
  
  // Database
  static const String hiveBoxTransactions = 'transactions';
  static const String hiveBoxBudgets = 'budgets';
  static const String hiveBoxAccounts = 'accounts';
  static const String hiveBoxGoals = 'goals';
  static const String hiveBoxCategories = 'categories';
  static const String hiveBoxRecurringTransactions = 'recurring_transactions';
  static const String hiveBoxSplitExpenses = 'split_expenses';
  static const String hiveBoxBadges = 'badges';
  static const String hiveBoxCurrencyRates = 'currency_rates';
  static const String hiveBoxCurrencies = 'currencies';
  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxUserData = 'user_data';
  
  // SharedPreferences Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyPinEnabled = 'pin_enabled';
  static const String keyPinHash = 'pin_hash';
  static const String keyBaseCurrency = 'base_currency';
  static const String keyLastBackup = 'last_backup';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyAutoBackupEnabled = 'auto_backup_enabled';
  
  // Default Values
  static const String defaultCurrency = 'USD';
  static const String defaultLanguage = 'en';
  static const int defaultDecimalPlaces = 2;
  static const double defaultBudgetAlertThreshold = 0.8;
  static const int defaultNotificationDaysBefore = 1;
  
  // File Paths
  static const String backupFileName = 'money_manager_backup';
  static const String exportFileName = 'transactions_export';
  static const String receiptImagesFolder = 'receipt_images';
  
  // Limits
  static const int maxTransactionsPerQuery = 1000;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxCategoryNameLength = 50;
  static const int maxAccountNameLength = 50;
  static const int maxGoalNameLength = 50;
  static const int maxNotesLength = 500;
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Chart Settings
  static const int maxChartDataPoints = 50;
  static const double chartAnimationDuration = 1.5;
  
  // Notification IDs
  static const int budgetAlertNotificationId = 1001;
  static const int recurringTransactionNotificationId = 1002;
  static const int goalMilestoneNotificationId = 1003;
  static const int backupReminderNotificationId = 1004;
  
  // Voice Commands
  static const Duration voiceInputTimeout = Duration(seconds: 30);
  static const Duration voiceInputPause = Duration(seconds: 3);
  
  // Security
  static const int pinLength = 4;
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);
  
  // Export/Import
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];
  static const List<String> supportedBackupFormats = ['json', 'csv'];
  
  // URLs
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';
  static const String supportUrl = 'https://example.com/support';
  static const String githubUrl = 'https://github.com/example/money-manager';
}
