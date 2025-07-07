import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../providers/auth_provider.dart';

class SecuritySettingsWidget extends ConsumerStatefulWidget {
  const SecuritySettingsWidget({super.key});

  @override
  ConsumerState<SecuritySettingsWidget> createState() =>
      _SecuritySettingsWidgetState();
}

class _SecuritySettingsWidgetState
    extends ConsumerState<SecuritySettingsWidget> {
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _isPinLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final authState = ref.watch(authStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Security overview
        _buildSecurityOverview(authState),
        const SizedBox(height: AppDimensions.spacingL),

        // PIN Protection section
        _buildPinSection(authState),
        const SizedBox(height: AppDimensions.spacingL),

        // Biometric Authentication section
        _buildBiometricSection(authState),
        const SizedBox(height: AppDimensions.spacingL),

        // Session Management
        _buildSessionSection(),
        const SizedBox(height: AppDimensions.spacingL),

        // Advanced Security
        _buildAdvancedSection(),
      ],
    );
  }

  Widget _buildSecurityOverview(AuthState authState) {
    final theme = ShadTheme.of(context);
    final securityLevel = _calculateSecurityLevel(authState);

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: _getSecurityColor(securityLevel),
                  size: 24,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  'settings.securityLevel'.tr(),
                  style: theme.textTheme.h4,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingS,
                    vertical: AppDimensions.paddingXs,
                  ),
                  decoration: BoxDecoration(
                    color: _getSecurityColor(securityLevel).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Text(
                    _getSecurityLevelText(securityLevel),
                    style: TextStyle(
                      color: _getSecurityColor(securityLevel),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // Security score indicator
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: securityLevel / 3,
                    backgroundColor: AppColors.lightBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getSecurityColor(securityLevel),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  '${((securityLevel / 3) * 100).toInt()}%',
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingS),

            Text(
              _getSecurityDescription(securityLevel),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinSection(AuthState authState) {
    final theme = ShadTheme.of(context);
    final isPinEnabled = authState.isPinEnabled;

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pin,
                  color: isPinEnabled
                      ? AppColors.success
                      : AppColors.lightDisabled,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  'settings.pinProtection'.tr(),
                  style: theme.textTheme.h4,
                ),
                const Spacer(),
                ShadSwitch(
                  value: isPinEnabled,
                  onChanged: _isPinLoading ? null : _togglePin,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'settings.pinProtectionDescription'.tr(),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            if (isPinEnabled) ...[
              const SizedBox(height: AppDimensions.spacingM),
              Row(
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      size: ShadButtonSize.sm,
                      onPressed: _isPinLoading ? null : _changePin,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit, size: 16),
                          const SizedBox(width: AppDimensions.spacingXs),
                          Text('settings.changePin'.tr()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: ShadButton.outline(
                      size: ShadButtonSize.sm,
                      onPressed: _isPinLoading ? null : _testPin,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user, size: 16),
                          const SizedBox(width: AppDimensions.spacingXs),
                          Text('settings.testPin'.tr()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_isPinLoading) ...[
              const SizedBox(height: AppDimensions.spacingS),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricSection(AuthState authState) {
    final theme = ShadTheme.of(context);
    final isBiometricEnabled = authState.isBiometricEnabled;

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fingerprint,
                  color: isBiometricEnabled
                      ? AppColors.success
                      : AppColors.lightDisabled,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  'settings.biometricAuth'.tr(),
                  style: theme.textTheme.h4,
                ),
                const Spacer(),
                ShadSwitch(
                  value: isBiometricEnabled,
                  onChanged: _isBiometricLoading ? null : _toggleBiometric,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'settings.biometricAuthDescription'.tr(),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            if (isBiometricEnabled) ...[
              const SizedBox(height: AppDimensions.spacingM),
              _buildBiometricOptions(),
            ],
            if (_isBiometricLoading) ...[
              const SizedBox(height: AppDimensions.spacingS),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricOptions() {
    return FutureBuilder<List<BiometricType>>(
      future: LocalAuthentication().getAvailableBiometrics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final biometrics = snapshot.data ?? [];

        if (biometrics.isEmpty) {
          return Text(
            'settings.noBiometricsAvailable'.tr(),
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 12,
            ),
          );
        }

        return Column(
          children: biometrics.map((biometric) {
            return ListTile(
              dense: true,
              leading: Icon(
                _getBiometricIcon(biometric),
                size: 16,
                color: AppColors.success,
              ),
              title: Text(
                _getBiometricName(biometric),
                style: const TextStyle(fontSize: 14),
              ),
              trailing: Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.success,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSessionSection() {
    final theme = ShadTheme.of(context);

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: theme.colorScheme.foreground,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  'settings.sessionManagement'.tr(),
                  style: theme.textTheme.h4,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // Auto lock timeout
            _buildAutoLockSetting(),
            const SizedBox(height: AppDimensions.spacingM),

            // Lock on app minimize
            _buildLockOnMinimizeSetting(),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoLockSetting() {
    final theme = ShadTheme.of(context);
    const timeouts = [1, 5, 15, 30, 60]; // minutes
    const selectedTimeout = 5; // This would come from settings

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings.autoLockTimeout'.tr(),
          style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Wrap(
          spacing: AppDimensions.spacingS,
          children: timeouts.map((timeout) {
            final isSelected = timeout == selectedTimeout;
            return ChoiceChip(
              label: Text('${timeout}m'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  // Update auto lock timeout
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLockOnMinimizeSetting() {
    return SwitchListTile(
      title: Text('settings.lockOnAppMinimize'.tr()),
      subtitle: Text('settings.lockOnAppMinimizeDescription'.tr()),
      value: true, // This would come from settings
      onChanged: (value) {
        // Update lock on minimize setting
      },
      dense: true,
    );
  }

  Widget _buildAdvancedSection() {
    final theme = ShadTheme.of(context);

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: theme.colorScheme.foreground,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  'settings.advancedSecurity'.tr(),
                  style: theme.textTheme.h4,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // Security actions
            _buildSecurityAction(
              icon: Icons.logout,
              title: 'settings.logoutAllDevices'.tr(),
              subtitle: 'settings.logoutAllDevicesDescription'.tr(),
              onTap: _logoutAllDevices,
              dangerous: false,
            ),
            const SizedBox(height: AppDimensions.spacingS),

            _buildSecurityAction(
              icon: Icons.refresh,
              title: 'settings.resetSecuritySettings'.tr(),
              subtitle: 'settings.resetSecuritySettingsDescription'.tr(),
              onTap: _resetSecuritySettings,
              dangerous: false,
            ),
            const SizedBox(height: AppDimensions.spacingS),

            _buildSecurityAction(
              icon: Icons.delete_forever,
              title: 'settings.deleteAllData'.tr(),
              subtitle: 'settings.deleteAllDataDescription'.tr(),
              onTap: _deleteAllData,
              dangerous: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool dangerous,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: dangerous ? AppColors.error : null,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: dangerous ? AppColors.error : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      dense: true,
    );
  }

  int _calculateSecurityLevel(AuthState authState) {
    int level = 0;
    if (authState.isPinEnabled) level++;
    if (authState.isBiometricEnabled) level++;
    // Add other security factors
    level++; // Base security
    return level;
  }

  Color _getSecurityColor(int level) {
    switch (level) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.success;
      default:
        return AppColors.lightDisabled;
    }
  }

  String _getSecurityLevelText(int level) {
    switch (level) {
      case 1:
        return 'settings.securityLow'.tr();
      case 2:
        return 'settings.securityMedium'.tr();
      case 3:
        return 'settings.securityHigh'.tr();
      default:
        return 'settings.securityNone'.tr();
    }
  }

  String _getSecurityDescription(int level) {
    switch (level) {
      case 1:
        return 'settings.securityLowDescription'.tr();
      case 2:
        return 'settings.securityMediumDescription'.tr();
      case 3:
        return 'settings.securityHighDescription'.tr();
      default:
        return 'settings.securityNoneDescription'.tr();
    }
  }

  IconData _getBiometricIcon(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return Icons.face;
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.iris:
        return Icons.visibility;
      case BiometricType.strong:
        return Icons.security;
      case BiometricType.weak:
        return Icons.security;
    }
  }

  String _getBiometricName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'settings.faceId'.tr();
      case BiometricType.fingerprint:
        return 'settings.fingerprint'.tr();
      case BiometricType.iris:
        return 'settings.iris'.tr();
      case BiometricType.strong:
        return 'settings.strongBiometric'.tr();
      case BiometricType.weak:
        return 'settings.weakBiometric'.tr();
    }
  }

  Future<void> _togglePin(bool enabled) async {
    setState(() {
      _isPinLoading = true;
    });

    try {
      if (enabled) {
        // Navigate to PIN setup
        // context.push('/auth/setup-pin');
      } else {
        await ref.read(authServiceProvider).disableBiometric();
      }
    } catch (e) {
      _showError('settings.pinToggleError'.tr());
    } finally {
      setState(() {
        _isPinLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    setState(() {
      _isBiometricLoading = true;
    });

    try {
      if (enabled) {
        final isAvailable = await LocalAuthentication().isDeviceSupported();
        if (!isAvailable) {
          _showError('settings.biometricNotAvailable'.tr());
          return;
        }

        final authenticated = await LocalAuthentication().authenticate(
          localizedReason: 'settings.authenticateToEnable'.tr(),
        );

        if (authenticated) {
          await ref.read(authServiceProvider).enableBiometric();
        }
      } else {
        await ref.read(authServiceProvider).disableBiometric();
      }
    } catch (e) {
      _showError('settings.biometricToggleError'.tr());
    } finally {
      setState(() {
        _isBiometricLoading = false;
      });
    }
  }

  void _changePin() {
    // Navigate to change PIN screen
    // context.push('/auth/change-pin');
  }

  void _testPin() {
    // Navigate to PIN test screen
    // context.push('/auth/test-pin');
  }

  void _logoutAllDevices() {
    _showConfirmationDialog(
      title: 'settings.logoutAllDevices'.tr(),
      message: 'settings.logoutAllDevicesConfirmation'.tr(),
      onConfirm: () {
        // Implement logout all devices
      },
    );
  }

  void _resetSecuritySettings() {
    _showConfirmationDialog(
      title: 'settings.resetSecuritySettings'.tr(),
      message: 'settings.resetSecuritySettingsConfirmation'.tr(),
      onConfirm: () {
        // Implement reset security settings
      },
    );
  }

  void _deleteAllData() {
    _showConfirmationDialog(
      title: 'settings.deleteAllData'.tr(),
      message: 'settings.deleteAllDataConfirmation'.tr(),
      onConfirm: () {
        // Implement delete all data
      },
      dangerous: true,
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    bool dangerous = false,
  }) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(title),
        description: Text(message),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          dangerous
              ? ShadButton.destructive(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  child: Text('common.delete'.tr()),
                )
              : ShadButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  child: Text('common.confirm'.tr()),
                ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ShadSonner.of(context).show(
      ShadToast.raw(
        variant: ShadToastVariant.primary,
        description: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
