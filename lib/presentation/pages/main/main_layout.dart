import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/route_names.dart';
import '../../widgets/navigation/navigation_shell.dart';
import '../../widgets/navigation/floating_quick_add.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final showFAB = _shouldShowFloatingActionButton(currentRoute);

    return NavigationShell(
      child: Scaffold(
        body: child,
        floatingActionButton: showFAB ? const FloatingQuickAdd() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  bool _shouldShowFloatingActionButton(String route) {
    // Show FAB on main navigation pages
    final mainRoutes = [
      RouteNames.home,
      RouteNames.accounts,
      RouteNames.transactions,
      RouteNames.analytics,
    ];

    return mainRoutes.any((mainRoute) => route == mainRoute);
  }
}
