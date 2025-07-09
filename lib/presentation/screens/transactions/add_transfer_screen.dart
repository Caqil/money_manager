// lib/presentation/screens/transactions/add_transfer_screen.dart
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
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/account_selector.dart';

class AddTransferScreen extends ConsumerStatefulWidget {
  final String? fromAccountId;
  final String? toAccountId;

  const AddTransferScreen({
    super.key,
    this.fromAccountId,
    this.toAccountId,
  });

  @override
  ConsumerState<AddTransferScreen> createState() => _AddTransferScreenState();
}

class _AddTransferScreenState extends ConsumerState<AddTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _uuid = const Uuid();

  Account? _fromAccount;
  Account? _toAccount;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Quick amount buttons for common transfer amounts
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
      final accountsAsync = ref.read(accountListProvider);
      accountsAsync.whenData((accounts) {
        // Set default from account if provided
        if (widget.fromAccountId != null) {
          final fromAccount = accounts.firstWhere(
            (acc) => acc.id == widget.fromAccountId,
            orElse: () => accounts.first,
          );
          setState(() {
            _fromAccount = fromAccount;
          });
        }

        // Set default to account if provided
        if (widget.toAccountId != null) {
          final toAccount = accounts.firstWhere(
            (acc) => acc.id == widget.toAccountId,
            orElse: () => accounts.first,
          );
          setState(() {
            _toAccount = toAccount;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final accountsAsync = ref.watch(accountListProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'transactions.addTransfer'.tr(),
        showBackButton: true,
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: LoadingWidget()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading accounts',
                style: theme.textTheme.h4,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              ShadButton.outline(
                onPressed: () => ref.refresh(accountListProvider),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
        data: (accounts) => _buildTransferScreen(context, accounts),
      ),
    );
  }

  Widget _buildTransferScreen(BuildContext context, List<Account> accounts) {
    final activeAccounts = accounts.where((acc) => acc.isActive).toList();

    if (activeAccounts.length < 2) {
      return _buildInsufficientAccountsView();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),

            const SizedBox(height: AppDimensions.spacingL),

            // Transfer Flow Visualization
            _buildTransferFlow(),

            const SizedBox(height: AppDimensions.spacingL),

            // From Account Section
            _buildFromAccountSection(activeAccounts),

            const SizedBox(height: AppDimensions.spacingL),

            // Swap Button
            _buildSwapButton(),

            const SizedBox(height: AppDimensions.spacingL),

            // To Account Section
            _buildToAccountSection(activeAccounts),

            const SizedBox(height: AppDimensions.spacingL),

            // Amount Section
            _buildAmountSection(),

            const SizedBox(height: AppDimensions.spacingL),

            // Date Selection
            _buildDateSection(),

            const SizedBox(height: AppDimensions.spacingL),

            // Notes Section
            _buildNotesSection(),

            const SizedBox(height: AppDimensions.spacingL),

            // Transfer Summary
            if (_canShowSummary()) _buildTransferSummary(),

            const SizedBox(height: AppDimensions.spacingXl),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsufficientAccountsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            'Need More Accounts',
            style: ShadTheme.of(context).textTheme.h4,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            'You need at least 2 active accounts to create transfers',
            style: ShadTheme.of(context).textTheme.muted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          ShadButton(
            onPressed: () => context.go('/accounts/add'),
            child: Text('Add Account'),
          ),
        ],
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
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
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
              Icons.swap_horiz,
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
                  'Transfer Money',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  'Move funds between your accounts',
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

  Widget _buildTransferFlow() {
    if (_fromAccount == null && _toAccount == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
      ),
      child: Row(
        children: [
          // From Account
          Expanded(
            child: Column(
              children: [
                Text(
                  'From',
                  style: ShadTheme.of(context).textTheme.muted,
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  _fromAccount?.name ?? 'Select Account',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                if (_fromAccount != null)
                  Text(
                    CurrencyFormatter.format(
                      _fromAccount!.balance,
                      currency: _fromAccount!.currency,
                    ),
                    style: ShadTheme.of(context).textTheme.small,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),

          // Arrow
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(
              Icons.arrow_forward,
              color: AppColors.primary,
              size: 20,
            ),
          ),

          // To Account
          Expanded(
            child: Column(
              children: [
                Text(
                  'To',
                  style: ShadTheme.of(context).textTheme.muted,
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  _toAccount?.name ?? 'Select Account',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                if (_toAccount != null)
                  Text(
                    CurrencyFormatter.format(
                      _toAccount!.balance,
                      currency: _toAccount!.currency,
                    ),
                    style: ShadTheme.of(context).textTheme.small,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFromAccountSection(List<Account> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'From Account',
          style: ShadTheme.of(context).textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        AccountSelector(
          selectedAccountId: _fromAccount?.id,
          onAccountSelected: (account) {
            setState(() {
              _fromAccount = account;
              // Clear to account if it's the same as from account
              if (_toAccount?.id == account?.id) {
                _toAccount = null;
              }
            });
          },
          excludeAccountIds: _toAccount != null ? [_toAccount!.id] : null,
          enabled: !_isLoading,
          showBalance: true,
        ),
      ],
    );
  }

  Widget _buildSwapButton() {
    final canSwap = _fromAccount != null && _toAccount != null;

    return Center(
      child: ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: canSwap && !_isLoading ? _swapAccounts : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert, size: 16),
            const SizedBox(width: AppDimensions.spacingXs),
            Text('Swap'),
          ],
        ),
      ),
    );
  }

  Widget _buildToAccountSection(List<Account> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'To Account',
          style: ShadTheme.of(context).textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        AccountSelector(
          selectedAccountId: _toAccount?.id,
          onAccountSelected: (account) {
            setState(() {
              _toAccount = account;
            });
          },
          excludeAccountIds: _fromAccount != null ? [_fromAccount!.id] : null,
          enabled: !_isLoading,
          showBalance: true,
        ),
      ],
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transfer Amount',
          style: ShadTheme.of(context).textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),

        // Amount Input
        ShadInputFormField(
          controller: _amountController,
          placeholder: Text('0.00'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: !_isLoading && _fromAccount != null,
          validator: (value) {
            final error = ValidationHelper.getAmountErrorMessage(value);
            if (error != null) return error;

            if (_fromAccount != null) {
              final amount = double.tryParse(value);
              if (amount != null && amount > _fromAccount!.availableBalance) {
                return 'Insufficient funds in source account';
              }
            }
            return null;
          },
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          leading: Text(
            _fromAccount?.currency ?? 'USD',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // Quick Amount Buttons
        if (_fromAccount != null) _buildQuickAmountButtons(),

        // Available balance info
        if (_fromAccount != null) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  'Available: ${CurrencyFormatter.format(_fromAccount!.availableBalance, currency: _fromAccount!.currency)}',
                  style: ShadTheme.of(context).textTheme.small.copyWith(
                        color: AppColors.info,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickAmountButtons() {
    // Filter quick amounts based on available balance
    final availableBalance = _fromAccount!.availableBalance;
    final filteredAmounts =
        _quickAmounts.where((amount) => amount <= availableBalance).toList();

    if (filteredAmounts.isEmpty) {
      return const SizedBox.shrink();
    }

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
          children: [
            ...filteredAmounts.map((amount) {
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
                    currency: _fromAccount!.currency,
                  ),
                ),
              );
            }),
            // Add "All" button for transferring entire balance
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: _isLoading
                  ? null
                  : () {
                      _amountController.text = availableBalance.toString();
                    },
              child: Text('All'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transfer Date',
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
          'Transfer Notes',
          style: ShadTheme.of(context).textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ShadInputFormField(
          controller: _notesController,
          placeholder: Text('Add notes about this transfer...'),
          maxLines: 3,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildTransferSummary() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return const SizedBox.shrink();

    final fromBalanceAfter = _fromAccount!.balance - amount;
    final toBalanceAfter = _toAccount!.balance + amount;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer Summary',
            style: ShadTheme.of(context).textTheme.h4.copyWith(
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // From account after transfer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_fromAccount!.name} after:'),
              Text(
                CurrencyFormatter.format(fromBalanceAfter,
                    currency: _fromAccount!.currency),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: fromBalanceAfter < 0 ? AppColors.error : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingS),

          // To account after transfer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_toAccount!.name} after:'),
              Text(
                CurrencyFormatter.format(toBalanceAfter,
                    currency: _toAccount!.currency),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),

          // Warning for negative balance
          if (fromBalanceAfter < 0) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Row(
              children: [
                Icon(
                  Icons.warning,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    'This transfer will result in a negative balance',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canSubmit = _fromAccount != null &&
        _toAccount != null &&
        _amountController.text.isNotEmpty &&
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
            onPressed: canSubmit ? _saveTransfer : null,
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
                      Text('Processing...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_horiz, size: 18, color: Colors.white),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text('Transfer Funds'),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  bool _canShowSummary() {
    return _fromAccount != null &&
        _toAccount != null &&
        _amountController.text.isNotEmpty &&
        double.tryParse(_amountController.text) != null;
  }

  void _swapAccounts() {
    setState(() {
      final temp = _fromAccount;
      _fromAccount = _toAccount;
      _toAccount = temp;
      // Clear amount when swapping to avoid confusion
      _amountController.clear();
    });
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

  Future<void> _saveTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create transfer transaction
      final transaction = Transaction(
        id: _uuid.v4(),
        amount: amount,
        categoryId: '', // Transfers don't have categories
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        type: TransactionType.transfer,
        accountId: _fromAccount!.id,
        transferToAccountId: _toAccount!.id,
        currency: _fromAccount!.currency,
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
              'Transfer of ${CurrencyFormatter.format(amount, currency: _fromAccount!.currency)} completed successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        throw Exception('Failed to save transfer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create transfer: ${e.toString()}'),
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
}
