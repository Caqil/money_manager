import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/transaction.dart';
import '../../../providers/category_provider.dart';
import '../../../widgets/common/loading_widget.dart';

class CategorySelector extends ConsumerStatefulWidget {
  final String? selectedCategoryId;
  final Function(Category?) onCategorySelected;
  final TransactionType? transactionType;
  final String? label;
  final String? placeholder;
  final bool enabled;
  final bool required;
  final bool showCreateOption;
  final String? errorText;

  const CategorySelector({
    super.key,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.transactionType,
    this.label,
    this.placeholder,
    this.enabled = true,
    this.required = false,
    this.showCreateOption = true,
    this.errorText,
  });

  @override
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector> {
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.selectedCategoryId != null) {
      _loadSelectedCategory();
    }
  }

  @override
  void didUpdateWidget(CategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategoryId != oldWidget.selectedCategoryId) {
      if (widget.selectedCategoryId != null) {
        _loadSelectedCategory();
      } else {
        setState(() {
          _selectedCategory = null;
        });
      }
    }
  }

  void _loadSelectedCategory() {
    if (widget.selectedCategoryId != null) {
      final categoryAsync =
          ref.read(categoryProvider(widget.selectedCategoryId!));
      categoryAsync.whenData((category) {
        if (mounted && category != null) {
          setState(() {
            _selectedCategory = category;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // Determine which categories to show based on transaction type
    final categoriesAsync = widget.transactionType != null
        ? ref.watch(categoriesByTypeProvider(
            _mapTransactionToCategoryType(widget.transactionType!)))
        : ref.watch(activeCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: theme.textTheme.h4,
              ),
              if (widget.required)
                Text(
                  ' *',
                  style: theme.textTheme.h4.copyWith(
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
        ],
        categoriesAsync.when(
          loading: () => _buildLoadingSelector(theme),
          error: (error, _) => _buildErrorSelector(theme, error),
          data: (categories) => _buildCategorySelector(theme, categories),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            widget.errorText!,
            style: theme.textTheme.small.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingSelector(ShadThemeData theme) {
    return const ShimmerLoading(
      child: SkeletonLoader(
        height: 48,
        width: double.infinity,
      ),
    );
  }

  Widget _buildErrorSelector(ShadThemeData theme, Object error) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.error),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              'categories.errorLoadingCategories'.tr(),
              style: theme.textTheme.small.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: () => ref.invalidate(activeCategoriesProvider),
            child: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(
      ShadThemeData theme, List<Category> allCategories) {
    // Filter and organize categories
    final parentCategories = allCategories
        .where((cat) => !cat.isSubcategory)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (parentCategories.isEmpty) {
      return _buildEmptyState(theme);
    }

    // Build options list
    final options = <ShadOption<String>>[];

    // Add parent categories and their subcategories
    for (final parent in parentCategories) {
      options.add(ShadOption(
        value: parent.id,
        child: _buildCategoryOption(parent),
      ));

      // Add subcategories
      final subcategories = allCategories
          .where((cat) => cat.parentCategoryId == parent.id)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      for (final subcategory in subcategories) {
        options.add(ShadOption(
          value: subcategory.id,
          child: _buildSubcategoryOption(subcategory),
        ));
      }
    }

    // Add create new option if enabled
    if (widget.showCreateOption && widget.enabled) {
      options.add(ShadOption(
        value: '__create_new__',
        child: _buildCreateNewOption(),
      ));
    }

    return ShadSelectFormField<String>(
      enabled: widget.enabled,
      placeholder: Text(widget.placeholder ?? 'categories.selectCategory'.tr()),
      options: options,
      selectedOptionBuilder: (context, value) {
        if (value == null) {
          return Text(widget.placeholder ?? 'categories.selectCategory'.tr());
        }
        if (value == '__create_new__') {
          return Text('categories.createNew'.tr());
        }

        final category = allCategories.firstWhere((cat) => cat.id == value);
        return _buildSelectedCategoryDisplay(category);
      },
      onChanged: widget.enabled
          ? (String? categoryId) {
              if (categoryId == '__create_new__') {
                _showCreateCategoryDialog();
                return;
              }

              final category = categoryId != null
                  ? allCategories.firstWhere((cat) => cat.id == categoryId)
                  : null;
              setState(() {
                _selectedCategory = category;
              });
              widget.onCategorySelected(category);
            }
          : null,
      initialValue: widget.selectedCategoryId,
    );
  }

  Widget _buildCategoryOption(Category category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXs),
      child: Row(
        children: [
          // Category Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(category.color),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
            ),
            child: Icon(
              _getIconData(category.iconName),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),

          // Category Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category.description != null &&
                    category.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    category.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.lightOnSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Type badge
          _buildTypeBadge(category.type),
        ],
      ),
    );
  }

  Widget _buildSubcategoryOption(Category subcategory) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.paddingL,
        top: AppDimensions.spacingXs,
        bottom: AppDimensions.spacingXs,
      ),
      child: Row(
        children: [
          // Indent indicator
          Container(
            width: 2,
            height: 20,
            color: AppColors.lightBorder,
          ),
          const SizedBox(width: AppDimensions.spacingS),

          // Subcategory Icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(subcategory.color),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
            ),
            child: Icon(
              _getIconData(subcategory.iconName),
              color: Colors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),

          // Subcategory Name
          Expanded(
            child: Text(
              subcategory.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateNewOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.add,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              'categories.createNewCategory'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCategoryDisplay(Category category) {
    return Row(
      children: [
        // Category Icon
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Color(category.color),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
          ),
          child: Icon(
            _getIconData(category.iconName),
            color: Colors.white,
            size: 12,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),

        // Category Name
        Expanded(
          child: Text(
            category.name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Type badge (small)
        if (widget.transactionType == null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: _getTypeColor(category.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              _getTypeAbbreviation(category.type),
              style: TextStyle(
                fontSize: 9,
                color: _getTypeColor(category.type),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeBadge(CategoryType type) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _getTypeColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
      ),
      child: Text(
        _getTypeDisplayName(type),
        style: TextStyle(
          fontSize: 10,
          color: _getTypeColor(type),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                color: AppColors.lightDisabled,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  'categories.noCategoriesAvailable'.tr(),
                  style: theme.textTheme.small.copyWith(
                    color: AppColors.lightDisabled,
                  ),
                ),
              ),
            ],
          ),
          if (widget.showCreateOption && widget.enabled) ...[
            const SizedBox(height: AppDimensions.spacingS),
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: _showCreateCategoryDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Text('categories.createCategory'.tr()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCreateCategoryDialog() {
    // Navigate to create category screen or show dialog
    // This could be implemented based on your navigation patterns
    // For now, we'll show a simple dialog
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('categories.createCategory'.tr()),
        description: Text('categories.createCategoryDescription'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to create category screen
              // context.push('/categories/add?type=${widget.transactionType?.name}');
            },
            child: Text('categories.createCategory'.tr()),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return AppColors.income;
      case CategoryType.expense:
        return AppColors.expense;
      case CategoryType.both:
        return AppColors.transfer;
    }
  }

  String _getTypeDisplayName(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return 'categories.income'.tr();
      case CategoryType.expense:
        return 'categories.expense'.tr();
      case CategoryType.both:
        return 'categories.both'.tr();
    }
  }

  String _getTypeAbbreviation(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return 'I';
      case CategoryType.expense:
        return 'E';
      case CategoryType.both:
        return 'B';
    }
  }

  CategoryType _mapTransactionToCategoryType(TransactionType transactionType) {
    switch (transactionType) {
      case TransactionType.income:
        return CategoryType.income;
      case TransactionType.expense:
        return CategoryType.expense;
      case TransactionType.transfer:
        // For transfers, we might want to show both types or handle differently
        return CategoryType.both;
    }
  }

  IconData _getIconData(String iconName) {
    // This should match your existing icon mapping logic
    switch (iconName) {
      case 'category':
        return Icons.category;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'movie':
        return Icons.movie;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'business_center':
        return Icons.business_center;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }
}
