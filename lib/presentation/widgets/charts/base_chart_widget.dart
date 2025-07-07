import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/dimensions.dart';
import '../../../data/services/settings_service.dart';
import '../common/empty_state_widget.dart';
import '../common/loading_widget.dart';

/// Base chart widget that provides common functionality for all chart types
abstract class BaseChartWidget extends ConsumerStatefulWidget {
  final String? title;
  final double? height;
  final EdgeInsets? padding;
  final bool showTitle;
  final bool showAnimation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool showBorder;
  final Color? borderColor;
  final double? borderWidth;
  final Widget? emptyStateWidget;
  final String? emptyStateMessage;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final String? errorMessage;
  final bool showLegend;
  final LegendPosition legendPosition;

  const BaseChartWidget({
    super.key,
    this.title,
    this.height,
    this.padding,
    this.showTitle = true,
    this.showAnimation = true,
    this.backgroundColor,
    this.borderRadius,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth,
    this.emptyStateWidget,
    this.emptyStateMessage,
    this.onRefresh,
    this.isLoading = false,
    this.errorMessage,
    this.showLegend = false,
    this.legendPosition = LegendPosition.bottom,
  });

  /// Build the actual chart widget
  Widget buildChart(BuildContext context, WidgetRef ref);

  /// Build the legend widget if needed
  Widget? buildLegend(BuildContext context, WidgetRef ref) => null;

  /// Get chart data - override this to provide data validation
  bool get hasData => true;

  @override
  ConsumerState<BaseChartWidget> createState() => _BaseChartWidgetState();
}

class _BaseChartWidgetState extends ConsumerState<BaseChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.showAnimation) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(BaseChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showAnimation && oldWidget.isLoading && !widget.isLoading) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsServiceProvider);
    final animationsEnabled = settings.areChartAnimationsEnabled();

    return Card(
      elevation: AppDimensions.elevationS,
      color: widget.backgroundColor ?? theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: widget.borderRadius ?? 
            BorderRadius.circular(AppDimensions.radiusM),
        side: widget.showBorder
            ? BorderSide(
                color: widget.borderColor ?? theme.dividerColor,
                width: widget.borderWidth ?? 1.0,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTitle && widget.title != null) ...[
              _buildTitle(theme),
              const SizedBox(height: AppDimensions.spacingM),
            ],
            Expanded(
              child: _buildContent(context, animationsEnabled),
            ),
            if (widget.showLegend && 
                widget.legendPosition == LegendPosition.bottom) ...[
              const SizedBox(height: AppDimensions.spacingM),
              _buildLegendSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.title!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh, size: AppDimensions.iconS),
            onPressed: widget.onRefresh,
            tooltip: 'common.refresh'.tr(),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool animationsEnabled) {
    if (widget.isLoading) {
      return const ChartLoadingPlaceholder();
    }

    if (widget.errorMessage != null) {
      return _buildErrorState();
    }

    if (!widget.hasData) {
      return widget.emptyStateWidget ?? _buildEmptyState();
    }

    final chart = widget.buildChart(context, ref);
    
    if (animationsEnabled && widget.showAnimation) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * _animation.value),
              child: chart,
            ),
          );
        },
      );
    }

    return chart;
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: AppDimensions.iconL,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            widget.errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (widget.onRefresh != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            TextButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text('common.retry'.tr()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnalyticsEmptyState(
      customMessage: widget.emptyStateMessage ?? 'analytics.noData'.tr(),
      onAddData: widget.onRefresh,
    );
  }

  Widget _buildLegendSection() {
    final legend = widget.buildLegend(context, ref);
    if (legend == null) return const SizedBox.shrink();
    return legend;
  }
}

/// Base state class for chart widgets
abstract class BaseChartState<T extends BaseChartWidget> 
    extends ConsumerState<T> {
  
  /// Common color palette for charts
  static const List<Color> defaultColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Yellow
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF97316), // Orange
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF84CC16), // Lime
    Color(0xFF6366F1), // Indigo
  ];

  /// Get color for index with fallback
  Color getColorForIndex(int index) {
    return defaultColors[index % defaultColors.length];
  }

  /// Format currency values
  String formatCurrency(double value, [String? currencyCode]) {
    final settings = ref.read(settingsServiceProvider);
    final currency = currencyCode ?? settings.getBaseCurrency();
    
    return NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: value % 1 == 0 ? 0 : 2,
    ).format(value);
  }

  /// Format percentage values
  String formatPercentage(double value) {
    return NumberFormat.percentPattern().format(value);
  }

  /// Format compact numbers (1K, 1M, etc.)
  String formatCompactNumber(double value) {
    return NumberFormat.compact().format(value);
  }

  /// Get currency symbol
  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toLowerCase()) {
      case 'usd':
        return '\$';
      case 'eur':
        return '€';
      case 'gbp':
        return '£';
      case 'jpy':
        return '¥';
      case 'cad':
        return 'C\$';
      case 'aud':
        return 'A\$';
      case 'chf':
        return 'CHF ';
      case 'cny':
        return '¥';
      case 'inr':
        return '₹';
      default:
        return currencyCode.toUpperCase() + ' ';
    }
  }

  /// Common grid styling
  FlGridData get defaultGridData => FlGridData(
        show: true,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        horizontalInterval: null,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            strokeWidth: 0.5,
            dashArray: [3, 3],
          );
        },
      );

  /// Common border styling
  FlBorderData get defaultBorderData => FlBorderData(
        show: false,
      );

  /// Common touch styling for tooltips
  TextStyle get tooltipTextStyle => TextStyle(
        color: Theme.of(context).colorScheme.onInverseSurface,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      );
}

/// Enum for legend position
enum LegendPosition {
  top,
  bottom,
  left,
  right,
  none,
}

/// Chart data state management
class ChartDataState<T> {
  final T? data;
  final bool isLoading;
  final String? error;

  const ChartDataState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  bool get hasData => data != null && error == null;
  bool get hasError => error != null;

  ChartDataState<T> copyWith({
    T? data,
    bool? isLoading,
    String? error,
  }) {
    return ChartDataState<T>(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Extension for getting settings service
extension SettingsServiceRef on WidgetRef {
  SettingsService get settingsService => read(settingsServiceProvider);
}

/// Provider for settings service
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});