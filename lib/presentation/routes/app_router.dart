// lib/presentation/routes/app_router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/presentation/pages/main/main_layout.dart';
import 'package:money_manager/presentation/screens/error/error_page.dart';

// Import all your screen files
import '../screens/accounts/account_details_screen.dart';
import '../screens/accounts/account_transactions_screen.dart';
import '../screens/accounts/transfer_funds_screen.dart';
import '../screens/analytics/category_analytics_screen.dart';
import '../screens/analytics/custom_analytics_screen.dart';
import '../screens/analytics/financial_health_screen.dart';
import '../screens/analytics/income_expense_analytics_screen.dart';
import '../screens/analytics/monthly_analytics_screen.dart';
import '../screens/analytics/yearly_analytics_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
// Main screens
import '../screens/home/home_screen.dart';
import '../screens/accounts/account_list_screen.dart';
import '../screens/accounts/add_edit_account_screen.dart';

import '../screens/transactions/add_expense_screen.dart';
import '../screens/transactions/add_income_screen.dart';
import '../screens/transactions/add_transfer_screen.dart';
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
  // FIXED: Only watch specific values that affect routing, not the entire state
  // This prevents rebuilds when settings are loading/updating
  final authState = ref.watch(authStateProvider);
  final isFirstLaunch = ref.watch(isFirstLaunchProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final currentLocation = state.matchedLocation;

      // FIXED: Add navigation guard to prevent redirects during normal app usage
      final isInMainApp = currentLocation.startsWith('/') &&
          currentLocation != RouteNames.splash &&
          currentLocation != RouteNames.onboarding &&
          currentLocation != RouteNames.login;

      print('🧭 Router Redirect Check:');
      print('  Current: $currentLocation');
      print('  IsInMainApp: $isInMainApp');
      print('  FirstLaunch: $isFirstLaunch');
      print('  Auth: ${authState.isAuthenticated}');

      // IMPORTANT: Let splash handle its own navigation - no redirects from splash
      if (currentLocation == RouteNames.splash) {
        print('🎯 At splash - no redirect');
        return null;
      }

      // IMPORTANT: Don't redirect if already on onboarding
      if (currentLocation == RouteNames.onboarding) {
        print('🎯 At onboarding - no redirect');
        return null;
      }

      // FIXED: Don't redirect if user is already using the main app
      // This prevents the settings action issue
      if (isInMainApp) {
        print('🎯 In main app - no redirect needed');
        return null;
      }

      // Only redirect TO onboarding if first launch AND not in main app
      if (isFirstLaunch &&
          !isInMainApp &&
          currentLocation != RouteNames.onboarding &&
          currentLocation != RouteNames.splash) {
        print('🎯 Redirecting to onboarding');
        return RouteNames.onboarding;
      }

      // Auth redirects only for specific routes
      final requiresAuth = [
        RouteNames.home,
        RouteNames.accounts,
        RouteNames.transactions,
        RouteNames.analytics,
      ].any((route) => currentLocation.startsWith(route));

      if (requiresAuth &&
          authState.isPinEnabled &&
          !authState.isAuthenticated &&
          currentLocation != RouteNames.login) {
        print('🎯 Redirecting to login');
        return RouteNames.login;
      }

      print('🎯 No redirect needed');
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
              ),
              GoRoute(
                path: 'add-income',
                name: 'add-income',
                builder: (context, state) => const AddIncomeScreen(),
              ),
              GoRoute(
                path: 'add-expense',
                name: 'add-expense',
                builder: (context, state) => const AddExpenseScreen(),
              ),
              // GoRoute(
              //   path: 'transfer',
              //   name: 'dd-transfer',
              //   builder: (context, state) => const DdTransferScreen(),
              // ),
              GoRoute(
                path: 'voice',
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
              GoRoute(
                path: ':categoryId/edit',
                name: 'edit-category',
                builder: (context, state) {
                  final categoryId = state.pathParameters['categoryId']!;
                  return AddEditCategoryScreen(categoryId: categoryId);
                },
              ),
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
              GoRoute(
                path: ':budgetId/edit',
                name: 'edit-budget',
                builder: (context, state) {
                  final budgetId = state.pathParameters['budgetId']!;
                  return AddEditBudgetScreen(budgetId: budgetId);
                },
              ),
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
          //       path: ':goalId/edit',
          //       name: 'edit-goal',
          //       builder: (context, state) {
          //         final goalId = state.pathParameters['goalId']!;
          //         return AddEditGoalScreen(goalId: goalId);
          //       },
          //     ),
          //   ],
          // ),

          // Analytics Routes
          GoRoute(
            path: RouteNames.analytics,
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
            routes: [
              GoRoute(
                path: 'monthly',
                name: 'monthly-analytics',
                builder: (context, state) => const MonthlyAnalyticsScreen(),
              ),
              GoRoute(
                path: 'yearly',
                name: 'yearly-analytics',
                builder: (context, state) => const YearlyAnalyticsScreen(),
              ),
              GoRoute(
                path: 'categories',
                name: 'category-analytics',
                builder: (context, state) => const CategoryAnalyticsScreen(),
              ),
              GoRoute(
                path: 'income-expense',
                name: 'income-expense-analytics',
                builder: (context, state) =>
                    const IncomeExpenseAnalyticsScreen(),
              ),
              GoRoute(
                path: 'financial-health',
                name: 'financial-health',
                builder: (context, state) => const FinancialHealthScreen(),
              ),
              GoRoute(
                path: 'custom',
                name: 'custom-analytics',
                builder: (context, state) => const CustomAnalyticsScreen(),
              ),
            ],
          ),

          // Split Expense Routes
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
          //       path: ':expenseId/edit',
          //       name: 'edit-split-expense',
          //       builder: (context, state) {
          //         final expenseId = state.pathParameters['expenseId']!;
          //         return AddEditSplitExpenseScreen(expenseId: expenseId);
          //       },
          //     ),
          //   ],
          // ),

          // // Recurring Transaction Routes
          // GoRoute(
          //   path: RouteNames.recurring,
          //   name: 'recurring',
          //   builder: (context, state) => const RecurringTransactionListScreen(),
          //   routes: [
          //     GoRoute(
          //       path: 'add',
          //       name: 'add-recurring',
          //       builder: (context, state) =>
          //           const AddEditRecurringTransactionScreen(),
          //     ),
          //     GoRoute(
          //       path: ':recurringId/edit',
          //       name: 'edit-recurring',
          //       builder: (context, state) {
          //         final recurringId = state.pathParameters['recurringId']!;
          //         return AddEditRecurringTransactionScreen(
          //             recurringId: recurringId);
          //       },
          //     ),
          //   ],
          // ),

          // Settings Routes
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
              // Commented out until screens are created
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
            ],
          ),
        ],
      ),
    ],
  );
});
