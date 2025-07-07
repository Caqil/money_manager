import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/presentation/pages/main/main_layout.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/transactions/transaction_list_screen.dart';
import '../screens/transactions/add_edit_transaction_screen.dart';
import '../screens/budgets/budget_list_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/accounts/account_list_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../providers/auth_provider.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    // redirect: (context, state) {
    //   final isAuthenticated = authState.isAuthenticated;
    //   final isOnAuthPages = state.matchedLocation.startsWith('/auth') ||
    //       state.matchedLocation == RouteNames.splash;

    //   if (!isAuthenticated && !isOnAuthPages) {
    //     return RouteNames.login;
    //   }

    //   if (isAuthenticated &&
    //       isOnAuthPages &&
    //       state.matchedLocation != RouteNames.splash) {
    //     return RouteNames.home;
    //   }

    //   return null;
    // },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
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
          // GoRoute(
          //   path: RouteNames.goals,
          //   name: 'goals',
          //   builder: (context, state) => const GoalListScreen(),
          // ),
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
