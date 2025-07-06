import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:money_manager/data/models/transaction.dart';

import '../../core/enums/transaction_type.dart';

part 'recurring_transaction.g.dart';

@HiveType(typeId: 5)
class RecurringTransaction extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final TransactionType type;

  @HiveField(5)
  final String accountId;

  @HiveField(6)
  final RecurrenceFrequency frequency;

  @HiveField(7)
  final DateTime startDate;

  @HiveField(8)
  final DateTime? endDate;

  @HiveField(9)
  final bool isActive;

  @HiveField(10)
  final DateTime? lastExecuted;

  @HiveField(11)
  final DateTime? nextExecution;

  @HiveField(12)
  final String? notes;

  @HiveField(13)
  final String currency;

  @HiveField(14)
  final int intervalValue; // e.g., every 2 weeks

  @HiveField(15)
  final List<int>? weekdays; // For weekly: [1,2,3,4,5] = Mon-Fri

  @HiveField(16)
  final int? dayOfMonth; // For monthly: 15th day

  @HiveField(17)
  final List<int>? monthsOfYear; // For yearly: [1,6] = Jan, Jun

  @HiveField(18)
  final DateTime createdAt;

  @HiveField(19)
  final DateTime updatedAt;

  @HiveField(20)
  final bool enableNotifications;

  @HiveField(21)
  final int notificationDaysBefore;

  @HiveField(22)
  final String? transferToAccountId;

  const RecurringTransaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.type,
    required this.accountId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.lastExecuted,
    this.nextExecution,
    this.notes,
    this.currency = 'USD',
    this.intervalValue = 1,
    this.weekdays,
    this.dayOfMonth,
    this.monthsOfYear,
    required this.createdAt,
    required this.updatedAt,
    this.enableNotifications = true,
    this.notificationDaysBefore = 1,
    this.transferToAccountId,
  });

  RecurringTransaction copyWith({
    String? id,
    String? name,
    double? amount,
    String? categoryId,
    TransactionType? type,
    String? accountId,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? lastExecuted,
    DateTime? nextExecution,
    String? notes,
    String? currency,
    int? intervalValue,
    List<int>? weekdays,
    int? dayOfMonth,
    List<int>? monthsOfYear,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? enableNotifications,
    int? notificationDaysBefore,
    String? transferToAccountId,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      nextExecution: nextExecution ?? this.nextExecution,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
      intervalValue: intervalValue ?? this.intervalValue,
      weekdays: weekdays ?? this.weekdays,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      monthsOfYear: monthsOfYear ?? this.monthsOfYear,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      notificationDaysBefore:
          notificationDaysBefore ?? this.notificationDaysBefore,
      transferToAccountId: transferToAccountId ?? this.transferToAccountId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        amount,
        categoryId,
        type,
        accountId,
        frequency,
        startDate,
        endDate,
        isActive,
        lastExecuted,
        nextExecution,
        notes,
        currency,
        intervalValue,
        weekdays,
        dayOfMonth,
        monthsOfYear,
        createdAt,
        updatedAt,
        enableNotifications,
        notificationDaysBefore,
        transferToAccountId,
      ];
}

@HiveType(typeId: 18)
enum RecurrenceFrequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  quarterly,
  @HiveField(4)
  yearly,
  @HiveField(5)
  custom,
}
