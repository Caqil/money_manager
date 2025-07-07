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
import 'widgets/account_form.dart';

class AddEditAccountScreen extends ConsumerStatefulWidget {
  final String? accountId;

  const AddEditAccountScreen({
    super.key,
    this.accountId,
  });

  @override
  ConsumerState<AddEditAccountScreen> createState() =>
      _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends ConsumerState<AddEditAccountScreen> {
  bool _isLoading = false;

  bool get isEditing => widget.accountId != null;

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      final accountAsync = ref.watch(accountProvider(widget.accountId!));

      return accountAsync.when(
        loading: () => Scaffold(
          appBar: CustomAppBar(
            title: 'accounts.editAccount'.tr(),
            showBackButton: true,
          ),
          body: const Center(
            child: ShimmerLoading(
              child: SkeletonLoader(height: 400, width: double.infinity),
            ),
          ),
        ),
        error: (error, _) => Scaffold(
          appBar: CustomAppBar(
            title: 'accounts.editAccount'.tr(),
            showBackButton: true,
          ),
          body: Center(
            child: CustomErrorWidget(
              title: 'Error loading account',
              message: error.toString(),
              actionText: 'common.retry'.tr(),
              onActionPressed: () =>
                  ref.refresh(accountProvider(widget.accountId!)),
            ),
          ),
        ),
        data: (account) {
          if (account == null) {
            return Scaffold(
              appBar: CustomAppBar(
                title: 'accounts.editAccount'.tr(),
                showBackButton: true,
              ),
              body: const Center(
                child: EmptyStateWidget(
                  title: 'Account not found',
                  message:
                      'The account you are trying to edit could not be found.',
                ),
              ),
            );
          }

          return _buildScreen(account);
        },
      );
    }

    return _buildScreen(null);
  }

  Widget _buildScreen(Account? account) {
    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing
            ? 'accounts.editAccount'.tr()
            : 'accounts.addAccount'.tr(),
        showBackButton: true,
        actions: [
          if (isEditing && account != null)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, account),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      const Icon(Icons.copy, size: 16),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text('Duplicate Account'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text(
                        'common.delete'.tr(),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              if (!isEditing) ...[
                _buildHeader(),
                const SizedBox(height: AppDimensions.spacingL),
              ],

              // Account Form
              AccountForm(
                initialAccount: account,
                onSubmit: _handleSubmit,
                isLoading: _isLoading,
                enabled: !_isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create New Account',
          style: theme.textTheme.h2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          'Add a new account to track your finances and manage your money.',
          style: theme.textTheme.muted,
        ),
      ],
    );
  }

  Future<void> _handleSubmit(AccountFormData formData) async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(accountListProvider.notifier);

      if (isEditing) {
        // Update existing account
        final existingAccountAsync =
            ref.read(accountProvider(widget.accountId!));
        final existingAccount = existingAccountAsync.value;

        if (existingAccount != null) {
          final updatedAccount = formData.updateAccount(existingAccount);
          final success = await notifier.updateAccount(updatedAccount);

          if (success && mounted) {
            _showSuccessMessage('Account updated successfully');
            context.go('/accounts/${widget.accountId}');
          } else if (mounted) {
            _showErrorMessage('Failed to update account');
          }
        } else if (mounted) {
          _showErrorMessage('Account not found');
        }
      } else {
        // Create new account
        final newAccount =
            formData.toAccount(id: ''); // Repository will generate ID
        final accountId = await notifier.addAccount(newAccount);

        if (accountId != null && mounted) {
          _showSuccessMessage('Account created successfully');
          context.go('/accounts/$accountId');
        } else if (mounted) {
          _showErrorMessage('Failed to create account');
        }
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage('An error occurred: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleMenuAction(String? action, Account account) {
    switch (action) {
      case 'duplicate':
        _duplicateAccount(account);
        break;
      case 'delete':
        _showDeleteConfirmation(account);
        break;
    }
  }

  void _duplicateAccount(Account account) {
    // Navigate to add screen with duplicated data
    final duplicatedAccount = account.copyWith(
      id: '', // Clear ID for new account
      name: '${account.name} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Navigate to add screen with the duplicated account data
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AddEditAccountScreen(accountId: null),
        settings: RouteSettings(
          arguments: duplicatedAccount,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
            'Are you sure you want to delete "${account.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount(account);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              'common.delete'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(Account account) async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(accountListProvider.notifier);
      final success = await notifier.deleteAccount(account.id);

      if (success && mounted) {
        _showSuccessMessage('Account deleted successfully');
        context.go('/accounts');
      } else if (mounted) {
        _showErrorMessage('Failed to delete account');
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage('An error occurred: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ShadSonner.of(context).show(
        ShadToast(
          description: Text(message),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ShadSonner.of(context).show(
        ShadToast(
          description: Text(message),
        ),
      );
    }
  }
}
