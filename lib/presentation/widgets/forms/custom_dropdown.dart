import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
class CustomDropdown<T> extends StatefulWidget {
  final String? labelText;
  final String? placeholder;
  final String? description;
  final T? value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final bool required;
  final bool allowDeselection;
  final bool closeOnSelect;
  final AutovalidateMode? autovalidateMode;
  final double? minWidth;
  final double? maxWidth;
  final Widget Function(BuildContext, T)? selectedOptionBuilder;

  const CustomDropdown({
    super.key,
    this.labelText,
    this.placeholder,
    this.description,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.required = false,
    this.allowDeselection = false,
    this.closeOnSelect = true,
    this.autovalidateMode,
    this.minWidth,
    this.maxWidth,
    this.selectedOptionBuilder,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  String? _getValidator(T? value) {
    if (widget.validator != null) {
      return widget.validator!(value);
    }

    if (widget.required && value == null) {
      return 'validation.required'.tr();
    }

    return null;
  }

  Widget _buildSelectedOption(BuildContext context, T value) {
    if (widget.selectedOptionBuilder != null) {
      return widget.selectedOptionBuilder!(context, value);
    }

    final item = widget.items.firstWhere((item) => item.value == value);
    return Text(item.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // Build options widgets
    final options = widget.items.map((item) {
      return ShadOption<T>(
        value: item.value,
        child: Row(
          children: [
            if (item.icon != null) ...[
              item.icon!,
              const SizedBox(width: AppDimensions.spacingM),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.text,
                    style: item.enabled
                        ? theme.textTheme.p
                        : theme.textTheme.muted,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: theme.textTheme.muted,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (item.trailing != null) ...[
              const SizedBox(width: AppDimensions.spacingS),
              item.trailing!,
            ],
          ],
        ),
      );
    }).toList();

    // If using form field mode
    if (widget.labelText != null ||
        widget.description != null ||
        widget.required) {
      return ShadSelectFormField<T>(
        id: widget.labelText?.toLowerCase().replaceAll(' ', '_'),
        initialValue: widget.value,
        enabled: widget.enabled,
        allowDeselection: widget.allowDeselection,
        closeOnSelect: widget.closeOnSelect,
        minWidth: widget.minWidth,
        maxWidth: widget.maxWidth,
        label: widget.labelText != null
            ? Row(
                children: [
                  Text(widget.labelText!),
                  if (widget.required)
                    Text(
                      ' *',
                      style: TextStyle(
                        color: theme.colorScheme.destructive,
                      ),
                    ),
                ],
              )
            : null,
        placeholder:
            widget.placeholder != null ? Text(widget.placeholder!) : null,
        description:
            widget.description != null ? Text(widget.description!) : null,
        options: options,
        selectedOptionBuilder:
            widget.selectedOptionBuilder ?? _buildSelectedOption,
        onChanged: widget.enabled ? widget.onChanged : null,
        validator: _getValidator,
      );
    }

    // Basic dropdown without form field
    return ShadSelect<T>(
      initialValue: widget.value,
      enabled: widget.enabled,
      allowDeselection: widget.allowDeselection,
      closeOnSelect: widget.closeOnSelect,
      minWidth: widget.minWidth,
      maxWidth: widget.maxWidth,
      placeholder:
          widget.placeholder != null ? Text(widget.placeholder!) : null,
      options: options,
      selectedOptionBuilder:
          widget.selectedOptionBuilder ?? _buildSelectedOption,
      onChanged: widget.enabled ? widget.onChanged : null,
    );
  }
}

// Dropdown item data class
class DropdownItem<T> {
  final T value;
  final String text;
  final String? subtitle;
  final Widget? icon;
  final Widget? trailing;
  final bool enabled;

  const DropdownItem({
    required this.value,
    required this.text,
    this.subtitle,
    this.icon,
    this.trailing,
    this.enabled = true,
  });
}

// Specialized dropdown for currencies
class CurrencyDropdown extends StatelessWidget {
  final String? labelText;
  final String? value;
  final List<String> currencies;
  final ValueChanged<String?>? onChanged;
  final bool required;
  final String? Function(String?)? validator;
  final double? minWidth;
  final double? maxWidth;

  const CurrencyDropdown({
    super.key,
    this.labelText,
    this.value,
    required this.currencies,
    this.onChanged,
    this.required = false,
    this.validator,
    this.minWidth,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      labelText: labelText ?? 'common.currency'.tr(),
      placeholder: 'forms.selectCurrency'.tr(),
      value: value,
      required: required,
      minWidth: minWidth,
      maxWidth: maxWidth,
      items: currencies.map((currency) {
        return DropdownItem<String>(
          value: currency,
          text: currency,
          subtitle: _getCurrencyName(currency),
          icon: const Icon(
            Icons.attach_money,
            size: AppDimensions.iconS,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  String _getCurrencyName(String code) {
    // Map of common currency codes to names
    const currencyNames = {
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'GBP': 'British Pound',
      'JPY': 'Japanese Yen',
      'AUD': 'Australian Dollar',
      'CAD': 'Canadian Dollar',
      'CHF': 'Swiss Franc',
      'CNY': 'Chinese Yuan',
      'INR': 'Indian Rupee',
      'KRW': 'South Korean Won',
      'SGD': 'Singapore Dollar',
      'IDR': 'Indonesian Rupiah',
    };

    return currencyNames[code] ?? code;
  }
}

// Category dropdown
class CategoryDropdown extends StatelessWidget {
  final String? labelText;
  final String? value;
  final List<CategoryItem> categories;
  final ValueChanged<String?>? onChanged;
  final bool required;
  final String? Function(String?)? validator;
  final double? minWidth;
  final double? maxWidth;

  const CategoryDropdown({
    super.key,
    this.labelText,
    this.value,
    required this.categories,
    this.onChanged,
    this.required = false,
    this.validator,
    this.minWidth,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      labelText: labelText ?? 'common.category'.tr(),
      placeholder: 'forms.selectCategory'.tr(),
      value: value,
      required: required,
      minWidth: minWidth,
      maxWidth: maxWidth,
      items: categories.map((category) {
        return DropdownItem<String>(
          value: category.id,
          text: category.name,
          icon: Icon(
            category.icon,
            size: AppDimensions.iconS,
            color: category.color,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

// Category item data class
class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

// Account dropdown
class AccountDropdown extends StatelessWidget {
  final String? labelText;
  final String? value;
  final List<AccountItem> accounts;
  final ValueChanged<String?>? onChanged;
  final bool required;
  final String? Function(String?)? validator;
  final double? minWidth;
  final double? maxWidth;

  const AccountDropdown({
    super.key,
    this.labelText,
    this.value,
    required this.accounts,
    this.onChanged,
    this.required = false,
    this.validator,
    this.minWidth,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      labelText: labelText ?? 'common.account'.tr(),
      placeholder: 'forms.selectAccount'.tr(),
      value: value,
      required: required,
      minWidth: minWidth,
      maxWidth: maxWidth,
      items: accounts.map((account) {
        return DropdownItem<String>(
          value: account.id,
          text: account.name,
          subtitle: account.balance,
          icon: Icon(
            account.icon,
            size: AppDimensions.iconS,
            color: AppColors.primary,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

// Account item data class
class AccountItem {
  final String id;
  final String name;
  final String? balance;
  final IconData icon;

  const AccountItem({
    required this.id,
    required this.name,
    this.balance,
    this.icon = Icons.account_balance_wallet,
  });
}

// Search dropdown
class SearchDropdown<T> extends StatefulWidget {
  final String? labelText;
  final String? placeholder;
  final String? searchPlaceholder;
  final T? value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final ValueChanged<String>? onSearchChanged;
  final bool enabled;
  final bool required;
  final double? minWidth;
  final double? maxWidth;
  final Widget Function(BuildContext, T)? selectedOptionBuilder;

  const SearchDropdown({
    super.key,
    this.labelText,
    this.placeholder,
    this.searchPlaceholder,
    this.value,
    required this.items,
    this.onChanged,
    this.onSearchChanged,
    this.enabled = true,
    this.required = false,
    this.minWidth,
    this.maxWidth,
    this.selectedOptionBuilder,
  });

  @override
  State<SearchDropdown<T>> createState() => _SearchDropdownState<T>();
}

class _SearchDropdownState<T> extends State<SearchDropdown<T>> {
  String _searchValue = '';

  List<DropdownItem<T>> get _filteredItems {
    if (_searchValue.isEmpty) return widget.items;

    return widget.items.where((item) {
      return item.text.toLowerCase().contains(_searchValue.toLowerCase()) ||
          (item.subtitle?.toLowerCase().contains(_searchValue.toLowerCase()) ??
              false);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchValue = value;
    });
    widget.onSearchChanged?.call(value);
  }

  Widget _buildSelectedOption(BuildContext context, T value) {
    if (widget.selectedOptionBuilder != null) {
      return widget.selectedOptionBuilder!(context, value);
    }

    final item = widget.items.firstWhere((item) => item.value == value);
    return Text(item.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // Build options widgets
    final options = <Widget>[
      ..._filteredItems.map((item) {
        return ShadOption<T>(
          value: item.value,
          child: Row(
            children: [
              if (item.icon != null) ...[
                item.icon!,
                const SizedBox(width: AppDimensions.spacingM),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.text,
                      style: item.enabled
                          ? theme.textTheme.p
                          : theme.textTheme.muted,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        style: theme.textTheme.muted,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (item.trailing != null) ...[
                const SizedBox(width: AppDimensions.spacingS),
                item.trailing!,
              ],
            ],
          ),
        );
      }),
      if (_filteredItems.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('No items found'),
        ),
    ];

    return ShadSelect<T>.withSearch(
      initialValue: widget.value,
      enabled: widget.enabled,
      minWidth: widget.minWidth,
      maxWidth: widget.maxWidth,
      placeholder:
          widget.placeholder != null ? Text(widget.placeholder!) : null,
      searchPlaceholder: widget.searchPlaceholder != null
          ? Text(widget.searchPlaceholder!)
          : null,
      options: options,
      selectedOptionBuilder:
          widget.selectedOptionBuilder ?? _buildSelectedOption,
      onChanged: widget.enabled ? widget.onChanged : null,
      onSearchChanged: _onSearchChanged,
    );
  }
}

// Multi-select dropdown
class MultiSelectDropdown<T> extends StatelessWidget {
  final String? labelText;
  final String? placeholder;
  final List<T> selectedValues;
  final List<DropdownItem<T>> items;
  final ValueChanged<List<T>>? onChanged;
  final bool enabled;
  final bool required;
  final double? minWidth;
  final double? maxWidth;
  final Widget Function(BuildContext, List<T>)? selectedOptionsBuilder;

  const MultiSelectDropdown({
    super.key,
    this.labelText,
    this.placeholder,
    required this.selectedValues,
    required this.items,
    this.onChanged,
    this.enabled = true,
    this.required = false,
    this.minWidth,
    this.maxWidth,
    this.selectedOptionsBuilder,
  });

  Widget _buildSelectedOptions(BuildContext context, List<T> values) {
    if (selectedOptionsBuilder != null) {
      return selectedOptionsBuilder!(context, values);
    }

    if (values.isEmpty) {
      return Text(placeholder ?? 'Select items');
    }

    final selectedTexts = values.map((value) {
      final item = items.firstWhere((item) => item.value == value);
      return item.text;
    }).join(', ');

    return Text(selectedTexts);
  }

  @override
  Widget build(BuildContext context) {
    // Build options widgets
    final options = items.map((item) {
      return ShadOption<T>(
        value: item.value,
        child: Row(
          children: [
            if (item.icon != null) ...[
              item.icon!,
              const SizedBox(width: AppDimensions.spacingM),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.text,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: ShadTheme.of(context).textTheme.muted,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (item.trailing != null) ...[
              const SizedBox(width: AppDimensions.spacingS),
              item.trailing!,
            ],
          ],
        ),
      );
    }).toList();

    return ShadSelect<T>.multiple(
      initialValues: selectedValues.toSet(),
      enabled: enabled,
      allowDeselection: true,
      closeOnSelect: false,
      minWidth: minWidth,
      maxWidth: maxWidth,
      placeholder: placeholder != null ? Text(placeholder!) : null,
      options: options,
      selectedOptionsBuilder: _buildSelectedOptions,
      onChanged: enabled
          ? (Set<T> values) => onChanged?.call(values.toList())
          : null,
    );
  }
}
