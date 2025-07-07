import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState
    extends ConsumerState<LanguageSettingsScreen> {
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Language data with native names and regions
  static const Map<String, Map<String, String>> _languageData = {
    'en': {
      'native': 'English',
      'english': 'English',
      'region': 'United States',
      'flag': '🇺🇸',
      'completion': '100%'
    },
    'es': {
      'native': 'Español',
      'english': 'Spanish',
      'region': 'Spain',
      'flag': '🇪🇸',
      'completion': '95%'
    },
    'fr': {
      'native': 'Français',
      'english': 'French',
      'region': 'France',
      'flag': '🇫🇷',
      'completion': '90%'
    },
    'de': {
      'native': 'Deutsch',
      'english': 'German',
      'region': 'Germany',
      'flag': '🇩🇪',
      'completion': '85%'
    },
    'it': {
      'native': 'Italiano',
      'english': 'Italian',
      'region': 'Italy',
      'flag': '🇮🇹',
      'completion': '80%'
    },
    'pt': {
      'native': 'Português',
      'english': 'Portuguese',
      'region': 'Brazil',
      'flag': '🇧🇷',
      'completion': '75%'
    },
    'ru': {
      'native': 'Русский',
      'english': 'Russian',
      'region': 'Russia',
      'flag': '🇷🇺',
      'completion': '70%'
    },
    'ja': {
      'native': '日本語',
      'english': 'Japanese',
      'region': 'Japan',
      'flag': '🇯🇵',
      'completion': '65%'
    },
    'ko': {
      'native': '한국어',
      'english': 'Korean',
      'region': 'South Korea',
      'flag': '🇰🇷',
      'completion': '60%'
    },
    'zh': {
      'native': '中文',
      'english': 'Chinese',
      'region': 'China',
      'flag': '🇨🇳',
      'completion': '55%'
    },
    'ar': {
      'native': 'العربية',
      'english': 'Arabic',
      'region': 'Saudi Arabia',
      'flag': '🇸🇦',
      'completion': '50%'
    },
    'hi': {
      'native': 'हिन्दी',
      'english': 'Hindi',
      'region': 'India',
      'flag': '🇮🇳',
      'completion': '45%'
    },
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final settings = ref.watch(settingsStateProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'settings.language'.tr(),
        showBackButton: true,
      ),
      body: settings.isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                // Current language section
                _buildCurrentLanguageSection(settings),

                // Search bar
                _buildSearchBar(theme),

                // Info section
                _buildInfoSection(),

                // Language list
                Expanded(
                  child: _buildLanguageList(settings),
                ),
              ],
            ),
    );
  }

  Widget _buildCurrentLanguageSection(SettingsState settings) {
    final currentLanguage = settings.language;
    final languageInfo = _languageData[currentLanguage] ??
        {
          'native': currentLanguage,
          'english': currentLanguage,
          'region': '',
          'flag': '🌐',
          'completion': '100%'
        };
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: Center(
                      child: Text(
                        languageInfo['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
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
                        const SizedBox(height: 2),
                        Text(
                          languageInfo['native']!,
                          style: theme.textTheme.h4,
                        ),
                        Text(
                          languageInfo['english']!,
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

              // Sample text
              const SizedBox(height: AppDimensions.spacingM),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'settings.sampleText'.tr(),
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome to Money Manager!',
                      style: theme.textTheme.p.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ShadThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: ShadInput(
        controller: _searchController,
        placeholder: Text('settings.searchLanguages'.tr()),
        leading: const Icon(Icons.search, size: 20),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingL),
      child: ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  'settings.languageInfo'.tr(),
                  style: ShadTheme.of(context).textTheme.small.copyWith(
                        color:
                            ShadTheme.of(context).colorScheme.mutedForeground,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageList(SettingsState settings) {
    final currentLanguage = settings.language;

    // Filter languages based on search
    final filteredLanguages = _languageData.entries.where((entry) {
      if (_searchQuery.isEmpty) return true;

      final code = entry.key.toLowerCase();
      final native = entry.value['native']!.toLowerCase();
      final english = entry.value['english']!.toLowerCase();
      final region = entry.value['region']!.toLowerCase();

      return code.contains(_searchQuery) ||
          native.contains(_searchQuery) ||
          english.contains(_searchQuery) ||
          region.contains(_searchQuery);
    }).toList();

    // Sort: current first, then by completion percentage
    filteredLanguages.sort((a, b) {
      if (a.key == currentLanguage) return -1;
      if (b.key == currentLanguage) return 1;

      final aCompletion = int.parse(a.value['completion']!.replaceAll('%', ''));
      final bCompletion = int.parse(b.value['completion']!.replaceAll('%', ''));

      return bCompletion.compareTo(aCompletion);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingM,
      ),
      itemCount: filteredLanguages.length,
      itemBuilder: (context, index) {
        final entry = filteredLanguages[index];
        final languageCode = entry.key;
        final languageInfo = entry.value;

        return _buildLanguageItem(
          languageCode,
          languageInfo,
          currentLanguage,
        );
      },
    );
  }

  Widget _buildLanguageItem(
    String languageCode,
    Map<String, String> languageInfo,
    String currentLanguage,
  ) {
    final isSelected = languageCode == currentLanguage;
    final completion =
        int.parse(languageInfo['completion']!.replaceAll('%', ''));

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingXs),
      child: ShadCard(
        child: InkWell(
          onTap: isSelected ? null : () => _selectLanguage(languageCode),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              children: [
                // Flag
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : ShadTheme.of(context)
                            .colorScheme
                            .muted
                            .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Center(
                    child: Text(
                      languageInfo['flag']!,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),

                // Language info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            languageInfo['native']!,
                            style: ShadTheme.of(context)
                                .textTheme
                                .large
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? AppColors.primary : null,
                                ),
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          if (completion < 100)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getCompletionColor(completion)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusXs),
                              ),
                              child: Text(
                                languageInfo['completion']!,
                                style: ShadTheme.of(context)
                                    .textTheme
                                    .small
                                    .copyWith(
                                      color: _getCompletionColor(completion),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        languageInfo['english']!,
                        style: ShadTheme.of(context).textTheme.p,
                      ),
                      if (languageInfo['region']!.isNotEmpty)
                        Text(
                          languageInfo['region']!,
                          style: ShadTheme.of(context).textTheme.small.copyWith(
                                color: ShadTheme.of(context)
                                    .colorScheme
                                    .mutedForeground,
                              ),
                        ),
                    ],
                  ),
                ),

                // Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                        color:
                            ShadTheme.of(context).colorScheme.mutedForeground,
                        size: 20,
                      ),

                    // Completion progress bar
                    if (completion < 100) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ShadTheme.of(context).colorScheme.muted,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: completion / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getCompletionColor(completion),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCompletionColor(int completion) {
    if (completion >= 90) return AppColors.success;
    if (completion >= 70) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _selectLanguage(String languageCode) async {
    setState(() => _isLoading = true);

    try {
      // Update settings
      await ref.read(settingsStateProvider.notifier).setLanguage(languageCode);

      // Change app locale
      if (mounted) {
        final newLocale = Locale(languageCode);
        await context.setLocale(newLocale);

        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text('settings.languageChanged'.tr()),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate back after successful change
        Navigator.of(context).pop();
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
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
