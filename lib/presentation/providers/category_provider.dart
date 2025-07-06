import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';

// Repository provider
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(),
);

// Category list provider
final categoryListProvider = StateNotifierProvider<CategoryNotifier, AsyncValue<List<Category>>>(
  (ref) => CategoryNotifier(ref.read(categoryRepositoryProvider)),
);

// Active categories provider
final activeCategoriesProvider = Provider<AsyncValue<List<Category>>>(
  (ref) {
    final categories = ref.watch(categoryListProvider);
    return categories.when(
      data: (list) => AsyncValue.data(list.where((category) => category.isActive).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Categories by type provider
final categoriesByTypeProvider = Provider.family<AsyncValue<List<Category>>, CategoryType>(
  (ref, type) {
    final categories = ref.watch(categoryListProvider);
    return categories.when(
      data: (list) => AsyncValue.data(
        list.where((category) => 
          category.type == type || category.type == CategoryType.both).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Parent categories provider
final parentCategoriesProvider = Provider<AsyncValue<List<Category>>>(
  (ref) {
    final categories = ref.watch(categoryListProvider);
    return categories.when(
      data: (list) => AsyncValue.data(
        list.where((category) => category.parentCategoryId == null).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Subcategories provider
final subcategoriesProvider = Provider.family<AsyncValue<List<Category>>, String>(
  (ref, parentId) {
    final categories = ref.watch(categoryListProvider);
    return categories.when(
      data: (list) => AsyncValue.data(
        list.where((category) => category.parentCategoryId == parentId).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Single category provider
final categoryProvider = Provider.family<AsyncValue<Category?>, String>(
  (ref, categoryId) {
    final categories = ref.watch(categoryListProvider);
    return categories.when(
      data: (list) {
        try {
          final category = list.firstWhere((category) => category.id == categoryId);
          return AsyncValue.data(category);
        } catch (e) {
          return const AsyncValue.data(null);
        }
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Default categories provider
final defaultCategoriesProvider = Provider<AsyncValue<List<Category>>>(
  (ref) {
    final categories = ref.watch(categoryListProvider);
    return categories.when(
      data: (list) => AsyncValue.data(list.where((category) => category.isDefault).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Income categories provider
final incomeCategoriesProvider = Provider<AsyncValue<List<Category>>>(
  (ref) {
    return ref.watch(categoriesByTypeProvider(CategoryType.income));
  },
);

// Expense categories provider
final expenseCategoriesProvider = Provider<AsyncValue<List<Category>>>(
  (ref) {
    return ref.watch(categoriesByTypeProvider(CategoryType.expense));
  },
);

// Category operations state
class CategoryNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final CategoryRepository _repository;

  CategoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  // Load all categories
  Future<void> loadCategories() async {
    try {
      state = const AsyncValue.loading();
      final categories = await _repository.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Initialize default categories
  Future<void> initializeDefaultCategories() async {
    try {
      await _repository.initializeDefaultCategories();
      await loadCategories(); // Refresh list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Add category
  Future<String?> addCategory(Category category) async {
    try {
      final id = await _repository.addCategory(category);
      await loadCategories(); // Refresh list
      return id;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  // Update category
  Future<bool> updateCategory(Category category) async {
    try {
      await _repository.updateCategory(category);
      await loadCategories(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Delete category
  Future<bool> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      await loadCategories(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Toggle category status
  Future<bool> toggleCategoryStatus(String id, bool isActive) async {
    try {
      if (isActive) {
        await _repository.activateCategory(id);
      } else {
        await _repository.deactivateCategory(id);
      }
      await loadCategories(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Update sort order
  Future<bool> updateSortOrder(String id, int newSortOrder) async {
    try {
      await _repository.updateSortOrder(id, newSortOrder);
      await loadCategories(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Search categories
  Future<List<Category>> searchCategories(String query) async {
    try {
      return await _repository.searchCategories(query);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return [];
    }
  }

  // Refresh categories
  Future<void> refresh() async {
    await loadCategories();
  }
}

