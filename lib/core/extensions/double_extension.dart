import 'dart:math' as math;
import 'package:intl/intl.dart';

import '../utils/currency_formatter.dart';
import '../utils/file_helper.dart';

extension DoubleExtension on double {
  // Currency formatting
  String toCurrency({
    String currency = 'USD',
    bool showSymbol = true,
    bool showCode = false,
    int? decimalPlaces,
  }) {
    return CurrencyFormatter.format(
      this,
      currency: currency,
      showSymbol: showSymbol,
      showCode: showCode,
      decimalPlaces: decimalPlaces,
    );
  }

  // Compact currency formatting
  String toCurrencyCompact({
    String currency = 'USD',
    int decimalPlaces = 1,
  }) {
    return CurrencyFormatter.formatCompact(
      this,
      currency: currency,
      decimalPlaces: decimalPlaces,
    );
  }

  // Percentage formatting
  String toPercentage({
    int decimalPlaces = 1,
    bool showSign = true,
  }) {
    return CurrencyFormatter.formatPercentage(
      this,
      decimalPlaces: decimalPlaces,
      showSign: showSign,
    );
  }

  // Round to specific decimal places
  double roundToDecimal(int places) {
    final factor = math.pow(10, places).toDouble();
    return (this * factor).round() / factor;
  }

  // Check if value is positive
  bool get isPositive => this > 0;

  // Check if value is negative
  bool get isNegative => this < 0;

  // Check if value is zero or close to zero
  bool get isZero => abs() < 0.01;

  // Get absolute value
  double get positive => abs();

  // Format with thousand separators
  String toStringWithSeparator({
    String separator = ',',
    int decimalPlaces = 2,
  }) {
    final formatter = NumberFormat('#,##0.${'0' * decimalPlaces}');
    return formatter.format(this);
  }

  // Convert to different units
  double get toKilo => this / 1000;
  double get toMillion => this / 1000000;
  double get toBillion => this / 1000000000;

  // Safe operations
  double safeAdd(double other) {
    return (this * 100 + other * 100) / 100;
  }

  double safeSubtract(double other) {
    return (this * 100 - other * 100) / 100;
  }

  double safeMultiply(double other) {
    return (this * 100 * other) / 100;
  }

  double safeDivide(double other) {
    if (other == 0) return 0;
    return this / other;
  }

  // Clamp between min and max
  double clampBetween(double min, double max) {
    return clamp(min, max) as double;
  }

  // Check if within range
  bool isInRange(double min, double max) {
    return this >= min && this <= max;
  }

  // Format as file size
  String toFileSize() {
    return FileHelper.formatFileSize(toInt());
  }

  // Convert to different number formats
  String toOrdinal() {
    final number = toInt();
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  // Mathematical helpers
  double get squared => this * this;
  double get cubed => this * this * this;
  double sqrt() => math.sqrt(this);
  double pow(num exponent) => math.pow(this, exponent).toDouble();

  // Progress calculations
  double progressTo(double target) {
    if (target == 0) return 0;
    return (this / target).clamp(0.0, 1.0);
  }

  // Budget calculations
  double remainingFrom(double budget) {
    return (budget - this).clamp(0.0, double.infinity);
  }

  double exceededFrom(double budget) {
    return (this - budget).clamp(0.0, double.infinity);
  }

  // Investment calculations
  double compoundInterest({
    required double rate,
    required int periods,
    double additionalContribution = 0,
  }) {
    if (rate == 0) return this + (additionalContribution * periods);

    final compoundGrowth = this * math.pow(1 + rate, periods);
    final contributionGrowth =
        additionalContribution * ((math.pow(1 + rate, periods) - 1) / rate);

    return compoundGrowth + contributionGrowth;
  }
}
