import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/export_import_widget.dart';
import 'widgets/settings_item.dart';

class BackupSettingsScreen extends ConsumerStatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  ConsumerState<BackupSettingsScreen> createState() =>
      _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final settings = ref.watch(settingsStateProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'settings.backupRestore'.tr(),
        showBackButton: true,
      ),
      body: settings.isLoading
          ? const Center(child: ShimmerLoading(child: SkeletonLoader()))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auto Backup Section
                  _buildAutoBackupSection(settings),

                  // Backup History Section
                  _buildBackupHistorySection(),

                  // Manual Backup Section
                  _buildManualBackupSection(),

                  // Import/Export Section
                  _buildImportExportSection(),

                  // Cloud Storage Section
                  _buildCloudStorageSection(),

                  // Advanced Options
                  _buildAdvancedSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildAutoBackupSection(SettingsState settings) {
    return SettingsSection(
      title: 'settings.autoBackup'.tr(),
      children: [
        SettingsItem.toggle(
          icon: Icons.backup,
          title: 'settings.enableAutoBackup'.tr(),
          subtitle: 'settings.enableAutoBackupDescription'.tr(),
          switchValue: settings.autoBackupEnabled,
          onSwitchChanged: _toggleAutoBackup,
          enabled: !_isLoading,
        ),
        if (settings.autoBackupEnabled) ...[
          SettingsItem.navigation(
            icon: Icons.schedule,
            title: 'settings.backupFrequency'.tr(),
            subtitle: 'settings.backupFrequencyDescription'.tr(),
            value: _getBackupFrequencyText(),
            onTap: _showBackupFrequencyDialog,
            enabled: !_isLoading,
          ),
          SettingsItem.navigation(
            icon: Icons.wifi,
            title: 'settings.backupOnWifiOnly'.tr(),
            subtitle: 'settings.backupOnWifiOnlyDescription'.tr(),
            onTap: () {},
            trailing: ShadSwitch(
              value: true, // This would come from settings
              onChanged: _isLoading
                  ? null
                  : (value) {
                      // Update wifi only setting
                    },
            ),
            enabled: !_isLoading,
          ),
        ],
        if (settings.lastBackupDate != null)
          SettingsItem.info(
            icon: Icons.history,
            title: 'settings.lastBackup'.tr(),
            subtitle:
                DateFormat.yMMMMd().add_jm().format(settings.lastBackupDate!),
            trailing: IconButton(
              onPressed: _isLoading ? null : _performManualBackup,
              icon: const Icon(Icons.backup, size: 16),
              tooltip: 'settings.backupNow'.tr(),
            ),
          ),
      ],
    );
  }

  Widget _buildBackupHistorySection() {
    return SettingsSection(
      title: 'settings.backupHistory'.tr(),
      children: [
        SettingsItem.navigation(
          icon: Icons.history,
          title: 'settings.viewBackupHistory'.tr(),
          subtitle: 'settings.viewBackupHistoryDescription'.tr(),
          onTap: _viewBackupHistory,
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.storage,
          title: 'settings.manageBackupStorage'.tr(),
          subtitle: 'settings.manageBackupStorageDescription'.tr(),
          value: '2.5 MB', // This would be calculated
          onTap: _manageBackupStorage,
          enabled: !_isLoading,
        ),
        SettingsItem.action(
          icon: Icons.delete_sweep,
          title: 'settings.cleanOldBackups'.tr(),
          subtitle: 'settings.cleanOldBackupsDescription'.tr(),
          onTap: _cleanOldBackups,
          enabled: !_isLoading,
          trailing: const Icon(Icons.chevron_right, size: 16),
        ),
      ],
    );
  }

  Widget _buildManualBackupSection() {
    return SettingsSection(
      title: 'settings.manualBackup'.tr(),
      children: [
        SettingsItem.action(
          icon: Icons.backup,
          title: 'settings.createBackupNow'.tr(),
          subtitle: 'settings.createBackupNowDescription'.tr(),
          onTap: _performManualBackup,
          enabled: !_isLoading,
          trailing: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right, size: 16),
        ),
        SettingsItem.navigation(
          icon: Icons.settings,
          title: 'settings.backupSettings'.tr(),
          subtitle: 'settings.backupSettingsDescription'.tr(),
          onTap: _configureBackupSettings,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildImportExportSection() {
    return SettingsSection(
      title: 'settings.importExport'.tr(),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: ExportImportWidget(
            onExportCompleted: _onExportCompleted,
            onImportCompleted: _onImportCompleted,
          ),
        ),
      ],
    );
  }

  Widget _buildCloudStorageSection() {
    return SettingsSection(
      title: 'settings.cloudStorage'.tr(),
      children: [
        SettingsItem.navigation(
          icon: Icons.cloud,
          title: 'Google Drive',
          subtitle: 'settings.googleDriveDescription'.tr(),
          value: 'Connected', // This would be dynamic
          onTap: _configureGoogleDrive,
          enabled: !_isLoading,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Icon(Icons.chevron_right, size: 16),
            ],
          ),
        ),
        SettingsItem.navigation(
          icon: Icons.cloud_outlined,
          title: 'iCloud',
          subtitle: 'settings.iCloudDescription'.tr(),
          value: 'Not Connected',
          onTap: _configureICloud,
          enabled: !_isLoading,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.lightDisabled,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Icon(Icons.chevron_right, size: 16),
            ],
          ),
        ),
        SettingsItem.navigation(
          icon: Icons.folder,
          title: 'settings.localStorage'.tr(),
          subtitle: 'settings.localStorageDescription'.tr(),
          onTap: _configureLocalStorage,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return SettingsSection(
      title: 'settings.advancedOptions'.tr(),
      children: [
        SettingsItem.toggle(
          icon: Icons.compress,
          title: 'settings.compressBackups'.tr(),
          subtitle: 'settings.compressBackupsDescription'.tr(),
          switchValue: true, // This would come from settings
          onSwitchChanged: (value) {
            // Update compression setting
          },
          enabled: !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.lock,
          title: 'settings.encryptBackups'.tr(),
          subtitle: 'settings.encryptBackupsDescription'.tr(),
          switchValue: false, // This would come from settings
          onSwitchChanged: (value) {
            // Update encryption setting
          },
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.restore,
          title: 'settings.restoreFromBackup'.tr(),
          subtitle: 'settings.restoreFromBackupDescription'.tr(),
          onTap: _showRestoreDialog,
          enabled: !_isLoading,
        ),
        SettingsItem.action(
          icon: Icons.refresh,
          title: 'settings.resetBackupSettings'.tr(),
          subtitle: 'settings.resetBackupSettingsDescription'.tr(),
          onTap: _resetBackupSettings,
          enabled: !_isLoading,
          isDestructive: true,
        ),
      ],
    );
  }

  Future<void> _toggleAutoBackup(bool enabled) async {
    setState(() {
      _isLoading = true;
    });

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
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.autoBackupToggleError'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showBackupFrequencyDialog() {
    final frequencies = [
      ('daily', 'settings.daily'.tr()),
      ('weekly', 'settings.weekly'.tr()),
      ('monthly', 'settings.monthly'.tr()),
    ];

    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('settings.selectBackupFrequency'.tr()),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: frequencies
              .map((freq) => ListTile(
                    title: Text(freq.$2),
                    onTap: () {
                      Navigator.of(context).pop();
                      // Update backup frequency
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _performManualBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate backup process
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.backupCompleted'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.backupError'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _viewBackupHistory() {
    // Navigate to backup history screen
  }

  void _manageBackupStorage() {
    // Navigate to storage management screen
  }

  void _cleanOldBackups() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('settings.cleanOldBackups'.tr()),
        description: Text('settings.cleanOldBackupsConfirmation'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Perform cleanup
            },
            child: Text('settings.clean'.tr()),
          ),
        ],
      ),
    );
  }

  void _configureBackupSettings() {
    // Navigate to detailed backup configuration
  }

  void _configureGoogleDrive() {
    // Configure Google Drive integration
  }

  void _configureICloud() {
    // Configure iCloud integration
  }

  void _configureLocalStorage() {
    // Configure local storage options
  }

  void _showRestoreDialog() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('settings.restoreFromBackup'.tr()),
        description: Text('settings.restoreWarning'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton.destructive(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to restore screen
            },
            child: Text('settings.restore'.tr()),
          ),
        ],
      ),
    );
  }

  void _resetBackupSettings() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('settings.resetBackupSettings'.tr()),
        description: Text('settings.resetBackupSettingsConfirmation'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton.destructive(
            onPressed: () {
              Navigator.of(context).pop();
              // Reset backup settings
            },
            child: Text('settings.reset'.tr()),
          ),
        ],
      ),
    );
  }

  void _onExportCompleted(String fileName) {
    // Handle export completion
  }

  void _onImportCompleted(String fileName) {
    // Handle import completion
  }

  String _getBackupFrequencyText() {
    // This would come from settings
    return 'settings.weekly'.tr();
  }
}
