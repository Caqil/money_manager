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

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() =>
      _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  bool _isLoading = false;

  // Theme options data
  static const List<Map<String, dynamic>> _themeOptions = [
    {
      'mode': ThemeMode.system,
      'name': 'System',
      'description': 'Follow system theme',
      'icon': Icons.brightness_auto,
      'primaryColor': Colors.blue,
      'backgroundColor': Colors.grey,
    },
    {
      'mode': ThemeMode.light,
      'name': 'Light',
      'description': 'Light theme for daytime use',
      'icon': Icons.light_mode,
      'primaryColor': Colors.orange,
      'backgroundColor': Colors.white,
    },
    {
      'mode': ThemeMode.dark,
      'name': 'Dark',
      'description': 'Dark theme for nighttime use',
      'icon': Icons.dark_mode,
      'primaryColor': Colors.purple,
      'backgroundColor': Colors.black,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final settings = ref.watch(settingsStateProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'settings.theme'.tr(),
        showBackButton: true,
      ),
      body: settings.isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Current theme preview
                  _buildCurrentThemePreview(settings),

                  // Theme options
                  _buildThemeOptions(settings),

                  // Display preferences
                  _buildDisplayPreferences(settings),

                  // Appearance customization
                  _buildAppearanceCustomization(settings),

                  SizedBox(height: AppDimensions.spacingXl),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentThemePreview(SettingsState settings) {
    final currentTheme = settings.themeMode;
    final currentOption = _themeOptions.firstWhere(
      (option) => option['mode'] == currentTheme,
      orElse: () => _themeOptions[0],
    );
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
                  // Theme preview
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(
                        color: currentOption['primaryColor'],
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background pattern
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusM),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  currentOption['primaryColor']
                                      .withOpacity(0.1),
                                  currentOption['primaryColor']
                                      .withOpacity(0.05),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Icon
                        Center(
                          child: Icon(
                            currentOption['icon'],
                            color: currentOption['primaryColor'],
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),

                  // Current theme info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'settings.currentTheme'.tr(),
                          style: theme.textTheme.small.copyWith(
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'settings.${currentOption['name'].toLowerCase()}'
                              .tr(),
                          style: theme.textTheme.h4,
                        ),
                        Text(
                          'settings.${currentOption['name'].toLowerCase()}Description'
                              .tr(),
                          style: theme.textTheme.small.copyWith(
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Text(
                      'settings.active'.tr(),
                      style: theme.textTheme.small.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spacingM),

              // Theme preview cards
              Row(
                children: [
                  Expanded(
                    child: _buildPreviewCard(
                      'settings.appBackground'.tr(),
                      currentOption['backgroundColor'],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: _buildPreviewCard(
                      'settings.accentColor'.tr(),
                      currentOption['primaryColor'],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: _buildPreviewCard(
                      'settings.textColor'.tr(),
                      theme.colorScheme.foreground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: ShadTheme.of(context).colorScheme.muted.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              border: Border.all(
                color: ShadTheme.of(context).colorScheme.border,
                width: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: ShadTheme.of(context).textTheme.small,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptions(SettingsState settings) {
    final currentTheme = settings.themeMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppDimensions.paddingS,
              bottom: AppDimensions.spacingS,
            ),
            child: Text(
              'settings.chooseTheme'.tr(),
              style: ShadTheme.of(context).textTheme.h4.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ),
          ShadCard(
            child: Column(
              children: _themeOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = option['mode'] == currentTheme;

                return _buildThemeOption(
                  option,
                  isSelected,
                  index < _themeOptions.length - 1,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    Map<String, dynamic> option,
    bool isSelected,
    bool showDivider,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: isSelected ? null : () => _selectTheme(option['mode']),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              children: [
                // Theme preview
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? option['primaryColor'].withOpacity(0.1)
                        : ShadTheme.of(context)
                            .colorScheme
                            .muted
                            .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    border: isSelected
                        ? Border.all(
                            color: option['primaryColor'],
                            width: 2,
                          )
                        : null,
                  ),
                  child: Icon(
                    option['icon'],
                    color: isSelected ? option['primaryColor'] : null,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),

                // Theme info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'settings.${option['name'].toLowerCase()}'.tr(),
                        style: ShadTheme.of(context).textTheme.large.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? option['primaryColor'] : null,
                            ),
                      ),
                      Text(
                        'settings.${option['name'].toLowerCase()}Description'
                            .tr(),
                        style: ShadTheme.of(context).textTheme.p,
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  )
                else if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    color: ShadTheme.of(context).colorScheme.mutedForeground,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 72),
            child: Divider(height: 1),
          ),
      ],
    );
  }

  Widget _buildDisplayPreferences(SettingsState settings) {
    return SettingsSection(
      title: 'settings.displayPreferences'.tr(),
      children: [
        SettingsItem.toggle(
          icon: Icons.animation,
          title: 'settings.chartAnimations'.tr(),
          subtitle: 'settings.enableChartAnimations'.tr(),
          switchValue: settings.chartAnimationsEnabled,
          onSwitchChanged: _toggleChartAnimations,
          enabled: !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.auto_awesome,
          title: 'settings.smoothAnimations'.tr(),
          subtitle: 'settings.smoothAnimationsDescription'.tr(),
          switchValue: true, // This would come from settings
          onSwitchChanged: _toggleSmoothAnimations,
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.speed,
          title: 'settings.animationSpeed'.tr(),
          subtitle: 'settings.animationSpeedDescription'.tr(),
          value: 'Normal', // This would come from settings
          onTap: _configureAnimationSpeed,
          enabled: !_isLoading,
        ),
        SettingsItem.toggle(
          icon: Icons.reduce_capacity,
          title: 'settings.reduceMotion'.tr(),
          subtitle: 'settings.reduceMotionDescription'.tr(),
          switchValue: false, // This would come from settings
          onSwitchChanged: _toggleReduceMotion,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildAppearanceCustomization(SettingsState settings) {
    return SettingsSection(
      title: 'settings.appearanceCustomization'.tr(),
      children: [
        SettingsItem.navigation(
          icon: Icons.text_fields,
          title: 'settings.fontSize'.tr(),
          subtitle: 'settings.fontSizeDescription'.tr(),
          value: 'Medium', // This would come from settings
          onTap: _configureFontSize,
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.font_download,
          title: 'settings.fontFamily'.tr(),
          subtitle: 'settings.fontFamilyDescription'.tr(),
          value: 'System Default', // This would come from settings
          onTap: _configureFontFamily,
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.palette,
          title: 'settings.accentColor'.tr(),
          subtitle: 'settings.accentColorDescription'.tr(),
          value: 'Blue', // This would come from settings
          onTap: _configureAccentColor,
          enabled: !_isLoading,
          trailing: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              border: Border.all(
                color: ShadTheme.of(context).colorScheme.border,
                width: 1,
              ),
            ),
          ),
        ),
        SettingsItem.toggle(
          icon: Icons.contrast,
          title: 'settings.highContrast'.tr(),
          subtitle: 'settings.highContrastDescription'.tr(),
          switchValue: false, // This would come from settings
          onSwitchChanged: _toggleHighContrast,
          enabled: !_isLoading,
        ),
        SettingsItem.navigation(
          icon: Icons.border_style,
          title: 'settings.borderRadius'.tr(),
          subtitle: 'settings.borderRadiusDescription'.tr(),
          value: 'Medium', // This would come from settings
          onTap: _configureBorderRadius,
          enabled: !_isLoading,
        ),
        SettingsItem.action(
          icon: Icons.refresh,
          title: 'settings.resetTheme'.tr(),
          subtitle: 'settings.resetThemeDescription'.tr(),
          onTap: _resetTheme,
          enabled: !_isLoading,
          trailing: const Icon(Icons.refresh, size: 16),
        ),
      ],
    );
  }

  // Action handlers
  Future<void> _selectTheme(ThemeMode themeMode) async {
    setState(() => _isLoading = true);

    try {
      await ref.read(settingsStateProvider.notifier).setThemeMode(themeMode);

      if (mounted) {
        final themeName = _themeOptions
            .firstWhere((option) => option['mode'] == themeMode)['name'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.themeChanged'.tr(args: [themeName])),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.themeChangeError'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleChartAnimations(bool enabled) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(settingsStateProvider.notifier)
          .setChartAnimationsEnabled(enabled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled
                ? 'settings.chartAnimationsEnabled'.tr()
                : 'settings.chartAnimationsDisabled'.tr()),
          ),
        );
      }
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

  Future<void> _toggleSmoothAnimations(bool enabled) async {
    // Implementation for toggling smooth animations
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Smooth animations ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _configureAnimationSpeed() async {
    // Implementation for configuring animation speed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configure animation speed')),
    );
  }

  Future<void> _toggleReduceMotion(bool enabled) async {
    // Implementation for toggling reduce motion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Reduce motion ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _configureFontSize() async {
    // Implementation for configuring font size
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configure font size')),
    );
  }

  Future<void> _configureFontFamily() async {
    // Implementation for configuring font family
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configure font family')),
    );
  }

  Future<void> _configureAccentColor() async {
    // Implementation for configuring accent color
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configure accent color')),
    );
  }

  Future<void> _toggleHighContrast(bool enabled) async {
    // Implementation for toggling high contrast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('High contrast ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  Future<void> _configureBorderRadius() async {
    // Implementation for configuring border radius
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configure border radius')),
    );
  }

  Future<void> _resetTheme() async {
    final result = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('settings.resetTheme'.tr()),
        description: Text('settings.resetThemeConfirmation'.tr()),
        actions: [
          ShadButton.outline(
            child: Text('common.cancel'.tr()),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton(
            child: Text('settings.reset'.tr()),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        // Reset to system theme
        await ref
            .read(settingsStateProvider.notifier)
            .setThemeMode(ThemeMode.system);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('settings.themeReset'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reset theme: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
