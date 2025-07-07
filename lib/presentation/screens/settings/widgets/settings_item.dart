import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';

enum SettingsItemType { navigation, toggle, action, info }

class SettingsItem extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final SettingsItemType type;
  final bool enabled;
  final bool? switchValue;
  final Function(bool)? onSwitchChanged;
  final Color? iconColor;
  final Color? titleColor;
  final bool showDivider;
  final bool isDestructive;
  final Widget? badge;

  const SettingsItem({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.type = SettingsItemType.navigation,
    this.enabled = true,
    this.switchValue,
    this.onSwitchChanged,
    this.iconColor,
    this.titleColor,
    this.showDivider = false,
    this.isDestructive = false,
    this.badge,
  });

  // Navigation item constructor
  const SettingsItem.navigation({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    required this.onTap,
    this.enabled = true,
    this.iconColor,
    this.titleColor,
    this.showDivider = false,
    this.badge,
  })  : type = SettingsItemType.navigation,
        switchValue = null,
        onSwitchChanged = null,
        isDestructive = false;

  // Toggle item constructor
  const SettingsItem.toggle({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.switchValue,
    required this.onSwitchChanged,
    this.enabled = true,
    this.iconColor,
    this.titleColor,
    this.showDivider = false,
    this.badge,
  })  : type = SettingsItemType.toggle,
        value = null,
        trailing = null,
        onTap = null,
        isDestructive = false;

  // Action item constructor
  const SettingsItem.action({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    this.enabled = true,
    this.iconColor,
    this.titleColor,
    this.showDivider = false,
    this.isDestructive = false,
    this.badge,
  })  : type = SettingsItemType.action,
        value = null,
        switchValue = null,
        onSwitchChanged = null;

  // Info item constructor
  const SettingsItem.info({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.enabled = true,
    this.iconColor,
    this.titleColor,
    this.showDivider = false,
    this.badge,
  })  : type = SettingsItemType.info,
        onTap = null,
        switchValue = null,
        onSwitchChanged = null,
        isDestructive = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingS,
              ),
              child: Row(
                children: [
                  // Leading icon
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (iconColor ?? theme.colorScheme.muted)
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: enabled
                            ? iconColor ?? theme.colorScheme.foreground
                            : theme.colorScheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                  ],

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.p.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: enabled
                                      ? _getTitleColor(theme)
                                      : theme.colorScheme.mutedForeground,
                                ),
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: AppDimensions.spacingS),
                              badge!,
                            ],
                          ],
                        ),

                        // Subtitle
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.small.copyWith(
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ],

                        // Value (for info items)
                        if (value != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            value!,
                            style: theme.textTheme.small.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Trailing content
                  _buildTrailing(theme),
                ],
              ),
            ),
          ),
        ),

        // Divider
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Divider(height: 1),
          ),
      ],
    );
  }

  Widget _buildTrailing(ShadThemeData theme) {
    switch (type) {
      case SettingsItemType.navigation:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: AppDimensions.spacingS),
            ],
            Icon(
              Icons.chevron_right,
              size: 20,
              color: enabled
                  ? theme.colorScheme.mutedForeground
                  : theme.colorScheme.mutedForeground.withOpacity(0.5),
            ),
          ],
        );

      case SettingsItemType.toggle:
        return ShadSwitch(
          value: switchValue ?? false,
          onChanged: enabled ? onSwitchChanged : null,
        );

      case SettingsItemType.action:
        return trailing ?? const SizedBox.shrink();

      case SettingsItemType.info:
        return trailing ?? const SizedBox.shrink();
    }
  }

  Color _getTitleColor(ShadThemeData theme) {
    if (titleColor != null) return titleColor!;
    if (isDestructive) return AppColors.error;
    return theme.colorScheme.foreground;
  }
}

// Specialized settings items for common use cases

class SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const SettingsSection({
    super.key,
    this.title,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimensions.paddingS,
                bottom: AppDimensions.spacingS,
              ),
              child: Text(
                title!,
                style: theme.textTheme.h4.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          ShadCard(
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const SettingsGroup({
    super.key,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingS,
            ),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

// Badge widgets for settings items
class SettingsBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? backgroundColor;

  const SettingsBadge({
    super.key,
    required this.text,
    this.color,
    this.backgroundColor,
  });

  const SettingsBadge.new_({
    super.key,
    required this.text,
  })  : color = Colors.white,
        backgroundColor = AppColors.success;

  const SettingsBadge.beta({
    super.key,
    required this.text,
  })  : color = Colors.white,
        backgroundColor = AppColors.warning;

  const SettingsBadge.pro({
    super.key,
    required this.text,
  })  : color = Colors.white,
        backgroundColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
      ),
      child: Text(
        text,
        style: theme.textTheme.small.copyWith(
          color: color ?? Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Specialized settings items
class LanguageSettingsItem extends StatelessWidget {
  final String currentLanguage;
  final VoidCallback? onTap;
  final bool enabled;

  const LanguageSettingsItem({
    super.key,
    required this.currentLanguage,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsItem.navigation(
      icon: Icons.language,
      title: 'settings.language'.tr(),
      subtitle: 'settings.selectAppLanguage'.tr(),
      value: _getLanguageDisplayName(currentLanguage),
      onTap: onTap,
      enabled: enabled,
    );
  }

  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return languageCode.toUpperCase();
    }
  }
}

class ThemeSettingsItem extends StatelessWidget {
  final ThemeMode currentTheme;
  final VoidCallback? onTap;
  final bool enabled;

  const ThemeSettingsItem({
    super.key,
    required this.currentTheme,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsItem.navigation(
      icon: Icons.palette,
      title: 'settings.theme'.tr(),
      subtitle: 'settings.selectAppTheme'.tr(),
      value: _getThemeDisplayName(currentTheme),
      onTap: onTap,
      enabled: enabled,
    );
  }

  String _getThemeDisplayName(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.light:
        return 'settings.light'.tr();
      case ThemeMode.dark:
        return 'settings.dark'.tr();
      case ThemeMode.system:
        return 'settings.system'.tr();
    }
  }
}

class CurrencySettingsItem extends StatelessWidget {
  final String currentCurrency;
  final VoidCallback? onTap;
  final bool enabled;

  const CurrencySettingsItem({
    super.key,
    required this.currentCurrency,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsItem.navigation(
      icon: Icons.attach_money,
      title: 'settings.baseCurrency'.tr(),
      subtitle: 'settings.selectBaseCurrency'.tr(),
      value: currentCurrency,
      onTap: onTap,
      enabled: enabled,
    );
  }
}
