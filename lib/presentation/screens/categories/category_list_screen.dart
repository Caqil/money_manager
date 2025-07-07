import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/category.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/category_item.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  final CategoryType? filterType;
  final bool selectionMode;
  final String? selectedCategoryId;
  final Function(Category)? onCategorySelected;

  const CategoryListScreen({
    super.key,
    this.filterType,
    this.selectionMode = false,
    this.selectedCategoryId,
    this.onCategorySelected,
  });

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  CategoryType _selectedType = CategoryType.expense;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.filterType ?? CategoryType.expense;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _getInitialTabIndex(),
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  int _getInitialTabIndex() {
    switch (_selectedType) {
      case CategoryType.income:
        return 0;
      case CategoryType.expense:
        return 1;
      case CategoryType.both:
        return 2;
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedType = CategoryType.income;
            break;
          case 1:
            _selectedType = CategoryType.expense;
            break;
          case 2:
            _selectedType = CategoryType.both;
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.selectionMode
            ? 'categories.selectCategory'.tr()
            : 'categories.categories'.tr(),
        showBackButton: widget.selectionMode,
        actions: [
          if (!widget.selectionMode) ...[
            // Search toggle
            IconButton(
              onPressed: () => _showSearchDialog(),
              icon: const Icon(Icons.search),
              tooltip: 'common.search'.tr(),
            ),
            // Filter menu
            ShadPopover(
              popover: (context) => _buildFilterMenu(),
              child: IconButton(
                onPressed: () {},
                icon: Stack(
                  children: [
                    const Icon(Icons.filter_list),
                    if (_showInactive)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'common.filter'.tr(),
              ),
            ),
            // More actions
            ShadPopover(
              popover: (context) => _buildActionsMenu(),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
                tooltip: 'common.moreActions'.tr(),
              ),
            ),
          ],
        ],
        bottom: widget.filterType == null && !widget.selectionMode
            ? TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: Icon(Icons.arrow_upward, color: AppColors.income),
                    text: 'categories.income'.tr(),
                  ),
                  Tab(
                    icon: Icon(Icons.arrow_downward, color: AppColors.expense),
                    text: 'categories.expense'.tr(),
                  ),
                  Tab(
                    icon: Icon(Icons.swap_vert, color: AppColors.transfer),
                    text: 'categories.both'.tr(),
                  ),
                ],
              )
            : null,
      ),
      floatingActionButton: widget.selectionMode
          ? null
          : FloatingActionButton(
              onPressed: _navigateToAddCategory,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: widget.filterType == null && !widget.selectionMode
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(CategoryType.income),
                _buildCategoryList(CategoryType.expense),
                _buildCategoryList(CategoryType.both),
              ],
            )
          : _buildCategoryList(widget.filterType ?? _selectedType),
    );
  }

  Widget _buildFilterMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
          value: _showInactive,
          onChanged: (value) {
            setState(() {
              _showInactive = value ?? false;
            });
            Navigator.of(context).pop();
          },
          title: Text('categories.showInactive'.tr()),
        ),
      ],
    );
  }

  Widget _buildActionsMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.refresh, size: 18),
          title: Text('common.refresh'.tr()),
          onTap: () {
            Navigator.of(context).pop();
            ref.invalidate(categoryListProvider);
          },
        ),
        ListTile(
          leading: const Icon(Icons.download, size: 18),
          title: Text('categories.initializeDefaults'.tr()),
          onTap: () {
            Navigator.of(context).pop();
            _initializeDefaultCategories();
          },
        ),
      ],
    );
  }

  Widget _buildCategoryList(CategoryType type) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(type));

    return categoriesAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState(error),
      data: (categories) => _buildCategoryContent(categories),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: ShimmerLoading(
        child: Column(
          children: [
            SizedBox(height: AppDimensions.spacingL),
            SkeletonLoader(height: 80, width: double.infinity),
            SizedBox(height: AppDimensions.spacingM),
            SkeletonLoader(height: 80, width: double.infinity),
            SizedBox(height: AppDimensions.spacingM),
            SkeletonLoader(height: 80, width: double.infinity),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: CustomErrorWidget(
        title: 'errors.loadingCategories'.tr(),
        message: error.toString(),
        actionText: 'common.retry'.tr(),
        onActionPressed: () => ref.invalidate(categoryListProvider),
      ),
    );
  }

  Widget _buildCategoryContent(List<Category> allCategories) {
    // Filter categories based on search query and active status
    final filteredCategories = _filterCategories(allCategories);

    if (filteredCategories.isEmpty) {
      return _buildEmptyState();
    }

    // Separate parent categories and subcategories
    final parentCategories = filteredCategories
        .where((category) => !category.isSubcategory)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(categoryListProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        itemCount: parentCategories.length,
        itemBuilder: (context, index) {
          final category = parentCategories[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: CategoryItem(
              category: category,
              onTap: widget.selectionMode
                  ? () => _handleCategorySelection(category)
                  : () => _navigateToEditCategory(category),
              onEdit: widget.selectionMode
                  ? null
                  : () => _navigateToEditCategory(category),
              onDelete: widget.selectionMode || category.isDefault
                  ? null
                  : () => _showDeleteConfirmation(category),
              onToggleStatus: widget.selectionMode
                  ? null
                  : () => _toggleCategoryStatus(category),
              showSubcategories: !widget.selectionMode,
              isSelectable: widget.selectionMode,
              isSelected: widget.selectedCategoryId == category.id,
              showActions: !widget.selectionMode,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return SearchEmptyState(
        searchQuery: _searchQuery,
        onClearSearch: () {
          setState(() {
            _searchQuery = '';
          });
        },
      );
    }

    return CategoriesEmptyState(
      onAddCategory: widget.selectionMode ? null : _navigateToAddCategory,
      customMessage: widget.selectionMode
          ? 'categories.noCategoriesForSelection'.tr()
          : null,
    );
  }

  List<Category> _filterCategories(List<Category> categories) {
    return categories.where((category) {
      // Filter by active status
      if (!_showInactive && !category.isActive) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!category.name.toLowerCase().contains(query) &&
            !(category.description?.toLowerCase().contains(query) ?? false) &&
            !(category.tags?.any((tag) => tag.toLowerCase().contains(query)) ??
                false)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _handleCategorySelection(Category category) {
    widget.onCategorySelected?.call(category);
    if (!widget.selectionMode) return;
    context.pop();
  }

  void _navigateToAddCategory() {
    final type = widget.filterType ?? _selectedType;
    context.push('/categories/add?type=${type.name}');
  }

  void _navigateToEditCategory(Category category) {
    context.push('/categories/edit/${category.id}');
  }

  void _showSearchDialog() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('common.search'.tr()),
        child: ShadInput(
          placeholder: Text('categories.searchCategories'.tr()),
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Category category) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('categories.deleteCategory'.tr()),
        description: Text(
          'categories.deleteCategoryConfirmation'.tr(
            namedArgs: {'categoryName': category.name},
          ),
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton.destructive(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCategory(category);
            },
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final notifier = ref.read(categoryListProvider.notifier);
    final success = await notifier.deleteCategory(category.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'categories.categoryDeleted'.tr()
              : 'categories.errorDeletingCategory'.tr()),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
      );
    }
  }

  Future<void> _toggleCategoryStatus(Category category) async {
    final notifier = ref.read(categoryListProvider.notifier);
    final updatedCategory = category.copyWith(
      isActive: !category.isActive,
      updatedAt: DateTime.now(),
    );

    final success = await notifier.updateCategory(updatedCategory);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (category.isActive
                  ? 'categories.categoryDeactivated'.tr()
                  : 'categories.categoryActivated'.tr())
              : 'categories.errorUpdatingCategory'.tr()),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
      );
    }
  }

  Future<void> _initializeDefaultCategories() async {
    final notifier = ref.read(categoryListProvider.notifier);

    try {
      await notifier.initializeDefaultCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('categories.defaultCategoriesInitialized'.tr()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('categories.errorInitializingDefaults'.tr()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
        );
      }
    }
  }
}
