// lib/presentation/screens/accounts/transfer_funds_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validation_helper.dart';
import '../../../data/models/account.dart';
import '../../providers/account_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../transactions/widgets/account_selector.dart';

class TransferFundsScreen extends ConsumerStatefulWidget {
  final String? fromAccountId;
  final String? toAccountId;

  const TransferFundsScreen({
    super.key,
    this.fromAccountId,
    this.toAccountId,
  });

  @override
  ConsumerState<TransferFundsScreen> createState() =>
      _TransferFundsScreenState();
}

class _TransferFundsScreenState extends ConsumerState<TransferFundsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  Account? _fromAccount;
  Account? _toAccount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeAccounts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountsAsync = ref.read(accountListProvider);
      accountsAsync.whenData((accounts) {
        if (widget.fromAccountId != null) {
          final fromAccount = accounts.firstWhere(
            (acc) => acc.id == widget.fromAccountId,
            orElse: () => accounts.first,
          );
          setState(() {
            _fromAccount = fromAccount;
          });
        }

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
        title: 'accounts.transferFunds'.tr(),
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
        data: (accounts) => _buildTransferForm(context, accounts),
      ),
    );
  }

  Widget _buildTransferForm(BuildContext context, List<Account> accounts) {
    final theme = ShadTheme.of(context);

    // Filter accounts to only show active ones
    final activeAccounts = accounts.where((acc) => acc.isActive).toList();

    if (activeAccounts.length < 2) {
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
              'accounts.needTwoAccounts'.tr(),
              style: theme.textTheme.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'accounts.needTwoAccountsMessage'.tr(),
              style: theme.textTheme.muted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ShadButton(
              onPressed: () => context.go('/accounts/add'),
              child: Text('accounts.addAccount'.tr()),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transfer Overview Card
            _buildTransferOverviewCard(),

            const SizedBox(height: AppDimensions.spacingL),

            // From Account
            _buildAccountSection(
              title: 'accounts.fromAccount'.tr(),
              selectedAccount: _fromAccount,
              accounts: activeAccounts,
              excludeAccountId: _toAccount?.id,
              onAccountSelected: (account) {
                setState(() {
                  _fromAccount = account;
                  // Clear to account if it's the same
                  if (_toAccount?.id == account?.id) {
                    _toAccount = null;
                  }
                });
              },
            ),

            const SizedBox(height: AppDimensions.spacingL),

            // Transfer Direction Indicator
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(
                  Icons.arrow_downward,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.spacingL),

            // To Account
            _buildAccountSection(
              title: 'accounts.toAccount'.tr(),
              selectedAccount: _toAccount,
              accounts: activeAccounts,
              excludeAccountId: _fromAccount?.id,
              onAccountSelected: (account) {
                setState(() {
                  _toAccount = account;
                });
              },
            ),

            const SizedBox(height: AppDimensions.spacingL),

            // Amount Section
            _buildAmountSection(),

            const SizedBox(height: AppDimensions.spacingL),

            // Notes Section
            _buildNotesSection(),

            const SizedBox(height: AppDimensions.spacingXl),

            // Transfer Button
            _buildTransferButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferOverviewCard() {
    if (_fromAccount == null || _toAccount == null)
      return const SizedBox.shrink();

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transfer Summary',
              style: ShadTheme.of(context).textTheme.h4,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: ShadTheme.of(context).textTheme.muted,
                      ),
                      Text(
                        _fromAccount!.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        CurrencyFormatter.format(
                          _fromAccount!.balance,
                          currency: _fromAccount!.currency,
                        ),
                        style: ShadTheme.of(context).textTheme.small,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: AppColors.primary),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'To',
                        style: ShadTheme.of(context).textTheme.muted,
                      ),
                      Text(
                        _toAccount!.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        CurrencyFormatter.format(
                          _toAccount!.balance,
                          currency: _toAccount!.currency,
                        ),
                        style: ShadTheme.of(context).textTheme.small,
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection({
    required String title,
    required Account? selectedAccount,
    required List<Account> accounts,
    String? excludeAccountId,
    required void Function(Account?) onAccountSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ShadTheme.of(context).textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        AccountSelector(
          selectedAccountId: selectedAccount?.id,
          onAccountSelected: onAccountSelected,
          excludeAccountIds:
              excludeAccountId != null ? [excludeAccountId] : null,
          showBalance: true,
          enabled: !_isLoading,
        ),
        if (selectedAccount != null) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    'Available: ${CurrencyFormatter.format(selectedAccount.availableBalance, currency: selectedAccount.currency)}',
                    style: ShadTheme.of(context).textTheme.small.copyWith(
                          color: AppColors.secondary,
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

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'accounts.transferAmount'.tr(),
          style: ShadTheme.of(context).textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ShadInputFormField(
          controller: _amountController,
          placeholder: Text('forms.enterAmount'.tr()),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: !_isLoading && _fromAccount != null && _toAccount != null,
          validator: (value) {
            final error = ValidationHelper.getAmountErrorMessage(value ?? '');
            if (error != null) return error;

            if (_fromAccount != null && value != null) {
              final amount = double.tryParse(value);
              if (amount != null && amount > _fromAccount!.availableBalance) {
                return 'Insufficient funds in selected account';
              }
            }
            return null;
          },
          trailing: Text(
            _fromAccount?.currency ?? 'USD',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (_fromAccount != null && _amountController.text.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingS),
          _buildBalanceAfterTransfer(),
        ],
      ],
    );
  }

  Widget _buildBalanceAfterTransfer() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _fromAccount == null || _toAccount == null) {
      return const SizedBox.shrink();
    }

    final fromBalanceAfter = _fromAccount!.balance - amount;
    final toBalanceAfter = _toAccount!.balance + amount;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_fromAccount!.name} after:',
                style: ShadTheme.of(context).textTheme.small,
              ),
              Text(
                CurrencyFormatter.format(fromBalanceAfter,
                    currency: _fromAccount!.currency),
                style: ShadTheme.of(context).textTheme.small.copyWith(
                      fontWeight: FontWeight.w600,
                      color: fromBalanceAfter < 0 ? AppColors.error : null,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_toAccount!.name} after:',
                style: ShadTheme.of(context).textTheme.small,
              ),
              Text(
                CurrencyFormatter.format(toBalanceAfter,
                    currency: _toAccount!.currency),
                style: ShadTheme.of(context).textTheme.small.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildTransferButton() {
    final canTransfer = _fromAccount != null &&
        _toAccount != null &&
        _amountController.text.isNotEmpty &&
        !_isLoading;

    return SizedBox(
      width: double.infinity,
      child: ShadButton(
        onPressed: canTransfer ? _performTransfer : null,
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
                  Text('common.processing'.tr()),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.swap_horiz, size: 18),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text('accounts.transferFunds'.tr()),
                ],
              ),
      ),
    );
  }

  Future<void> _performTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Perform the transfer
      final success =
          await ref.read(accountListProvider.notifier).transferBetweenAccounts(
                _fromAccount!.id,
                _toAccount!.id,
                amount,
              );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transfer of ${CurrencyFormatter.format(amount, currency: _fromAccount!.currency)} completed successfully',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transfer failed. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: ${e.toString()}'),
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
