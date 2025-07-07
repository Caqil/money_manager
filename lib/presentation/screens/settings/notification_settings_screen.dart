import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/settings_item.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final settings = ref.watch(settingsStateProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'settings.notifications'.tr(),
        showBackButton: true,
      ),
      body: settings.isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Master switch
                  _buildMasterSection(settings),

                  // Budget notifications
                  _buildBudgetSection(settings),

                  // Goal notifications
                  _buildGoalSection(settings),

                  // Transaction notifications
                  _buildTransactionSection(settings),

                  // Backup notifications
                  _buildBackupSection(settings),

                  // System notifications
                  _buildSystemSection(settings),

                  // Notification preferences
                  _buildPreferencesSection(settings),

                  SizedBox(height: AppDimensions.spacingXl),
                ],
              ),
            ),
    );
  }

  Widget _buildMasterSection(SettingsState settings) {
    final theme = ShadTheme.of(context);
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingL),
      child: ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: settings.notificationsEnabled
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.mutedForeground.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: Icon(
                      settings.notificationsEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: settings.notificationsEnabled
                          ? AppColors.success
                          : AppColors.mutedForeground,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'settings.masterNotifications'.tr(),
                          style: theme.textTheme.h4,
                        ),
                        Text(
                          settings.notificationsEnabled
                              ? 'settings.notificationsEnabled'.tr()
                              : 'settings.notificationsDisabled'.tr(),
                          style: theme.textTheme.small.copyWith(
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ShadSwitch(
                    value: settings.notificationsEnabled,
                    onChanged: _toggleMasterNotifications,
                  ),
                ],
              ),
              if (!settings.notificationsEnabled) ...[
                const SizedBox(height: AppDimensions.spacingM),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Text(
                          'settings.notificationsDisabledWarning'.tr(),
                          style: theme.textTheme.small.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetSection(SettingsState settings) {
    return SettingsSection(
      title: 'settings.budgetNotifications'.tr(),
      children: [
        SettingsItem.toggle(
          icon: Icons.account_balance_wallet,
          title: 'settings.budgetAlerts'.tr(),
          subtitle: 'settings.budgetAlertsDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific budget settings
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleBudgetAlerts : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.tune,
          title: 'settings.budgetAlertThreshold'.tr(),
          subtitle: 'settings.budgetAlertThresholdDescription'.tr(),
          value: '${(settings.budgetAlertThreshold * 100).toInt()}%',
          onTap:
              settings.notificationsEnabled ? _configureBudgetThreshold : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.trending_up,
          title: 'settings.overspendingAlerts'.tr(),
          subtitle: 'settings.overspendingAlertsDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific settings
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleOverspendingAlerts : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.schedule,
          title: 'settings.budgetReminderAlerts'.tr(),
          subtitle: 'settings.budgetReminderAlertsDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific settings
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleBudgetReminders : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
      ],
    );
  }

  Widget _buildGoalSection(SettingsState settings) {
    return SettingsSection(
      title: 'settings.goalNotifications'.tr(),
      children: [
        SettingsItem.toggle(
          icon: Icons.flag,
          title: 'settings.goalReminders'.tr(),
          subtitle: 'settings.goalRemindersDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific goal settings
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleGoalReminders : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.celebration,
          title: 'settings.goalAchievements'.tr(),
          subtitle: 'settings.goalAchievementsDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific settings
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleGoalAchievements : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.timeline,
          title: 'settings.goalProgress'.tr(),
          subtitle: 'settings.goalProgressDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific settings
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleGoalProgress : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.schedule,
          title: 'settings.goalReminderFrequency'.tr(),
          subtitle: 'settings.goalReminderFrequencyDescription'.tr(),
          value: 'Weekly', // This would come from settings
          onTap: settings.notificationsEnabled ? _configureGoalFrequency : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
      ],
    );
  }

  Widget _buildTransactionSection(SettingsState settings) {
    return SettingsSection(
      title: 'settings.transactionNotifications'.tr(),
      children: [
        SettingsItem.toggle(
          icon: Icons.receipt,
          title: 'settings.transactionReminders'.tr(),
          subtitle: 'settings.transactionRemindersDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific settings
          onSwitchChanged: settings.notificationsEnabled
              ? _toggleTransactionReminders
              : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.timer,
          title: 'settings.reminderFrequency'.tr(),
          subtitle: 'settings.reminderFrequencyDescription'.tr(),
          value: '${settings.transactionReminderDays} ${tr('settings.days')}',
          onTap: settings.notificationsEnabled
              ? _configureReminderFrequency
              : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.repeat,
          title: 'settings.recurringTransactionAlerts'.tr(),
          subtitle: 'settings.recurringTransactionAlertsDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific settings
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleRecurringAlerts : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.attach_money,
          title: 'settings.largeTransactionAlerts'.tr(),
          subtitle: 'settings.largeTransactionAlertsDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? false
              : false, // This would come from specific settings
          onSwitchChanged: settings.notificationsEnabled
              ? _toggleLargeTransactionAlerts
              : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
      ],
    );
  }

  Widget _buildBackupSection(SettingsState settings) {
    return SettingsSection(
      title: 'settings.backupNotifications'.tr(),
      children: [
        SettingsItem.toggle(
          icon: Icons.backup,
          title: 'settings.backupReminders'.tr(),
          subtitle: 'settings.backupRemindersDescription'.tr(),
          switchValue:
              settings.notificationsEnabled && settings.autoBackupEnabled,
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleBackupReminders : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.check_circle,
          title: 'settings.backupSuccessAlerts'.tr(),
          subtitle: 'settings.backupSuccessAlertsDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific settings
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleBackupSuccess : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.error,
          title: 'settings.backupFailureAlerts'.tr(),
          subtitle: 'settings.backupFailureAlertsDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific settings
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleBackupFailure : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
      ],
    );
  }

  Widget _buildSystemSection(SettingsState settings) {
    return SettingsSection(
      title: 'settings.systemNotifications'.tr(),
      children: [
        SettingsItem.toggle(
          icon: Icons.system_update,
          title: 'settings.appUpdates'.tr(),
          subtitle: 'settings.appUpdatesDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific settings
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleAppUpdates : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.tips_and_updates,
          title: 'settings.tipsAndTricks'.tr(),
          subtitle: 'settings.tipsAndTricksDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific settings
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleTipsAndTricks : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.security,
          title: 'settings.securityAlerts'.tr(),
          subtitle: 'settings.securityAlertsDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific settings
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleSecurityAlerts : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(SettingsState settings) {
    return SettingsSection(
      title: 'settings.notificationPreferences'.tr(),
      children: [
        SettingsItem.navigation(
          icon: Icons.schedule,
          title: 'settings.quietHours'.tr(),
          subtitle: 'settings.quietHoursDescription'.tr(),
          value: '22:00 - 08:00', // This would come from settings
          onTap: settings.notificationsEnabled ? _configureQuietHours : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.vibration,
          title: 'settings.notificationSound'.tr(),
          subtitle: 'settings.notificationSoundDescription'.tr(),
          value: 'Default', // This would come from settings
          onTap: settings.notificationsEnabled
              ? _configureNotificationSound
              : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.vibration,
          title: 'settings.vibration'.tr(),
          subtitle: 'settings.vibrationDescription'.tr(),
          switchValue: settings.notificationsEnabled
              ? true
              : false, // This would come from specific settings
          onSwitchChanged:
              settings.notificationsEnabled ? _toggleVibration : null,
          enabled: settings.notificationsEnabled && !_isLoading,
        ),
        SettingsItem.action(
          icon: Icons.notification_important,
          title: 'settings.testNotification'.tr(),
          subtitle: 'settings.testNotificationDescription'.tr(),
          onTap: settings.notificationsEnabled ? _sendTestNotification : null,
          enabled: settings.notificationsEnabled && !_isLoading,
          trailing: const Icon(Icons.send, size: 16),
        ),
      ],
    );
  }

  // Action handlers
  Future<void> _toggleMasterNotifications(bool enabled) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(settingsStateProvider.notifier)
          .setNotificationsEnabled(enabled);
      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text(enabled
                ? 'settings.notificationsEnabled'.tr()
                : 'settings.notificationsDisabled'.tr()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.raw(
              variant: ShadToastVariant.primary,
              description: Text('Failed to update notifications: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Budget notification handlers
  Future<void> _toggleBudgetAlerts(bool enabled) async {
    // Implementation for budget alerts toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description:
              Text('Budget alerts ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _configureBudgetThreshold() async {
    // Implementation for budget threshold configuration
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description: Text('Configure budget threshold')),
    );
  }

  Future<void> _toggleOverspendingAlerts(bool enabled) async {
    // Implementation for overspending alerts toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description:
              Text('Overspending alerts ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _toggleBudgetReminders(bool enabled) async {
    // Implementation for budget reminders toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description:
              Text('Budget reminders ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  // Goal notification handlers
  Future<void> _toggleGoalReminders(bool enabled) async {
    // Implementation for goal reminders toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description:
              Text('Goal reminders ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _toggleGoalAchievements(bool enabled) async {
    // Implementation for goal achievements toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description:
              Text('Goal achievements ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _toggleGoalProgress(bool enabled) async {
    // Implementation for goal progress toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description:
              Text('Goal progress ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _configureGoalFrequency() async {
    // Implementation for goal frequency configuration
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description: Text('Configure goal frequency')),
    );
  }

  // Transaction notification handlers
  Future<void> _toggleTransactionReminders(bool enabled) async {
    // Implementation for transaction reminders toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description: Text(
              'Transaction reminders ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _configureReminderFrequency() async {
    // Implementation for reminder frequency configuration
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description: Text('Configure reminder frequency')),
    );
  }

  Future<void> _toggleRecurringAlerts(bool enabled) async {
    // Implementation for recurring alerts toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description:
              Text('Recurring alerts ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _toggleLargeTransactionAlerts(bool enabled) async {
    // Implementation for large transaction alerts toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description: Text(
              'Large transaction alerts ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  // Backup notification handlers
  Future<void> _toggleBackupReminders(bool enabled) async {
    // Implementation for backup reminders toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description:
              Text('Backup reminders ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _toggleBackupSuccess(bool enabled) async {
    // Implementation for backup success toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description: Text(
              'Backup success alerts ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _toggleBackupFailure(bool enabled) async {
    // Implementation for backup failure toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description: Text(
              'Backup failure alerts ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  // System notification handlers
  Future<void> _toggleAppUpdates(bool enabled) async {
    // Implementation for app updates toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description: Text('App updates ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _toggleTipsAndTricks(bool enabled) async {
    // Implementation for tips and tricks toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description:
              Text('Tips and tricks ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _toggleSecurityAlerts(bool enabled) async {
    // Implementation for security alerts toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description:
              Text('Security alerts ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  // Preference handlers
  Future<void> _configureQuietHours() async {
    // Implementation for quiet hours configuration
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description: Text('Configure quiet hours')),
    );
  }

  Future<void> _configureNotificationSound() async {
    // Implementation for notification sound configuration
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description: Text('Configure notification sound')),
    );
  }

  Future<void> _toggleVibration(bool enabled) async {
    // Implementation for vibration toggle
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description: Text('Vibration ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _sendTestNotification() async {
    // Implementation for sending test notification
    ShadSonner.of(context).show(
      ShadToast.raw(
          variant: ShadToastVariant.primary,
          description: Text('Test notification sent!')),
    );
  }
}
