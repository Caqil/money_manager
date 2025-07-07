import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/account.dart';
import '../../providers/account_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'widgets/transfer_form.dart';

class TransferScreen extends ConsumerStatefulWidget {
  final String? fromAccountId;
  final String? toAccountId;

  const TransferScreen({
    super.key,
    this.fromAccountId,
    this.toAccountId,
  });

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  bool _isLoading = false;
  Account? _fromAccount;
  Account? _toAccount;

  @override
  void initState() {
    super.initState();
    _loadPreselectedAccounts();
  }

  Future<void> _loadPreselectedAccounts() async {
    // Load preselected accounts if IDs are provided
    if (widget.fromAccountId != null) {
      final fromAccountAsync = ref.read(accountProvider(widget.fromAccountId!));
      fromAccountAsync.whenData((account) {
        if (mounted) {
          setState(() => _fromAccount = account);
        }
      });
    }

    if (widget.toAccountId != null) {
      final toAccountAsync = ref.read(accountProvider(widget.toAccountId!));
      toAccountAsync.whenData((account) {
        if (mounted) {
          setState(() => _toAccount = account);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAccountsAsync = ref.watch(activeAccountsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'accounts.transferFunds'.tr(),
        showBackButton: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('Transfer History'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'scheduled',
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('Scheduled Transfers'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: activeAccountsAsync.when(
        loading: () => const Center(
          child: ShimmerLoading(
            child: SkeletonLoader(height: 400, width: double.infinity),
          ),
        ),
        error: (error, _) => Center(
          child: CustomErrorWidget(
            title: 'Error loading accounts',
            message: error.toString(),
            onActionPressed: () => ref.refresh(activeAccountsProvider),
          ),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(
              child: EmptyStateWidget(
                title: 'No Active Accounts',
                message:
                    'You need at least two active accounts to make a transfer.',
                actionText: 'Add Account',
              ),
            );
          }

          if (accounts.length < 2) {
            return const Center(
              child: EmptyStateWidget(
                title: 'Insufficient Accounts',
                message:
                    'You need at least two active accounts to make a transfer.',
                actionText: 'Add Another Account',
              ),
            );
          }

          return _buildTransferForm(accounts);
        },
      ),
    );
  }

  Widget _buildTransferForm(List<Account> accounts) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),

            const SizedBox(height: AppDimensions.spacingL),

            // Recent Transfers (if any)
            _buildRecentTransfers(),

            const SizedBox(height: AppDimensions.spacingL),

            // Transfer Form
            TransferForm(
              fromAccount: _fromAccount,
              toAccount: _toAccount,
              onSubmit: _handleTransfer,
              isLoading: _isLoading,
              enabled: !_isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = ShadTheme.of(context);

    return ShadCard(
      backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transfer Money',
                        style: theme.textTheme.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      Text(
                        'Move money between your accounts instantly.',
                        style: theme.textTheme.muted,
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

  Widget _buildRecentTransfers() {
    // TODO: Implement recent transfers display
    // This would show the last few transfers for quick access
    return const SizedBox.shrink();
  }

  Future<void> _handleTransfer(TransferFormData formData) async {
    setState(() => _isLoading = true);

    try {
      final accountNotifier = ref.read(accountListProvider.notifier);

      // Perform the transfer
      final success = await accountNotifier.transferBetweenAccounts(
        formData.fromAccountId,
        formData.toAccountId,
        formData.amount,
      );

      if (success && mounted) {
        _showSuccessMessage('Transfer completed successfully');

        // Navigate back or to success screen
        if (Navigator.of(context).canPop()) {
          context.pop();
        } else {
          context.go('/accounts');
        }
      } else if (mounted) {
        _showErrorMessage('Transfer failed. Please try again.');
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage('Transfer failed: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleMenuAction(String? action) {
    switch (action) {
      case 'history':
        _showTransferHistory();
        break;
      case 'scheduled':
        _showScheduledTransfers();
        break;
    }
  }

  void _showTransferHistory() {
    // TODO: Navigate to transfer history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transfer history coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showScheduledTransfers() {
    // TODO: Navigate to scheduled transfers screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scheduled transfers coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
