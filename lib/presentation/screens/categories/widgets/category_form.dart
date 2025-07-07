import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../data/models/category.dart';
import '../../../providers/category_provider.dart';
import '../../../widgets/common/loading_widget.dart';
import 'category_icon_picker.dart';

typedef CategoryFormData = ({
  String name,
  String? description,
  String iconName,
  int color,
  CategoryType type,
  String? parentCategoryId,
  List<String>? tags,
  bool enableBudgetTracking,
});

class CategoryForm extends ConsumerStatefulWidget {
  final Category? category;
  final CategoryType? defaultType;
  final bool enabled;
  final bool isLoading;
  final Function(CategoryFormData)? onSubmit;
  final VoidCallback? onCancel;

  const CategoryForm({
    super.key,
    this.category,
    this.defaultType,
    this.enabled = true,
    this.isLoading = false,
    this.onSubmit,
    this.onCancel,
  });

  @override
  ConsumerState<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  String _selectedIcon = 'category';
  int _selectedColor = AppColors.categoryColors[0].value;
  CategoryType _selectedType = CategoryType.expense;
  String? _selectedParentCategoryId;
  bool _enableBudgetTracking = true;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.category != null) {
      final category = widget.category!;
      _nameController.text = category.name;
      _descriptionController.text = category.description ?? '';
      _selectedIcon = category.iconName;
      _selectedColor = category.color;
      _selectedType = category.type;
      _selectedParentCategoryId = category.parentCategoryId;
      _enableBudgetTracking = category.enableBudgetTracking;
      _tagsController.text = category.tags?.join(', ') ?? '';
    } else {
      _selectedType = widget.defaultType ?? CategoryType.expense;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Name
          _buildNameField(),
          const SizedBox(height: AppDimensions.spacingM),

          // Description
          _buildDescriptionField(),
          const SizedBox(height: AppDimensions.spacingM),

          // Type Selection
          _buildTypeSelection(),
          const SizedBox(height: AppDimensions.spacingM),

          // Parent Category (for subcategories)
          if (_selectedType != CategoryType.both) ...[
            _buildParentCategorySelection(),
            const SizedBox(height: AppDimensions.spacingM),
          ],

          // Icon Selection
          _buildIconSelection(),
          const SizedBox(height: AppDimensions.spacingM),

          // Color Selection
          _buildColorSelection(),
          const SizedBox(height: AppDimensions.spacingM),

          // Tags
          _buildTagsField(),
          const SizedBox(height: AppDimensions.spacingM),

          // Budget Tracking
          _buildBudgetTrackingSwitch(),
          SizedBox(height: AppDimensions.spacingXl),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'categories.categoryName'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ShadInputFormField(
          controller: _nameController,
          placeholder: Text('categories.enterCategoryName'.tr()),
          enabled: widget.enabled && !widget.isLoading,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'categories.nameRequired'.tr();
            }
            if (value.trim().length < 2) {
              return 'categories.nameMinLength'.tr();
            }
            if (value.trim().length > 50) {
              return 'categories.nameMaxLength'.tr();
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'categories.description'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ShadInputFormField(
          controller: _descriptionController,
          placeholder: Text('categories.enterDescription'.tr()),
          maxLines: 3,
          enabled: widget.enabled && !widget.isLoading,
        ),
      ],
    );
  }

  Widget _buildTypeSelection() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'categories.categoryType'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ShadSelectFormField<CategoryType>(
          placeholder: Text('categories.selectType'.tr()),
          options: [
            ShadOption(
              value: CategoryType.income,
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: AppColors.income,
                    size: 16,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text('categories.income'.tr()),
                ],
              ),
            ),
            ShadOption(
              value: CategoryType.expense,
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_downward,
                    color: AppColors.expense,
                    size: 16,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text('categories.expense'.tr()),
                ],
              ),
            ),
            ShadOption(
              value: CategoryType.both,
              child: Row(
                children: [
                  Icon(
                    Icons.swap_vert,
                    color: AppColors.transfer,
                    size: 16,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text('categories.both'.tr()),
                ],
              ),
            ),
          ],
          selectedOptionBuilder: (context, value) =>
              Text(_getTypeDisplayName(value)),
          onChanged: widget.enabled && !widget.isLoading
              ? (CategoryType? value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      _selectedParentCategoryId =
                          null; // Reset parent when type changes
                    });
                  }
                }
              : null,
          initialValue: _selectedType,
        ),
      ],
    );
  }

  Widget _buildParentCategorySelection() {
    final theme = ShadTheme.of(context);
    final parentCategoriesAsync = ref.watch(parentCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'categories.parentCategory'.tr(),
          style: theme.textTheme.h4,
        ),
        Text(
          'categories.parentCategoryOptional'.tr(),
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        parentCategoriesAsync.when(
          loading: () => const ShimmerLoading(
            child: SkeletonLoader(height: 48, width: double.infinity),
          ),
          error: (error, _) => Text(
            'categories.errorLoadingParents'.tr(),
            style: theme.textTheme.small.copyWith(color: AppColors.error),
          ),
          data: (categories) {
            final filteredCategories = categories
                .where((cat) =>
                    cat.type == _selectedType &&
                    cat.id != widget.category?.id) // Prevent self-selection
                .toList();

            if (filteredCategories.isEmpty) {
              return Text(
                'categories.noParentCategoriesAvailable'.tr(),
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              );
            }

            return ShadSelectFormField<String>(
              placeholder: Text('categories.selectParentCategory'.tr()),
              options: [
                ShadOption(
                  value: null,
                  child: Text('categories.noParentCategory'.tr()),
                ),
                ...filteredCategories.map((category) => ShadOption(
                      value: category.id,
                      child: Row(
                        children: [
                          Icon(
                            _getIconData(category.iconName),
                            color: Color(category.color),
                            size: 16,
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          Text(category.name),
                        ],
                      ),
                    )),
              ],
              selectedOptionBuilder: (context, value) {
                if (value == null)
                  return Text('categories.noParentCategory'.tr());
                final category =
                    filteredCategories.firstWhere((cat) => cat.id == value);
                return Text(category.name);
              },
              onChanged: widget.enabled && !widget.isLoading
                  ? (String? value) {
                      setState(() {
                        _selectedParentCategoryId = value;
                      });
                    }
                  : null,
              initialValue: _selectedParentCategoryId,
            );
          },
        ),
      ],
    );
  }

  Widget _buildIconSelection() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'categories.icon'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        GestureDetector(
          onTap: widget.enabled && !widget.isLoading ? _showIconPicker : null,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.border,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(_selectedColor),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    _getIconData(_selectedIcon),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Text(
                    'categories.tapToSelectIcon'.tr(),
                    style: theme.textTheme.p,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelection() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'categories.color'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: AppColors.categoryColors
              .map((color) => GestureDetector(
                    onTap: widget.enabled && !widget.isLoading
                        ? () => setState(() => _selectedColor = color.value)
                        : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                        border: _selectedColor == color.value
                            ? Border.all(
                                color: theme.colorScheme.foreground,
                                width: 2,
                              )
                            : null,
                      ),
                      child: _selectedColor == color.value
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTagsField() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'categories.tags'.tr(),
          style: theme.textTheme.h4,
        ),
        Text(
          'categories.tagsOptional'.tr(),
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ShadInputFormField(
          controller: _tagsController,
          placeholder: Text('categories.enterTagsCommaSeparated'.tr()),
          enabled: widget.enabled && !widget.isLoading,
        ),
      ],
    );
  }

  Widget _buildBudgetTrackingSwitch() {
    final theme = ShadTheme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'categories.enableBudgetTracking'.tr(),
                style: theme.textTheme.h4,
              ),
              Text(
                'categories.enableBudgetTrackingDescription'.tr(),
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        ShadSwitch(
          value: _enableBudgetTracking,
          onChanged: widget.enabled && !widget.isLoading
              ? (bool value) {
                  setState(() {
                    _enableBudgetTracking = value;
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.onCancel != null) ...[
          Expanded(
            child: ShadButton.outline(
              onPressed:
                  widget.enabled && !widget.isLoading ? widget.onCancel : null,
              child: Text('common.cancel'.tr()),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
        ],
        Expanded(
          child: ShadButton(
            onPressed:
                widget.enabled && !widget.isLoading && widget.onSubmit != null
                    ? _handleSubmit
                    : null,
            child: widget.isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text('common.saving'.tr()),
                    ],
                  )
                : Text(widget.category != null
                    ? 'categories.updateCategory'.tr()
                    : 'categories.createCategory'.tr()),
          ),
        ),
      ],
    );
  }

  void _showIconPicker() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('categories.selectIcon'.tr()),
        child: SizedBox(
          width: double.maxFinite,
          child: CategoryIconPicker(
            selectedIcon: _selectedIcon,
            onIconSelected: (String iconName) {
              setState(() {
                _selectedIcon = iconName;
              });
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsController.text.trim().isNotEmpty
        ? _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList()
        : null;

    final formData = (
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      iconName: _selectedIcon,
      color: _selectedColor,
      type: _selectedType,
      parentCategoryId: _selectedParentCategoryId,
      tags: tags,
      enableBudgetTracking: _enableBudgetTracking,
    );

    widget.onSubmit?.call(formData);
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

  IconData _getIconData(String iconName) {
    // This should match your existing icon mapping logic
    // For now, return a default icon
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
