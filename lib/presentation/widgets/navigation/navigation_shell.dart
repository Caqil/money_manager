import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/route_names.dart';
import 'app_bottom_navigation.dart';

class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final shouldShowBottomNav = _shouldShowBottomNavigation(currentRoute);

    return Scaffold(
      body: child,
      bottomNavigationBar: shouldShowBottomNav
          ? AppBottomNavigation(currentRoute: currentRoute)
          : null,
    );
  }

  bool _shouldShowBottomNavigation(String route) {
    // Define routes where bottom navigation should be hidden
    final hiddenRoutes = [
      RouteNames.splash,
      RouteNames.onboarding,
      RouteNames.login,
      RouteNames.register,
      RouteNames.forgotPassword,
      RouteNames.resetPassword,
      RouteNames.error,
      RouteNames.notFound,
    ];

    // Hide on auth routes
    if (hiddenRoutes.any((hiddenRoute) => route.startsWith(hiddenRoute))) {
      return false;
    }

    // Hide on modal routes
    final modalRoutes = [
      RouteNames.quickAdd,
      RouteNames.calculator,
      RouteNames.currencyConverter,
      RouteNames.scanner,
    ];

    if (modalRoutes.any((modalRoute) => route.startsWith(modalRoute))) {
      return false;
    }

    // Hide on form/add/edit pages (optional)
    if (route.contains('/add') || route.contains('/edit')) {
      // Uncomment to hide bottom nav on add/edit pages
      // return false;
    }

    return true;
  }
}
