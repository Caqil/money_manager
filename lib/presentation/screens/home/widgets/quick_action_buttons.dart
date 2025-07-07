import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';

class QuickActionButtons extends ConsumerWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    Icons.flash_on,
                    color: AppColors.accent,
                    size: AppDimensions.iconM,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Text(
                  'dashboard.quickAdd'.tr(),
                  style: theme.textTheme.h4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spacingM),

            // Action Buttons Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppDimensions.spacingS,
              crossAxisSpacing: AppDimensions.spacingS,
              childAspectRatio: 2.2,
              children: [
                _buildActionButton(
                  context: context,
                  icon: Icons.remove_circle_outline,
                  label: 'quickActions.addExpense'.tr(),
                  color: AppColors.error,
                  onTap: () => context.push('/transactions/add?type=expense'),
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.add_circle_outline,
                  label: 'quickActions.addIncome'.tr(),
                  color: AppColors.success,
                  onTap: () => context.push('/transactions/add?type=income'),
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.swap_horiz,
                  label: 'quickActions.transfer'.tr(),
                  color: AppColors.primary,
                  onTap: () => context.push('/transfer'),
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.receipt_long,
                  label: 'quickActions.scan'.tr(),
                  color: AppColors.secondary,
                  onTap: () => context.push('/scan-receipt'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = ShadTheme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: AppDimensions.iconM,
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                label,
                style: theme.textTheme.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
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
