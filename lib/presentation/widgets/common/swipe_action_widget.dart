import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';

class SwipeActionWidget extends StatefulWidget {
  final Widget child;
  final List<SwipeAction>? leftActions;
  final List<SwipeAction>? rightActions;
  final double threshold;
  final bool enabled;
  final VoidCallback? onSwipeStart;
  final VoidCallback? onSwipeEnd;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool allowFullSwipe;
  final VoidCallback? onFullSwipeLeft;
  final VoidCallback? onFullSwipeRight;
  final double fullSwipeThreshold;

  const SwipeActionWidget({
    super.key,
    required this.child,
    this.leftActions,
    this.rightActions,
    this.threshold = 0.3,
    this.enabled = true,
    this.onSwipeStart,
    this.onSwipeEnd,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
    this.allowFullSwipe = false,
    this.onFullSwipeLeft,
    this.onFullSwipeRight,
    this.fullSwipeThreshold = 0.7,
  });

  @override
  State<SwipeActionWidget> createState() => _SwipeActionWidgetState();
}

class _SwipeActionWidgetState extends State<SwipeActionWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _dragExtent = 0.0;
  bool _dragUnderway = false;
  Size? _childSize;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isRTL => Directionality.of(context) == TextDirection.RTL;

  void _handleDragStart(DragStartDetails details) {
    if (!widget.enabled) return;

    _dragUnderway = true;
    widget.onSwipeStart?.call();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !_dragUnderway) return;

    final delta = details.primaryDelta ?? 0.0;
    final oldDragExtent = _dragExtent;

    if (_isRTL) {
      _dragExtent += -delta;
    } else {
      _dragExtent += delta;
    }

    // Determine which actions to show based on drag direction
    final leftActions = _isRTL ? widget.rightActions : widget.leftActions;
    final rightActions = _isRTL ? widget.leftActions : widget.rightActions;

    // Limit drag extent based on available actions
    if (_dragExtent > 0 && leftActions == null) {
      _dragExtent = 0;
    } else if (_dragExtent < 0 && rightActions == null) {
      _dragExtent = 0;
    }

    if (oldDragExtent.sign != _dragExtent.sign) {
      setState(() {});
    }

    if (_dragExtent != oldDragExtent) {
      setState(() {});
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!widget.enabled || !_dragUnderway) return;

    _dragUnderway = false;
    widget.onSwipeEnd?.call();

    final width = _childSize?.width ?? 0.0;
    final velocity = details.primaryVelocity ?? 0.0;
    final threshold = width * widget.threshold;
    final fullSwipeThreshold = width * widget.fullSwipeThreshold;

    // Check for full swipe
    if (widget.allowFullSwipe) {
      if (_dragExtent > fullSwipeThreshold) {
        widget.onFullSwipeLeft?.call();
        _resetPosition();
        return;
      } else if (_dragExtent < -fullSwipeThreshold) {
        widget.onFullSwipeRight?.call();
        _resetPosition();
        return;
      }
    }

    // Check for action trigger
    if (_dragExtent.abs() > threshold || velocity.abs() > 1000) {
      if (_dragExtent > 0) {
        _showLeftActions();
      } else {
        _showRightActions();
      }
    } else {
      _resetPosition();
    }
  }

  void _showLeftActions() {
    final leftActions = _isRTL ? widget.rightActions : widget.leftActions;
    if (leftActions == null || leftActions.isEmpty) {
      _resetPosition();
      return;
    }

    final actionWidth = _calculateActionWidth(leftActions);
    _animateTo(actionWidth);
  }

  void _showRightActions() {
    final rightActions = _isRTL ? widget.leftActions : widget.rightActions;
    if (rightActions == null || rightActions.isEmpty) {
      _resetPosition();
      return;
    }

    final actionWidth = _calculateActionWidth(rightActions);
    _animateTo(-actionWidth);
  }

  double _calculateActionWidth(List<SwipeAction> actions) {
    return actions.length * 80.0; // Default action width
  }

  void _animateTo(double target) {
    final startValue = _dragExtent;
    _animationController.reset();

    _animation = Tween<double>(
      begin: startValue,
      end: target,
    ).animate(_animationController);

    _animationController.forward().then((_) {
      _dragExtent = target;
    });
  }

  void _resetPosition() {
    _animateTo(0.0);
  }

  void _onActionTap(SwipeAction action) {
    action.onTap?.call();
    _resetPosition();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _childSize = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Stack(
            children: [
              // Background actions
              _buildBackgroundActions(),

              // Main content
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final offset = _dragUnderway ? _dragExtent : _animation.value;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: widget.child,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundActions() {
    final leftActions = _isRTL ? widget.rightActions : widget.leftActions;
    final rightActions = _isRTL ? widget.leftActions : widget.rightActions;

    return Row(
      children: [
        // Left actions
        if (leftActions != null && leftActions.isNotEmpty)
          ...leftActions.map((action) => _buildActionButton(action)),

        const Spacer(),

        // Right actions
        if (rightActions != null && rightActions.isNotEmpty)
          ...rightActions.map((action) => _buildActionButton(action)),
      ],
    );
  }

  Widget _buildActionButton(SwipeAction action) {
    return Container(
      width: action.width ?? 80.0,
      height: _childSize?.height ?? double.infinity,
      color: action.backgroundColor,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onActionTap(action),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (action.icon != null)
                Icon(
                  action.icon,
                  color: action.iconColor ?? Colors.white,
                  size: action.iconSize ?? AppDimensions.iconM,
                ),
              if (action.label != null) ...[
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  action.label!,
                  style: TextStyle(
                    color: action.textColor ?? Colors.white,
                    fontSize: action.fontSize ?? 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class for swipe actions
class SwipeAction {
  final String? label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final double? width;
  final double? iconSize;
  final double? fontSize;
  final VoidCallback? onTap;

  const SwipeAction({
    this.label,
    this.icon,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.width,
    this.iconSize,
    this.fontSize,
    this.onTap,
  });
}

/// Predefined swipe actions for common use cases

/// Delete action (red background)
class DeleteSwipeAction extends SwipeAction {
  const DeleteSwipeAction({
    String? label,
    VoidCallback? onTap,
    double? width,
  }) : super(
          label: label,
          icon: Icons.delete_rounded,
          backgroundColor: AppColors.error,
          iconColor: Colors.white,
          textColor: Colors.white,
          width: width,
          onTap: onTap,
        );
}

/// Edit action (blue background)
class EditSwipeAction extends SwipeAction {
  const EditSwipeAction({
    String? label,
    VoidCallback? onTap,
    double? width,
  }) : super(
          label: label,
          icon: Icons.edit_rounded,
          backgroundColor: AppColors.primary,
          iconColor: Colors.white,
          textColor: Colors.white,
          width: width,
          onTap: onTap,
        );
}

/// Archive action (gray background)
class ArchiveSwipeAction extends SwipeAction {
  const ArchiveSwipeAction({
    super.label,
    super.onTap,
    super.width,
  }) : super(
          icon: Icons.archive_rounded,
          backgroundColor: const Color(0xFF757575),
          iconColor: Colors.white,
          textColor: Colors.white,
        );
}

/// Share action (green background)
class ShareSwipeAction extends SwipeAction {
  const ShareSwipeAction({
    String? label,
    VoidCallback? onTap,
    double? width,
  }) : super(
          label: label,
          icon: Icons.share_rounded,
          backgroundColor: AppColors.success,
          iconColor: Colors.white,
          textColor: Colors.white,
          width: width,
          onTap: onTap,
        );
}

/// Mark as favorite action (yellow background)
class FavoriteSwipeAction extends SwipeAction {
  const FavoriteSwipeAction({
    String? label,
    VoidCallback? onTap,
    double? width,
    bool isFavorite = false,
  }) : super(
          label: label,
          icon: isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
          backgroundColor: AppColors.warning,
          iconColor: Colors.white,
          textColor: Colors.white,
          width: width,
          onTap: onTap,
        );
}

/// Mark as paid action (green background)
class MarkPaidSwipeAction extends SwipeAction {
  const MarkPaidSwipeAction({
    String? label,
    VoidCallback? onTap,
    double? width,
  }) : super(
          label: label,
          icon: Icons.check_circle_rounded,
          backgroundColor: AppColors.success,
          iconColor: Colors.white,
          textColor: Colors.white,
          width: width,
          onTap: onTap,
        );
}

/// Duplicate action (purple background)
class DuplicateSwipeAction extends SwipeAction {
  const DuplicateSwipeAction({
    String? label,
    VoidCallback? onTap,
    double? width,
  }) : super(
          label: label,
          icon: Icons.copy_rounded,
          backgroundColor: AppColors.accent,
          iconColor: Colors.white,
          textColor: Colors.white,
          width: width,
          onTap: onTap,
        );
}

/// Specialized swipe action widgets for money manager features

/// Transaction list item with swipe actions
class SwipeableTransactionItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onMarkFavorite;
  final bool showEdit;
  final bool showDelete;
  final bool showDuplicate;
  final bool showFavorite;
  final bool isFavorite;

  const SwipeableTransactionItem({
    super.key,
    required this.child,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onMarkFavorite,
    this.showEdit = true,
    this.showDelete = true,
    this.showDuplicate = false,
    this.showFavorite = false,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final leftActions = <SwipeAction>[];
    final rightActions = <SwipeAction>[];

    // Left actions (positive actions)
    if (showEdit && onEdit != null) {
      leftActions.add(EditSwipeAction(
        label: 'common.edit'.tr(),
        onTap: onEdit,
      ));
    }

    if (showDuplicate && onDuplicate != null) {
      leftActions.add(DuplicateSwipeAction(
        label: 'transactions.duplicate'.tr(),
        onTap: onDuplicate,
      ));
    }

    if (showFavorite && onMarkFavorite != null) {
      leftActions.add(FavoriteSwipeAction(
        label: isFavorite ? 'common.unfavorite'.tr() : 'common.favorite'.tr(),
        onTap: onMarkFavorite,
        isFavorite: isFavorite,
      ));
    }

    // Right actions (destructive actions)
    if (showDelete && onDelete != null) {
      rightActions.add(DeleteSwipeAction(
        label: 'common.delete'.tr(),
        onTap: onDelete,
      ));
    }

    return SwipeActionWidget(
      leftActions: leftActions.isNotEmpty ? leftActions : null,
      rightActions: rightActions.isNotEmpty ? rightActions : null,
      child: child,
    );
  }
}

/// Budget item with swipe actions
class SwipeableBudgetItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReset;
  final bool showEdit;
  final bool showDelete;
  final bool showReset;

  const SwipeableBudgetItem({
    super.key,
    required this.child,
    this.onEdit,
    this.onDelete,
    this.onReset,
    this.showEdit = true,
    this.showDelete = true,
    this.showReset = false,
  });

  @override
  Widget build(BuildContext context) {
    final leftActions = <SwipeAction>[];
    final rightActions = <SwipeAction>[];

    // Left actions
    if (showEdit && onEdit != null) {
      leftActions.add(EditSwipeAction(
        label: 'common.edit'.tr(),
        onTap: onEdit,
      ));
    }

    if (showReset && onReset != null) {
      leftActions.add(SwipeAction(
        label: 'budgets.reset'.tr(),
        icon: Icons.refresh_rounded,
        backgroundColor: AppColors.warning,
        iconColor: Colors.white,
        textColor: Colors.white,
        onTap: onReset,
      ));
    }

    // Right actions
    if (showDelete && onDelete != null) {
      rightActions.add(DeleteSwipeAction(
        label: 'common.delete'.tr(),
        onTap: onDelete,
      ));
    }

    return SwipeActionWidget(
      leftActions: leftActions.isNotEmpty ? leftActions : null,
      rightActions: rightActions.isNotEmpty ? rightActions : null,
      child: child,
    );
  }
}

/// Goal item with swipe actions
class SwipeableGoalItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onComplete;
  final VoidCallback? onAddProgress;
  final bool showEdit;
  final bool showDelete;
  final bool showComplete;
  final bool showAddProgress;
  final bool isCompleted;

  const SwipeableGoalItem({
    super.key,
    required this.child,
    this.onEdit,
    this.onDelete,
    this.onComplete,
    this.onAddProgress,
    this.showEdit = true,
    this.showDelete = true,
    this.showComplete = false,
    this.showAddProgress = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final leftActions = <SwipeAction>[];
    final rightActions = <SwipeAction>[];

    // Left actions
    if (showEdit && onEdit != null) {
      leftActions.add(EditSwipeAction(
        label: 'common.edit'.tr(),
        onTap: onEdit,
      ));
    }

    if (showAddProgress && onAddProgress != null && !isCompleted) {
      leftActions.add(SwipeAction(
        label: 'goals.addProgress'.tr(),
        icon: Icons.add_rounded,
        backgroundColor: AppColors.success,
        iconColor: Colors.white,
        textColor: Colors.white,
        onTap: onAddProgress,
      ));
    }

    if (showComplete && onComplete != null && !isCompleted) {
      leftActions.add(MarkPaidSwipeAction(
        label: 'goals.markComplete'.tr(),
        onTap: onComplete,
      ));
    }

    // Right actions
    if (showDelete && onDelete != null) {
      rightActions.add(DeleteSwipeAction(
        label: 'common.delete'.tr(),
        onTap: onDelete,
      ));
    }

    return SwipeActionWidget(
      leftActions: leftActions.isNotEmpty ? leftActions : null,
      rightActions: rightActions.isNotEmpty ? rightActions : null,
      child: child,
    );
  }
}
