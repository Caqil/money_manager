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

  static const Map<String, Map<String, String>> _languageData = {
    'en': {'native': 'English', 'flag': '🇺🇸'},
    'es': {'native': 'Español', 'flag': '🇪🇸'},
    'fr': {'native': 'Français', 'flag': '🇫🇷'},
    'de': {'native': 'Deutsch', 'flag': '🇩🇪'},
    'it': {'native': 'Italiano', 'flag': '🇮🇹'},
    'pt': {'native': 'Português', 'flag': '🇧🇷'},
    'ru': {'native': 'Русский', 'flag': '🇷🇺'},
    'ja': {'native': '日本語', 'flag': '🇯🇵'},
    'ko': {'native': '한국어', 'flag': '🇰🇷'},
    'zh': {'native': '中文', 'flag': '🇨🇳'},
    'ar': {'native': 'العربية', 'flag': '🇸🇦'},
    'hi': {'native': 'हिन्दी', 'flag': '🇮🇳'},
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
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ShadInput(
                    controller: _searchController,
                    placeholder: Text('languages.searchPlaceholder'.tr()),
                    leading: const Icon(Icons.search, size: 20),
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),

                // Language list
                Expanded(child: _buildLanguageList(settings, theme)),
              ],
            ),
    );
  }

  Widget _buildLanguageList(SettingsState settings, ShadThemeData theme) {
    final currentLanguage = settings.language;

    var filteredLanguages = _languageData.entries.where((entry) {
      if (_searchQuery.isEmpty) return true;
      return entry.value['native']!.toLowerCase().contains(_searchQuery) ||
          entry.key.toLowerCase().contains(_searchQuery);
    }).toList();

    // Current language first, then alphabetical
    filteredLanguages.sort((a, b) {
      if (a.key == currentLanguage) return -1;
      if (b.key == currentLanguage) return 1;
      return a.value['native']!.compareTo(b.value['native']!);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredLanguages.length,
      itemBuilder: (context, index) {
        final entry = filteredLanguages[index];
        final languageCode = entry.key;
        final languageInfo = entry.value;
        final isSelected = languageCode == currentLanguage;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isSelected ? null : () => _selectLanguage(languageCode),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : theme.colorScheme.background,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : theme.colorScheme.border,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Flag
                    Text(languageInfo['flag']!,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),

                    // Language name
                    Expanded(
                      child: Text(
                        languageInfo['native']!,
                        style: theme.textTheme.p.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                    ),

                    // Check icon
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 20,
                      )
                    else if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectLanguage(String languageCode) async {
    setState(() => _isLoading = true);

    try {
      await ref.read(settingsStateProvider.notifier).setLanguage(languageCode);

      if (mounted) {
        await context.setLocale(Locale(languageCode));

        ShadSonner.of(context).show(
          ShadToast(
            description: Text('languages.changeSuccess'.tr()),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast(
            description: Text('languages.changeError'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
