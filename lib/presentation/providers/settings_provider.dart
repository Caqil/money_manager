// lib/presentation/providers/settings_provider.dart
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
final themeModeProvider = Provider<ThemeMode>(
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
  final ThemeMode themeMode;
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
    this.themeMode = ThemeMode.system,
    this.language = 'en',
    this.baseCurrency = 'USD',
    this.notificationsEnabled = true,
    this.autoBackupEnabled = false,
    this.budgetAlertThreshold = 0.8,
    this.transactionReminderDays = 7,
    this.preferredExportFormat = 'csv',
    this.chartAnimationsEnabled = true,
    this.voiceInputEnabled = false,
    this.voiceInputLanguage = 'en',
    this.recentCurrencies = const [],
    this.dashboardWidgets = const [],
    this.quickActions = const [],
    this.transactionsPerPage = 20,
    this.defaultTransactionView = 'list',
    this.analyticsTrackingEnabled = false,
    this.isFirstLaunch = true,
    this.lastBackupDate,
    this.error,
    this.isLoading = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
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

// COMPLETE Settings notifier with all missing methods
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(const SettingsState());

  // Load all settings from service
  Future<void> loadSettings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Load all settings from the service
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

      state = SettingsState(
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
  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setThemeMode(themeMode);
      state = state.copyWith(themeMode: themeMode, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update theme: $e',
      );
    }
  }

  // Set language
  Future<void> setLanguage(String language) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setLanguage(language);
      state = state.copyWith(language: language, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update language: $e',
      );
    }
  }

  // Set base currency
  Future<void> setBaseCurrency(String currency) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setBaseCurrency(currency);
      state = state.copyWith(baseCurrency: currency, isLoading: false);
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
        error: 'Failed to update notification settings: $e',
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
        error: 'Failed to update backup settings: $e',
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

  // Set transaction reminder days
  Future<void> setTransactionReminderDays(int days) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setTransactionReminderDays(days);
      state = state.copyWith(transactionReminderDays: days, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update reminder settings: $e',
      );
    }
  }

  // Set preferred export format
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

  // Set chart animations enabled
  Future<void> setChartAnimationsEnabled(bool enabled) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setChartAnimationsEnabled(enabled);
      state = state.copyWith(chartAnimationsEnabled: enabled, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update animation settings: $e',
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
        error: 'Failed to update voice input settings: $e',
      );
    }
  }

  // Set voice input language
  Future<void> setVoiceInputLanguage(String language) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setVoiceInputLanguage(language);
      state = state.copyWith(voiceInputLanguage: language, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update voice language: $e',
      );
    }
  }

  // Set transactions per page
  Future<void> setTransactionsPerPage(int count) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setTransactionsPerPage(count);
      state = state.copyWith(transactionsPerPage: count, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update pagination settings: $e',
      );
    }
  }

  // Set default transaction view
  Future<void> setDefaultTransactionView(String view) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setDefaultTransactionView(view);
      state = state.copyWith(defaultTransactionView: view, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update view settings: $e',
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
        error: 'Failed to update analytics settings: $e',
      );
    }
  }

  // ADDED: Set first launch status (this was missing!)
  Future<void> setIsFirstLaunch(bool isFirstLaunch) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.setIsFirstLaunch(isFirstLaunch);
      state = state.copyWith(isFirstLaunch: isFirstLaunch, isLoading: false);
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

  // Add recent currency
  Future<void> addRecentCurrency(String currency) async {
    try {
      await _service.addRecentCurrency(currency);
      final updatedCurrencies = _service.getRecentCurrencies();
      state = state.copyWith(recentCurrencies: updatedCurrencies);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add recent currency: $e');
    }
  }

  // Update dashboard widgets
  Future<void> updateDashboardWidgets(List<String> widgets) async {
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

  // Update quick actions
  Future<void> updateQuickActions(List<String> actions) async {
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

  // Reset all settings to defaults
  Future<void> resetSettings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.resetAllSettings();
      await loadSettings(); // Reload all settings
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reset settings: $e',
      );
    }
  }

  // Export settings
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      return await _service.exportSettings();
    } catch (e) {
      state = state.copyWith(error: 'Failed to export settings: $e');
      rethrow;
    }
  }

  // Import settings
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _service.importSettings(settings);
      await loadSettings(); // Reload all settings
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to import settings: $e',
      );
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh settings
  Future<void> refresh() async {
    await loadSettings();
  }
}
