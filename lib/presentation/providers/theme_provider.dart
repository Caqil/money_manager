import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../core/enums/app_theme.dart';
import 'settings_provider.dart';

// Theme mode provider from settings
final currentThemeModeProvider = Provider<ThemeMode>(
  (ref) {
    final appTheme = ref.watch(themeModeProvider);

    switch (appTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  },
);

// Theme change notifier
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, AppTheme>(
  (ref) => ThemeNotifier(ref),
);

class ThemeNotifier extends StateNotifier<AppTheme> {
  final Ref _ref;

  ThemeNotifier(this._ref) : super(AppTheme.system) {
    // Load initial theme from settings
    _loadTheme();
  }

  void _loadTheme() {
    final theme = _ref.read(themeModeProvider);
    state = theme;
  }

  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    await _ref.read(settingsStateProvider.notifier).setThemeMode(theme);
  }

  void toggleTheme() {
    switch (state) {
      case AppTheme.light:
        setTheme(AppTheme.dark);
        break;
      case AppTheme.dark:
        setTheme(AppTheme.system);
        break;
      case AppTheme.system:
        setTheme(AppTheme.light);
        break;
    }
  }
}
