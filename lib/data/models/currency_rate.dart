import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'currency_rate.g.dart';

@HiveType(typeId: 9)
class CurrencyRate extends Equatable {
  @HiveField(0)
  final String fromCurrency;

  @HiveField(1)
  final String toCurrency;

  @HiveField(2)
  final double rate;

  @HiveField(3)
  final DateTime lastUpdated;

  @HiveField(4)
  final bool isUserDefined; // User manually set vs auto-fetched

  @HiveField(5)
  final DateTime createdAt;

  const CurrencyRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.lastUpdated,
    this.isUserDefined = false,
    required this.createdAt,
  });

  CurrencyRate copyWith({
    String? fromCurrency,
    String? toCurrency,
    double? rate,
    DateTime? lastUpdated,
    bool? isUserDefined,
    DateTime? createdAt,
  }) {
    return CurrencyRate(
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      rate: rate ?? this.rate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isUserDefined: isUserDefined ?? this.isUserDefined,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get currencyPair => '${fromCurrency}_$toCurrency';

  double convertAmount(double amount) => amount * rate;

  @override
  List<Object?> get props => [
        fromCurrency,
        toCurrency,
        rate,
        lastUpdated,
        isUserDefined,
        createdAt,
      ];
}

@HiveType(typeId: 10)
class Currency extends Equatable {
  @HiveField(0)
  final String code; // ISO 4217 code (USD, EUR, etc.)

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String symbol;

  @HiveField(3)
  final int decimalPlaces;

  @HiveField(4)
  final bool isActive;

  @HiveField(5)
  final String? country;

  @HiveField(6)
  final bool isBaseCurrency; // User's primary currency

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    this.decimalPlaces = 2,
    this.isActive = true,
    this.country,
    this.isBaseCurrency = false,
  });

  Currency copyWith({
    String? code,
    String? name,
    String? symbol,
    int? decimalPlaces,
    bool? isActive,
    String? country,
    bool? isBaseCurrency,
  }) {
    return Currency(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      isActive: isActive ?? this.isActive,
      country: country ?? this.country,
      isBaseCurrency: isBaseCurrency ?? this.isBaseCurrency,
    );
  }

  @override
  List<Object?> get props => [
        code,
        name,
        symbol,
        decimalPlaces,
        isActive,
        country,
        isBaseCurrency,
      ];
}
