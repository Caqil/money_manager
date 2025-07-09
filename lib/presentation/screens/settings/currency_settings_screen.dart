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

  static const Map<String, Map<String, String>> _currencyData = {
    'USD': {'name': 'US Dollar', 'symbol': '\$'},
    'EUR': {'name': 'Euro', 'symbol': '€'},
    'GBP': {'name': 'British Pound', 'symbol': '£'},
    'JPY': {'name': 'Japanese Yen', 'symbol': '¥'},
    'CAD': {'name': 'Canadian Dollar', 'symbol': 'C\$'},
    'AUD': {'name': 'Australian Dollar', 'symbol': 'A\$'},
    'CHF': {'name': 'Swiss Franc', 'symbol': 'CHF'},
    'CNY': {'name': 'Chinese Yuan', 'symbol': '¥'},
    'INR': {'name': 'Indian Rupee', 'symbol': '₹'},
    'KRW': {'name': 'South Korean Won', 'symbol': '₩'},
    'SGD': {'name': 'Singapore Dollar', 'symbol': 'S\$'},
    'HKD': {'name': 'Hong Kong Dollar', 'symbol': 'HK\$'},
    'NZD': {'name': 'New Zealand Dollar', 'symbol': 'NZ\$'},
    'SEK': {'name': 'Swedish Krona', 'symbol': 'kr'},
    'NOK': {'name': 'Norwegian Krone', 'symbol': 'kr'},
    'DKK': {'name': 'Danish Krone', 'symbol': 'kr'},
    'PLN': {'name': 'Polish Zloty', 'symbol': 'zł'},
    'CZK': {'name': 'Czech Koruna', 'symbol': 'Kč'},
    'HUF': {'name': 'Hungarian Forint', 'symbol': 'Ft'},
    'RUB': {'name': 'Russian Ruble', 'symbol': '₽'},
    'BRL': {'name': 'Brazilian Real', 'symbol': 'R\$'},
    'MXN': {'name': 'Mexican Peso', 'symbol': 'MX\$'},
    'ARS': {'name': 'Argentine Peso', 'symbol': '\$'},
    'CLP': {'name': 'Chilean Peso', 'symbol': '\$'},
    'COP': {'name': 'Colombian Peso', 'symbol': '\$'},
    'PEN': {'name': 'Peruvian Sol', 'symbol': 'S/'},
    'ZAR': {'name': 'South African Rand', 'symbol': 'R'},
    'EGP': {'name': 'Egyptian Pound', 'symbol': '£'},
    'NGN': {'name': 'Nigerian Naira', 'symbol': '₦'},
    'TRY': {'name': 'Turkish Lira', 'symbol': '₺'},
    'ILS': {'name': 'Israeli Shekel', 'symbol': '₪'},
    'AED': {'name': 'UAE Dirham', 'symbol': 'د.إ'},
    'SAR': {'name': 'Saudi Riyal', 'symbol': 'ر.س'},
    'QAR': {'name': 'Qatari Riyal', 'symbol': 'ر.ق'},
    'THB': {'name': 'Thai Baht', 'symbol': '฿'},
    'VND': {'name': 'Vietnamese Dong', 'symbol': '₫'},
    'IDR': {'name': 'Indonesian Rupiah', 'symbol': 'Rp'},
    'MYR': {'name': 'Malaysian Ringgit', 'symbol': 'RM'},
    'PHP': {'name': 'Philippine Peso', 'symbol': '₱'},
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
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ShadInput(
                    controller: _searchController,
                    placeholder: Text('currencies.searchPlaceholder'.tr()),
                    leading: const Icon(Icons.search, size: 20),
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),

                // Currency list
                Expanded(child: _buildCurrencyList(settings, theme)),
              ],
            ),
    );
  }

  Widget _buildCurrencyList(SettingsState settings, ShadThemeData theme) {
    final currentCurrency = settings.baseCurrency;

    var filteredCurrencies = _currencyData.entries.where((entry) {
      if (_searchQuery.isEmpty) return true;
      return entry.value['name']!.toLowerCase().contains(_searchQuery) ||
          entry.key.toLowerCase().contains(_searchQuery);
    }).toList();

    // Current currency first, then alphabetical
    filteredCurrencies.sort((a, b) {
      if (a.key == currentCurrency) return -1;
      if (b.key == currentCurrency) return 1;
      return a.value['name']!.compareTo(b.value['name']!);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredCurrencies.length,
      itemBuilder: (context, index) {
        final entry = filteredCurrencies[index];
        final currencyCode = entry.key;
        final currencyInfo = entry.value;
        final isSelected = currencyCode == currentCurrency;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isSelected ? null : () => _selectCurrency(currencyCode),
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
                    // Currency symbol
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.15)
                            : theme.colorScheme.muted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(width: 16),

                    // Currency info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyCode,
                            style: theme.textTheme.large.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.primary : null,
                            ),
                          ),
                          Text(
                            currencyInfo['name']!,
                            style: theme.textTheme.p.copyWith(
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Check icon or sample amount
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
                      )
                    else
                      Text(
                        CurrencyFormatter.format(100, currency: currencyCode),
                        style: theme.textTheme.small.copyWith(
                          color: theme.colorScheme.mutedForeground,
                          fontWeight: FontWeight.w500,
                        ),
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

  Future<void> _selectCurrency(String currencyCode) async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(settingsStateProvider.notifier)
          .setBaseCurrency(currencyCode);

      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast(
            description:
                Text('currencies.changeSuccess'.tr(args: [currencyCode])),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.destructive(
            description: Text('currencies.changeError'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
