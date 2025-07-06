import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'category.g.dart';

@HiveType(typeId: 6)
class Category extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String iconName;

  @HiveField(4)
  final int color; // Color value

  @HiveField(5)
  final CategoryType type;

  @HiveField(6)
  final bool isDefault; // System default categories

  @HiveField(7)
  final bool isActive;

  @HiveField(8)
  final String? parentCategoryId; // For subcategories

  @HiveField(9)
  final int sortOrder;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  @HiveField(12)
  final List<String>? tags; // For filtering/searching

  @HiveField(13)
  final bool enableBudgetTracking;

  @HiveField(14)
  final Map<String, dynamic>? metadata;

  const Category({
    required this.id,
    required this.name,
    this.description,
    required this.iconName,
    required this.color,
    required this.type,
    this.isDefault = false,
    this.isActive = true,
    this.parentCategoryId,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.tags,
    this.enableBudgetTracking = true,
    this.metadata,
  });

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    int? color,
    CategoryType? type,
    bool? isDefault,
    bool? isActive,
    String? parentCategoryId,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool? enableBudgetTracking,
    Map<String, dynamic>? metadata,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      enableBudgetTracking: enableBudgetTracking ?? this.enableBudgetTracking,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isSubcategory => parentCategoryId != null;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconName,
        color,
        type,
        isDefault,
        isActive,
        parentCategoryId,
        sortOrder,
        createdAt,
        updatedAt,
        tags,
        enableBudgetTracking,
        metadata,
      ];
}

@HiveType(typeId: 19)
enum CategoryType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  both, // Can be used for both income and expense
}
