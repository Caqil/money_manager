import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'goal.g.dart';

@HiveType(typeId: 4)
class Goal extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final double targetAmount;
  
  @HiveField(4)
  final double currentAmount;
  
  @HiveField(5)
  final DateTime? targetDate;
  
  @HiveField(6)
  final GoalType type;
  
  @HiveField(7)
  final GoalPriority priority;
  
  @HiveField(8)
  final String currency;
  
  @HiveField(9)
  final bool isActive;
  
  @HiveField(10)
  final String? categoryId; // Related category
  
  @HiveField(11)
  final List<String>? accountIds; // Accounts to track
  
  @HiveField(12)
  final DateTime createdAt;
  
  @HiveField(13)
  final DateTime updatedAt;
  
  @HiveField(14)
  final String? iconName;
  
  @HiveField(15)
  final int? color;
  
  @HiveField(16)
  final bool enableNotifications;
  
  @HiveField(17)
  final double monthlyTarget; // Auto-calculated or manual
  
  @HiveField(18)
  final List<GoalMilestone>? milestones;

  const Goal({
    required this.id,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    required this.type,
    this.priority = GoalPriority.medium,
    this.currency = 'USD',
    this.isActive = true,
    this.categoryId,
    this.accountIds,
    required this.createdAt,
    required this.updatedAt,
    this.iconName,
    this.color,
    this.enableNotifications = true,
    this.monthlyTarget = 0.0,
    this.milestones,
  });

  Goal copyWith({
    String? id,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    GoalType? type,
    GoalPriority? priority,
    String? currency,
    bool? isActive,
    String? categoryId,
    List<String>? accountIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? iconName,
    int? color,
    bool? enableNotifications,
    double? monthlyTarget,
    List<GoalMilestone>? milestones,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      categoryId: categoryId ?? this.categoryId,
      accountIds: accountIds ?? this.accountIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
      milestones: milestones ?? this.milestones,
    );
  }

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  bool get isCompleted => currentAmount >= targetAmount;

  int? get daysRemaining {
    if (targetDate == null) return null;
    final now = DateTime.now();
    final difference = targetDate!.difference(now).inDays;
    return difference >= 0 ? difference : null;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        targetAmount,
        currentAmount,
        targetDate,
        type,
        priority,
        currency,
        isActive,
        categoryId,
        accountIds,
        createdAt,
        updatedAt,
        iconName,
        color,
        enableNotifications,
        monthlyTarget,
        milestones,
      ];
}

@HiveType(typeId: 15)
enum GoalType {
  @HiveField(0)
  savings,
  @HiveField(1)
  debtPayoff,
  @HiveField(2)
  purchase,
  @HiveField(3)
  emergency,
  @HiveField(4)
  investment,
  @HiveField(5)
  vacation,
  @HiveField(6)
  education,
  @HiveField(7)
  retirement,
  @HiveField(8)
  other,
}

@HiveType(typeId: 16)
enum GoalPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  urgent,
}

@HiveType(typeId: 17)
class GoalMilestone extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final double amount;
  
  @HiveField(3)
  final bool isCompleted;
  
  @HiveField(4)
  final DateTime? completedAt;

  const GoalMilestone({
    required this.id,
    required this.name,
    required this.amount,
    this.isCompleted = false,
    this.completedAt,
  });

  GoalMilestone copyWith({
    String? id,
    String? name,
    double? amount,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return GoalMilestone(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, amount, isCompleted, completedAt];
}
