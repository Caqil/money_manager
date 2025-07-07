import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../providers/settings_provider.dart';

class CurrencyDisplayWidget extends ConsumerWidget {
  final double amount;
  final String? currency;
  final TextStyle? style;
  final Color? color;
  final int? decimalPlaces;
  final bool showSign;
  final bool showCurrency;
  final bool compact;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool isIncome;
  final bool isExpense;
  final bool autoColor;

  const CurrencyDisplayWidget({
    super.key,
    required this.amount,
    this.currency,
    this.style,
    this.color,
    this.decimalPlaces,
    this.showSign = false,
    this.showCurrency = true,
    this.compact = false,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.isIncome = false,
    this.isExpense = false,
    this.autoColor = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseCurrency = ref.watch(baseCurrencyProvider);
    final effectiveCurrency = currency ?? baseCurrency;
    final theme = Theme.of(context);

    // Determine color
    Color? effectiveColor = color;
    if (autoColor) {
      if (isIncome || amount > 0) {
        effectiveColor = AppColors.income;
      } else if (isExpense || amount < 0) {
        effectiveColor = AppColors.expense;
      }
    }

    // Format amount
    final formattedAmount = _formatAmount(
      amount,
      effectiveCurrency,
      decimalPlaces: decimalPlaces,
      compact: compact,
      showSign: showSign,
    );

    // Build display based on layout preference
    if (compact) {
      return Text(
        formattedAmount,
        style: (style ?? AppTextStyles.bodyMedium).copyWith(
          color: effectiveColor,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.end,
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Currency symbol
        if (showCurrency) ...[
          Text(
            _getCurrencySymbol(effectiveCurrency),
            style: (style ?? AppTextStyles.bodyMedium).copyWith(
              color: effectiveColor?.withOpacity(0.8) ??
                  theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingXs),
        ],

        // Amount
        Text(
          _formatAmountOnly(
            amount,
            decimalPlaces: decimalPlaces,
            compact: compact,
            showSign: showSign,
          ),
          style: (style ?? AppTextStyles.bodyMedium).copyWith(
            color: effectiveColor,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Currency code (if showing currency and not using symbol)
        if (showCurrency && _shouldShowCurrencyCode(effectiveCurrency)) ...[
          const SizedBox(width: AppDimensions.spacingXs),
          Text(
            effectiveCurrency,
            style: (style ?? AppTextStyles.bodySmall).copyWith(
              color: effectiveColor?.withOpacity(0.8) ??
                  theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  String _formatAmount(
    double amount,
    String currency, {
    int? decimalPlaces,
    bool compact = false,
    bool showSign = false,
  }) {
    final formatter = NumberFormat.currency(
      locale: 'en_US', // Can be made dynamic based on locale
      symbol: _getCurrencySymbol(currency),
      decimalDigits: decimalPlaces ?? 2,
    );

    if (compact && amount.abs() >= 1000) {
      return _formatCompactCurrency(amount, currency, showSign: showSign);
    }

    String formatted = formatter.format(amount.abs());

    if (showSign) {
      if (amount > 0) {
        formatted = '+$formatted';
      } else if (amount < 0) {
        formatted = '-$formatted';
      }
    } else if (amount < 0) {
      formatted = '-$formatted';
    }

    return formatted;
  }

  String _formatAmountOnly(
    double amount, {
    int? decimalPlaces,
    bool compact = false,
    bool showSign = false,
  }) {
    final formatter = NumberFormat(
      '#,##0.${'0' * (decimalPlaces ?? 2)}',
      'en_US',
    );

    if (compact && amount.abs() >= 1000) {
      return _formatCompactNumber(amount, showSign: showSign);
    }

    String formatted = formatter.format(amount.abs());

    if (showSign) {
      if (amount > 0) {
        formatted = '+$formatted';
      } else if (amount < 0) {
        formatted = '-$formatted';
      }
    } else if (amount < 0) {
      formatted = '-$formatted';
    }

    return formatted;
  }

  String _formatCompactCurrency(
    double amount,
    String currency, {
    bool showSign = false,
  }) {
    final symbol = _getCurrencySymbol(currency);
    final compactNumber = _formatCompactNumber(amount, showSign: showSign);
    return '$symbol$compactNumber';
  }

  String _formatCompactNumber(double amount, {bool showSign = false}) {
    final absAmount = amount.abs();
    String suffix = '';
    double displayAmount = absAmount;

    if (absAmount >= 1000000000) {
      displayAmount = absAmount / 1000000000;
      suffix = 'B';
    } else if (absAmount >= 1000000) {
      displayAmount = absAmount / 1000000;
      suffix = 'M';
    } else if (absAmount >= 1000) {
      displayAmount = absAmount / 1000;
      suffix = 'K';
    }

    final formatter = NumberFormat('#,##0.#', 'en_US');
    String formatted = formatter.format(displayAmount) + suffix;

    if (showSign) {
      if (amount > 0) {
        formatted = '+$formatted';
      } else if (amount < 0) {
        formatted = '-$formatted';
      }
    } else if (amount < 0) {
      formatted = '-$formatted';
    }

    return formatted;
  }

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'INR':
        return '₹';
      case 'CNY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'IDR':
        return 'Rp';
      case 'SGD':
        return 'S\$';
      case 'AUD':
        return 'A\$';
      case 'CAD':
        return 'C\$';
      case 'CHF':
        return 'CHF';
      default:
        return currencyCode;
    }
  }

  bool _shouldShowCurrencyCode(String currencyCode) {
    // Show currency code for currencies without unique symbols
    final currenciesWithoutSymbols = ['CHF', 'SEK', 'NOK', 'DKK', 'PLN'];
    return currenciesWithoutSymbols.contains(currencyCode.toUpperCase());
  }
}

// Specialized currency display widgets for common use cases

/// Large currency display for main amounts
class CurrencyDisplayLarge extends StatelessWidget {
  final double amount;
  final String? currency;
  final bool autoColor;

  const CurrencyDisplayLarge({
    super.key,
    required this.amount,
    this.currency,
    this.autoColor = false,
  });

  @override
  Widget build(BuildContext context) {
    return CurrencyDisplayWidget(
      amount: amount,
      currency: currency,
      style: AppTextStyles.currencyLarge,
      autoColor: autoColor,
    );
  }
}

/// Medium currency display for cards and list items
class CurrencyDisplayMedium extends StatelessWidget {
  final double amount;
  final String? currency;
  final bool autoColor;
  final bool compact;

  const CurrencyDisplayMedium({
    super.key,
    required this.amount,
    this.currency,
    this.autoColor = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return CurrencyDisplayWidget(
      amount: amount,
      currency: currency,
      style: AppTextStyles.currencyMedium,
      autoColor: autoColor,
      compact: compact,
    );
  }
}

/// Small currency display for compact layouts
class CurrencyDisplaySmall extends StatelessWidget {
  final double amount;
  final String? currency;
  final bool autoColor;
  final bool compact;

  const CurrencyDisplaySmall({
    super.key,
    required this.amount,
    this.currency,
    this.autoColor = false,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    return CurrencyDisplayWidget(
      amount: amount,
      currency: currency,
      style: AppTextStyles.currencySmall,
      autoColor: autoColor,
      compact: compact,
    );
  }
}

/// Income amount display (always green)
class IncomeDisplay extends StatelessWidget {
  final double amount;
  final String? currency;
  final TextStyle? style;
  final bool showSign;

  const IncomeDisplay({
    super.key,
    required this.amount,
    this.currency,
    this.style,
    this.showSign = true,
  });

  @override
  Widget build(BuildContext context) {
    return CurrencyDisplayWidget(
      amount: amount,
      currency: currency,
      style: style,
      color: AppColors.income,
      isIncome: true,
      showSign: showSign,
    );
  }
}

/// Expense amount display (always red)
class ExpenseDisplay extends StatelessWidget {
  final double amount;
  final String? currency;
  final TextStyle? style;
  final bool showSign;

  const ExpenseDisplay({
    super.key,
    required this.amount,
    this.currency,
    this.style,
    this.showSign = true,
  });

  @override
  Widget build(BuildContext context) {
    return CurrencyDisplayWidget(
      amount: amount,
      currency: currency,
      style: style,
      color: AppColors.expense,
      isExpense: true,
      showSign: showSign,
    );
  }
}
