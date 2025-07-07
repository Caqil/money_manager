import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/dimensions.dart';

class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? labelText;
  final String? sublabelText;
  final Widget? label;
  final Widget? sublabel;
  final bool enabled;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final EdgeInsetsGeometry? padding;

  const CustomSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.labelText,
    this.sublabelText,
    this.label,
    this.sublabel,
    this.enabled = true,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Simple switch without label
    if (labelText == null &&
        sublabelText == null &&
        label == null &&
        sublabel == null) {
      return ShadSwitch(
        value: value,
        onChanged: enabled ? onChanged : null,
      );
    }

    // Switch with label and sublabel
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingS,
            horizontal: AppDimensions.paddingM,
          ),
      child: ShadSwitch(
        value: value,
        onChanged: enabled ? onChanged : null,
        label: label ?? (labelText != null ? Text(labelText!) : null),
        sublabel:
            sublabel ?? (sublabelText != null ? Text(sublabelText!) : null),
      ),
    );
  }
}

// Switch group for multiple options
class CustomSwitchGroup extends StatefulWidget {
  final List<SwitchGroupItem> items;
  final Map<String, bool> values;
  final ValueChanged<Map<String, bool>>? onChanged;
  final String? title;
  final String? subtitle;
  final bool enabled;
  final EdgeInsetsGeometry? padding;
  final double spacing;

  const CustomSwitchGroup({
    super.key,
    required this.items,
    required this.values,
    this.onChanged,
    this.title,
    this.subtitle,
    this.enabled = true,
    this.padding,
    this.spacing = AppDimensions.spacingS,
  });

  @override
  State<CustomSwitchGroup> createState() => _CustomSwitchGroupState();
}

class _CustomSwitchGroupState extends State<CustomSwitchGroup> {
  late Map<String, bool> _values;

  @override
  void initState() {
    super.initState();
    _values = Map<String, bool>.from(widget.values);
  }

  @override
  void didUpdateWidget(CustomSwitchGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.values != oldWidget.values) {
      _values = Map<String, bool>.from(widget.values);
    }
  }

  void _onItemChanged(String key, bool value) {
    if (!widget.enabled) return;

    setState(() {
      _values[key] = value;
    });

    widget.onChanged?.call(_values);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: theme.textTheme.h4,
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
          child: Column(
            children: widget.items
                .map((item) => Padding(
                      padding: EdgeInsets.only(bottom: widget.spacing),
                      child: CustomSwitch(
                        value: _values[item.key] ?? false,
                        onChanged: (value) => _onItemChanged(item.key, value),
                        labelText: item.title,
                        sublabelText: item.subtitle,
                        enabled: widget.enabled && item.enabled,
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// Switch group item data class
class SwitchGroupItem {
  final String key;
  final String title;
  final String? subtitle;
  final bool enabled;

  const SwitchGroupItem({
    required this.key,
    required this.title,
    this.subtitle,
    this.enabled = true,
  });
}

// Switch form field
class SwitchFormField extends StatelessWidget {
  final String id;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;
  final String? Function(bool)? validator;
  final String? labelText;
  final String? sublabelText;
  final Widget? inputLabel;
  final Widget? inputSublabel;
  final bool enabled;

  const SwitchFormField({
    super.key,
    required this.id,
    this.initialValue = false,
    this.onChanged,
    this.validator,
    this.labelText,
    this.sublabelText,
    this.inputLabel,
    this.inputSublabel,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShadSwitchFormField(
      id: id,
      initialValue: initialValue,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      inputLabel: inputLabel ?? (labelText != null ? Text(labelText!) : null),
      inputSublabel:
          inputSublabel ?? (sublabelText != null ? Text(sublabelText!) : null),
    );
  }
}

// Compact switch for lists
class CompactSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;
  final bool enabled;
  final Widget? leading;

  const CompactSwitch({
    super.key,
    required this.value,
    this.onChanged,
    required this.title,
    this.enabled = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return InkWell(
      onTap: enabled ? () => onChanged?.call(!value) : null,
      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingS,
          horizontal: AppDimensions.paddingM,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppDimensions.spacingM),
            ],
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.p.copyWith(
                  color: enabled
                      ? theme.colorScheme.foreground
                      : theme.colorScheme.mutedForeground,
                ),
              ),
            ),
            ShadSwitch(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

// Settings switch with card style
class SettingsSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;
  final String? description;
  final Widget? icon;
  final bool enabled;

  const SettingsSwitch({
    super.key,
    required this.value,
    this.onChanged,
    required this.title,
    this.description,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
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
                        ? theme.colorScheme.foreground
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
          ShadSwitch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

// List tile switch
class SwitchListTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool enabled;
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;

  const SwitchListTile({
    super.key,
    required this.value,
    this.onChanged,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.dense = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return InkWell(
      onTap: enabled ? () => onChanged?.call(!value) : null,
      child: Container(
        padding: contentPadding ??
            EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: dense ? AppDimensions.paddingS : AppDimensions.paddingM,
            ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
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
                      color: enabled
                          ? theme.colorScheme.foreground
                          : theme.colorScheme.mutedForeground,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      subtitle!,
                      style: theme.textTheme.muted,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppDimensions.spacingM),
              trailing!,
            ],
            const SizedBox(width: AppDimensions.spacingM),
            ShadSwitch(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}
