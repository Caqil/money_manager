import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/constants/dimensions.dart';

/// Represents a single legend item
class LegendItem {
  final String label;
  final Color color;
  final double? value;
  final String? formattedValue;
  final IconData? icon;
  final bool isVisible;
  final VoidCallback? onTap;

  const LegendItem({
    required this.label,
    required this.color,
    this.value,
    this.formattedValue,
    this.icon,
    this.isVisible = true,
    this.onTap,
  });

  LegendItem copyWith({
    String? label,
    Color? color,
    double? value,
    String? formattedValue,
    IconData? icon,
    bool? isVisible,
    VoidCallback? onTap,
  }) {
    return LegendItem(
      label: label ?? this.label,
      color: color ?? this.color,
      value: value ?? this.value,
      formattedValue: formattedValue ?? this.formattedValue,
      icon: icon ?? this.icon,
      isVisible: isVisible ?? this.isVisible,
      onTap: onTap ?? this.onTap,
    );
  }
}

/// Chart legend widget that displays legend items for charts
class ChartLegendWidget extends ConsumerWidget {
  final List<LegendItem> items;
  final LegendLayout layout;
  final LegendAlignment alignment;
  final double spacing;
  final double runSpacing;
  final EdgeInsets? padding;
  final bool showValues;
  final bool interactive;
  final int? maxColumns;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final TextStyle? textStyle;
  final double indicatorSize;
  final LegendIndicatorType indicatorType;
  final bool showPercentages;
  final double? totalValue;

  const ChartLegendWidget({
    super.key,
    required this.items,
    this.layout = LegendLayout.wrap,
    this.alignment = LegendAlignment.start,
    this.spacing = AppDimensions.spacingS,
    this.runSpacing = AppDimensions.spacingS,
    this.padding,
    this.showValues = true,
    this.interactive = true,
    this.maxColumns,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.textStyle,
    this.indicatorSize = 12.0,
    this.indicatorType = LegendIndicatorType.circle,
    this.showPercentages = false,
    this.totalValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final effectiveTextStyle = textStyle ?? theme.textTheme.bodySmall;

    if (items.isEmpty) return const SizedBox.shrink();

    Widget legendWidget;
    switch (layout) {
      case LegendLayout.column:
        legendWidget = _buildColumnLayout(effectiveTextStyle!);
        break;
      case LegendLayout.row:
        legendWidget = _buildRowLayout(effectiveTextStyle!);
        break;
      case LegendLayout.wrap:
        legendWidget = _buildWrapLayout(effectiveTextStyle!);
        break;
      case LegendLayout.grid:
        legendWidget = _buildGridLayout(effectiveTextStyle!);
        break;
    }

    return Container(
      padding: padding,
      child: legendWidget,
    );
  }

  Widget _buildColumnLayout(TextStyle textStyle) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: items.map((item) => _buildLegendItem(item, textStyle)).toList(),
    );
  }

  Widget _buildRowLayout(TextStyle textStyle) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: items
            .map((item) => Padding(
                  padding: EdgeInsets.only(right: spacing),
                  child: _buildLegendItem(item, textStyle),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildWrapLayout(TextStyle textStyle) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: _getWrapAlignment(),
      crossAxisAlignment: _getWrapRunAlignment(),
      children: items.map((item) => _buildLegendItem(item, textStyle)).toList(),
    );
  }

  Widget _buildGridLayout(TextStyle textStyle) {
    final columns = maxColumns ?? 2;
    final rows = (items.length / columns).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        final startIndex = rowIndex * columns;
        final endIndex = (startIndex + columns).clamp(0, items.length);
        final rowItems = items.sublist(startIndex, endIndex);

        return Padding(
          padding:
              EdgeInsets.only(bottom: rowIndex < rows - 1 ? runSpacing : 0),
          child: Row(
            mainAxisAlignment: mainAxisAlignment,
            children: rowItems.map((item) {
              return Expanded(
                child: _buildLegendItem(item, textStyle),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  Widget _buildLegendItem(LegendItem item, TextStyle textStyle) {
    final widget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIndicator(item),
        SizedBox(width: spacing * 0.75),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                style: textStyle.copyWith(
                  color: item.isVisible
                      ? textStyle.color
                      : textStyle.color?.withOpacity(0.5),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (showValues &&
                  (item.formattedValue != null || item.value != null))
                Text(
                  _getValueText(item),
                  style: textStyle.copyWith(
                    fontSize: (textStyle.fontSize ?? 14) * 0.85,
                    color: item.isVisible
                        ? textStyle.color?.withOpacity(0.7)
                        : textStyle.color?.withOpacity(0.3),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (interactive && item.onTap != null) {
      return InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingXs),
          child: widget,
        ),
      );
    }

    return widget;
  }

  Widget _buildIndicator(LegendItem item) {
    final effectiveColor =
        item.isVisible ? item.color : item.color.withOpacity(0.3);

    switch (indicatorType) {
      case LegendIndicatorType.circle:
        return Container(
          width: indicatorSize,
          height: indicatorSize,
          decoration: BoxDecoration(
            color: effectiveColor,
            shape: BoxShape.circle,
          ),
        );
      case LegendIndicatorType.square:
        return Container(
          width: indicatorSize,
          height: indicatorSize,
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case LegendIndicatorType.line:
        return Container(
          width: indicatorSize * 1.5,
          height: 3,
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      case LegendIndicatorType.icon:
        return Icon(
          item.icon ?? Icons.circle,
          size: indicatorSize,
          color: effectiveColor,
        );
    }
  }

  String _getValueText(LegendItem item) {
    if (item.formattedValue != null) {
      if (showPercentages &&
          item.value != null &&
          totalValue != null &&
          totalValue! > 0) {
        final percentage = (item.value! / totalValue!) * 100;
        return '${item.formattedValue} (${percentage.toStringAsFixed(1)}%)';
      }
      return item.formattedValue!;
    }

    if (item.value != null) {
      if (showPercentages && totalValue != null && totalValue! > 0) {
        final percentage = (item.value! / totalValue!) * 100;
        return '${NumberFormat.compact().format(item.value)} (${percentage.toStringAsFixed(1)}%)';
      }
      return NumberFormat.compact().format(item.value);
    }

    return '';
  }

  WrapAlignment _getWrapAlignment() {
    switch (alignment) {
      case LegendAlignment.start:
        return WrapAlignment.start;
      case LegendAlignment.center:
        return WrapAlignment.center;
      case LegendAlignment.end:
        return WrapAlignment.end;
      case LegendAlignment.spaceBetween:
        return WrapAlignment.spaceBetween;
      case LegendAlignment.spaceAround:
        return WrapAlignment.spaceAround;
      case LegendAlignment.spaceEvenly:
        return WrapAlignment.spaceEvenly;
    }
  }

  WrapCrossAlignment _getWrapRunAlignment() {
    switch (crossAxisAlignment) {
      case CrossAxisAlignment.start:
        return WrapCrossAlignment.start;
      case CrossAxisAlignment.center:
        return WrapCrossAlignment.center;
      case CrossAxisAlignment.end:
        return WrapCrossAlignment.end;
      default:
        return WrapCrossAlignment.start;
    }
  }
}

/// Compact legend widget for small spaces
class CompactLegendWidget extends StatelessWidget {
  final List<LegendItem> items;
  final int maxItems;
  final double indicatorSize;
  final double spacing;
  final TextStyle? textStyle;
  final bool showOthers;

  const CompactLegendWidget({
    super.key,
    required this.items,
    this.maxItems = 3,
    this.indicatorSize = 8.0,
    this.spacing = AppDimensions.spacingXs,
    this.textStyle,
    this.showOthers = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextStyle = textStyle ?? theme.textTheme.bodySmall;

    final visibleItems = items.take(maxItems).toList();
    final hasMoreItems = items.length > maxItems;

    return Wrap(
      spacing: spacing,
      children: [
        ...visibleItems
            .map((item) => _buildCompactItem(item, effectiveTextStyle!)),
        if (hasMoreItems && showOthers)
          _buildOthersItem(effectiveTextStyle!, items.length - maxItems),
      ],
    );
  }

  Widget _buildCompactItem(LegendItem item, TextStyle textStyle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: indicatorSize,
          height: indicatorSize,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: spacing * 0.5),
        Text(
          item.label,
          style: textStyle.copyWith(fontSize: 10),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildOthersItem(TextStyle textStyle, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: indicatorSize,
          height: indicatorSize,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: spacing * 0.5),
        Text(
          '+$count ${'common.others'.tr()}',
          style: textStyle.copyWith(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

/// Interactive legend that allows toggling visibility
class InteractiveLegendWidget extends StatefulWidget {
  final List<LegendItem> items;
  final Function(int index, bool isVisible)? onToggle;
  final LegendLayout layout;
  final bool allowMultipleSelection;

  const InteractiveLegendWidget({
    super.key,
    required this.items,
    this.onToggle,
    this.layout = LegendLayout.wrap,
    this.allowMultipleSelection = true,
  });

  @override
  State<InteractiveLegendWidget> createState() =>
      _InteractiveLegendWidgetState();
}

class _InteractiveLegendWidgetState extends State<InteractiveLegendWidget> {
  late List<bool> _visibilityStates;

  @override
  void initState() {
    super.initState();
    _visibilityStates = widget.items.map((item) => item.isVisible).toList();
  }

  @override
  void didUpdateWidget(InteractiveLegendWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _visibilityStates = widget.items.map((item) => item.isVisible).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final updatedItems = widget.items.asMap().entries.map((entry) {
      return entry.value.copyWith(
        isVisible: _visibilityStates[entry.key],
        onTap: () => _toggleItem(entry.key),
      );
    }).toList();

    return ChartLegendWidget(
      items: updatedItems,
      layout: widget.layout,
      interactive: true,
    );
  }

  void _toggleItem(int index) {
    setState(() {
      if (!widget.allowMultipleSelection) {
        // Single selection mode
        for (int i = 0; i < _visibilityStates.length; i++) {
          _visibilityStates[i] = i == index;
        }
      } else {
        // Multiple selection mode
        _visibilityStates[index] = !_visibilityStates[index];

        // Ensure at least one item is visible
        if (_visibilityStates.every((visible) => !visible)) {
          _visibilityStates[index] = true;
        }
      }
    });

    widget.onToggle?.call(index, _visibilityStates[index]);
  }
}

/// Enums for legend configuration
enum LegendLayout {
  column,
  row,
  wrap,
  grid,
}

enum LegendAlignment {
  start,
  center,
  end,
  spaceBetween,
  spaceAround,
  spaceEvenly,
}

enum LegendIndicatorType {
  circle,
  square,
  line,
  icon,
}
