import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final TransactionType type;

  @HiveField(6)
  final String? imagePath;

  @HiveField(7)
  final String accountId;

  @HiveField(8)
  final String currency;

  @HiveField(9)
  final bool isRecurring;

  @HiveField(10)
  final String? recurringId;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final String? splitExpenseId;

  @HiveField(14)
  final String? transferToAccountId;

  @HiveField(15)
  final Map<String, dynamic>? metadata;

  const Transaction({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.notes,
    required this.type,
    this.imagePath,
    required this.accountId,
    this.currency = 'USD',
    this.isRecurring = false,
    this.recurringId,
    required this.createdAt,
    required this.updatedAt,
    this.splitExpenseId,
    this.transferToAccountId,
    this.metadata,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? notes,
    TransactionType? type,
    String? imagePath,
    String? accountId,
    String? currency,
    bool? isRecurring,
    String? recurringId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? splitExpenseId,
    String? transferToAccountId,
    Map<String, dynamic>? metadata,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath,
      accountId: accountId ?? this.accountId,
      currency: currency ?? this.currency,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      splitExpenseId: splitExpenseId ?? this.splitExpenseId,
      transferToAccountId: transferToAccountId ?? this.transferToAccountId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        categoryId,
        date,
        notes,
        type,
        imagePath,
        accountId,
        currency,
        isRecurring,
        recurringId,
        createdAt,
        updatedAt,
        splitExpenseId,
        transferToAccountId,
        metadata,
      ];
}

@HiveType(typeId: 11)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  transfer,
}
