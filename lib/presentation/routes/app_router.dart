// lib/presentation/routes/app_router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/presentation/pages/main/main_layout.dart';
import 'package:money_manager/presentation/screens/error/error_page.dart';

// Import all your screen files (you'll need to create these)
import '../screens/accounts/account_details_screen.dart';
import '../screens/accounts/account_transactions_screen.dart';
import '../screens/accounts/transfer_funds_screen.dart';
import '../screens/analytics/category_analytics_screen.dart';
import '../screens/analytics/income_expense_analytics_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
// Main screens
import '../screens/home/home_screen.dart';
import '../screens/accounts/account_list_screen.dart';
import '../screens/accounts/add_edit_account_screen.dart';

import '../screens/transactions/add_expense_screen.dart';
import '../screens/transactions/add_income_screen.dart';
import '../screens/transactions/dd_transfer_screen.dart';
import '../screens/transactions/duplicate_transaction_screen.dart';
import '../screens/transactions/receipt_view_screen.dart';
import '../screens/transactions/transaction_detail_screen.dart';
import '../screens/transactions/transaction_list_screen.dart';
import '../screens/transactions/add_edit_transaction_screen.dart';

import '../screens/categories/category_list_screen.dart';
import '../screens/categories/add_edit_category_screen.dart';

import '../screens/budgets/budget_list_screen.dart';
import '../screens/budgets/add_edit_budget_screen.dart';

import '../screens/goals/goal_list_screen.dart';
import '../screens/goals/add_edit_goal_screen.dart';

import '../screens/analytics/analytics_screen.dart';
import '../screens/split_expenses/split_expense_list_screen.dart';
import '../screens/split_expenses/add_edit_split_expense_screen.dart';

import '../screens/recurring/recurring_transaction_list_screen.dart';
import '../screens/recurring/add_edit_recurring_transaction_screen.dart';

import '../screens/settings/settings_screen.dart';
import '../screens/settings/security_settings_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/settings/currency_settings_screen.dart';
import '../screens/settings/theme_settings_screen.dart';
import '../screens/settings/language_settings_screen.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/transactions/voice_input_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final settingsState = ref.watch(settingsStateProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final currentLocation = state.matchedLocation;
      final settingsState = ref.read(settingsStateProvider);

      // IMPORTANT: Let splash handle its own navigation
      if (currentLocation == RouteNames.splash) {
        return null;
      }

      // IMPORTANT: Don't redirect if already on onboarding
      if (currentLocation == RouteNames.onboarding) {
        return null;
      }

      // Only redirect TO onboarding if first launch
      if (settingsState.isFirstLaunch &&
          currentLocation != RouteNames.onboarding &&
          currentLocation != RouteNames.splash) {
        return RouteNames.onboarding;
      }

      return null;
    },
    routes: [
      // Authentication & Onboarding Routes
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.auth,
        name: 'auth',
        redirect: (context, state) => RouteNames.login,
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Main Application Shell Route
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          // Home Route
          GoRoute(
            path: RouteNames.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Account Routes
          GoRoute(
            path: RouteNames.accounts,
            name: 'accounts',
            builder: (context, state) => const AccountListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-account',
                builder: (context, state) => const AddEditAccountScreen(),
              ),
              GoRoute(
                path: 'transfer',
                name: 'transfer-funds',
                builder: (context, state) => const TransferFundsScreen(),
              ),
              GoRoute(
                path: ':accountId',
                name: 'account-details',
                builder: (context, state) {
                  final accountId = state.pathParameters['accountId']!;
                  return AccountDetailsScreen(accountId: accountId);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'edit-account',
                    builder: (context, state) {
                      final accountId = state.pathParameters['accountId']!;
                      return AddEditAccountScreen(accountId: accountId);
                    },
                  ),
                  GoRoute(
                    path: 'transactions',
                    name: 'account-transactions',
                    builder: (context, state) {
                      final accountId = state.pathParameters['accountId']!;
                      return AccountTransactionsScreen(accountId: accountId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Transaction Routes
          GoRoute(
            path: RouteNames.transactions,
            name: 'transactions',
            builder: (context, state) => const TransactionListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-transaction',
                builder: (context, state) => const AddEditTransactionScreen(),
                routes: [
                  GoRoute(
                    path: 'income',
                    name: 'add-income',
                    builder: (context, state) => const AddIncomeScreen(),
                  ),
                  GoRoute(
                    path: 'expense',
                    name: 'add-expense',
                    builder: (context, state) => const AddExpenseScreen(),
                  ),
                  GoRoute(
                    path: 'transfer',
                    name: 'add-transfer',
                    builder: (context, state) => const AddTransferScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: 'voice-input',
                name: 'voice-input',
                builder: (context, state) => const VoiceInputScreen(),
              ),
              GoRoute(
                path: ':transactionId',
                name: 'transaction-details',
                builder: (context, state) {
                  final transactionId = state.pathParameters['transactionId']!;
                  return TransactionDetailScreen(transactionId: transactionId);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'edit-transaction',
                    builder: (context, state) {
                      final transactionId =
                          state.pathParameters['transactionId']!;
                      return AddEditTransactionScreen(
                          transactionId: transactionId);
                    },
                  ),
                  GoRoute(
                    path: 'duplicate',
                    name: 'duplicate-transaction',
                    builder: (context, state) {
                      final transactionId =
                          state.pathParameters['transactionId']!;
                      return DuplicateTransactionScreen(
                          transactionId: transactionId);
                    },
                  ),
                  GoRoute(
                    path: 'receipt',
                    name: 'receipt-view',
                    builder: (context, state) {
                      final transactionId =
                          state.pathParameters['transactionId']!;
                      return ReceiptViewScreen(transactionId: transactionId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Analytics Routes
          GoRoute(
            path: RouteNames.analytics,
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
            routes: [
              GoRoute(
                path: 'income-expense',
                name: 'income-expense-analytics',
                builder: (context, state) =>
                    const IncomeExpenseAnalyticsScreen(),
              ),
              GoRoute(
                path: 'categories',
                name: 'category-analytics',
                builder: (context, state) => const CategoryAnalyticsScreen(),
              ),
              // GoRoute(
              //   path: 'monthly',
              //   name: 'monthly-analytics',
              //   builder: (context, state) => const MonthlyAnalyticsScreen(),
              // ),
              // GoRoute(
              //   path: 'yearly',
              //   name: 'yearly-analytics',
              //   builder: (context, state) => const YearlyAnalyticsScreen(),
              // ),
              // GoRoute(
              //   path: 'custom',
              //   name: 'custom-analytics',
              //   builder: (context, state) => const CustomAnalyticsScreen(),
              // ),
              // GoRoute(
              //   path: 'financial-health',
              //   name: 'financial-health',
              //   builder: (context, state) => const FinancialHealthScreen(),
              // ),
              // GoRoute(
              //   path: 'export',
              //   name: 'export-data',
              //   builder: (context, state) => const ExportDataScreen(),
              // ),
            ],
          ),

          // More/Settings Section
          GoRoute(
            path: RouteNames.more,
            name: 'more',
            redirect: (context, state) => RouteNames.settings,
          ),

          // Category Routes
          GoRoute(
            path: RouteNames.categories,
            name: 'categories',
            builder: (context, state) => const CategoryListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-category',
                builder: (context, state) => const AddEditCategoryScreen(),
              ),
              // GoRoute(
              //   path: ':categoryId',
              //   name: 'category-details',
              //   builder: (context, state) {
              //     final categoryId = state.pathParameters['categoryId']!;
              //     return CategoryDetailsScreen(categoryId: categoryId);
              //   },
              //   routes: [
              //     GoRoute(
              //       path: 'edit',
              //       name: 'edit-category',
              //       builder: (context, state) {
              //         final categoryId = state.pathParameters['categoryId']!;
              //         return AddEditCategoryScreen(categoryId: categoryId);
              //       },
              //     ),
              //   ],
              // ),
            ],
          ),

          // Budget Routes
          GoRoute(
            path: RouteNames.budgets,
            name: 'budgets',
            builder: (context, state) => const BudgetListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-budget',
                builder: (context, state) => const AddEditBudgetScreen(),
              ),
              // GoRoute(
              //   path: ':budgetId',
              //   name: 'budget-details',
              //   builder: (context, state) {
              //     final budgetId = state.pathParameters['budgetId']!;
              //     return BudgetDetailsScreen(budgetId: budgetId);
              //   },
              //   routes: [
              //     GoRoute(
              //       path: 'edit',
              //       name: 'edit-budget',
              //       builder: (context, state) {
              //         final budgetId = state.pathParameters['budgetId']!;
              //         return AddEditBudgetScreen(budgetId: budgetId);
              //       },
              //     ),
              //   ],
              // ),
            ],
          ),

          // Goal Routes
          // GoRoute(
          //   path: RouteNames.goals,
          //   name: 'goals',
          //   builder: (context, state) => const GoalListScreen(),
          //   routes: [
          //     GoRoute(
          //       path: 'add',
          //       name: 'add-goal',
          //       builder: (context, state) => const AddEditGoalScreen(),
          //     ),
          //     GoRoute(
          //       path: ':goalId',
          //       name: 'goal-details',
          //       builder: (context, state) {
          //         final goalId = state.pathParameters['goalId']!;
          //         return GoalDetailsScreen(goalId: goalId);
          //       },
          //       routes: [
          //         GoRoute(
          //           path: 'edit',
          //           name: 'edit-goal',
          //           builder: (context, state) {
          //             final goalId = state.pathParameters['goalId']!;
          //             return AddEditGoalScreen(goalId: goalId);
          //           },
          //         ),
          //       ],
          //     ),
          //   ],
          // ),

          // Achievement Routes
          // GoRoute(
          //   path: RouteNames.achievements,
          //   name: 'achievements',
          //   builder: (context, state) => const AchievementListScreen(),
          //   routes: [
          //     GoRoute(
          //       path: ':achievementId',
          //       name: 'achievement-details',
          //       builder: (context, state) {
          //         final achievementId = state.pathParameters['achievementId']!;
          //         return AchievementDetailsScreen(achievementId: achievementId);
          //       },
          //     ),
          //   ],
          // ),

          // Split Expenses Routes
          // GoRoute(
          //   path: RouteNames.splitExpenses,
          //   name: 'split-expenses',
          //   builder: (context, state) => const SplitExpenseListScreen(),
          //   routes: [
          //     GoRoute(
          //       path: 'add',
          //       name: 'add-split-expense',
          //       builder: (context, state) => const AddEditSplitExpenseScreen(),
          //     ),
          //     GoRoute(
          //       path: ':expenseId',
          //       name: 'split-expense-details',
          //       builder: (context, state) {
          //         final expenseId = state.pathParameters['expenseId']!;
          //         return SplitExpenseDetailsScreen(expenseId: expenseId);
          //       },
          //       routes: [
          //         GoRoute(
          //           path: 'edit',
          //           name: 'edit-split-expense',
          //           builder: (context, state) {
          //             final expenseId = state.pathParameters['expenseId']!;
          //             return AddEditSplitExpenseScreen(expenseId: expenseId);
          //           },
          //         ),
          //       ],
          //     ),
          //   ],
          // ),

          // Recurring Transactions Routes
          GoRoute(
            path: RouteNames.recurringTransactions,
            name: 'recurring-transactions',
            builder: (context, state) => const RecurringTransactionListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-recurring-transaction',
                builder: (context, state) =>
                    const AddEditRecurringTransactionScreen(),
              ),
              // GoRoute(
              //   path: ':recurringId',
              //   name: 'recurring-transaction-details',
              //   builder: (context, state) {
              //     final recurringId = state.pathParameters['recurringId']!;
              //     return RecurringTransactionDetailsScreen(
              //         recurringId: recurringId);
              //   },
              //   routes: [
              //     GoRoute(
              //       path: 'edit',
              //       name: 'edit-recurring-transaction',
              //       builder: (context, state) {
              //         final recurringId = state.pathParameters['recurringId']!;
              //         return AddEditRecurringTransactionScreen(
              //             recurringId: recurringId);
              //       },
              //     ),
              //   ],
              // ),
            ],
          ),

          // Settings & Profile Routes
          GoRoute(
            path: RouteNames.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              // GoRoute(
              //   path: 'security',
              //   name: 'security-settings',
              //   builder: (context, state) => const SecuritySettingsScreen(),
              // ),
              GoRoute(
                path: 'notifications',
                name: 'notification-settings',
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
              GoRoute(
                path: 'currency',
                name: 'currency-settings',
                builder: (context, state) => const CurrencySettingsScreen(),
              ),
              // GoRoute(
              //   path: 'theme',
              //   name: 'theme-settings',
              //   builder: (context, state) => const ThemeSettingsScreen(),
              // ),
              GoRoute(
                path: 'language',
                name: 'language-settings',
                builder: (context, state) => const LanguageSettingsScreen(),
              ),
              // GoRoute(
              //   path: 'data',
              //   name: 'data-settings',
              //   builder: (context, state) => const DataSettingsScreen(),
              // ),
              // GoRoute(
              //   path: 'about',
              //   name: 'about-app',
              //   builder: (context, state) => const AboutAppScreen(),
              // ),
              // GoRoute(
              //   path: 'privacy',
              //   name: 'privacy-policy',
              //   builder: (context, state) => const PrivacyPolicyScreen(),
              // ),
              // GoRoute(
              //   path: 'terms',
              //   name: 'terms-of-service',
              //   builder: (context, state) => const TermsOfServiceScreen(),
              // ),
            ],
          ),

          // Profile Routes
          // GoRoute(
          //   path: RouteNames.profile,
          //   name: 'profile',
          //   builder: (context, state) => const ProfileScreen(),
          //   routes: [
          //     GoRoute(
          //       path: 'edit',
          //       name: 'edit-profile',
          //       builder: (context, state) => const EditProfileScreen(),
          //     ),
          //     GoRoute(
          //       path: 'change-password',
          //       name: 'change-password',
          //       builder: (context, state) => const ChangePasswordScreen(),
          //     ),
          //   ],
          // ),

          // Backup Routes
          // GoRoute(
          //   path: RouteNames.backup,
          //   name: 'backup',
          //   builder: (context, state) => const BackupScreen(),
          //   routes: [
          //     GoRoute(
          //       path: 'restore',
          //       name: 'backup-restore',
          //       builder: (context, state) => const BackupRestoreScreen(),
          //     ),
          //     GoRoute(
          //       path: 'history',
          //       name: 'backup-history',
          //       builder: (context, state) => const BackupHistoryScreen(),
          //     ),
          //     GoRoute(
          //       path: 'export',
          //       name: 'data-export',
          //       builder: (context, state) => const DataExportScreen(),
          //     ),
          //     GoRoute(
          //       path: 'import',
          //       name: 'data-import',
          //       builder: (context, state) => const DataImportScreen(),
          //     ),
          //   ],
          // ),

          // Help & Support Routes
          // GoRoute(
          //   path: RouteNames.help,
          //   name: 'help',
          //   builder: (context, state) => const HelpScreen(),
          //   routes: [
          //     GoRoute(
          //       path: 'contact',
          //       name: 'contact',
          //       builder: (context, state) => const ContactScreen(),
          //     ),
          //     GoRoute(
          //       path: 'feedback',
          //       name: 'feedback',
          //       builder: (context, state) => const FeedbackScreen(),
          //     ),
          //     GoRoute(
          //       path: ':topicId',
          //       name: 'help-topic',
          //       builder: (context, state) {
          //         final topicId = state.pathParameters['topicId']!;
          //         return HelpTopicScreen(topicId: topicId);
          //       },
          //     ),
          //   ],
          // ),
        ],
      ),

      // Modal/Overlay Routes (outside of shell)
      // GoRoute(
      //   path: RouteNames.quickAdd,
      //   name: 'quick-add',
      //   builder: (context, state) => const QuickAddScreen(),
      // ),
      // GoRoute(
      //   path: RouteNames.calculator,
      //   name: 'calculator',
      //   builder: (context, state) => const CalculatorScreen(),
      // ),
      // GoRoute(
      //   path: RouteNames.currencyConverter,
      //   name: 'currency-converter',
      //   builder: (context, state) => const CurrencyConverterScreen(),
      // ),
      // GoRoute(
      //   path: RouteNames.scanner,
      //   name: 'scanner',
      //   builder: (context, state) => const ScannerScreen(),
      // ),

      // // Error Routes
      // GoRoute(
      //   path: RouteNames.notFound,
      //   name: 'not-found',
      //   builder: (context, state) => const NotFoundScreen(),
      // ),
      // GoRoute(
      //   path: RouteNames.error,
      //   name: 'error',
      //   builder: (context, state) => const ErrorScreen(),
      // ),
    ],
  );
});
