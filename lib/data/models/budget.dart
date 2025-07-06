import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'budget.g.dart';

@HiveType(typeId: 2)
class Budget extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final double limit;

  @HiveField(4)
  final BudgetPeriod period;

  @HiveField(5)
  final DateTime startDate;

  @HiveField(6)
  final DateTime? endDate;

  @HiveField(7)
  final bool isActive;

  @HiveField(8)
  final double alertThreshold; // Percentage (0.0 to 1.0)

  @HiveField(9)
  final bool enableAlerts;

  @HiveField(10)
  final List<String>? accountIds; // Specific accounts to track

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final String? description;

  @HiveField(14)
  final BudgetRolloverType rolloverType;

  const Budget({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.limit,
    required this.period,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.alertThreshold = 0.8,
    this.enableAlerts = true,
    this.accountIds,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.rolloverType = BudgetRolloverType.reset,
  });

  Budget copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? limit,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    double? alertThreshold,
    bool? enableAlerts,
    List<String>? accountIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    BudgetRolloverType? rolloverType,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      limit: limit ?? this.limit,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      enableAlerts: enableAlerts ?? this.enableAlerts,
      accountIds: accountIds ?? this.accountIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      rolloverType: rolloverType ?? this.rolloverType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        categoryId,
        limit,
        period,
        startDate,
        endDate,
        isActive,
        alertThreshold,
        enableAlerts,
        accountIds,
        createdAt,
        updatedAt,
        description,
        rolloverType,
      ];
}

@HiveType(typeId: 12)
enum BudgetPeriod {
  @HiveField(0)
  weekly,
  @HiveField(1)
  monthly,
  @HiveField(2)
  quarterly,
  @HiveField(3)
  yearly,
  @HiveField(4)
  custom,
}

@HiveType(typeId: 13)
enum BudgetRolloverType {
  @HiveField(0)
  reset, // Reset to 0 at period end
  @HiveField(1)
  rollover, // Carry remaining amount to next period
  @HiveField(2)
  accumulate, // Add remaining to next period limit
}
