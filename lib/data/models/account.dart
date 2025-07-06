
import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'account.g.dart';

@HiveType(typeId: 3)
class Account extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final double balance;
  
  @HiveField(3)
  final String currency;
  
  @HiveField(4)
  final AccountType type;
  
  @HiveField(5)
  final String? description;
  
  @HiveField(6)
  final String? iconName;
  
  @HiveField(7)
  final int? color; // Color value for UI
  
  @HiveField(8)
  final bool isActive;
  
  @HiveField(9)
  final bool includeInTotal;
  
  @HiveField(10)
  final double? creditLimit; // For credit card accounts
  
  @HiveField(11)
  final DateTime? lastSyncDate;
  
  @HiveField(12)
  final DateTime createdAt;
  
  @HiveField(13)
  final DateTime updatedAt;
  
  @HiveField(14)
  final String? bankName;
  
  @HiveField(15)
  final String? accountNumber; // Last 4 digits for display
  
  @HiveField(16)
  final Map<String, dynamic>? metadata;

  const Account({
    required this.id,
    required this.name,
    required this.balance,
    this.currency = 'USD',
    required this.type,
    this.description,
    this.iconName,
    this.color,
    this.isActive = true,
    this.includeInTotal = true,
    this.creditLimit,
    this.lastSyncDate,
    required this.createdAt,
    required this.updatedAt,
    this.bankName,
    this.accountNumber,
    this.metadata,
  });

  Account copyWith({
    String? id,
    String? name,
    double? balance,
    String? currency,
    AccountType? type,
    String? description,
    String? iconName,
    int? color,
    bool? isActive,
    bool? includeInTotal,
    double? creditLimit,
    DateTime? lastSyncDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bankName,
    String? accountNumber,
    Map<String, dynamic>? metadata,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      includeInTotal: includeInTotal ?? this.includeInTotal,
      creditLimit: creditLimit ?? this.creditLimit,
      lastSyncDate: lastSyncDate ?? this.lastSyncDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      metadata: metadata ?? this.metadata,
    );
  }

  double get availableBalance {
    if (type == AccountType.creditCard && creditLimit != null) {
      return creditLimit! + balance; // balance is negative for credit cards
    }
    return balance;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        balance,
        currency,
        type,
        description,
        iconName,
        color,
        isActive,
        includeInTotal,
        creditLimit,
        lastSyncDate,
        createdAt,
        updatedAt,
        bankName,
        accountNumber,
        metadata,
      ];
}

@HiveType(typeId: 14)
enum AccountType {
  @HiveField(0)
  cash,
  @HiveField(1)
  checking,
  @HiveField(2)
  savings,
  @HiveField(3)
  creditCard,
  @HiveField(4)
  investment,
  @HiveField(5)
  loan,
  @HiveField(6)
  other,
}


