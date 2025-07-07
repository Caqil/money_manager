import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/constants/dimensions.dart';
import '../../routes/route_names.dart';

class AppBottomNavigation extends StatelessWidget {
  final String currentRoute;

  const AppBottomNavigation({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = _getCurrentIndex(currentRoute);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: AppDimensions.elevationL,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: AppDimensions.bottomNavHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildNavigationItems(context, currentIndex),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavigationItems(BuildContext context, int currentIndex) {
    final items = [
      _NavigationItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'navigation.home'.tr(),
        route: RouteNames.home,
        isActive: currentIndex == 0,
        badge: null,
      ),
      _NavigationItem(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
        label: 'navigation.accounts'.tr(),
        route: RouteNames.accounts,
        isActive: currentIndex == 1,
        badge: null,
      ),
      _NavigationItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'navigation.transactions'.tr(),
        route: RouteNames.transactions,
        isActive: currentIndex == 2,
        badge: null,
      ),
      _NavigationItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: 'navigation.analytics'.tr(),
        route: RouteNames.analytics,
        isActive: currentIndex == 3,
        badge: null,
      ),
      _NavigationItem(
        icon: Icons.more_horiz_outlined,
        activeIcon: Icons.more_horiz_rounded,
        label: 'common.more'.tr(),
        route: RouteNames.more,
        isActive: currentIndex == 4,
        badge: null,
      ),
    ];

    return items
        .map((item) => _NavigationItemWidget(
              item: item,
              onTap: () => _onItemTapped(context, item.route),
            ))
        .toList();
  }

  void _onItemTapped(BuildContext context, String route) {
    if (currentRoute != route) {
      context.go(route);
    }
  }

  int _getCurrentIndex(String route) {
    // Handle sub-routes by checking the base route
    if (route.startsWith('/accounts')) return 1;
    if (route.startsWith('/transactions')) return 2;
    if (route.startsWith('/analytics')) return 3;
    if (route.startsWith('/more') || _isMoreSubRoute(route)) return 4;
    return 0; // Default to home
  }

  bool _isMoreSubRoute(String route) {
    final moreSubRoutes = [
      RouteNames.categories,
      RouteNames.budgets,
      RouteNames.goals,
      RouteNames.achievements,
      RouteNames.splitExpenses,
      RouteNames.recurringTransactions,
      RouteNames.settings,
      RouteNames.profile,
      RouteNames.backup,
      RouteNames.help,
    ];

    return moreSubRoutes.any((subRoute) => route.startsWith(subRoute));
  }
}

class _NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isActive;
  final Widget? badge;

  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.isActive,
    this.badge,
  });
}

class _NavigationItemWidget extends StatelessWidget {
  final _NavigationItem item;
  final VoidCallback onTap;

  const _NavigationItemWidget({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingXs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        item.isActive ? item.activeIcon : item.icon,
                        key: ValueKey(item.isActive),
                        size: AppDimensions.iconM,
                        color: item.isActive
                            ? colorScheme.primary
                            : colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    if (item.badge != null)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: item.badge!,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: item.isActive
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.6),
                    fontWeight:
                        item.isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
