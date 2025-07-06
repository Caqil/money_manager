import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../data/services/settings_service.dart';
import '../../core/enums/app_theme.dart';

// Settings service provider
final settingsServiceProvider = Provider<SettingsService>(
  (ref) => SettingsService(),
);

// Settings state provider
final settingsStateProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref.read(settingsServiceProvider)),
);

// Individual setting providers
final themeModeProvider = Provider<AppTheme>(
  (ref) => ref.watch(settingsStateProvider).themeMode,
);

final languageProvider = Provider<String>(
  (ref) => ref.watch(settingsStateProvider).language,
);

final baseCurrencyProvider = Provider<String>(
  (ref) => ref.watch(settingsStateProvider).baseCurrency,
);

final notificationsEnabledSettingProvider = Provider<bool>(
  (ref) => ref.watch(settingsStateProvider).notificationsEnabled,
);

final autoBackupEnabledProvider = Provider<bool>(
  (ref) => ref.watch(settingsStateProvider).autoBackupEnabled,
);

final budgetAlertThresholdProvider = Provider<double>(
  (ref) => ref.watch(settingsStateProvider).budgetAlertThreshold,
);

final chartAnimationsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(settingsStateProvider).chartAnimationsEnabled,
);

final voiceInputEnabledProvider = Provider<bool>(
  (ref) => ref.watch(settingsStateProvider).voiceInputEnabled,
);

final isFirstLaunchProvider = Provider<bool>(
  (ref) => ref.watch(settingsStateProvider).isFirstLaunch,
);

final dashboardWidgetsProvider = Provider<List<String>>(
  (ref) => ref.watch(settingsStateProvider).dashboardWidgets,
);

final quickActionsProvider = Provider<List<String>>(
  (ref) => ref.watch(settingsStateProvider).quickActions,
);

final recentCurrenciesProvider = Provider<List<String>>(
  (ref) => ref.watch(settingsStateProvider).recentCurrencies,
);

// Settings state
class SettingsState {
  final AppTheme themeMode;
  final String language;
  final String baseCurrency;
  final bool notificationsEnabled;
  final bool autoBackupEnabled;
  final double budgetAlertThreshold;
  final int transactionReminderDays;
  final String preferredExportFormat;
  final bool chartAnimationsEnabled;
  final bool voiceInputEnabled;
  final String voiceInputLanguage;
  final List<String> recentCurrencies;
  final List<String> dashboardWidgets;
  final List<String> quickActions;
  final int transactionsPerPage;
  final String defaultTransactionView;
  final bool analyticsTrackingEnabled;
  final bool isFirstLaunch;
  final DateTime? lastBackupDate;
  final String? error;
  final bool isLoading;

  const SettingsState({
    this.themeMode = AppTheme.system,
    this.language = 'en',
    this.baseCurrency = 'USD',
    this.notificationsEnabled = true,
    this.autoBackupEnabled = false,
    this.budgetAlertThreshold = 0.8,
    this.transactionReminderDays = 1,
    this.preferredExportFormat = 'csv',
    this.chartAnimationsEnabled = true,
    this.voiceInputEnabled = true,
    this.voiceInputLanguage = 'en_US',
    this.recentCurrencies = const ['USD'],
    this.dashboardWidgets = const [
      'balance_card',
      'recent_transactions',
      'budget_overview',
      'spending_chart',
    ],
    this.quickActions = const [
      'add_expense',
      'add_income',
      'transfer',
    ],
    this.transactionsPerPage = 20,
    this.defaultTransactionView = 'list',
    this.analyticsTrackingEnabled = false,
    this.isFirstLaunch = true,
    this.lastBackupDate,
    this.error,
    this.isLoading = false,
  });

  SettingsState copyWith({
    AppTheme? themeMode,
    String? language,
    String? baseCurrency,
    bool? notificationsEnabled,
    bool? autoBackupEnabled,
    double? budgetAlertThreshold,
    int? transactionReminderDays,
    String? preferredExportFormat,
    bool? chartAnimationsEnabled,
    bool? voiceInputEnabled,
    String? voiceInputLanguage,
    List<String>? recentCurrencies,
    List<String>? dashboardWidgets,
    List<String>? quickActions,
    int? transactionsPerPage,
    String? defaultTransactionView,
    bool? analyticsTrackingEnabled,
    bool? isFirstLaunch,
    DateTime? lastBackupDate,
    String? error,
    bool? isLoading,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      budgetAlertThreshold: budgetAlertThreshold ?? this.budgetAlertThreshold,
      transactionReminderDays:
          transactionReminderDays ?? this.transactionReminderDays,
      preferredExportFormat:
          preferredExportFormat ?? this.preferredExportFormat,
      chartAnimationsEnabled:
          chartAnimationsEnabled ?? this.chartAnimationsEnabled,
      voiceInputEnabled: voiceInputEnabled ?? this.voiceInputEnabled,
      voiceInputLanguage: voiceInputLanguage ?? this.voiceInputLanguage,
      recentCurrencies: recentCurrencies ?? this.recentCurrencies,
      dashboardWidgets: dashboardWidgets ?? this.dashboardWidgets,
      quickActions: quickActions ?? this.quickActions,
      transactionsPerPage: transactionsPerPage ?? this.transactionsPerPage,
      defaultTransactionView:
          defaultTransactionView ?? this.defaultTransactionView,
      analyticsTrackingEnabled:
          analyticsTrackingEnabled ?? this.analyticsTrackingEnabled,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Settings notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(const SettingsState()) {
    _loadSettings();
  }

  // Load all settings
  Future<void> _loadSettings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final themeMode = _service.getThemeMode();
      final language = _service.getLanguage();
      final baseCurrency = _service.getBaseCurrency();
      final notificationsEnabled = _service.areNotificationsEnabled();
      final autoBackupEnabled = _service.isAutoBackupEnabled();
      final budgetAlertThreshold = _service.getBudgetAlertThreshold();
      final transactionReminderDays = _service.getTransactionReminderDays();
      final preferredExportFormat = _service.getPreferredExportFormat();
      final chartAnimationsEnabled = _service.areChartAnimationsEnabled();
      final voiceInputEnabled = _service.isVoiceInputEnabled();
      final voiceInputLanguage = _service.getVoiceInputLanguage();
      final recentCurrencies = _service.getRecentCurrencies();
      final dashboardWidgets = _service.getDashboardWidgets();
      final quickActions = _service.getQuickActions();
      final transactionsPerPage = _service.getTransactionsPerPage();
      final defaultTransactionView = _service.getDefaultTransactionView();
      final analyticsTrackingEnabled = _service.isAnalyticsTrackingEnabled();
      final isFirstLaunch = _service.isFirstLaunch();
      final lastBackupDate = _service.getLastBackupDate();

      state = state.copyWith(
        themeMode: themeMode,
        language: language,
        baseCurrency: baseCurrency,
        notificationsEnabled: notificationsEnabled,
        autoBackupEnabled: autoBackupEnabled,
        budgetAlertThreshold: budgetAlertThreshold,
        transactionReminderDays: transactionReminderDays,
        preferredExportFormat: preferredExportFormat,
        chartAnimationsEnabled: chartAnimationsEnabled,
        voiceInputEnabled: voiceInputEnabled,
        voiceInputLanguage: voiceInputLanguage,
        recentCurrencies: recentCurrencies,
        dashboardWidgets: dashboardWidgets,
        quickActions: quickActions,
        transactionsPerPage: transactionsPerPage,
        defaultTransactionView: defaultTransactionView,
        analyticsTrackingEnabled: analyticsTrackingEnabled,
        isFirstLaunch: isFirstLaunch,
        lastBackupDate: lastBackupDate,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings: $e',
      );
    }
  }

  // Set theme mode
  Future<void> setThemeMode(AppTheme theme) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setThemeMode(theme);
      state = state.copyWith(themeMode: theme, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update theme: $e',
      );
    }
  }

  // Set language
  Future<void> setLanguage(String languageCode) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setLanguage(languageCode);
      state = state.copyWith(language: languageCode, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update language: $e',
      );
    }
  }

  // Set base currency
  Future<void> setBaseCurrency(String currencyCode) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setBaseCurrency(currencyCode);
      await _service.addRecentCurrency(currencyCode);
      state = state.copyWith(
        baseCurrency: currencyCode,
        recentCurrencies: _service.getRecentCurrencies(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update currency: $e',
      );
    }
  }

  // Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setNotificationsEnabled(enabled);
      state = state.copyWith(notificationsEnabled: enabled, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update notifications setting: $e',
      );
    }
  }

  // Set auto backup enabled
  Future<void> setAutoBackupEnabled(bool enabled) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setAutoBackupEnabled(enabled);
      state = state.copyWith(autoBackupEnabled: enabled, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update auto backup setting: $e',
      );
    }
  }

  // Set budget alert threshold
  Future<void> setBudgetAlertThreshold(double threshold) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setBudgetAlertThreshold(threshold);
      state = state.copyWith(budgetAlertThreshold: threshold, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update budget alert threshold: $e',
      );
    }
  }

  // Set chart animations enabled
  Future<void> setChartAnimationsEnabled(bool enabled) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setChartAnimationsEnabled(enabled);
      state = state.copyWith(chartAnimationsEnabled: enabled, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update chart animations setting: $e',
      );
    }
  }

  // Set voice input enabled
  Future<void> setVoiceInputEnabled(bool enabled) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setVoiceInputEnabled(enabled);
      state = state.copyWith(voiceInputEnabled: enabled, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update voice input setting: $e',
      );
    }
  }

  // Set dashboard widgets
  Future<void> setDashboardWidgets(List<String> widgets) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setDashboardWidgets(widgets);
      state = state.copyWith(dashboardWidgets: widgets, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update dashboard widgets: $e',
      );
    }
  }

  // Set quick actions
  Future<void> setQuickActions(List<String> actions) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setQuickActions(actions);
      state = state.copyWith(quickActions: actions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update quick actions: $e',
      );
    }
  }

  // Set analytics tracking enabled
  Future<void> setAnalyticsTrackingEnabled(bool enabled) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setAnalyticsTrackingEnabled(enabled);
      state =
          state.copyWith(analyticsTrackingEnabled: enabled, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update analytics tracking: $e',
      );
    }
  }

  // Mark first launch as completed
  Future<void> setFirstLaunchCompleted() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setFirstLaunchCompleted();
      state = state.copyWith(isFirstLaunch: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update first launch status: $e',
      );
    }
  }

  // Set last backup date
  Future<void> setLastBackupDate(DateTime date) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setLastBackupDate(date);
      state = state.copyWith(lastBackupDate: date, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update last backup date: $e',
      );
    }
  }

  // Update transaction reminder days
  Future<void> setTransactionReminderDays(int days) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setTransactionReminderDays(days);
      state = state.copyWith(transactionReminderDays: days, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update transaction reminder days: $e',
      );
    }
  }

  // Update preferred export format
  Future<void> setPreferredExportFormat(String format) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setPreferredExportFormat(format);
      state = state.copyWith(preferredExportFormat: format, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update export format: $e',
      );
    }
  }

  // Reset all settings
  Future<bool> resetAllSettings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.resetAllSettings();
      state = const SettingsState();
      await _loadSettings();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reset settings: $e',
      );
      return false;
    }
  }

  // Export settings
  Map<String, dynamic> exportSettings() {
    return _service.exportSettings();
  }

  // Import settings
  Future<bool> importSettings(Map<String, dynamic> settings) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.importSettings(settings);
      await _loadSettings();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to import settings: $e',
      );
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh settings
  Future<void> refresh() async {
    await _loadSettings();
  }
}
