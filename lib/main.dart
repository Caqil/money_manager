import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  _registerHiveAdapters();

  // Initialize Services
  await HiveService.init();
  await NotificationService.init();

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
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(RecurringTransactionAdapter());
  Hive.registerAdapter(SplitExpenseAdapter());
  Hive.registerAdapter(BadgeAdapter());
}
