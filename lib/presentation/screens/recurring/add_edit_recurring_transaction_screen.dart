import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/recurring_transaction.dart';
import '../../../data/models/transaction.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import 'widgets/recurring_transaction_form.dart';

// Note: You'll need to create this provider similar to your existing patterns
// For now, I'll use placeholder provider names that should be implemented
final recurringTransactionRepositoryProvider =
    Provider<dynamic>((ref) => throw UnimplementedError());

class DummyRecurringTransactionListNotifier
    extends StateNotifier<AsyncValue<List<RecurringTransaction>>> {
  DummyRecurringTransactionListNotifier() : super(const AsyncValue.loading());
}

final recurringTransactionListProvider = StateNotifierProvider<
    DummyRecurringTransactionListNotifier,
    AsyncValue<List<RecurringTransaction>>>(
  (ref) => DummyRecurringTransactionListNotifier(),
);
final recurringTransactionProvider =
    Provider.family<AsyncValue<RecurringTransaction?>, String>(
        (ref, id) => throw UnimplementedError());

class AddEditRecurringTransactionScreen extends ConsumerStatefulWidget {
  final String? recurringTransactionId;
  final TransactionType? defaultType;
  final String? defaultAccountId;
  final String? defaultCategoryId;

  const AddEditRecurringTransactionScreen({
    super.key,
    this.recurringTransactionId,
    this.defaultType,
    this.defaultAccountId,
    this.defaultCategoryId,
  });

  @override
  ConsumerState<AddEditRecurringTransactionScreen> createState() =>
      _AddEditRecurringTransactionScreenState();
}

class _AddEditRecurringTransactionScreenState
    extends ConsumerState<AddEditRecurringTransactionScreen> {
  bool _isLoading = false;
  bool _isSaving = false;
  RecurringTransaction? _recurringTransaction;
  String? _error;

  bool get isEditing => widget.recurringTransactionId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadRecurringTransaction();
    }
  }

  Future<void> _loadRecurringTransaction() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final recurringTransactionAsync = ref
          .read(recurringTransactionProvider(widget.recurringTransactionId!));
      recurringTransactionAsync.when(
        data: (recurringTransaction) {
          if (recurringTransaction != null) {
            setState(() {
              _recurringTransaction = recurringTransaction;
              _isLoading = false;
            });
          } else {
            setState(() {
              _error = 'recurring.transactionNotFound'.tr();
              _isLoading = false;
            });
          }
        },
        loading: () {
          setState(() => _isLoading = true);
        },
        error: (error, stackTrace) {
          setState(() {
            _error = error.toString();
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing
            ? 'recurring.editRecurring'.tr()
            : 'recurring.addRecurring'.tr(),
        showBackButton: true,
        actions: [
          if (isEditing && _recurringTransaction != null && !_isLoading)
            IconButton(
              onPressed: _isSaving ? null : _showDeleteConfirmation,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'recurring.deleteRecurring'.tr(),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ShadThemeData theme) {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return CustomErrorWidget(
        error: _error!,
        onActionPressed: isEditing ? _loadRecurringTransaction : null,
      );
    }

    if (isEditing && _recurringTransaction == null) {
      return CustomErrorWidget(
        error: 'recurring.transactionNotFound'.tr(),
        onActionPressed: () => context.pop(),
      );
    }

    return RecurringTransactionForm(
      recurringTransaction: _recurringTransaction,
      defaultType: widget.defaultType,
      defaultAccountId: widget.defaultAccountId,
      defaultCategoryId: widget.defaultCategoryId,
      enabled: !_isSaving,
      isLoading: _isSaving,
      onCancel: _handleCancel,
      onSubmit: _handleSubmit,
    );
  }

  Future<void> _handleSubmit(RecurringTransactionFormData formData) async {
    setState(() => _isSaving = true);

    try {
      final currency = ref.read(baseCurrencyProvider);
      final now = DateTime.now();

      RecurringTransaction recurringTransaction;
      if (isEditing && _recurringTransaction != null) {
        // Update existing recurring transaction
        recurringTransaction = _recurringTransaction!.copyWith(
          name: formData.name,
          amount: formData.amount,
          type: formData.type,
          accountId: formData.accountId,
          categoryId: formData.categoryId,
          transferToAccountId: formData.transferToAccountId,
          frequency: formData.frequency,
          intervalValue: formData.intervalValue,
          weekdays: formData.weekdays,
          dayOfMonth: formData.dayOfMonth,
          monthsOfYear: formData.monthsOfYear,
          startDate: formData.startDate,
          endDate: formData.endDate,
          notes: formData.notes,
          enableNotifications: formData.enableNotifications,
          notificationDaysBefore: formData.notificationDaysBefore,
          updatedAt: now,
        );

        // TODO: Implement update method when provider is created
        // final success = await ref.read(recurringTransactionListProvider.notifier).updateRecurringTransaction(recurringTransaction);
        final success = true; // Placeholder

        if (!success) {
          throw Exception('Failed to update recurring transaction');
        }

        if (mounted) {
          ShadSonner.of(context).show(
            ShadToast.raw(
              variant: ShadToastVariant.primary,
              description: Text('recurring.transactionUpdated'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Create new recurring transaction
        recurringTransaction = RecurringTransaction(
          id: const Uuid().v4(),
          name: formData.name,
          amount: formData.amount,
          type: formData.type,
          accountId: formData.accountId,
          categoryId: formData.categoryId ?? '',
          transferToAccountId: formData.transferToAccountId,
          frequency: formData.frequency,
          intervalValue: formData.intervalValue,
          weekdays: formData.weekdays,
          dayOfMonth: formData.dayOfMonth,
          monthsOfYear: formData.monthsOfYear,
          startDate: formData.startDate,
          endDate: formData.endDate,
          notes: formData.notes,
          currency: currency,
          enableNotifications: formData.enableNotifications,
          notificationDaysBefore: formData.notificationDaysBefore,
          createdAt: now,
          updatedAt: now,
        );

        // TODO: Implement add method when provider is created
        // final recurringTransactionId = await ref.read(recurringTransactionListProvider.notifier).addRecurringTransaction(recurringTransaction);
        final recurringTransactionId = recurringTransaction.id; // Placeholder

        if (recurringTransactionId.isEmpty) {
          throw Exception('Failed to create recurring transaction');
        }

        if (mounted) {
          ShadSonner.of(context).show(
            ShadToast.raw(
              variant: ShadToastVariant.primary,
              description: Text('recurring.transactionCreated'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text(isEditing
                ? 'recurring.updateError'.tr()
                : 'recurring.createError'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleCancel() {
    if (_isSaving) return;

    // Check if form has changes (simplified - in real app you'd track form state)
    context.pop();
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('recurring.deleteRecurring'.tr()),
        description: Text('recurring.deleteConfirmation'
            .tr(args: [_recurringTransaction!.name])),
        actions: [
          ShadButton.outline(
            child: Text('common.cancel'.tr()),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: Text('common.delete'.tr()),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteRecurringTransaction();
    }
  }

  Future<void> _deleteRecurringTransaction() async {
    if (_recurringTransaction == null) return;

    setState(() => _isSaving = true);

    try {
      // TODO: Implement delete method when provider is created
      // final success = await ref.read(recurringTransactionListProvider.notifier).deleteRecurringTransaction(_recurringTransaction!.id);
      final success = true; // Placeholder

      if (!success) {}

      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text('recurring.transactionDeleted'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text('recurring.deleteError'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// Quick recurring transaction creation screen with templates
class QuickRecurringTransactionScreen extends ConsumerStatefulWidget {
  final TransactionType? initialType;

  const QuickRecurringTransactionScreen({
    super.key,
    this.initialType,
  });

  @override
  ConsumerState<QuickRecurringTransactionScreen> createState() =>
      _QuickRecurringTransactionScreenState();
}

class _QuickRecurringTransactionScreenState
    extends ConsumerState<QuickRecurringTransactionScreen> {
  bool _isLoading = false;
  TransactionType? _selectedType;

  // Recurring transaction templates
  static const List<RecurringTransactionTemplate> _templates = [
    RecurringTransactionTemplate(
      name: 'Salary',
      type: TransactionType.income,
      frequency: RecurrenceFrequency.monthly,
      suggestedAmount: 5000,
      icon: Icons.work,
    ),
    RecurringTransactionTemplate(
      name: 'Rent Payment',
      type: TransactionType.expense,
      frequency: RecurrenceFrequency.monthly,
      suggestedAmount: 1500,
      icon: Icons.home,
    ),
    RecurringTransactionTemplate(
      name: 'Utility Bills',
      type: TransactionType.expense,
      frequency: RecurrenceFrequency.monthly,
      suggestedAmount: 200,
      icon: Icons.electrical_services,
    ),
    RecurringTransactionTemplate(
      name: 'Insurance Premium',
      type: TransactionType.expense,
      frequency: RecurrenceFrequency.monthly,
      suggestedAmount: 300,
      icon: Icons.security,
    ),
    RecurringTransactionTemplate(
      name: 'Subscription Service',
      type: TransactionType.expense,
      frequency: RecurrenceFrequency.monthly,
      suggestedAmount: 50,
      icon: Icons.subscriptions,
    ),
    RecurringTransactionTemplate(
      name: 'Investment Transfer',
      type: TransactionType.transfer,
      frequency: RecurrenceFrequency.monthly,
      suggestedAmount: 1000,
      icon: Icons.trending_up,
    ),
    RecurringTransactionTemplate(
      name: 'Weekly Allowance',
      type: TransactionType.expense,
      frequency: RecurrenceFrequency.weekly,
      suggestedAmount: 100,
      icon: Icons.money,
    ),
    RecurringTransactionTemplate(
      name: 'Car Payment',
      type: TransactionType.expense,
      frequency: RecurrenceFrequency.monthly,
      suggestedAmount: 400,
      icon: Icons.directions_car,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final currency = ref.watch(baseCurrencyProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'recurring.quickCreate'.tr(),
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'recurring.chooseTemplate'.tr(),
              style: theme.textTheme.h2,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'recurring.templateDescription'.tr(),
              style: theme.textTheme.p.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),

            // Type filter
            _buildTypeFilter(theme),
            const SizedBox(height: AppDimensions.spacingL),

            // Templates grid
            _buildTemplatesGrid(currency, theme),
            const SizedBox(height: AppDimensions.spacingL),

            // Custom recurring transaction option
            _buildCustomRecurringTransactionOption(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilter(ShadThemeData theme) {
    final types = [
      null, // All types
      ...TransactionType.values,
    ];

    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingS,
      children: types.map((type) {
        final isSelected = _selectedType == type;
        return FilterChip(
          label: Text(
              type == null ? 'common.all'.tr() : _getTypeDisplayName(type)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedType = selected ? type : null;
            });
          },
          backgroundColor:
              isSelected ? AppColors.primary.withOpacity(0.1) : null,
          selectedColor: AppColors.primary.withOpacity(0.2),
        );
      }).toList(),
    );
  }

  Widget _buildTemplatesGrid(String currency, ShadThemeData theme) {
    final filteredTemplates = _selectedType == null
        ? _templates
        : _templates
            .where((template) => template.type == _selectedType)
            .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: AppDimensions.spacingM,
        mainAxisSpacing: AppDimensions.spacingM,
      ),
      itemCount: filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = filteredTemplates[index];
        return _buildTemplateCard(template, currency, theme);
      },
    );
  }

  Widget _buildTemplateCard(RecurringTransactionTemplate template,
      String currency, ShadThemeData theme) {
    return ShadCard(
      child: InkWell(
        onTap: _isLoading ? null : () => _createFromTemplate(template),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and type
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getTypeColor(template.type).withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Icon(
                      template.icon,
                      color: _getTypeColor(template.type),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTypeColor(template.type).withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXs),
                    ),
                    child: Text(
                      _getTypeDisplayName(template.type),
                      style: theme.textTheme.small.copyWith(
                        color: _getTypeColor(template.type),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),

              // Title
              Text(
                template.name,
                style: theme.textTheme.h4,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              // Amount and frequency
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.format(template.suggestedAmount,
                        currency: currency),
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _getFrequencyDisplayName(template.frequency),
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRecurringTransactionOption(ShadThemeData theme) {
    return ShadCard(
      child: InkWell(
        onTap: _isLoading ? null : _createCustomRecurringTransaction,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'recurring.createCustomRecurring'.tr(),
                      style: theme.textTheme.h4,
                    ),
                    Text(
                      'recurring.customRecurringDescription'.tr(),
                      style: theme.textTheme.small.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createFromTemplate(
      RecurringTransactionTemplate template) async {
    // Navigate to add screen with template pre-filled
    context.push('/recurring-transactions/add', extra: {
      'template': template,
    });
  }

  void _createCustomRecurringTransaction() {
    context.push('/recurring-transactions/add');
  }

  String _getTypeDisplayName(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'transactions.income'.tr();
      case TransactionType.expense:
        return 'transactions.expense'.tr();
      case TransactionType.transfer:
        return 'transactions.transfer'.tr();
    }
  }

  String _getFrequencyDisplayName(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'recurring.frequencies.daily'.tr();
      case RecurrenceFrequency.weekly:
        return 'recurring.frequencies.weekly'.tr();
      case RecurrenceFrequency.monthly:
        return 'recurring.frequencies.monthly'.tr();
      case RecurrenceFrequency.quarterly:
        return 'recurring.frequencies.quarterly'.tr();
      case RecurrenceFrequency.yearly:
        return 'recurring.frequencies.yearly'.tr();
      case RecurrenceFrequency.custom:
        return 'recurring.frequencies.custom'.tr();
    }
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.success;
      case TransactionType.expense:
        return AppColors.error;
      case TransactionType.transfer:
        return AppColors.primary;
    }
  }
}

// Recurring transaction template class
class RecurringTransactionTemplate {
  final String name;
  final TransactionType type;
  final RecurrenceFrequency frequency;
  final double suggestedAmount;
  final IconData icon;

  const RecurringTransactionTemplate({
    required this.name,
    required this.type,
    required this.frequency,
    required this.suggestedAmount,
    required this.icon,
  });
}
