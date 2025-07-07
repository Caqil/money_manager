// lib/presentation/routes/app_router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/presentation/pages/main/main_layout.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/transactions/transaction_list_screen.dart';
import '../screens/transactions/add_edit_transaction_screen.dart';
import '../screens/budgets/budget_list_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/accounts/account_list_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../providers/settings_provider.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {

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
      // Public routes (no authentication required)
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
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Protected routes (require authentication if enabled)
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: RouteNames.transactions,
            name: 'transactions',
            builder: (context, state) => const TransactionListScreen(),
            routes: [
              GoRoute(
                path: '/add',
                name: 'add-transaction',
                builder: (context, state) => const AddEditTransactionScreen(),
              ),
              GoRoute(
                path: '/edit/:id',
                name: 'edit-transaction',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AddEditTransactionScreen(transactionId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.budgets,
            name: 'budgets',
            builder: (context, state) => const BudgetListScreen(),
          ),
          GoRoute(
            path: RouteNames.analytics,
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: RouteNames.accounts,
            name: 'accounts',
            builder: (context, state) => const AccountListScreen(),
          ),
          GoRoute(
            path: RouteNames.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
