import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/dimensions.dart';

class CustomRadioGroup<T> extends StatefulWidget {
  final List<RadioGroupItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T?>? onChanged;
  final String? title;
  final String? subtitle;
  final bool enabled;
  final bool required;
  final String? Function(T?)? validator;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final bool wrap;
  final WrapAlignment wrapAlignment;
  final double runSpacing;
  final Axis direction;
  final RadioGroupStyle style;

  const CustomRadioGroup({
    super.key,
    required this.items,
    this.selectedValue,
    this.onChanged,
    this.title,
    this.subtitle,
    this.enabled = true,
    this.required = false,
    this.validator,
    this.autovalidateMode,
    this.padding,
    this.spacing = AppDimensions.spacingS,
    this.wrap = false,
    this.wrapAlignment = WrapAlignment.start,
    this.runSpacing = AppDimensions.spacingS,
    this.direction = Axis.vertical,
    this.style = RadioGroupStyle.list,
  });

  @override
  State<CustomRadioGroup<T>> createState() => _CustomRadioGroupState<T>();
}

class _CustomRadioGroupState<T> extends State<CustomRadioGroup<T>> {
  T? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedValue;
  }

  @override
  void didUpdateWidget(CustomRadioGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      _selectedValue = widget.selectedValue;
    }
  }

  void _onItemChanged(T? value) {
    if (!widget.enabled) return;

    setState(() {
      _selectedValue = value;
    });

    widget.onChanged?.call(value);
  }

  String? _getValidator() {
    if (widget.validator != null) {
      return widget.validator!(_selectedValue);
    }

    if (widget.required && _selectedValue == null) {
      return 'validation.required'.tr();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // If using form field mode
    if (widget.title != null || widget.subtitle != null || widget.required) {
      return FormField<T>(
        initialValue: _selectedValue,
        validator: (_) => _getValidator(),
        autovalidateMode:
            widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
        builder: (fieldState) {
          final errorText = fieldState.errorText;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.title != null) ...[
                Row(
                  children: [
                    Text(
                      widget.title!,
                      style: theme.textTheme.h4,
                    ),
                    if (widget.required)
                      Text(
                        ' *',
                        style: theme.textTheme.h4.copyWith(
                          color: theme.colorScheme.destructive,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingS),
              ],
              if (widget.subtitle != null) ...[
                Text(
                  widget.subtitle!,
                  style: theme.textTheme.muted,
                ),
                const SizedBox(height: AppDimensions.spacingM),
              ],
              Container(
                padding: widget.padding,
                child: _buildRadioGroup(),
              ),
              if (errorText != null) ...[
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  errorText,
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.destructive,
                  ),
                ),
              ],
            ],
          );
        },
      );
    }

    // Basic radio group without form field
    return Container(
      padding: widget.padding,
      child: _buildRadioGroup(),
    );
  }

  Widget _buildRadioGroup() {
    switch (widget.style) {
      case RadioGroupStyle.list:
        return _buildListStyle();
      case RadioGroupStyle.card:
        return _buildCardStyle();
      case RadioGroupStyle.chip:
        return _buildChipStyle();
      case RadioGroupStyle.button:
        return _buildButtonStyle();
    }
  }

  Widget _buildListStyle() {
    final radioItems = widget.items.map((item) {
      return ShadRadio<T>(
        value: item.value,
        label: Text(item.title),
        sublabel: item.subtitle != null ? Text(item.subtitle!) : null,
      );
    }).toList();

    return ShadRadioGroup<T>(
      items: radioItems,
      onChanged: widget.enabled ? _onItemChanged : null,
    );
  }

  Widget _buildCardStyle() {
    final radioWidgets = widget.items.map((item) {
      return _buildRadioCard(item);
    }).toList();

    if (widget.wrap) {
      return Wrap(
        spacing: widget.spacing,
        runSpacing: widget.runSpacing,
        alignment: widget.wrapAlignment,
        children: radioWidgets,
      );
    }

    if (widget.direction == Axis.vertical) {
      return Column(
        children: radioWidgets
            .expand((w) => [
                  w,
                  SizedBox(height: widget.spacing),
                ])
            .take(radioWidgets.length * 2 - 1)
            .toList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: radioWidgets
            .expand((child) => [
                  child,
                  SizedBox(width: widget.spacing),
                ])
            .take(radioWidgets.length * 2 - 1)
            .toList(),
      ),
    );
  }

  Widget _buildChipStyle() {
    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      alignment: widget.wrapAlignment,
      children: widget.items.map((item) {
        return _buildChoiceChip(item);
      }).toList(),
    );
  }

  Widget _buildButtonStyle() {
    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      alignment: widget.wrapAlignment,
      children: widget.items.map((item) {
        return _buildRadioButton(item);
      }).toList(),
    );
  }

  Widget _buildRadioCard(RadioGroupItem<T> item) {
    final theme = ShadTheme.of(context);
    final isSelected = _selectedValue == item.value;
    final isEnabled = widget.enabled && item.enabled;

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      backgroundColor:
          isSelected ? theme.colorScheme.accent.withOpacity(0.1) : null,
      border: Border.all(
        color:
            isSelected ? theme.colorScheme.primary : theme.colorScheme.border,
        width: isSelected ? 2 : 1,
      ),
      child: InkWell(
        onTap: isEnabled ? () => _onItemChanged(item.value) : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.leading != null) ...[
                item.leading!,
                const SizedBox(height: AppDimensions.spacingS),
              ],
              Text(
                item.title,
                style: theme.textTheme.p.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? (isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.foreground)
                      : theme.colorScheme.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              if (item.subtitle != null) ...[
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  item.subtitle!,
                  style: theme.textTheme.small.copyWith(
                    color: isEnabled
                        ? theme.colorScheme.mutedForeground
                        : theme.colorScheme.mutedForeground.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(RadioGroupItem<T> item) {
    final theme = ShadTheme.of(context);
    final isSelected = _selectedValue == item.value;
    final isEnabled = widget.enabled && item.enabled;

    return FilterChip(
      label: Text(item.title),
      avatar: item.leading,
      selected: isSelected,
      onSelected: isEnabled
          ? (selected) {
              if (selected) {
                _onItemChanged(item.value);
              }
            }
          : null,
      selectedColor: theme.colorScheme.accent.withOpacity(0.2),
      checkmarkColor: theme.colorScheme.primary,
      backgroundColor: Colors.transparent,
      disabledColor: theme.colorScheme.mutedForeground.withOpacity(0.1),
      elevation: 0,
      pressElevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        side: BorderSide(
          color:
              isSelected ? theme.colorScheme.primary : theme.colorScheme.border,
        ),
      ),
    );
  }

  Widget _buildRadioButton(RadioGroupItem<T> item) {
    final isSelected = _selectedValue == item.value;
    final isEnabled = widget.enabled && item.enabled;

    return ShadButton.raw(
      onPressed: isEnabled ? () => _onItemChanged(item.value) : null,
      variant:
          isSelected ? ShadButtonVariant.primary : ShadButtonVariant.outline,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.leading != null) ...[
            item.leading!,
            const SizedBox(width: AppDimensions.spacingS),
          ],
          Text(item.title),
        ],
      ),
    );
  }
}

// Radio group item data class
class RadioGroupItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool enabled;

  const RadioGroupItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.enabled = true,
  });
}

// Radio group style enum
enum RadioGroupStyle {
  list,
  card,
  chip,
  button,
}

// Radio group form field
class RadioGroupFormField<T> extends StatelessWidget {
  final String? label;
  final List<RadioGroupItem<T>> items;
  final T? initialValue;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;

  const RadioGroupFormField({
    super.key,
    this.label,
    required this.items,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final radioItems = items.map((item) {
      return ShadRadio<T>(
        value: item.value,
        label: Text(item.title),
        sublabel: item.subtitle != null ? Text(item.subtitle!) : null,
      );
    }).toList();

    return ShadRadioGroupFormField<T>(
      label: label != null ? Text(label!) : null,
      items: radioItems,
      initialValue: initialValue,
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }
}

// Simple labeled radio button
class LabeledRadio<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final String label;
  final bool enabled;
  final EdgeInsetsGeometry? padding;

  const LabeledRadio({
    super.key,
    required this.value,
    this.groupValue,
    this.onChanged,
    required this.label,
    this.enabled = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: ShadRadioGroup<T>(
        items: [
          ShadRadio<T>(
            value: value,
            label: Text(label),
          ),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

// Radio card for settings
class RadioCard<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final String title;
  final String? description;
  final Widget? icon;
  final bool enabled;

  const RadioCard({
    super.key,
    required this.value,
    this.groupValue,
    this.onChanged,
    required this.title,
    this.description,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isSelected = groupValue == value;

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      backgroundColor:
          isSelected ? theme.colorScheme.accent.withOpacity(0.1) : null,
      border: Border.all(
        color:
            isSelected ? theme.colorScheme.primary : theme.colorScheme.border,
        width: isSelected ? 2 : 1,
      ),
      child: InkWell(
        onTap: enabled ? () => onChanged?.call(value) : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: AppDimensions.spacingM),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.p.copyWith(
                        fontWeight: FontWeight.w500,
                        color: enabled
                            ? (isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.foreground)
                            : theme.colorScheme.mutedForeground,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: AppDimensions.spacingXs),
                      Text(
                        description!,
                        style: theme.textTheme.muted,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: AppDimensions.iconS,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
