import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';

class EmptyStateWidget extends StatelessWidget {
  final Widget? icon;
  final IconData? iconData;
  final String? title;
  final String? message;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final Widget? illustration;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final EdgeInsetsGeometry? padding;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool showAction;

  const EmptyStateWidget({
    super.key,
    this.icon,
    this.iconData,
    this.title,
    this.message,
    this.actionText,
    this.onActionPressed,
    this.illustration,
    this.iconSize,
    this.iconColor,
    this.titleStyle,
    this.messageStyle,
    this.padding,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.showAction = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          // Illustration or Icon
          if (illustration != null)
            illustration!
          else if (icon != null)
            icon!
          else if (iconData != null)
            Icon(
              iconData!,
              size: iconSize ?? AppDimensions.iconXxl,
              color: iconColor ?? colorScheme.onSurface.withOpacity(0.4),
            ),

          const SizedBox(height: AppDimensions.spacingL),

          // Title
          if (title != null)
            Text(
              title!,
              style: titleStyle ??
                  theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: AppDimensions.spacingM),

          // Message
          if (message != null)
            Text(
              message!,
              style: messageStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: AppDimensions.spacingL),

          // Action Button
          if (showAction && actionText != null && onActionPressed != null)
            ShadButton(
              onPressed: onActionPressed,
              child: Text(actionText!),
            ),
        ],
      ),
    );
  }
}

/// Empty state for transactions
class TransactionsEmptyState extends StatelessWidget {
  final VoidCallback? onAddTransaction;
  final String? customMessage;

  const TransactionsEmptyState({
    super.key,
    this.onAddTransaction,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.receipt_long_outlined,
      title: 'transactions.noTransactions'.tr(),
      message: customMessage ?? 'transactions.createFirstTransaction'.tr(),
      actionText: 'transactions.addTransaction'.tr(),
      onActionPressed: onAddTransaction,
    );
  }
}

/// Empty state for accounts
class AccountsEmptyState extends StatelessWidget {
  final VoidCallback? onAddAccount;
  final String? customMessage;

  const AccountsEmptyState({
    super.key,
    this.onAddAccount,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.account_balance_wallet_outlined,
      title: 'accounts.noAccounts'.tr(),
      message: customMessage ?? 'accounts.createFirstAccount'.tr(),
      actionText: 'accounts.addAccount'.tr(),
      onActionPressed: onAddAccount,
    );
  }
}

/// Empty state for budgets
class BudgetsEmptyState extends StatelessWidget {
  final VoidCallback? onAddBudget;
  final String? customMessage;

  const BudgetsEmptyState({
    super.key,
    this.onAddBudget,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.pie_chart_outline_outlined,
      title: 'budgets.noBudgets'.tr(),
      message: customMessage ?? 'budgets.createFirstBudget'.tr(),
      actionText: 'budgets.addBudget'.tr(),
      onActionPressed: onAddBudget,
    );
  }
}

/// Empty state for goals
class GoalsEmptyState extends StatelessWidget {
  final VoidCallback? onAddGoal;
  final String? customMessage;

  const GoalsEmptyState({
    super.key,
    this.onAddGoal,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.flag_outlined,
      title: 'goals.noGoals'.tr(),
      message: customMessage ?? 'goals.createFirstGoal'.tr(),
      actionText: 'goals.addGoal'.tr(),
      onActionPressed: onAddGoal,
    );
  }
}

/// Empty state for categories
class CategoriesEmptyState extends StatelessWidget {
  final VoidCallback? onAddCategory;
  final String? customMessage;

  const CategoriesEmptyState({
    super.key,
    this.onAddCategory,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.category_outlined,
      title: 'categories.noCategories'.tr(),
      message: customMessage ?? 'categories.createFirstCategory'.tr(),
      actionText: 'categories.addCategory'.tr(),
      onActionPressed: onAddCategory,
    );
  }
}

/// Empty state for search results
class SearchEmptyState extends StatelessWidget {
  final String? searchQuery;
  final VoidCallback? onClearSearch;
  final String? customMessage;

  const SearchEmptyState({
    super.key,
    this.searchQuery,
    this.onClearSearch,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.search_off_rounded,
      title: 'common.noResults'.tr(),
      message: customMessage ??
          (searchQuery != null
              ? 'common.noResultsFor'.tr(namedArgs: {'query': searchQuery!})
              : 'common.tryDifferentSearch'.tr()),
      actionText: onClearSearch != null ? 'common.clearSearch'.tr() : null,
      onActionPressed: onClearSearch,
    );
  }
}

/// Empty state for analytics/reports
class AnalyticsEmptyState extends StatelessWidget {
  final VoidCallback? onAddData;
  final String? customMessage;

  const AnalyticsEmptyState({
    super.key,
    this.onAddData,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.bar_chart_outlined,
      title: 'analytics.noData'.tr(),
      message: customMessage ?? 'analytics.addDataToSeeReports'.tr(),
      actionText: 'transactions.addTransaction'.tr(),
      onActionPressed: onAddData,
    );
  }
}

/// Empty state for recurring transactions
class RecurringEmptyState extends StatelessWidget {
  final VoidCallback? onAddRecurring;
  final String? customMessage;

  const RecurringEmptyState({
    super.key,
    this.onAddRecurring,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.repeat_rounded,
      title: 'recurring.noRecurringTransactions'.tr(),
      message: customMessage ?? 'recurring.createFirstRecurring'.tr(),
      actionText: 'recurring.addRecurringTransaction'.tr(),
      onActionPressed: onAddRecurring,
    );
  }
}

/// Empty state for split expenses
class SplitExpensesEmptyState extends StatelessWidget {
  final VoidCallback? onAddSplit;
  final String? customMessage;

  const SplitExpensesEmptyState({
    super.key,
    this.onAddSplit,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.call_split_rounded,
      title: 'splitExpenses.noSplitExpenses'.tr(),
      message: customMessage ?? 'splitExpenses.createFirstSplit'.tr(),
      actionText: 'splitExpenses.addSplitExpense'.tr(),
      onActionPressed: onAddSplit,
    );
  }
}

/// Empty state for achievements
class AchievementsEmptyState extends StatelessWidget {
  final VoidCallback? onViewProgress;
  final String? customMessage;

  const AchievementsEmptyState({
    super.key,
    this.onViewProgress,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.emoji_events_outlined,
      title: 'achievements.noAchievements'.tr(),
      message: customMessage ?? 'achievements.startTrackingToEarn'.tr(),
      actionText: 'achievements.viewProgress'.tr(),
      onActionPressed: onViewProgress,
    );
  }
}

/// Empty state for network/connectivity issues
class NetworkEmptyState extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NetworkEmptyState({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.wifi_off_rounded,
      title: 'errors.noInternet'.tr(),
      message: customMessage ?? 'errors.checkConnection'.tr(),
      actionText: 'common.retry'.tr(),
      onActionPressed: onRetry,
      iconColor: AppColors.error,
    );
  }
}

/// Generic error empty state
class ErrorEmptyState extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? actionText;

  const ErrorEmptyState({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.error_outline_rounded,
      title: title ?? 'errors.general'.tr(),
      message: message ?? 'errors.tryAgain'.tr(),
      actionText: actionText ?? 'common.retry'.tr(),
      onActionPressed: onRetry,
      iconColor: AppColors.error,
    );
  }
}

/// Coming soon empty state
class ComingSoonEmptyState extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onGoBack;

  const ComingSoonEmptyState({
    super.key,
    this.title,
    this.message,
    this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.construction_rounded,
      title: title ?? 'messages.comingSoon'.tr(),
      message: message ?? 'messages.underDevelopment'.tr(),
      actionText: onGoBack != null ? 'common.back'.tr() : null,
      onActionPressed: onGoBack,
      iconColor: AppColors.warning,
      showAction: onGoBack != null,
    );
  }
}

/// Maintenance empty state
class MaintenanceEmptyState extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  const MaintenanceEmptyState({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      iconData: Icons.build_rounded,
      title: title ?? 'errors.maintenance'.tr(),
      message: message ?? 'errors.maintenanceMessage'.tr(),
      actionText: 'common.retry'.tr(),
      onActionPressed: onRetry,
      iconColor: AppColors.info,
    );
  }
}
