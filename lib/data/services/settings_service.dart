import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/enums/app_theme.dart';
import '../../core/errors/exceptions.dart';

class SettingsService {
  static SettingsService? _instance;
  late final SharedPreferences _prefs;
  bool _isInitialized = false;

  SettingsService._internal();

  factory SettingsService() {
    _instance ??= SettingsService._internal();
    return _instance!;
  }

  // Initialize settings service
  static Future<SettingsService> init() async {
    final instance = SettingsService();
    await instance._initialize();
    return instance;
  }

  Future<void> _initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize settings service: $e');
    }
  }

  // Theme settings
  AppTheme getThemeMode() {
    final themeString = _prefs.getString(AppConstants.keyThemeMode) ?? 'system';
    switch (themeString) {
      case 'light':
        return AppTheme.light;
      case 'dark':
        return AppTheme.dark;
      case 'system':
      default:
        return AppTheme.system;
    }
  }

  Future<void> setThemeMode(AppTheme theme) async {
    await _prefs.setString(AppConstants.keyThemeMode, theme.name);
  }

  // Language settings
  String getLanguage() {
    return _prefs.getString(AppConstants.keyLanguage) ??
        AppConstants.defaultLanguage;
  }

  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(AppConstants.keyLanguage, languageCode);
  }

  // Currency settings
  String getBaseCurrency() {
    return _prefs.getString(AppConstants.keyBaseCurrency) ??
        AppConstants.defaultCurrency;
  }

  Future<void> setBaseCurrency(String currencyCode) async {
    await _prefs.setString(AppConstants.keyBaseCurrency, currencyCode);
    // Also add to recent currencies
    await addRecentCurrency(currencyCode);
  }

  // Notification settings
  bool areNotificationsEnabled() {
    return _prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.keyNotificationsEnabled, enabled);
  }

  // Auto backup settings
  bool isAutoBackupEnabled() {
    return _prefs.getBool(AppConstants.keyAutoBackupEnabled) ?? false;
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.keyAutoBackupEnabled, enabled);
  }

  // Budget alert threshold
  double getBudgetAlertThreshold() {
    return _prefs.getDouble('budget_alert_threshold') ??
        AppConstants.defaultBudgetAlertThreshold;
  }

  Future<void> setBudgetAlertThreshold(double threshold) async {
    await _prefs.setDouble('budget_alert_threshold', threshold);
  }

  // Transaction reminder days
  int getTransactionReminderDays() {
    return _prefs.getInt('transaction_reminder_days') ??
        AppConstants.defaultNotificationDaysBefore;
  }

  Future<void> setTransactionReminderDays(int days) async {
    await _prefs.setInt('transaction_reminder_days', days);
  }

  // Export format
  String getPreferredExportFormat() {
    return _prefs.getString('preferred_export_format') ?? 'csv';
  }

  Future<void> setPreferredExportFormat(String format) async {
    await _prefs.setString('preferred_export_format', format);
  }

  // Chart animations
  bool areChartAnimationsEnabled() {
    return _prefs.getBool('chart_animations_enabled') ?? true;
  }

  Future<void> setChartAnimationsEnabled(bool enabled) async {
    await _prefs.setBool('chart_animations_enabled', enabled);
  }

  // Voice input settings
  bool isVoiceInputEnabled() {
    return _prefs.getBool('voice_input_enabled') ?? true;
  }

  Future<void> setVoiceInputEnabled(bool enabled) async {
    await _prefs.setBool('voice_input_enabled', enabled);
  }

  String getVoiceInputLanguage() {
    return _prefs.getString('voice_input_language') ?? 'en_US';
  }

  Future<void> setVoiceInputLanguage(String language) async {
    await _prefs.setString('voice_input_language', language);
  }

  // Recent currencies
  List<String> getRecentCurrencies() {
    return _prefs.getStringList('recent_currencies') ??
        [AppConstants.defaultCurrency];
  }

  Future<void> addRecentCurrency(String currencyCode) async {
    final recent = getRecentCurrencies();

    // Remove if already exists
    recent.remove(currencyCode);

    // Add to front
    recent.insert(0, currencyCode);

    // Keep only last 5
    if (recent.length > 5) {
      recent.removeRange(5, recent.length);
    }

    await _prefs.setStringList('recent_currencies', recent);
  }

  // Dashboard widgets
  List<String> getDashboardWidgets() {
    return _prefs.getStringList('dashboard_widgets') ??
        [
          'balance_card',
          'recent_transactions',
          'budget_overview',
          'spending_chart',
        ];
  }

  Future<void> setDashboardWidgets(List<String> widgets) async {
    await _prefs.setStringList('dashboard_widgets', widgets);
  }

  // Quick actions
  List<String> getQuickActions() {
    return _prefs.getStringList('quick_actions') ??
        [
          'add_expense',
          'add_income',
          'transfer',
        ];
  }

  Future<void> setQuickActions(List<String> actions) async {
    await _prefs.setStringList('quick_actions', actions);
  }

  // Pagination settings
  int getTransactionsPerPage() {
    return _prefs.getInt('transactions_per_page') ?? 20;
  }

  Future<void> setTransactionsPerPage(int count) async {
    await _prefs.setInt('transactions_per_page', count);
  }

  // Default view settings
  String getDefaultTransactionView() {
    return _prefs.getString('default_transaction_view') ?? 'list';
  }

  Future<void> setDefaultTransactionView(String view) async {
    await _prefs.setString('default_transaction_view', view);
  }

  // Analytics tracking
  bool isAnalyticsTrackingEnabled() {
    return _prefs.getBool('analytics_tracking_enabled') ?? false;
  }

  Future<void> setAnalyticsTrackingEnabled(bool enabled) async {
    await _prefs.setBool('analytics_tracking_enabled', enabled);
  }

  // First launch
  bool isFirstLaunch() {
    return _prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;
  }

  Future<void> setFirstLaunchCompleted() async {
    await _prefs.setBool(AppConstants.keyIsFirstLaunch, false);
  }

  // Last backup date
  DateTime? getLastBackupDate() {
    final timestamp = _prefs.getInt(AppConstants.keyLastBackup);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> setLastBackupDate(DateTime date) async {
    await _prefs.setInt(
        AppConstants.keyLastBackup, date.millisecondsSinceEpoch);
  }

  // Reset all settings
  Future<void> resetAllSettings() async {
    // Get keys to preserve
    final preserveKeys = {
      AppConstants.keyPinHash,
      AppConstants.keyBiometricEnabled,
      AppConstants.keyPinEnabled,
    };

    final allKeys = _prefs.getKeys();

    for (final key in allKeys) {
      if (!preserveKeys.contains(key)) {
        await _prefs.remove(key);
      }
    }

    // Set default values
    await setThemeMode(AppTheme.system);
    await setLanguage(AppConstants.defaultLanguage);
    await setBaseCurrency(AppConstants.defaultCurrency);
    await setNotificationsEnabled(true);
    await setAutoBackupEnabled(false);
    await setBudgetAlertThreshold(AppConstants.defaultBudgetAlertThreshold);
    await setChartAnimationsEnabled(true);
    await setVoiceInputEnabled(true);
  }

  // Export settings
  Map<String, dynamic> exportSettings() {
    final settings = <String, dynamic>{};

    settings['theme_mode'] = getThemeMode().name;
    settings['language'] = getLanguage();
    settings['base_currency'] = getBaseCurrency();
    settings['notifications_enabled'] = areNotificationsEnabled();
    settings['auto_backup_enabled'] = isAutoBackupEnabled();
    settings['budget_alert_threshold'] = getBudgetAlertThreshold();
    settings['transaction_reminder_days'] = getTransactionReminderDays();
    settings['preferred_export_format'] = getPreferredExportFormat();
    settings['chart_animations_enabled'] = areChartAnimationsEnabled();
    settings['voice_input_enabled'] = isVoiceInputEnabled();
    settings['voice_input_language'] = getVoiceInputLanguage();
    settings['recent_currencies'] = getRecentCurrencies();
    settings['dashboard_widgets'] = getDashboardWidgets();
    settings['quick_actions'] = getQuickActions();
    settings['transactions_per_page'] = getTransactionsPerPage();
    settings['default_transaction_view'] = getDefaultTransactionView();
    settings['analytics_tracking_enabled'] = isAnalyticsTrackingEnabled();

    return settings;
  }

  // Import settings
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      if (settings.containsKey('theme_mode')) {
        final themeString = settings['theme_mode'] as String;
        AppTheme theme;
        switch (themeString) {
          case 'light':
            theme = AppTheme.light;
            break;
          case 'dark':
            theme = AppTheme.dark;
            break;
          default:
            theme = AppTheme.system;
        }
        await setThemeMode(theme);
      }

      if (settings.containsKey('language')) {
        await setLanguage(settings['language'] as String);
      }

      if (settings.containsKey('base_currency')) {
        await setBaseCurrency(settings['base_currency'] as String);
      }

      if (settings.containsKey('notifications_enabled')) {
        await setNotificationsEnabled(
            settings['notifications_enabled'] as bool);
      }

      if (settings.containsKey('auto_backup_enabled')) {
        await setAutoBackupEnabled(settings['auto_backup_enabled'] as bool);
      }

      if (settings.containsKey('budget_alert_threshold')) {
        await setBudgetAlertThreshold(
            settings['budget_alert_threshold'] as double);
      }

      if (settings.containsKey('transaction_reminder_days')) {
        await setTransactionReminderDays(
            settings['transaction_reminder_days'] as int);
      }

      if (settings.containsKey('preferred_export_format')) {
        await setPreferredExportFormat(
            settings['preferred_export_format'] as String);
      }

      if (settings.containsKey('chart_animations_enabled')) {
        await setChartAnimationsEnabled(
            settings['chart_animations_enabled'] as bool);
      }

      if (settings.containsKey('voice_input_enabled')) {
        await setVoiceInputEnabled(settings['voice_input_enabled'] as bool);
      }

      if (settings.containsKey('voice_input_language')) {
        await setVoiceInputLanguage(settings['voice_input_language'] as String);
      }

      if (settings.containsKey('dashboard_widgets')) {
        await setDashboardWidgets(
            (settings['dashboard_widgets'] as List).cast<String>());
      }

      if (settings.containsKey('quick_actions')) {
        await setQuickActions(
            (settings['quick_actions'] as List).cast<String>());
      }

      if (settings.containsKey('transactions_per_page')) {
        await setTransactionsPerPage(settings['transactions_per_page'] as int);
      }

      if (settings.containsKey('default_transaction_view')) {
        await setDefaultTransactionView(
            settings['default_transaction_view'] as String);
      }

      if (settings.containsKey('analytics_tracking_enabled')) {
        await setAnalyticsTrackingEnabled(
            settings['analytics_tracking_enabled'] as bool);
      }

      if (settings.containsKey('recent_currencies')) {
        await _prefs.setStringList('recent_currencies',
            (settings['recent_currencies'] as List).cast<String>());
      }
    } catch (e) {
      throw Exception('Failed to import settings: $e');
    }
  }

  // Check if initialized
  bool get isInitialized => _isInitialized;

  // Dispose service
  void dispose() {
    // Clean up resources if needed
  }
}
