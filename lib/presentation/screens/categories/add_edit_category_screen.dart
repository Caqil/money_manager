import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/category.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/category_form.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final CategoryType? defaultType;

  const AddEditCategoryScreen({
    super.key,
    this.categoryId,
    this.defaultType,
  });

  @override
  ConsumerState<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  bool _isLoading = false;
  final _uuid = const Uuid();

  bool get isEditing => widget.categoryId != null;

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      final categoryAsync = ref.watch(categoryProvider(widget.categoryId!));

      return categoryAsync.when(
        loading: () => _buildLoadingScreen(),
        error: (error, _) => _buildErrorScreen(error),
        data: (category) {
          if (category == null) {
            return _buildNotFoundScreen();
          }
          return _buildScreen(category);
        },
      );
    }

    return _buildScreen(null);
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'categories.editCategory'.tr(),
        showBackButton: true,
      ),
      body: const Center(
        child: ShimmerLoading(
          child: SkeletonLoader(height: 400, width: double.infinity),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(Object error) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'categories.editCategory'.tr(),
        showBackButton: true,
      ),
      body: Center(
        child: CustomErrorWidget(
          title: 'errors.loadingCategory'.tr(),
          message: error.toString(),
          actionText: 'common.retry'.tr(),
          onActionPressed: () =>
              ref.refresh(categoryProvider(widget.categoryId!)),
        ),
      ),
    );
  }

  Widget _buildNotFoundScreen() {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'categories.editCategory'.tr(),
        showBackButton: true,
      ),
      body: const Center(
        child: EmptyStateWidget(
          iconData: Icons.category_outlined,
          title: 'Category not found',
          message: 'The category you are trying to edit could not be found.',
        ),
      ),
    );
  }

  Widget _buildScreen(Category? category) {
    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing
            ? 'categories.editCategory'.tr()
            : 'categories.addCategory'.tr(),
        showBackButton: true,
        actions: [
          if (isEditing && category != null && !category.isDefault)
            IconButton(
              onPressed:
                  _isLoading ? null : () => _showDeleteConfirmation(category),
              icon: Icon(
                Icons.delete_outline,
                color: _isLoading ? AppColors.lightDisabled : AppColors.error,
              ),
              tooltip: 'common.delete'.tr(),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              _buildHeader(category),
              const SizedBox(height: AppDimensions.spacingL),

              // Form
              CategoryForm(
                category: category,
                defaultType: widget.defaultType,
                enabled: !_isLoading,
                isLoading: _isLoading,
                onSubmit: _handleSubmit,
                onCancel: _handleCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Category? category) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          isEditing
              ? 'categories.editCategoryTitle'.tr()
              : 'categories.addCategoryTitle'.tr(),
          style: theme.textTheme.h2,
        ),
        const SizedBox(height: AppDimensions.spacingS),

        // Subtitle
        Text(
          isEditing
              ? 'categories.editCategorySubtitle'.tr()
              : 'categories.addCategorySubtitle'.tr(),
          style: theme.textTheme.p.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),

        // Warning for default categories
        if (isEditing && category?.isDefault == true) ...[
          const SizedBox(height: AppDimensions.spacingM),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    'categories.defaultCategoryWarning'.tr(),
                    style: theme.textTheme.small.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleSubmit(CategoryFormData formData) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(categoryListProvider.notifier);

      if (isEditing) {
        // Update existing category
        final updatedCategory = widget.categoryId != null
            ? ref.read(categoryProvider(widget.categoryId!)).value?.copyWith(
                  name: formData.name,
                  description: formData.description,
                  iconName: formData.iconName,
                  color: formData.color,
                  type: formData.type,
                  parentCategoryId: formData.parentCategoryId,
                  tags: formData.tags,
                  enableBudgetTracking: formData.enableBudgetTracking,
                  updatedAt: DateTime.now(),
                )
            : null;

        if (updatedCategory != null) {
          final success = await notifier.updateCategory(updatedCategory);
          if (success) {
            _showSuccessAndNavigateBack('categories.categoryUpdated'.tr());
          } else {
            _showError('categories.errorUpdatingCategory'.tr());
          }
        }
      } else {
        // Create new category
        final newCategory = Category(
          id: _uuid.v4(),
          name: formData.name,
          description: formData.description,
          iconName: formData.iconName,
          color: formData.color,
          type: formData.type,
          parentCategoryId: formData.parentCategoryId,
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: formData.tags,
          enableBudgetTracking: formData.enableBudgetTracking,
        );

        final categoryId = await notifier.addCategory(newCategory);
        if (categoryId != null) {
          _showSuccessAndNavigateBack('categories.categoryCreated'.tr());
        } else {
          _showError('categories.errorCreatingCategory'.tr());
        }
      }
    } catch (e) {
      _showError(isEditing
          ? 'categories.errorUpdatingCategory'.tr()
          : 'categories.errorCreatingCategory'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleCancel() {
    if (_isLoading) return;
    context.pop();
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
    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(categoryListProvider.notifier);
      final success = await notifier.deleteCategory(category.id);

      if (success) {
        _showSuccessAndNavigateBack('categories.categoryDeleted'.tr());
      } else {
        _showError('categories.errorDeletingCategory'.tr());
      }
    } catch (e) {
      _showError('categories.errorDeletingCategory'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessAndNavigateBack(String message) {
    if (!mounted) return;
    ShadSonner.of(context).show(
      ShadToast.raw(
        variant: ShadToastVariant.primary,
        description: Text(message),
      ),
    );

    context.pop();
  }

  void _showError(String message) {
    if (!mounted) return;
    ShadSonner.of(context).show(
      ShadToast.raw(
        variant: ShadToastVariant.destructive,
        description: Text(message),
      ),
    );
  }
}
