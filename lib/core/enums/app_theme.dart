
enum AppTheme {
  light,
  dark,
  system;

  String get displayName {
    switch (this) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.system:
        return 'System';
    }
  }

  String get icon {
    switch (this) {
      case AppTheme.light:
        return 'light_mode';
      case AppTheme.dark:
        return 'dark_mode';
      case AppTheme.system:
        return 'settings_brightness';
    }
  }
}
