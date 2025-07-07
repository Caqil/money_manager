import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../routes/route_names.dart';
import 'widgets/settings_item.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load settings when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsStateProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final settings = ref.watch(settingsStateProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'settings.title'.tr(),
        showBackButton: true,
      ),
      body: settings.isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              child: Column(
                children: [
                  // General Settings
                  _buildGeneralSection(settings),

                  // Appearance
                  _buildAppearanceSection(settings),

                  // Security
                  _buildSecuritySection(authState),

                  // Data & Backup
                  _buildDataSection(settings),

                  // Notifications
                  _buildNotificationSection(settings),

                  // About & Help
                  _buildAboutSection(),

                  // Advanced
                  _buildAdvancedSection(),

                   SizedBox(height: AppDimensions.spacingXl),
                ],
              ),
            ),
    );
  }

  Widget _buildGeneralSection(SettingsState settings) {
    return SettingsSection(
      title: 'settings.general'.tr(),
      children: [
        SettingsItem.navigation(
          icon: Icons.language,
          title: 'settings.language'.tr(),
          subtitle: 'settings.selectAppLanguage'.tr(),
          value: _getLanguageDisplayName(settings.language),
          onTap: () => context.push(RouteNames.languageSettings),
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.currency_exchange,
          title: 'settings.currency'.tr(),
          subtitle: 'settings.baseCurrency'.tr(),
          value: settings.baseCurrency,
          onTap: () => context.push(RouteNames.currencySettings),
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.account_balance_wallet,
          title: 'settings.accounts'.tr(),
          subtitle: 'settings.manageAccounts'.tr(),
          onTap: () => context.push('/accounts'),
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.category,
          title: 'settings.categories'.tr(),
          subtitle: 'settings.manageCategories'.tr(),
          onTap: () => context.push('/categories'),
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(SettingsState settings) {
    return SettingsSection(
      title: 'settings.appearance'.tr(),
      children: [
        SettingsItem.navigation(
          icon: Icons.palette,
          title: 'settings.theme'.tr(),
          subtitle: 'settings.chooseAppTheme'.tr(),
          value: _getThemeDisplayName(settings.themeMode),
          onTap: () => context.push(RouteNames.themeSettings),
          enabled: !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.animation,
          title: 'settings.chartAnimations'.tr(),
          subtitle: 'settings.enableChartAnimations'.tr(),
          switchValue: settings.chartAnimationsEnabled,
          onSwitchChanged: _toggleChartAnimations,
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.dashboard_customize,
          title: 'settings.dashboardWidgets'.tr(),
          subtitle: 'settings.customizeDashboard'.tr(),
          value:
              '${settings.dashboardWidgets.length} ${tr('settings.widgets')}',
          onTap: () => context.push('/settings/dashboard'),
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildSecuritySection(AuthState authState) {
    return SettingsSection(
      title: 'settings.security'.tr(),
      children: [
        SettingsItem.navigation(
          icon: Icons.security,
          title: 'settings.security'.tr(),
          subtitle: authState.isPinEnabled
              ? 'settings.securityEnabled'.tr()
              : 'settings.securityDisabled'.tr(),
          value: _getSecurityStatus(authState),
          onTap: () => context.push(RouteNames.securitySettings),
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.backup,
          title: 'settings.backupRestore'.tr(),
          subtitle: 'settings.manageBackups'.tr(),
          onTap: () => context.push('/settings/backup'),
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.cloud_upload,
          title: 'settings.dataExport'.tr(),
          subtitle: 'settings.exportData'.tr(),
          onTap: () => context.push(RouteNames.dataExport),
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildDataSection(SettingsState settings) {
    return SettingsSection(
      title: 'settings.dataManagement'.tr(),
      children: [
        SettingsItem.toggle(
          icon: Icons.backup_outlined,
          title: 'settings.autoBackup'.tr(),
          subtitle: 'settings.enableAutoBackup'.tr(),
          switchValue: settings.autoBackupEnabled,
          onSwitchChanged: _toggleAutoBackup,
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.storage,
          title: 'settings.storageUsage'.tr(),
          subtitle: 'settings.viewStorageDetails'.tr(),
          onTap: () => context.push('/settings/storage'),
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.file_download,
          title: 'settings.importData'.tr(),
          subtitle: 'settings.importFromFile'.tr(),
          onTap: () => context.push(RouteNames.dataImport),
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildNotificationSection(SettingsState settings) {
    return SettingsSection(
      title: 'settings.notifications'.tr(),
      children: [
        SettingsItem.navigation(
          icon: Icons.notifications,
          title: 'settings.notifications'.tr(),
          subtitle: settings.notificationsEnabled
              ? 'settings.notificationsEnabled'.tr()
              : 'settings.notificationsDisabled'.tr(),
          value: settings.notificationsEnabled ? 'On' : 'Off',
          onTap: () => context.push(RouteNames.notificationSettings),
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.schedule,
          title: 'settings.reminders'.tr(),
          subtitle: 'settings.transactionReminders'.tr(),
          value: '${settings.transactionReminderDays} ${tr('settings.days')}',
          onTap: () => context.push('/settings/reminders'),
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return SettingsSection(
      title: 'settings.about'.tr(),
      children: [
        SettingsItem.navigation(
          icon: Icons.info,
          title: 'settings.about'.tr(),
          subtitle: 'Version ${AppConstants.appVersion}',
          onTap: () => context.push(RouteNames.aboutApp),
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.help,
          title: 'settings.help'.tr(),
          subtitle: 'settings.helpAndSupport'.tr(),
          onTap: () => context.push(RouteNames.help),
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.privacy_tip,
          title: 'settings.privacy'.tr(),
          subtitle: 'settings.privacyPolicy'.tr(),
          onTap: () => context.push(RouteNames.privacyPolicy),
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.description,
          title: 'settings.terms'.tr(),
          subtitle: 'settings.termsOfService'.tr(),
          onTap: () => context.push(RouteNames.termsOfService),
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return SettingsSection(
      title: 'settings.advanced'.tr(),
      children: [
        SettingsItem.navigation(
          icon: Icons.analytics,
          title: 'settings.analytics'.tr(),
          subtitle: 'settings.analyticsSettings'.tr(),
          onTap: () => context.push('/settings/analytics'),
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.bug_report,
          title: 'settings.debug'.tr(),
          subtitle: 'settings.debugAndLogs'.tr(),
          onTap: () => context.push('/settings/debug'),
          enabled: !_isLoading,
        ),
        SettingsItem.action(
          icon: Icons.refresh,
          title: 'settings.resetApp'.tr(),
          subtitle: 'settings.resetConfirmation'.tr(),
          onTap: _showResetConfirmation,
          enabled: !_isLoading,
          isDestructive: true,
        ),
      ],
    );
  }

  // Helper methods
  String _getLanguageDisplayName(String languageCode) {
    final supportedLanguages = {
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'ru': 'Русский',
      'ja': '日本語',
      'ko': '한국어',
      'zh': '中文',
      'ar': 'العربية',
      'hi': 'हिन्दी',
    };
    return supportedLanguages[languageCode] ?? languageCode.toUpperCase();
  }

  String _getThemeDisplayName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'settings.light'.tr();
      case ThemeMode.dark:
        return 'settings.dark'.tr();
      case ThemeMode.system:
        return 'settings.system'.tr();
    }
  }

  String _getSecurityStatus(AuthState authState) {
    if (authState.isPinEnabled && authState.isBiometricEnabled) {
      return 'PIN + Biometric';
    } else if (authState.isPinEnabled) {
      return 'PIN Only';
    } else if (authState.isBiometricEnabled) {
      return 'Biometric Only';
    }
    return 'None';
  }

  // Action handlers
  Future<void> _toggleChartAnimations(bool enabled) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(settingsStateProvider.notifier)
          .setChartAnimationsEnabled(enabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update chart animations: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAutoBackup(bool enabled) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(settingsStateProvider.notifier)
          .setAutoBackupEnabled(enabled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled
                ? 'settings.autoBackupEnabled'.tr()
                : 'settings.autoBackupDisabled'.tr()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update auto backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showResetConfirmation() async {
    final result = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('settings.resetApp'.tr()),
        description: Text('settings.resetConfirmation'.tr()),
        actions: [
          ShadButton.outline(
            child: Text('common.cancel'.tr()),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: Text('settings.resetApp'.tr()),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true) {
      // Implement reset logic
      setState(() => _isLoading = true);
      try {
        // Add reset implementation here
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('settings.appReset'.tr())),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reset app: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
