// ==========================================
// lib/main.dart
// ==========================================

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/logger.dart';
import 'data/services/settings_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/hive_service.dart';
import 'data/services/encryption_service.dart';
import 'data/services/file_service.dart';
import 'data/models/transaction.dart';
import 'data/models/account.dart';
import 'data/models/category.dart';
import 'data/models/budget.dart';
import 'data/models/goal.dart';
import 'presentation/routes/app_router.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      // Ensure Flutter widgets are initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize logger
      AppLogger.init(isDebug: kDebugMode);
      AppLogger.info('🚀 Starting Money Manager App...');

      try {
        // Initialize core services
        await _initializeCore();

        // Initialize localization
        await _initializeLocalization();

        // Initialize routing
        _initializeRouting();

        // Initialize database and services
        await _initializeServices();

        // Initialize notifications
        await _initializeNotifications();

        AppLogger.info('✅ All services initialized successfully');

        // Run the app
        runApp(
          ProviderScope(
            observers: [
              if (kDebugMode) _RiverpodLogger(),
            ],
            child: EasyLocalization(
              supportedLocales: AppConstants.supportedLocales,
              path: AppConstants.localizationPath,
              fallbackLocale: AppConstants.defaultLocale,
              useFallbackTranslations: true,
              useOnlyLangCode: true,
              child: const MoneyManagerApp(),
            ),
          ),
        );
      } catch (e, stackTrace) {
        AppLogger.error('❌ Failed to initialize app', e, stackTrace);
        _handleInitializationError(e, stackTrace);
      }
    },
    (error, stackTrace) {
      AppLogger.error('💥 Uncaught error in main', error, stackTrace);
      _handleGlobalError(error, stackTrace);
    },
  );
}

/// Initialize core Flutter services
Future<void> _initializeCore() async {
  AppLogger.info('📱 Initializing core services...');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize timezone data
  tz.initializeTimeZones();

  AppLogger.info('✅ Core services initialized');
}

/// Initialize localization
Future<void> _initializeLocalization() async {
  AppLogger.info('🌐 Initializing localization...');

  await EasyLocalization.ensureInitialized();

  AppLogger.info('✅ Localization initialized');
}

/// Initialize routing
void _initializeRouting() {
  AppLogger.info('🗺️ Initializing routing...');

  AppRouter.initialize();

  AppLogger.info('✅ Routing initialized');
}

/// Initialize database and core services
Future<void> _initializeServices() async {
  AppLogger.info('🗄️ Initializing services...');

  // Initialize Hive
  await _initializeHive();

  // Initialize settings service
  await SettingsService.init();
  AppLogger.info('⚙️ Settings service initialized');

  // Initialize authentication service
  await AuthService.init();
  AppLogger.info('🔐 Auth service initialized');

  // Initialize encryption service
  await EncryptionService.init();
  AppLogger.info('🔒 Encryption service initialized');

  // Initialize file service
  await FileService.init();
  AppLogger.info('📁 File service initialized');

  // Initialize Hive service
  await HiveService.init();
  AppLogger.info('📦 Hive service initialized');

  AppLogger.info('✅ All services initialized');
}

/// Initialize Hive database
Future<void> _initializeHive() async {
  AppLogger.info('📦 Initializing Hive...');

  // Initialize Hive Flutter
  await Hive.initFlutter();

  // Register adapters
  _registerHiveAdapters();

  AppLogger.info('✅ Hive initialized with adapters');
}

/// Register Hive type adapters
void _registerHiveAdapters() {
  // Only register if not already registered
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TransactionAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(AccountAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(BudgetAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(GoalAdapter());
  }
  
  AppLogger.info('📝 Hive adapters registered');
}

/// Initialize notifications
Future<void> _initializeNotifications() async {
  AppLogger.info('🔔 Initializing notifications...');

  try {
    await NotificationService.init();
    AppLogger.info('✅ Notifications initialized');
  } catch (e) {
    AppLogger.warning('⚠️ Failed to initialize notifications: $e');
    // Continue without notifications
  }
}

/// Handle initialization errors
void _handleInitializationError(Object error, StackTrace stackTrace) {
  AppLogger.error('Initialization failed', error, stackTrace);
  
  runApp(
    MaterialApp(
      title: 'Money Manager - Error',
      home: InitializationErrorScreen(
        error: error,
        stackTrace: stackTrace,
      ),
    ),
  );
}

/// Handle global errors
void _handleGlobalError(Object error, StackTrace stackTrace) {
  // Log error
  AppLogger.error('Global error', error, stackTrace);
  
  // Report to crash analytics if available
  // FirebaseCrashlytics.instance.recordError(error, stackTrace);
}

/// Riverpod logger for debugging
class _RiverpodLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      AppLogger.debug('[RIVERPOD] ${provider.name ?? provider.runtimeType} updated');
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase provider,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      AppLogger.debug('[RIVERPOD] ${provider.name ?? provider.runtimeType} disposed');
    }
  }
}

/// Error screen for initialization failures
class InitializationErrorScreen extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  const InitializationErrorScreen({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade600,
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to Start App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'The app encountered an error during startup. Please restart the app.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (kDebugMode) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      'Error: $error\n\nStack trace:\n$stackTrace',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ElevatedButton.icon(
                onPressed: () {
                  // Restart the app
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else {
                    exit(0);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Restart App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// lib/app.dart
// ==========================================
