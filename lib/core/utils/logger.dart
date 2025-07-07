import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class AppLogger {
  static bool _isInitialized = false;
  static bool _isDebugMode = kDebugMode;

  static void init({bool isDebug = kDebugMode}) {
    _isDebugMode = isDebug;
    _isInitialized = true;
    info('🔧 Logger initialized (Debug: $_isDebugMode)');
  }

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (_isDebugMode) {
      _log(LogLevel.debug, message, error, stackTrace);
    }
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    if (!_isInitialized) return;

    final timestamp = DateTime.now().toIso8601String();
    final prefix = _getPrefix(level);
    final fullMessage = '[$timestamp] $prefix $message';

    if (error != null) {
      developer.log(
        '$fullMessage\nError: $error',
        name: 'MoneyManager',
        level: _getLevel(level),
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      developer.log(
        fullMessage,
        name: 'MoneyManager',
        level: _getLevel(level),
      );
    }

    // In debug mode, also print to console
    if (_isDebugMode) {
      if (kDebugMode) {
        print(fullMessage);
        if (error != null) {
          print('Error: $error');
          if (stackTrace != null) {
            print('Stack trace: $stackTrace');
          }
        }
      }
    }
  }

  static String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛 DEBUG';
      case LogLevel.info:
        return 'ℹ️ INFO';
      case LogLevel.warning:
        return '⚠️ WARNING';
      case LogLevel.error:
        return '❌ ERROR';
    }
  }

  static int _getLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 700;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
