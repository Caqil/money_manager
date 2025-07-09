import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'route_names.dart';

class RouteUtils {
  RouteUtils._();

  // Navigation helpers
  static void navigateTo(BuildContext context, String route, {Object? extra}) {
    context.go(route, extra: extra);
  }

  static void pushTo(BuildContext context, String route, {Object? extra}) {
    context.push(route, extra: extra);
  }

  static void replaceTo(BuildContext context, String route, {Object? extra}) {
    context.pushReplacement(route, extra: extra);
  }

  static void pop(BuildContext context, [Object? result]) {
    context.pop(result);
  }

  static bool canPop(BuildContext context) {
    return context.canPop();
  }

  // Parameter builders
  static String buildAccountRoute(String accountId) {
    return RouteNames.accountDetails.replaceAll(':accountId', accountId);
  }

  static String buildTransactionRoute(String transactionId) {
    return RouteNames.transactionDetails
        .replaceAll(':transactionId', transactionId);
  }

  static String buildEditAccountRoute(String accountId) {
    return RouteNames.editAccount.replaceAll(':accountId', accountId);
  }

  static String buildEditTransactionRoute(String transactionId) {
    return RouteNames.editTransaction
        .replaceAll(':transactionId', transactionId);
  }

  static String buildCategoryRoute(String categoryId) {
    return RouteNames.categoryDetails.replaceAll(':categoryId', categoryId);
  }

  static String buildBudgetRoute(String budgetId) {
    return RouteNames.budgetDetails.replaceAll(':budgetId', budgetId);
  }

  static String buildGoalRoute(String goalId) {
    return RouteNames.goalDetails.replaceAll(':goalId', goalId);
  }

  static String buildSplitExpenseRoute(String expenseId) {
    return RouteNames.splitExpenseDetails.replaceAll(':expenseId', expenseId);
  }

  static String buildRecurringRoute(String recurringId) {
    return RouteNames.recurringTransactionDetails
        .replaceAll(':recurringId', recurringId);
  }

  static String buildAchievementRoute(String achievementId) {
    return RouteNames.achievementDetails
        .replaceAll(':achievementId', achievementId);
  }


  // Query parameter helpers
  static String buildRouteWithQuery(
      String route, Map<String, String> queryParams) {
    if (queryParams.isEmpty) return route;

    final uri = Uri.parse(route);
    final newUri = uri.replace(queryParameters: queryParams);
    return newUri.toString();
  }

  // Navigation with parameters
  static void navigateToAccount(BuildContext context, String accountId) {
    context.go(buildAccountRoute(accountId));
  }

  static void navigateToTransaction(
      BuildContext context, String transactionId) {
    context.go(buildTransactionRoute(transactionId));
  }

  static void navigateToEditAccount(BuildContext context, String accountId) {
    context.push(buildEditAccountRoute(accountId));
  }

  static void navigateToEditTransaction(
      BuildContext context, String transactionId) {
    context.push(buildEditTransactionRoute(transactionId));
  }

  static void navigateToCategory(BuildContext context, String categoryId) {
    context.go(buildCategoryRoute(categoryId));
  }

  static void navigateToBudget(BuildContext context, String budgetId) {
    context.go(buildBudgetRoute(budgetId));
  }

  static void navigateToGoal(BuildContext context, String goalId) {
    context.go(buildGoalRoute(goalId));
  }

  // Quick navigation helpers
  static void goToHome(BuildContext context) {
    context.go(RouteNames.home);
  }

  static void goToAccounts(BuildContext context) {
    context.go(RouteNames.accounts);
  }

  static void goToTransactions(BuildContext context) {
    context.go(RouteNames.transactions);
  }

  static void goToAnalytics(BuildContext context) {
    context.go(RouteNames.analytics);
  }

  static void goToMore(BuildContext context) {
    context.go(RouteNames.more);
  }

  static void goToSettings(BuildContext context) {
    context.go(RouteNames.settings);
  }

  // Modal navigation
  static Future<T?> showModalRoute<T>(
    BuildContext context,
    Widget child, {
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => child,
    );
  }


  // Get current route name
  static String getCurrentRoute(BuildContext context) {
    final routerDelegate = GoRouter.of(context).routerDelegate;
    return routerDelegate.currentConfiguration.uri.toString();
  }

  // Check if current route matches
  static bool isCurrentRoute(BuildContext context, String route) {
    return getCurrentRoute(context) == route;
  }

  // Bottom navigation index mapping
  static int getBottomNavIndex(String route) {
    switch (route) {
      case RouteNames.home:
        return 0;
      case RouteNames.accounts:
        return 1;
      case RouteNames.transactions:
        return 2;
      case RouteNames.analytics:
        return 3;
      case RouteNames.more:
        return 4;
      default:
        return 0;
    }
  }

  static String getRouteFromBottomNavIndex(int index) {
    switch (index) {
      case 0:
        return RouteNames.home;
      case 1:
        return RouteNames.accounts;
      case 2:
        return RouteNames.transactions;
      case 3:
        return RouteNames.analytics;
      case 4:
        return RouteNames.more;
      default:
        return RouteNames.home;
    }
  }
}
