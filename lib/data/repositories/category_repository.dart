import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../services/hive_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

class CategoryRepository {
  static const _uuid = Uuid();
  late final HiveService _hiveService;

  CategoryRepository({HiveService? hiveService}) {
    _hiveService = hiveService ?? HiveService();
  }

  Future<Box<Category>> get _categoriesBox async {
    return await _hiveService.getBox<Category>(AppConstants.hiveBoxCategories);
  }

  // Add category
  Future<String> addCategory(Category category) async {
    try {
      final box = await _categoriesBox;
      final id = category.id.isEmpty ? _uuid.v4() : category.id;
      final now = DateTime.now();

      final newCategory = category.copyWith(
        id: id,
        createdAt: category.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
            ? now
            : category.createdAt,
        updatedAt: now,
      );

      await box.put(id, newCategory);
      return id;
    } catch (e) {
      throw DatabaseException(message: 'Failed to add category: $e');
    }
  }

  // Update category
  Future<void> updateCategory(Category category) async {
    try {
      final box = await _categoriesBox;

      if (!box.containsKey(category.id)) {
        throw CategoryNotFoundException(categoryId: category.id);
      }

      final updatedCategory = category.copyWith(updatedAt: DateTime.now());
      await box.put(category.id, updatedCategory);
    } catch (e) {
      if (e is CategoryNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to update category: $e');
    }
  }

  // Delete category
  Future<void> deleteCategory(String id) async {
    try {
      final box = await _categoriesBox;

      if (!box.containsKey(id)) {
        throw CategoryNotFoundException(categoryId: id);
      }

      // Check if it's a default category
      final category = box.get(id);
      if (category?.isDefault == true) {
        throw ValidationException(message: 'Cannot delete default category');
      }

      await box.delete(id);
    } catch (e) {
      if (e is CategoryNotFoundException || e is ValidationException) rethrow;
      throw DatabaseException(message: 'Failed to delete category: $e');
    }
  }

  // Get category by ID
  Future<Category?> getCategoryById(String id) async {
    try {
      final box = await _categoriesBox;
      return box.get(id);
    } catch (e) {
      throw DatabaseException(message: 'Failed to get category: $e');
    }
  }

  // Get all categories
  Future<List<Category>> getAllCategories() async {
    try {
      final box = await _categoriesBox;
      final categories = box.values.toList();

      // Sort by sort order and name
      categories.sort((a, b) {
        final sortOrderComparison = a.sortOrder.compareTo(b.sortOrder);
        if (sortOrderComparison != 0) return sortOrderComparison;
        return a.name.compareTo(b.name);
      });

      return categories;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get categories: $e');
    }
  }

  // Get active categories
  Future<List<Category>> getActiveCategories() async {
    try {
      final allCategories = await getAllCategories();
      return allCategories.where((category) => category.isActive).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get active categories: $e');
    }
  }

  // Get categories by type
  Future<List<Category>> getCategoriesByType(CategoryType type) async {
    try {
      final allCategories = await getAllCategories();
      return allCategories
          .where((category) =>
              category.type == type || category.type == CategoryType.both)
          .toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get categories by type: $e');
    }
  }

  // Get parent categories
  Future<List<Category>> getParentCategories() async {
    try {
      final allCategories = await getAllCategories();
      return allCategories
          .where((category) => category.parentCategoryId == null)
          .toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get parent categories: $e');
    }
  }

  // Get subcategories
  Future<List<Category>> getSubcategories(String parentId) async {
    try {
      final allCategories = await getAllCategories();
      return allCategories
          .where((category) => category.parentCategoryId == parentId)
          .toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get subcategories: $e');
    }
  }

  // Get default categories
  Future<List<Category>> getDefaultCategories() async {
    try {
      final allCategories = await getAllCategories();
      return allCategories.where((category) => category.isDefault).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get default categories: $e');
    }
  }

  // Search categories
  Future<List<Category>> searchCategories(String query) async {
    try {
      final allCategories = await getAllCategories();
      final lowercaseQuery = query.toLowerCase();

      return allCategories.where((category) {
        final name = category.name.toLowerCase();
        final description = category.description?.toLowerCase() ?? '';
        final tags = category.tags?.join(' ').toLowerCase() ?? '';

        return name.contains(lowercaseQuery) ||
            description.contains(lowercaseQuery) ||
            tags.contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to search categories: $e');
    }
  }

  // Deactivate category
  Future<void> deactivateCategory(String id) async {
    try {
      final category = await getCategoryById(id);
      if (category == null) {
        throw CategoryNotFoundException(categoryId: id);
      }

      final deactivatedCategory = category.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await updateCategory(deactivatedCategory);
    } catch (e) {
      if (e is CategoryNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to deactivate category: $e');
    }
  }

  // Activate category
  Future<void> activateCategory(String id) async {
    try {
      final category = await getCategoryById(id);
      if (category == null) {
        throw CategoryNotFoundException(categoryId: id);
      }

      final activatedCategory = category.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );

      await updateCategory(activatedCategory);
    } catch (e) {
      if (e is CategoryNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to activate category: $e');
    }
  }

  // Update sort order
  Future<void> updateSortOrder(String id, int newSortOrder) async {
    try {
      final category = await getCategoryById(id);
      if (category == null) {
        throw CategoryNotFoundException(categoryId: id);
      }

      final updatedCategory = category.copyWith(
        sortOrder: newSortOrder,
        updatedAt: DateTime.now(),
      );

      await updateCategory(updatedCategory);
    } catch (e) {
      if (e is CategoryNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to update sort order: $e');
    }
  }

  // Initialize default categories
  Future<void> initializeDefaultCategories() async {
    try {
      final existingDefaults = await getDefaultCategories();
      if (existingDefaults.isNotEmpty) return; // Already initialized

      final defaultCategories = _getDefaultCategoriesData();

      for (final category in defaultCategories) {
        await addCategory(category);
      }
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to initialize default categories: $e');
    }
  }

  // Clear all categories (except defaults)
  Future<void> clearUserCategories() async {
    try {
      final box = await _categoriesBox;
      final categories = box.values.toList();

      for (final category in categories) {
        if (!category.isDefault) {
          await box.delete(category.id);
        }
      }
    } catch (e) {
      throw DatabaseException(message: 'Failed to clear user categories: $e');
    }
  }

  // Get categories count
  Future<int> getCategoriesCount() async {
    try {
      final box = await _categoriesBox;
      return box.length;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get categories count: $e');
    }
  }

  // Batch operations
  Future<void> addCategoriesBatch(List<Category> categories) async {
    try {
      final box = await _categoriesBox;
      final categoriesMap = <String, Category>{};

      for (final category in categories) {
        final id = category.id.isEmpty ? _uuid.v4() : category.id;
        final now = DateTime.now();

        final newCategory = category.copyWith(
          id: id,
          createdAt:
              category.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
                  ? now
                  : category.createdAt,
          updatedAt: now,
        );

        categoriesMap[id] = newCategory;
      }

      await box.putAll(categoriesMap);
    } catch (e) {
      throw DatabaseException(message: 'Failed to add categories batch: $e');
    }
  }

  // Get default categories data
  List<Category> _getDefaultCategoriesData() {
    final now = DateTime.now();

    return [
      // Income categories
      Category(
        id: 'income_salary',
        name: 'Salary',
        iconName: 'work',
        color: 0xFF10B981,
        type: CategoryType.income,
        isDefault: true,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'income_freelance',
        name: 'Freelance',
        iconName: 'business_center',
        color: 0xFF059669,
        type: CategoryType.income,
        isDefault: true,
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'income_investment',
        name: 'Investment',
        iconName: 'trending_up',
        color: 0xFF0D9488,
        type: CategoryType.income,
        isDefault: true,
        sortOrder: 3,
        createdAt: now,
        updatedAt: now,
      ),

      // Expense categories
      Category(
        id: 'expense_food',
        name: 'Food & Dining',
        iconName: 'restaurant',
        color: 0xFFF59E0B,
        type: CategoryType.expense,
        isDefault: true,
        sortOrder: 10,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'expense_transport',
        name: 'Transportation',
        iconName: 'directions_car',
        color: 0xFF3B82F6,
        type: CategoryType.expense,
        isDefault: true,
        sortOrder: 11,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'expense_shopping',
        name: 'Shopping',
        iconName: 'shopping_cart',
        color: 0xFFEC4899,
        type: CategoryType.expense,
        isDefault: true,
        sortOrder: 12,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'expense_entertainment',
        name: 'Entertainment',
        iconName: 'movie',
        color: 0xFF8B5CF6,
        type: CategoryType.expense,
        isDefault: true,
        sortOrder: 13,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'expense_healthcare',
        name: 'Healthcare',
        iconName: 'local_hospital',
        color: 0xFFEF4444,
        type: CategoryType.expense,
        isDefault: true,
        sortOrder: 14,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'expense_utilities',
        name: 'Utilities',
        iconName: 'home',
        color: 0xFF6366F1,
        type: CategoryType.expense,
        isDefault: true,
        sortOrder: 15,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
