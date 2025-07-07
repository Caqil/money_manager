// lib/presentation/screens/transactions/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validation_helper.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/account_selector.dart';
import 'widgets/category_selector.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String? accountId;
  final String? categoryId;

  const AddExpenseScreen({
    super.key,
    this.accountId,
    this.categoryId,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _uuid = const Uuid();

  Account? _selectedAccount;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Quick amount buttons for common expense amounts
  final List<double> _quickAmounts = [5, 10, 25, 50, 100];

  // Popular expense categories for quick selection
  final List<Map<String, dynamic>> _popularCategories = [
    {
      'name': 'Food & Dining',
      'icon': Icons.restaurant,
      'color': Color(0xFFFF5722)
    },
    {
      'name': 'Transportation',
      'icon': Icons.directions_car,
      'color': Color(0xFF2196F3)
    },
    {
      'name': 'Shopping',
      'icon': Icons.shopping_bag,
      'color': Color(0xFF9C27B0)
    },
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Color(0xFFE91E63)},
    {
      'name': 'Bills & Utilities',
      'icon': Icons.receipt,
      'color': Color(0xFF607D8B)
    },
    {
      'name': 'Health & Fitness',
      'icon': Icons.fitness_center,
      'color': Color(0xFF4CAF50)
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeDefaults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set default account if provided
      if (widget.accountId != null) {
        final accountsAsync = ref.read(accountListProvider);
        accountsAsync.whenData((accounts) {
          final account = accounts.firstWhere(
            (acc) => acc.id == widget.accountId,
            orElse: () => accounts.first,
          );
          setState(() {
            _selectedAccount = account;
          });
        });
      }

      // Set default category if provided
      if (widget.categoryId != null) {
        final categoriesAsync = ref.read(categoryListProvider);
        categoriesAsync.whenData((categories) {
          final category = categories.firstWhere(
            (cat) => cat.id == widget.categoryId,
            orElse: () => categories.first,
          );
          setState(() {
            _selectedCategory = category;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'transactions.addExpense'.tr(),
        showBackButton: true,
        actions: [
          // Receipt scanner button
          IconButton(
            onPressed: _isLoading ? null : _scanReceipt,
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Scan Receipt',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(),

              const SizedBox(height: AppDimensions.spacingL),

              // Amount Section
              _buildAmountSection(),

              const SizedBox(height: AppDimensions.spacingL),

              // Account Selection
              _buildAccountSection(),

              const SizedBox(height: AppDimensions.spacingL),

              // Category Selection
              _buildCategorySection(),

              const SizedBox(height: AppDimensions.spacingL),

              // Date Selection
              _buildDateSection(),

              const SizedBox(height: AppDimensions.spacingL),

              // Notes Section
              _buildNotesSection(),

              const SizedBox(height: AppDimensions.spacingL),

              // Budget Warning (if applicable)
              _buildBudgetWarning(),

              const SizedBox(height: AppDimensions.spacingXl),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.error,
            AppColors.error.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: const Icon(
              Icons.trending_down,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Expense',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  'Track your spending and stay on budget',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'transactions.amount'.tr(),
          style: ShadTheme.of(context).textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),

        // Amount Input
        ShadInputFormField(
          controller: _amountController,
          placeholder: Text('0.00'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: !_isLoading,
          validator: (value) =>
              ValidationHelper.getAmountErrorMessage(value ?? ''),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          leading: Text(
            _selectedAccount?.currency ?? 'USD',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // Quick Amount Buttons
        _buildQuickAmountButtons(),
      ],
    );
  }

  Widget _buildQuickAmountButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Amounts',
          style: ShadTheme.of(context).textTheme.muted,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: _quickAmounts.map((amount) {
            return ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: _isLoading
                  ? null
                  : () {
                      _amountController.text = amount.toString();
                    },
              child: Text(
                CurrencyFormatter.format(
                  amount,
                  currency: _selectedAccount?.currency ?? 'USD',
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'accounts.account'.tr(),
          style: ShadTheme.of(context).textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        AccountSelector(
          selectedAccountId: _selectedAccount?.id,
          onAccountSelected: (account) {
            setState(() {
              _selectedAccount = account;
            });
          },
          enabled: !_isLoading,
          showBalance: true,
        ),
        if (_selectedAccount != null) ...[
          const SizedBox(height: AppDimensions.spacingS),
          _buildAccountBalanceInfo(),
        ],
      ],
    );
  }

  Widget _buildAccountBalanceInfo() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final balanceAfter = _selectedAccount!.balance - amount;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: balanceAfter < 0
            ? AppColors.error.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: balanceAfter < 0
              ? AppColors.error.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            balanceAfter < 0 ? Icons.warning : Icons.info_outline,
            size: 16,
            color: balanceAfter < 0 ? AppColors.error : AppColors.warning,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Balance: ${CurrencyFormatter.format(_selectedAccount!.balance, currency: _selectedAccount!.currency)}',
                  style: ShadTheme.of(context).textTheme.small,
                ),
                if (amount > 0) ...[
                  Text(
                    'After expense: ${CurrencyFormatter.format(balanceAfter, currency: _selectedAccount!.currency)}',
                    style: ShadTheme.of(context).textTheme.small.copyWith(
                          color: balanceAfter < 0
                              ? AppColors.error
                              : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'categories.category'.tr(),
              style: ShadTheme.of(context).textTheme.h4,
            ),
            const Spacer(),
            ShadButton.ghost(
              size: ShadButtonSize.sm,
              onPressed: _isLoading
                  ? null
                  : () {
                      context.go('/categories/add?type=expense');
                    },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Text('Add Category'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),

        // Popular Categories (if no categories exist)
        categoriesAsync.when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _buildPopularCategories(),
          data: (categories) {
            // Filter for expense categories
            final expenseCategories = categories
                .where((cat) =>
                    cat.type == CategoryType.expense ||
                    cat.type == CategoryType.both)
                .toList();

            if (expenseCategories.isEmpty) {
              return _buildPopularCategories();
            }

            return _buildCategoryGrid(expenseCategories);
          },
        ),
      ],
    );
  }

  Widget _buildPopularCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Categories',
          style: ShadTheme.of(context).textTheme.muted,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: AppDimensions.spacingS,
            mainAxisSpacing: AppDimensions.spacingS,
          ),
          itemCount: _popularCategories.length,
          itemBuilder: (context, index) {
            final category = _popularCategories[index];
            return GestureDetector(
              onTap: _isLoading
                  ? null
                  : () {
                      // Handle category creation/selection
                      _createAndSelectCategory(category);
                    },
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(
                    color: (category['color'] as Color).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: category['color'] as Color,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Text(
                        category['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Center(
          child: ShadButton.outline(
            onPressed: () => context.go('/categories/add?type=expense'),
            child: Text('Create Custom Category'),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(List<Category> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: AppDimensions.spacingS,
        mainAxisSpacing: AppDimensions.spacingS,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _selectedCategory?.id == category.id;

        return GestureDetector(
          onTap: _isLoading
              ? null
              : () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.secondary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : ShadTheme.of(context).colorScheme.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(category.iconName ?? 'expense'),
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: isSelected ? Colors.white : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'transactions.date'.tr(),
          style: ShadTheme.of(context).textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        InkWell(
          onTap: _isLoading ? null : _selectDate,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              border:
                  Border.all(color: ShadTheme.of(context).colorScheme.border),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  DateFormat.yMMMd().format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'transactions.notes'.tr(),
          style: ShadTheme.of(context).textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ShadInputFormField(
          controller: _notesController,
          placeholder: Text('transactions.addNotes'.tr()),
          maxLines: 3,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildBudgetWarning() {
    // Placeholder for budget warning
    // This would check if the expense would exceed the category budget
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (amount > 100 && _selectedCategory != null) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Alert',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                  Text(
                    'This expense is higher than usual for this category.',
                    style: ShadTheme.of(context).textTheme.small,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButtons() {
    final canSubmit = _amountController.text.isNotEmpty &&
        _selectedAccount != null &&
        _selectedCategory != null &&
        !_isLoading;

    return Row(
      children: [
        Expanded(
          child: ShadButton.outline(
            onPressed: _isLoading ? null : () => context.pop(),
            child: Text('common.cancel'.tr()),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          flex: 2,
          child: ShadButton(
            onPressed: canSubmit ? _saveExpense : null,
            child: _isLoading
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.remove, size: 18, color: Colors.white),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text('Add Expense'),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _scanReceipt() {
    // Placeholder for receipt scanning functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Receipt scanning feature coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _createAndSelectCategory(Map<String, dynamic> categoryData) {
    // Placeholder for creating a new category
    // In real implementation, this would create the category and select it
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating category: ${categoryData['name']}'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = Transaction(
        id: _uuid.v4(),
        amount: amount,
        categoryId: _selectedCategory!.id,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        type: TransactionType.expense,
        accountId: _selectedAccount!.id,
        currency: _selectedAccount!.currency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final transactionId = await ref
          .read(transactionListProvider.notifier)
          .addTransaction(transaction);

      if (transactionId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Expense of ${CurrencyFormatter.format(amount, currency: _selectedAccount!.currency)} added successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        throw Exception('Failed to save transaction');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add expense: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getCategoryIcon(String iconName) {
    // Simple icon mapping for categories
    switch (iconName) {
      case 'food':
      case 'restaurant':
        return Icons.restaurant;
      case 'transport':
      case 'car':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
      case 'utilities':
        return Icons.receipt;
      case 'health':
      case 'fitness':
        return Icons.fitness_center;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      default:
        return Icons.money_off;
    }
  }
}
