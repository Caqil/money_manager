import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';
import '../../routes/route_names.dart';

class FloatingQuickAdd extends StatelessWidget {
  const FloatingQuickAdd({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton(
      onPressed: () => _showQuickAddMenu(context),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: AppDimensions.elevationL,
      child: const Icon(Icons.add_rounded),
    );
  }

  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickAddMenu(),
    );
  }
}

class QuickAddMenu extends StatelessWidget {
  const QuickAddMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              Text(
                'quickActions.addExpense'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: AppDimensions.spacingM,
                mainAxisSpacing: AppDimensions.spacingM,
                childAspectRatio: 1,
                children: [
                  _QuickAddItem(
                    icon: Icons.remove_circle_outline,
                    label: 'transactions.types.expense'.tr(),
                    color: AppColors.error,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouteNames.addExpense);
                    },
                  ),
                  _QuickAddItem(
                    icon: Icons.add_circle_outline,
                    label: 'transactions.types.income'.tr(),
                    color: AppColors.success,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouteNames.addIncome);
                    },
                  ),
                  _QuickAddItem(
                    icon: Icons.swap_horiz_rounded,
                    label: 'transactions.types.transfer'.tr(),
                    color: AppColors.info,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouteNames.addTransfer);
                    },
                  ),
                  _QuickAddItem(
                    icon: Icons.camera_alt_outlined,
                    label: 'quickActions.scan'.tr(),
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouteNames.scanner);
                    },
                  ),
                  _QuickAddItem(
                    icon: Icons.calculate_outlined,
                    label: 'Calculator',
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouteNames.calculator);
                    },
                  ),
                  _QuickAddItem(
                    icon: Icons.currency_exchange_rounded,
                    label: 'Currency',
                    color: theme.colorScheme.primary,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouteNames.currencyConverter);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingL),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAddItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAddItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppDimensions.iconL,
                color: color,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
