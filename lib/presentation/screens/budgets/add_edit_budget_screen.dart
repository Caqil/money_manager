import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/budget.dart';
import '../../providers/budget_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import 'widgets/budget_form.dart';

class AddEditBudgetScreen extends ConsumerStatefulWidget {
  final String? budgetId;

  const AddEditBudgetScreen({
    super.key,
    this.budgetId,
  });

  @override
  ConsumerState<AddEditBudgetScreen> createState() =>
      _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends ConsumerState<AddEditBudgetScreen> {
  bool _isLoading = false;
  Budget? _existingBudget;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.budgetId != null;
    if (_isEditMode) {
      _loadExistingBudget();
    }
  }

  void _loadExistingBudget() {
    if (widget.budgetId == null) return;

    final budgetAsync = ref.read(budgetProvider(widget.budgetId!));
    budgetAsync.when(
      data: (budget) {
        setState(() {
          _existingBudget = budget;
        });
      },
      loading: () => setState(() => _isLoading = true),
      error: (error, stack) {
        _showError('budgets.loadError'.tr());
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Content
            Expanded(
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          ShadButton.ghost(
            onPressed: () => context.pop(),
            size: ShadButtonSize.sm,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: AppDimensions.iconS,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode
                      ? 'budgets.editBudget'.tr()
                      : 'budgets.addBudget'.tr(),
                  style: theme.textTheme.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isEditMode
                      ? 'budgets.editBudgetSubtitle'.tr()
                      : 'budgets.addBudgetSubtitle'.tr(),
                  style: theme.textTheme.p.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (_isEditMode && _existingBudget != null) ...[
            ShadButton.ghost(
              onPressed: _showDeleteConfirmation,
              size: ShadButtonSize.sm,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: AppDimensions.iconS,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isEditMode && _existingBudget == null) {
      return _buildLoadingContent();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        children: [
          // Form card
          ShadCard(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingS),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: Icon(
                          _isEditMode ? Icons.edit : Icons.add,
                          color: AppColors.primary,
                          size: AppDimensions.iconM,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditMode
                                  ? 'budgets.budgetDetails'.tr()
                                  : 'budgets.createNewBudget'.tr(),
                              style:
                                  ShadTheme.of(context).textTheme.h4.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                            ),
                            Text(
                              _isEditMode
                                  ? 'budgets.updateBudgetInfo'.tr()
                                  : 'budgets.fillBudgetInfo'.tr(),
                              style: ShadTheme.of(context).textTheme.muted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.spacingXl),

                  // Budget form
                  BudgetForm(
                    initialBudget: _existingBudget,
                    onSubmit: _handleSubmit,
                    isLoading: _isLoading,
                    enabled: !_isLoading,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Tips card
          if (!_isEditMode) _buildTipsCard(),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerLoading(
            child: SizedBox(),
          ),
          SizedBox(height: AppDimensions.spacingM),
          Text('budgets.loadingBudget...'),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: AppColors.info,
                    size: AppDimensions.iconM,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Text(
                  'budgets.budgetingTips'.tr(),
                  style: theme.textTheme.h4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),
            ..._getBudgetingTips().map((tip) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppDimensions.spacingS),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Text(
                          tip,
                          style: theme.textTheme.p.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _handleSubmit(BudgetFormData formData) async {
    setState(() => _isLoading = true);

    try {
      final budgetNotifier = ref.read(budgetListProvider.notifier);

      if (_isEditMode && _existingBudget != null) {
        // Update existing budget
        final updatedBudget = _existingBudget!.copyWith(
          name: formData.name,
          categoryId: formData.categoryId,
          limit: formData.limit,
          period: formData.period,
          startDate: formData.startDate,
          endDate: formData.endDate,
          isActive: formData.isActive,
          alertThreshold: formData.alertThreshold,
          enableAlerts: formData.enableAlerts,
          accountIds: formData.accountIds,
          description: formData.description,
          rolloverType: formData.rolloverType,
          updatedAt: DateTime.now(),
        );

        final success = await budgetNotifier.updateBudget(updatedBudget);

        if (success) {
          _showSuccess('budgets.budgetUpdated'.tr());
          context.pop();
        } else {
          _showError('budgets.updateError'.tr());
        }
      } else {
        // Create new budget
        final newBudget = Budget(
          id: '', // Will be generated by repository
          name: formData.name,
          categoryId: formData.categoryId,
          limit: formData.limit,
          period: formData.period,
          startDate: formData.startDate,
          endDate: formData.endDate,
          isActive: formData.isActive,
          alertThreshold: formData.alertThreshold,
          enableAlerts: formData.enableAlerts,
          accountIds: formData.accountIds,
          description: formData.description,
          rolloverType: formData.rolloverType,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final budgetId = await budgetNotifier.addBudget(newBudget);

        if (budgetId != null) {
          _showSuccess('budgets.budgetCreated'.tr());
          context.pop();
        } else {
          _showError('budgets.createError'.tr());
        }
      }
    } catch (error) {
      _showError(error.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('budgets.deleteBudget'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('budgets.deleteConfirmation'.tr()),
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: AppColors.warning,
                    size: AppDimensions.iconS,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      'budgets.deleteWarning'.tr(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleDelete();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _handleDelete() async {
    if (_existingBudget == null) return;

    setState(() => _isLoading = true);

    try {
      final budgetNotifier = ref.read(budgetListProvider.notifier);
      final success = await budgetNotifier.deleteBudget(_existingBudget!.id);

      if (success) {
        _showSuccess('budgets.budgetDeleted'.tr());
        context.pop();
      } else {
        _showError('budgets.deleteError'.tr());
      }
    } catch (error) {
      _showError(error.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  List<String> _getBudgetingTips() {
    return [
      'budgets.tip1'.tr(),
      'budgets.tip2'.tr(),
      'budgets.tip3'.tr(),
      'budgets.tip4'.tr(),
      'budgets.tip5'.tr(),
    ];
  }
}
