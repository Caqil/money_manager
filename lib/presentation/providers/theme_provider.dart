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
