import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  // Currency Symbols Map
  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CNY': '¥',
    'INR': '₹',
    'KRW': '₩',
    'BRL': 'R\$',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CHF': 'CHF',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'PLN': 'zł',
    'CZK': 'Kč',
    'HUF': 'Ft',
    'RUB': '₽',
    'TRY': '₺',
    'ZAR': 'R',
    'MXN': '\$',
    'SGD': 'S\$',
    'HKD': 'HK\$',
    'NZD': 'NZ\$',
    'THB': '฿',
    'MYR': 'RM',
    'IDR': 'Rp',
    'PHP': '₱',
    'VND': '₫',
    'TWD': 'NT\$',
    'ILS': '₪',
    'AED': 'د.إ',
    'SAR': 'ر.س',
    'EGP': 'ج.م',
    'NGN': '₦',
    'KES': 'KSh',
    'GHS': '₵',
    'UGX': 'USh',
    'TZS': 'TSh',
    'ZMW': 'ZK',
    'BWP': 'P',
    'NAD': 'N\$',
    'SZL': 'L',
    'LSL': 'L',
  };

  // Decimal Places Map
  static const Map<String, int> _decimalPlaces = {
    'JPY': 0,
    'KRW': 0,
    'VND': 0,
    'CLP': 0,
    'ISK': 0,
    'UGX': 0,
    'RWF': 0,
    'XAF': 0,
    'XOF': 0,
    'XPF': 0,
    'BIF': 0,
    'DJF': 0,
    'GNF': 0,
    'KMF': 0,
    'MGA': 1,
    'MRU': 1,
    'BHD': 3,
    'IQD': 3,
    'JOD': 3,
    'KWD': 3,
    'LYD': 3,
    'OMR': 3,
    'TND': 3,
  };

  // Format currency amount
  static String format(
    double amount, {
    String currency = 'USD',
    bool showSymbol = true,
    bool showCode = false,
    int? decimalPlaces,
    String? locale,
  }) {
    final symbol = _currencySymbols[currency] ?? currency;
    final decimals = decimalPlaces ?? _decimalPlaces[currency] ?? 2;

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: showSymbol ? symbol : '',
      decimalDigits: decimals,
    );

    final formatted = formatter.format(amount);

    if (showCode && currency != symbol) {
      return '$formatted $currency';
    }

    return formatted;
  }

  // Format with custom settings
  static String formatCustom(
    double amount, {
    required String symbol,
    int decimalPlaces = 2,
    bool symbolAtStart = true,
    bool useThousandsSeparator = true,
    String thousandsSeparator = ',',
    String decimalSeparator = '.',
  }) {
    final absAmount = amount.abs();
    final isNegative = amount < 0;

    // Format the number
    String formatted = absAmount.toStringAsFixed(decimalPlaces);

    // Add thousands separator
    if (useThousandsSeparator) {
      final parts = formatted.split('.');
      final integerPart = parts[0];
      final decimalPart = parts.length > 1 ? parts[1] : '';

      final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      final formattedInteger = integerPart.replaceAllMapped(
        regex,
        (match) => '${match[1]}$thousandsSeparator',
      );

      formatted = decimalPart.isNotEmpty
          ? '$formattedInteger$decimalSeparator$decimalPart'
          : formattedInteger;
    }

    // Add symbol and sign
    final signedFormatted = isNegative ? '-$formatted' : formatted;

    if (symbolAtStart) {
      return '$symbol$signedFormatted';
    } else {
      return '$signedFormatted$symbol';
    }
  }

  // Compact format (e.g., $1.2K, $1.5M)
  static String formatCompact(
    double amount, {
    String currency = 'USD',
    int decimalPlaces = 1,
  }) {
    final symbol = _currencySymbols[currency] ?? currency;
    final absAmount = amount.abs();
    final isNegative = amount < 0;

    String formatted;

    if (absAmount >= 1000000000) {
      formatted = '${(absAmount / 1000000000).toStringAsFixed(decimalPlaces)}B';
    } else if (absAmount >= 1000000) {
      formatted = '${(absAmount / 1000000).toStringAsFixed(decimalPlaces)}M';
    } else if (absAmount >= 1000) {
      formatted = '${(absAmount / 1000).toStringAsFixed(decimalPlaces)}K';
    } else {
      formatted = absAmount.toStringAsFixed(0);
    }

    final signedFormatted = isNegative ? '-$formatted' : formatted;
    return '$symbol$signedFormatted';
  }

  // Parse currency string to double
  static double? parse(String value, {String currency = 'USD'}) {
    if (value.isEmpty) return null;

    final symbol = _currencySymbols[currency] ?? currency;

    // Remove currency symbols and common formatting
    String cleaned = value
        .replaceAll(symbol, '')
        .replaceAll(currency, '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    // Handle negative values
    final isNegative = cleaned.startsWith('-') || cleaned.startsWith('(');
    if (isNegative) {
      cleaned = cleaned.replaceAll(RegExp(r'[-()]'), '');
    }

    final parsed = double.tryParse(cleaned);
    return parsed != null ? (isNegative ? -parsed : parsed) : null;
  }

  // Get currency symbol
  static String getSymbol(String currency) {
    return _currencySymbols[currency] ?? currency;
  }

  // Get decimal places for currency
  static int getDecimalPlaces(String currency) {
    return _decimalPlaces[currency] ?? 2;
  }

  // Check if currency exists
  static bool isValidCurrency(String currency) {
    return _currencySymbols.containsKey(currency);
  }

  // Get all supported currencies
  static List<String> getSupportedCurrencies() {
    return _currencySymbols.keys.toList()..sort();
  }

  // Format percentage
  static String formatPercentage(
    double value, {
    int decimalPlaces = 1,
    bool showSign = true,
  }) {
    final formatted = (value * 100).toStringAsFixed(decimalPlaces);
    final sign = showSign && value > 0 ? '+' : '';
    return '$sign$formatted%';
  }
}
