import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'badge.g.dart';

@HiveType(typeId: 8)
class Badge extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String iconName;
  
  @HiveField(4)
  final int color;
  
  @HiveField(5)
  final BadgeType type;
  
  @HiveField(6)
  final BadgeCategory category;
  
  @HiveField(7)
  final bool isEarned;
  
  @HiveField(8)
  final DateTime? earnedAt;
  
  @HiveField(9)
  final double? targetValue; // Target to achieve
  
  @HiveField(10)
  final double? currentValue; // Current progress
  
  @HiveField(11)
  final String? unit; // e.g., "transactions", "dollars"
  
  @HiveField(12)
  final int difficulty; // 1-5 scale
  
  @HiveField(13)
  final int points; // Gamification points
  
  @HiveField(14)
  final DateTime createdAt;
  
  @HiveField(15)
  final Map<String, dynamic>? criteria; // Achievement criteria
  
  @HiveField(16)
  final bool isHidden; // Hidden until conditions are met

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.color,
    required this.type,
    required this.category,
    this.isEarned = false,
    this.earnedAt,
    this.targetValue,
    this.currentValue,
    this.unit,
    this.difficulty = 1,
    this.points = 10,
    required this.createdAt,
    this.criteria,
    this.isHidden = false,
  });

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    int? color,
    BadgeType? type,
    BadgeCategory? category,
    bool? isEarned,
    DateTime? earnedAt,
    double? targetValue,
    double? currentValue,
    String? unit,
    int? difficulty,
    int? points,
    DateTime? createdAt,
    Map<String, dynamic>? criteria,
    bool? isHidden,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      type: type ?? this.type,
      category: category ?? this.category,
      isEarned: isEarned ?? this.isEarned,
      earnedAt: earnedAt ?? this.earnedAt,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      criteria: criteria ?? this.criteria,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  double get progressPercentage {
    if (targetValue == null || currentValue == null || targetValue! <= 0) {
      return 0.0;
    }
    return (currentValue! / targetValue!).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconName,
        color,
        type,
        category,
        isEarned,
        earnedAt,
        targetValue,
        currentValue,
        unit,
        difficulty,
        points,
        createdAt,
        criteria,
        isHidden,
      ];
}

@HiveType(typeId: 23)
enum BadgeType {
  @HiveField(0)
  achievement, // One-time achievement
  @HiveField(1)
  milestone, // Progression milestone
  @HiveField(2)
  streak, // Consecutive actions
  @HiveField(3)
  challenge, // Time-limited challenge
}

@HiveType(typeId: 24)
enum BadgeCategory {
  @HiveField(0)
  savings,
  @HiveField(1)
  budgeting,
  @HiveField(2)
  transactions,
  @HiveField(3)
  goals,
  @HiveField(4)
  consistency,
  @HiveField(5)
  exploration, // Using app features
  @HiveField(6)
  social, // Sharing/splitting expenses
  @HiveField(7)
  special, // Seasonal or event-based
}