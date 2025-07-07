// lib/main.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'data/models/transaction.dart';
import 'data/models/budget.dart';
import 'data/models/account.dart';
import 'data/models/goal.dart';
import 'data/models/category.dart';
import 'data/models/recurring_transaction.dart';
import 'data/models/split_expense.dart';
import 'data/models/badge.dart';
import 'data/services/hive_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/settings_service.dart'; // ADD: Import SettingsService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Register Hive Adapters BEFORE initializing HiveService
  _registerHiveAdapters();

  // Initialize Services (HiveService will handle Hive.initFlutter())
  await HiveService.init();
  await NotificationService.init();

  // CRITICAL: Initialize both AuthService AND SettingsService before running the app
  await AuthService.init();
  await SettingsService.init(); // ADD: Initialize SettingsService

  runApp(
    ProviderScope(
        child: EasyLocalization(
      supportedLocales: AppConstants.supportedLocales,
      path: AppConstants.localizationPath,
      fallbackLocale: AppConstants.defaultLocale,
      useFallbackTranslations: true,
      useOnlyLangCode: true,
      child: MoneyManagerApp(),
    )),
  );
}

void _registerHiveAdapters() {
  // Register model adapters
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(TransactionAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(BudgetAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(AccountAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(GoalAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(CategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(RecurringTransactionAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(SplitExpenseAdapter());
  }
  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(BadgeAdapter());
  }

  // Register enum adapters - THESE ARE CRITICAL!
  // Add any enum adapters you have...
}
