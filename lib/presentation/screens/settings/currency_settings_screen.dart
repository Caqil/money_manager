import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';

class CurrencySettingsScreen extends ConsumerStatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  ConsumerState<CurrencySettingsScreen> createState() =>
      _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState
    extends ConsumerState<CurrencySettingsScreen> {
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Currency data with display names and regions
  static const Map<String, Map<String, String>> _currencyData = {
    'USD': {'name': 'US Dollar', 'region': 'United States', 'symbol': '\$'},
    'EUR': {'name': 'Euro', 'region': 'European Union', 'symbol': '€'},
    'GBP': {'name': 'British Pound', 'region': 'United Kingdom', 'symbol': '£'},
    'JPY': {'name': 'Japanese Yen', 'region': 'Japan', 'symbol': '¥'},
    'CAD': {'name': 'Canadian Dollar', 'region': 'Canada', 'symbol': 'C\$'},
    'AUD': {
      'name': 'Australian Dollar',
      'region': 'Australia',
      'symbol': 'A\$'
    },
    'CHF': {'name': 'Swiss Franc', 'region': 'Switzerland', 'symbol': 'CHF'},
    'CNY': {'name': 'Chinese Yuan', 'region': 'China', 'symbol': '¥'},
    'INR': {'name': 'Indian Rupee', 'region': 'India', 'symbol': '₹'},
    'KRW': {'name': 'South Korean Won', 'region': 'South Korea', 'symbol': '₩'},
    'SGD': {'name': 'Singapore Dollar', 'region': 'Singapore', 'symbol': 'S\$'},
    'HKD': {
      'name': 'Hong Kong Dollar',
      'region': 'Hong Kong',
      'symbol': 'HK\$'
    },
    'NZD': {
      'name': 'New Zealand Dollar',
      'region': 'New Zealand',
      'symbol': 'NZ\$'
    },
    'SEK': {'name': 'Swedish Krona', 'region': 'Sweden', 'symbol': 'kr'},
    'NOK': {'name': 'Norwegian Krone', 'region': 'Norway', 'symbol': 'kr'},
    'DKK': {'name': 'Danish Krone', 'region': 'Denmark', 'symbol': 'kr'},
    'PLN': {'name': 'Polish Zloty', 'region': 'Poland', 'symbol': 'zł'},
    'CZK': {'name': 'Czech Koruna', 'region': 'Czech Republic', 'symbol': 'Kč'},
    'HUF': {'name': 'Hungarian Forint', 'region': 'Hungary', 'symbol': 'Ft'},
    'RUB': {'name': 'Russian Ruble', 'region': 'Russia', 'symbol': '₽'},
    'BRL': {'name': 'Brazilian Real', 'region': 'Brazil', 'symbol': 'R\$'},
    'MXN': {'name': 'Mexican Peso', 'region': 'Mexico', 'symbol': 'MX\$'},
    'ARS': {'name': 'Argentine Peso', 'region': 'Argentina', 'symbol': '\$'},
    'CLP': {'name': 'Chilean Peso', 'region': 'Chile', 'symbol': '\$'},
    'COP': {'name': 'Colombian Peso', 'region': 'Colombia', 'symbol': '\$'},
    'PEN': {'name': 'Peruvian Sol', 'region': 'Peru', 'symbol': 'S/'},
    'ZAR': {
      'name': 'South African Rand',
      'region': 'South Africa',
      'symbol': 'R'
    },
    'EGP': {'name': 'Egyptian Pound', 'region': 'Egypt', 'symbol': '£'},
    'NGN': {'name': 'Nigerian Naira', 'region': 'Nigeria', 'symbol': '₦'},
    'TRY': {'name': 'Turkish Lira', 'region': 'Turkey', 'symbol': '₺'},
    'ILS': {'name': 'Israeli Shekel', 'region': 'Israel', 'symbol': '₪'},
    'AED': {
      'name': 'UAE Dirham',
      'region': 'United Arab Emirates',
      'symbol': 'د.إ'
    },
    'SAR': {'name': 'Saudi Riyal', 'region': 'Saudi Arabia', 'symbol': 'ر.س'},
    'QAR': {'name': 'Qatari Riyal', 'region': 'Qatar', 'symbol': 'ر.ق'},
    'THB': {'name': 'Thai Baht', 'region': 'Thailand', 'symbol': '฿'},
    'VND': {'name': 'Vietnamese Dong', 'region': 'Vietnam', 'symbol': '₫'},
    'IDR': {'name': 'Indonesian Rupiah', 'region': 'Indonesia', 'symbol': 'Rp'},
    'MYR': {'name': 'Malaysian Ringgit', 'region': 'Malaysia', 'symbol': 'RM'},
    'PHP': {'name': 'Philippine Peso', 'region': 'Philippines', 'symbol': '₱'},
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
        title: 'settings.currency'.tr(),
        showBackButton: true,
      ),
      body: settings.isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                // Current currency section
                _buildCurrentCurrencySection(settings),

                // Search bar
                _buildSearchBar(theme),

                // Currency list
                Expanded(
                  child: _buildCurrencyList(settings),
                ),
              ],
            ),
    );
  }

  Widget _buildCurrentCurrencySection(SettingsState settings) {
    final currentCurrency = settings.baseCurrency;
    final currencyInfo = _currencyData[currentCurrency];

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
                        currencyInfo?['symbol'] ?? currentCurrency,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'settings.currentBaseCurrency'.tr(),
                          style: ShadTheme.of(context).textTheme.small.copyWith(
                                color: ShadTheme.of(context)
                                    .colorScheme
                                    .mutedForeground,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyInfo?['name'] ?? currentCurrency,
                          style: ShadTheme.of(context).textTheme.h4,
                        ),
                        Text(
                          currencyInfo?['region'] ?? '',
                          style: ShadTheme.of(context).textTheme.small.copyWith(
                                color: ShadTheme.of(context)
                                    .colorScheme
                                    .mutedForeground,
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
                      style: ShadTheme.of(context).textTheme.small.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),

              // Sample amount display
              const SizedBox(height: AppDimensions.spacingM),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color:
                      ShadTheme.of(context).colorScheme.muted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'settings.sampleAmount'.tr(),
                      style: ShadTheme.of(context).textTheme.small,
                    ),
                    Text(
                      CurrencyFormatter.format(1234.56,
                          currency: currentCurrency),
                      style: ShadTheme.of(context).textTheme.large.copyWith(
                            fontWeight: FontWeight.w600,
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
        placeholder: Text('settings.searchCurrencies'.tr()),
        leading: const Icon(Icons.search, size: 20),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildCurrencyList(SettingsState settings) {
    final currentCurrency = settings.baseCurrency;
    final recentCurrencies = settings.recentCurrencies;

    // Filter currencies based on search
    final filteredCurrencies = _currencyData.entries.where((entry) {
      if (_searchQuery.isEmpty) return true;

      final code = entry.key.toLowerCase();
      final name = entry.value['name']!.toLowerCase();
      final region = entry.value['region']!.toLowerCase();

      return code.contains(_searchQuery) ||
          name.contains(_searchQuery) ||
          region.contains(_searchQuery);
    }).toList();

    // Sort: current first, then recent, then alphabetical
    filteredCurrencies.sort((a, b) {
      if (a.key == currentCurrency) return -1;
      if (b.key == currentCurrency) return 1;

      final aIsRecent = recentCurrencies.contains(a.key);
      final bIsRecent = recentCurrencies.contains(b.key);

      if (aIsRecent && !bIsRecent) return -1;
      if (!aIsRecent && bIsRecent) return 1;

      return a.value['name']!.compareTo(b.value['name']!);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingM,
      ),
      itemCount:
          filteredCurrencies.length + (recentCurrencies.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        // Show recent currencies section header
        if (recentCurrencies.isNotEmpty && index == 0) {
          return _buildSectionHeader('settings.recentCurrencies'.tr());
        }

        final adjustedIndex = recentCurrencies.isNotEmpty ? index - 1 : index;
        final entry = filteredCurrencies[adjustedIndex];
        final currencyCode = entry.key;
        final currencyInfo = entry.value;

        return _buildCurrencyItem(
          currencyCode,
          currencyInfo,
          currentCurrency,
          recentCurrencies.contains(currencyCode),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.paddingS,
        top: AppDimensions.paddingM,
        bottom: AppDimensions.paddingS,
      ),
      child: Text(
        title,
        style: ShadTheme.of(context).textTheme.h4.copyWith(
              color: AppColors.primary,
            ),
      ),
    );
  }

  Widget _buildCurrencyItem(
    String currencyCode,
    Map<String, String> currencyInfo,
    String currentCurrency,
    bool isRecent,
  ) {
    final isSelected = currencyCode == currentCurrency;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingXs),
      child: ShadCard(
        child: InkWell(
          onTap: isSelected ? null : () => _selectCurrency(currencyCode),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              children: [
                // Currency symbol
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
                      currencyInfo['symbol']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),

                // Currency info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            currencyCode,
                            style: ShadTheme.of(context)
                                .textTheme
                                .large
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? AppColors.primary : null,
                                ),
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          if (isRecent && !isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusXs),
                              ),
                              child: Text(
                                'settings.recent'.tr(),
                                style: ShadTheme.of(context)
                                    .textTheme
                                    .small
                                    .copyWith(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        currencyInfo['name']!,
                        style: ShadTheme.of(context).textTheme.p,
                      ),
                      Text(
                        currencyInfo['region']!,
                        style: ShadTheme.of(context).textTheme.small.copyWith(
                              color: ShadTheme.of(context)
                                  .colorScheme
                                  .mutedForeground,
                            ),
                      ),
                    ],
                  ),
                ),

                // Sample amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(100, currency: currencyCode),
                      style: ShadTheme.of(context).textTheme.p.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
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
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectCurrency(String currencyCode) async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(settingsStateProvider.notifier)
          .setBaseCurrency(currencyCode);

      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description:
                Text('settings.currencyChanged'.tr(args: [currencyCode])),
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
            description:
                Text('settings.currencyChangeError'.tr(args: [e.toString()])),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
