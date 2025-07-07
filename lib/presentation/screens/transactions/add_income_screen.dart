// lib/presentation/screens/transactions/add_income_screen.dart
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

class AddIncomeScreen extends ConsumerStatefulWidget {
  final String? accountId;
  final String? categoryId;

  const AddIncomeScreen({
    super.key,
    this.accountId,
    this.categoryId,
  });

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _uuid = const Uuid();

  Account? _selectedAccount;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Quick amount buttons for common income amounts
  final List<double> _quickAmounts = [100, 500, 1000, 2000, 5000];

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
        title: 'transactions.addIncome'.tr(),
        showBackButton: true,
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
            AppColors.success,
            AppColors.success.withOpacity(0.8),
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
              Icons.trending_up,
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
                  'Add Income',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  'Record money coming into your account',
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
              color: AppColors.success,
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
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    'Income will be added to ${_selectedAccount!.name}',
                    style: ShadTheme.of(context).textTheme.small.copyWith(
                          color: AppColors.success,
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
                      context.go('/categories/add?type=income');
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
        categoriesAsync.when(
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Text(
              'Error loading categories: $error',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          data: (categories) {
            // Filter for income categories
            final incomeCategories = categories
                .where((cat) =>
                    cat.type == CategoryType.income ||
                    cat.type == CategoryType.both)
                .toList();

            if (incomeCategories.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: ShadTheme.of(context).colorScheme.border),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 48,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Text(
                      'No income categories found',
                      style: ShadTheme.of(context).textTheme.h4,
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    ShadButton.outline(
                      onPressed: () =>
                          context.go('/categories/add?type=income'),
                      child: Text('Create Income Category'),
                    ),
                  ],
                ),
              );
            }

            return Wrap(
              spacing: AppDimensions.spacingS,
              runSpacing: AppDimensions.spacingS,
              children: incomeCategories.map((category) {
                final isSelected = _selectedCategory?.id == category.id;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (category.iconName != null)
                        Icon(
                          _getCategoryIcon(category.iconName!),
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.success,
                        ),
                      if (category.iconName != null)
                        const SizedBox(width: AppDimensions.spacingXs),
                      Text(category.name),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: _isLoading
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          }
                        },
                  selectedColor: AppColors.success,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
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
            onPressed: canSubmit ? _saveIncome : null,
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
                      Icon(Icons.add, size: 18, color: Colors.white),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text('Add Income'),
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

  Future<void> _saveIncome() async {
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
        type: TransactionType.income,
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
              'Income of ${CurrencyFormatter.format(amount, currency: _selectedAccount!.currency)} added successfully',
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
            content: Text('Failed to add income: ${e.toString()}'),
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
    // Simple icon mapping - you can expand this based on your needs
    switch (iconName) {
      case 'salary':
        return Icons.work;
      case 'bonus':
        return Icons.star;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard;
      case 'freelance':
        return Icons.laptop;
      case 'business':
        return Icons.business;
      default:
        return Icons.attach_money;
    }
  }
}

// Enum for category types (you might already have this)
enum CategoryType {
  income,
  expense,
  both,
}
