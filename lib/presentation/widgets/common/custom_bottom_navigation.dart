import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<BottomNavigationItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;
  final bool showLabels;
  final bool showSelectedLabels;
  final bool showUnselectedLabels;
  final double? selectedFontSize;
  final double? unselectedFontSize;
  final IconThemeData? selectedIconTheme;
  final IconThemeData? unselectedIconTheme;
  final EdgeInsetsGeometry? itemPadding;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
    this.showLabels = true,
    this.showSelectedLabels = true,
    this.showUnselectedLabels = true,
    this.selectedFontSize,
    this.unselectedFontSize,
    this.selectedIconTheme,
    this.unselectedIconTheme,
    this.itemPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine if we should use fixed or shifting type
    final type = items.length <= 3
        ? BottomNavigationBarType.fixed
        : BottomNavigationBarType.shifting;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.lightShadow,
            offset: const Offset(0, -1),
            blurRadius: elevation ?? AppDimensions.bottomNavElevation,
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: AppDimensions.bottomNavHeight,
          padding: itemPadding ??
              const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingS,
              ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return _buildNavigationItem(
                context,
                item,
                isSelected,
                () => onTap?.call(index),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    BottomNavigationItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveSelectedColor = selectedItemColor ?? colorScheme.primary;
    final effectiveUnselectedColor =
        unselectedItemColor ?? colorScheme.onSurface.withOpacity(0.6);

    final itemColor =
        isSelected ? effectiveSelectedColor : effectiveUnselectedColor;
    final iconSize = isSelected
        ? (selectedIconTheme?.size ?? AppDimensions.iconM)
        : (unselectedIconTheme?.size ?? AppDimensions.iconM);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingS,
              horizontal: AppDimensions.paddingXs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with badge support
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isSelected ? item.activeIcon ?? item.icon : item.icon,
                      color: itemColor,
                      size: iconSize,
                    ),
                    if (item.badge != null)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: item.badge!,
                      ),
                  ],
                ),

                // Label
                if (_shouldShowLabel(isSelected)) ...[
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    item.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: itemColor,
                      fontSize: isSelected
                          ? (selectedFontSize ?? 12.0)
                          : (unselectedFontSize ?? 11.0),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowLabel(bool isSelected) {
    if (!showLabels) return false;
    if (isSelected && !showSelectedLabels) return false;
    if (!isSelected && !showUnselectedLabels) return false;
    return true;
  }
}

/// Navigation item data class
class BottomNavigationItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Widget? badge;
  final Color? backgroundColor;
  final String? tooltip;

  const BottomNavigationItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badge,
    this.backgroundColor,
    this.tooltip,
  });
}

/// Predefined bottom navigation for the money manager app
class MoneyManagerBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Map<String, int>? badges;

  const MoneyManagerBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomNavigation(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        BottomNavigationItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'navigation.home'.tr(),
          badge: _buildBadge('home'),
        ),
        BottomNavigationItem(
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
          label: 'navigation.accounts'.tr(),
          badge: _buildBadge('accounts'),
        ),
        BottomNavigationItem(
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long_rounded,
          label: 'navigation.transactions'.tr(),
          badge: _buildBadge('transactions'),
        ),
        BottomNavigationItem(
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart_rounded,
          label: 'navigation.analytics'.tr(),
          badge: _buildBadge('analytics'),
        ),
        BottomNavigationItem(
          icon: Icons.more_horiz_outlined,
          activeIcon: Icons.more_horiz_rounded,
          label: 'common.more'.tr(),
          badge: _buildBadge('more'),
        ),
      ],
    );
  }

  Widget? _buildBadge(String key) {
    final count = badges?[key];
    if (count == null || count <= 0) return null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingXs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircular),
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Floating action button aware bottom navigation
class BottomNavigationWithFAB extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<BottomNavigationItem> items;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final bool notchMargin;

  const BottomNavigationWithFAB({
    super.key,
    required this.currentIndex,
    this.onTap,
    required this.items,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.notchMargin = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BottomAppBar(
      color: backgroundColor ?? theme.colorScheme.surface,
      elevation: AppDimensions.bottomNavElevation,
      notchMargin: notchMargin ? AppDimensions.spacingS : 0,
      shape: floatingActionButton != null
          ? const CircularNotchedRectangle()
          : null,
      child: Container(
        height: AppDimensions.bottomNavHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _buildItemsWithNotch(),
        ),
      ),
    );
  }

  List<Widget> _buildItemsWithNotch() {
    final List<Widget> children = [];
    final isEvenCount = items.length % 2 == 0;
    final middleIndex = items.length ~/ 2;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isSelected = i == currentIndex;

      children.add(
        _buildNavigationItem(
          item,
          isSelected,
          () => onTap?.call(i),
        ),
      );

      // Add spacer for FAB if this is the middle position
      if (floatingActionButton != null && isEvenCount && i == middleIndex - 1) {
        children.add(const SizedBox(width: AppDimensions.spacingXl));
      } else if (floatingActionButton != null &&
          !isEvenCount &&
          i == middleIndex) {
        children.add(const SizedBox(width: AppDimensions.spacingXl));
      }
    }

    return children;
  }

  Widget _buildNavigationItem(
    BottomNavigationItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingS,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? item.activeIcon ?? item.icon : item.icon,
                  color: isSelected
                      ? (selectedItemColor ?? AppColors.primary)
                      : (unselectedItemColor ?? Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (selectedItemColor ?? AppColors.primary)
                        : (unselectedItemColor ?? Colors.grey[600]),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
