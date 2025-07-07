import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'settings_provider.dart';

// Theme mode provider from settings
final currentThemeModeProvider = Provider<ThemeMode>(
  (ref) {
    final appTheme = ref.watch(themeModeProvider);

    switch (appTheme) {
      case ThemeMode.light:
        return ThemeMode.light;
      case ThemeMode.dark:
        return ThemeMode.dark;
      case ThemeMode.system:
        return ThemeMode.system;
    }
  },
);

// Theme change notifier
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(ref),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;

  ThemeNotifier(this._ref) : super(ThemeMode.system) {
    // Load initial theme from settings
    _loadTheme();
  }

  void _loadTheme() {
    final theme = _ref.read(themeModeProvider);
    state = theme;
  }

  Future<void> setTheme(ThemeMode theme) async {
    state = theme;
    await _ref.read(settingsStateProvider.notifier).setThemeMode(theme);
  }

  void toggleTheme() {
    switch (state) {
      case ThemeMode.light:
        setTheme(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setTheme(ThemeMode.system);
        break;
      case ThemeMode.system:
        setTheme(ThemeMode.light);
        break;
    }
  }
}
