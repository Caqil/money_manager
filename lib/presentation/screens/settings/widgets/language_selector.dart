import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../providers/settings_provider.dart';

class LanguageInfo {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRTL;

  const LanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.isRTL = false,
  });
}

class LanguageSelector extends ConsumerStatefulWidget {
  final String? selectedLanguage;
  final Function(String)? onLanguageChanged;
  final bool showNativeNames;
  final bool showFlags;
  final bool enabled;

  const LanguageSelector({
    super.key,
    this.selectedLanguage,
    this.onLanguageChanged,
    this.showNativeNames = true,
    this.showFlags = true,
    this.enabled = true,
  });

  @override
  ConsumerState<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends ConsumerState<LanguageSelector> {
  bool _isLoading = false;

  // Supported languages - matches your app constants
  static const List<LanguageInfo> _supportedLanguages = [
    LanguageInfo(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    LanguageInfo(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
    ),
    LanguageInfo(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
    ),
    LanguageInfo(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
    ),
    LanguageInfo(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
      flag: '🇮🇹',
    ),
    LanguageInfo(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      flag: '🇵🇹',
    ),
    LanguageInfo(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      flag: '🇷🇺',
    ),
    LanguageInfo(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
    ),
    LanguageInfo(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      flag: '🇰🇷',
    ),
    LanguageInfo(
      code: 'zh',
      name: 'Chinese',
      nativeName: '中文',
      flag: '🇨🇳',
    ),
    LanguageInfo(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
      isRTL: true,
    ),
    LanguageInfo(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
    ),
  ];

  String get _currentLanguage =>
      widget.selectedLanguage ?? ref.watch(languageProvider);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current language display
        _buildCurrentLanguageCard(),
        const SizedBox(height: AppDimensions.spacingM),

        // Language list
        _buildLanguageList(),
      ],
    );
  }

  Widget _buildCurrentLanguageCard() {
    final theme = ShadTheme.of(context);
    final currentLang = _getCurrentLanguageInfo();

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            // Flag
            if (widget.showFlags) ...[
              Text(
                currentLang.flag,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppDimensions.spacingM),
            ],

            // Language info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings.currentLanguage'.tr(),
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    widget.showNativeNames
                        ? currentLang.nativeName
                        : currentLang.name,
                    style: theme.textTheme.h4,
                  ),
                  if (widget.showNativeNames &&
                      currentLang.name != currentLang.nativeName) ...[
                    const SizedBox(height: 2),
                    Text(
                      currentLang.name,
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageList() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings.availableLanguages'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),

        // Search bar for languages
        ShadInput(
          placeholder: Text('settings.searchLanguages'.tr()),
          leading: const Icon(Icons.search, size: 18),
          onChanged: (value) {
            // Implement search functionality if needed
          },
        ),
        const SizedBox(height: AppDimensions.spacingS),

        // Language grid
        _buildLanguageGrid(),
      ],
    );
  }

  Widget _buildLanguageGrid() {
    final currentLang = _currentLanguage;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDimensions.spacingS,
        mainAxisSpacing: AppDimensions.spacingS,
        childAspectRatio: 3,
      ),
      itemCount: _supportedLanguages.length,
      itemBuilder: (context, index) {
        final language = _supportedLanguages[index];
        final isSelected = language.code == currentLang;
        final isCurrentlyLoading = _isLoading && isSelected;

        return _buildLanguageCard(language, isSelected, isCurrentlyLoading);
      },
    );
  }

  Widget _buildLanguageCard(
      LanguageInfo language, bool isSelected, bool isLoading) {
    final theme = ShadTheme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.enabled && !_isLoading && !isSelected
            ? () => _selectLanguage(language)
            : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : theme.colorScheme.muted.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(
              color: isSelected ? AppColors.primary : theme.colorScheme.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Flag
              if (widget.showFlags) ...[
                Text(
                  language.flag,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppDimensions.spacingS),
              ],

              // Language info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.showNativeNames
                          ? language.nativeName
                          : language.name,
                      style: theme.textTheme.p.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.showNativeNames &&
                        language.name != language.nativeName) ...[
                      const SizedBox(height: 2),
                      Text(
                        language.name,
                        style: theme.textTheme.small.copyWith(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.8)
                              : theme.colorScheme.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Status indicator
              if (isLoading) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ] else if (isSelected) ...[
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectLanguage(LanguageInfo language) async {
    if (!widget.enabled || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update language in EasyLocalization
      await context.setLocale(Locale(language.code));

      // Update in settings
      await ref.read(settingsStateProvider.notifier).setLanguage(language.code);

      // Call callback
      widget.onLanguageChanged?.call(language.code);

      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text('settings.languageChanged'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text('settings.languageChangeError'.tr()),
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

  LanguageInfo _getCurrentLanguageInfo() {
    return _supportedLanguages.firstWhere(
      (lang) => lang.code == _currentLanguage,
      orElse: () => _supportedLanguages.first,
    );
  }
}

// Language selector for use in dropdowns/selects
class CompactLanguageSelector extends ConsumerWidget {
  final String? selectedLanguage;
  final Function(String)? onLanguageChanged;
  final bool enabled;

  const CompactLanguageSelector({
    super.key,
    this.selectedLanguage,
    this.onLanguageChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = selectedLanguage ?? ref.watch(languageProvider);
    const languages = _LanguageSelectorState._supportedLanguages;

    return ShadSelectFormField<String>(
      enabled: enabled,
      placeholder: Text('settings.selectLanguage'.tr()),
      options: languages
          .map((language) => ShadOption(
                value: language.code,
                child: Row(
                  children: [
                    Text(
                      language.flag,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text(language.nativeName),
                    if (language.name != language.nativeName) ...[
                      const SizedBox(width: AppDimensions.spacingS),
                      Text(
                        '(${language.name})',
                        style: TextStyle(
                          color: AppColors.lightOnSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ))
          .toList(),
      selectedOptionBuilder: (context, value) {
        if (value == null) return Text('settings.selectLanguage'.tr());
        final language = languages.firstWhere((lang) => lang.code == value);
        return Row(
          children: [
            Text(
              language.flag,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Text(language.nativeName),
          ],
        );
      },
      onChanged: onLanguageChanged as ValueChanged<String?>?,
      initialValue: currentLanguage,
    );
  }
}
