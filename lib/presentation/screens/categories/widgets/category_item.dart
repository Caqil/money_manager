import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../data/models/category.dart';
import '../../../providers/category_provider.dart';

class CategoryItem extends ConsumerWidget {
  final Category category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  final bool showActions;
  final bool showSubcategories;
  final bool isSelectable;
  final bool isSelected;
  final bool showBadge;
  final Widget? trailing;
  final bool compact;

  const CategoryItem({
    super.key,
    required this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
    this.showActions = true,
    this.showSubcategories = false,
    this.isSelectable = false,
    this.isSelected = false,
    this.showBadge = true,
    this.trailing,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        _buildMainItem(context, ref, theme),
        if (showSubcategories && !compact) ...[
          _buildSubcategories(context, ref, theme),
        ],
      ],
    );
  }

  Widget _buildMainItem(
      BuildContext context, WidgetRef ref, ShadThemeData theme) {
    return ShadCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: EdgeInsets.all(
            compact ? AppDimensions.paddingS : AppDimensions.paddingM,
          ),
          child: Row(
            children: [
              // Selection indicator
              if (isSelectable) ...[
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color:
                      isSelected ? AppColors.primary : AppColors.lightDisabled,
                  size: compact ? 20 : 24,
                ),
                SizedBox(
                    width: compact
                        ? AppDimensions.spacingS
                        : AppDimensions.spacingM),
              ],

              // Category Icon
              _buildCategoryIcon(),
              SizedBox(
                  width: compact
                      ? AppDimensions.spacingS
                      : AppDimensions.spacingM),

              // Category Info
              Expanded(
                child: _buildCategoryInfo(theme),
              ),

              // Status and Actions
              _buildTrailingSection(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    return Container(
      width: compact ? 36 : 48,
      height: compact ? 36 : 48,
      decoration: BoxDecoration(
        color: Color(category.color),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Icon(
        _getIconData(category.iconName),
        color: Colors.white,
        size: compact ? 18 : 24,
      ),
    );
  }

  Widget _buildCategoryInfo(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Name and Type Badge
        Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: compact
                    ? theme.textTheme.p.copyWith(fontWeight: FontWeight.w600)
                    : theme.textTheme.h4,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showBadge && !compact) ...[
              const SizedBox(width: AppDimensions.spacingS),
              _buildTypeBadge(theme),
            ],
          ],
        ),

        // Description (if not compact and has description)
        if (!compact &&
            category.description != null &&
            category.description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            category.description!,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Tags (if not compact and has tags)
        if (!compact && category.tags != null && category.tags!.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingXs),
          _buildTags(theme),
        ],

        // Parent category info (if subcategory and compact)
        if (compact && category.isSubcategory) ...[
          const SizedBox(height: 2),
          Text(
            'categories.subcategory'.tr(),
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeBadge(ShadThemeData theme) {
    Color badgeColor;
    String badgeText;

    switch (category.type) {
      case CategoryType.income:
        badgeColor = AppColors.income;
        badgeText = 'categories.income'.tr();
        break;
      case CategoryType.expense:
        badgeColor = AppColors.expense;
        badgeText = 'categories.expense'.tr();
        break;
      case CategoryType.both:
        badgeColor = AppColors.transfer;
        badgeText = 'categories.both'.tr();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
      ),
      child: Text(
        badgeText,
        style: theme.textTheme.small.copyWith(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTags(ShadThemeData theme) {
    return Wrap(
      spacing: AppDimensions.spacingXs,
      children: category.tags!
          .take(3)
          .map((tag) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                ),
                child: Text(
                  tag,
                  style: theme.textTheme.small.copyWith(
                    fontSize: 9,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildTrailingSection(BuildContext context, ShadThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status indicators
        if (!category.isActive) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
            ),
            child: Text(
              'common.inactive'.tr(),
              style: theme.textTheme.small.copyWith(
                color: AppColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
        ],

        if (category.isDefault && showBadge && !compact) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
            ),
            child: Text(
              'categories.default'.tr(),
              style: theme.textTheme.small.copyWith(
                color: AppColors.info,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
        ],

        // Custom trailing widget
        if (trailing != null) ...[
          trailing!,
          const SizedBox(width: AppDimensions.spacingS),
        ],

        // Actions Menu
        if (showActions && !compact) _buildActionsMenu(context),
      ],
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return ShadPopover(
      popover: (context) => _buildActionsPopover(context),
      child: ShadButton.ghost(
        size: ShadButtonSize.sm,
        onPressed: () {},
        child: const Icon(Icons.more_vert, size: 18),
      ),
    );
  }

  Widget _buildActionsPopover(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          ListTile(
            leading: const Icon(Icons.edit, size: 18),
            title: Text('common.edit'.tr()),
            onTap: () {
              Navigator.of(context).pop();
              onEdit?.call();
            },
          ),
        if (onToggleStatus != null)
          ListTile(
            leading: Icon(
              category.isActive ? Icons.visibility_off : Icons.visibility,
              size: 18,
            ),
            title: Text(
              category.isActive
                  ? 'categories.deactivate'.tr()
                  : 'categories.activate'.tr(),
            ),
            onTap: () {
              Navigator.of(context).pop();
              onToggleStatus?.call();
            },
          ),
        if (onDelete != null && !category.isDefault)
          ListTile(
            leading: const Icon(Icons.delete, size: 18, color: AppColors.error),
            title: Text(
              'common.delete'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
          ),
      ],
    );
  }

  Widget _buildSubcategories(
      BuildContext context, WidgetRef ref, ShadThemeData theme) {
    final subcategoriesAsync = ref.watch(subcategoriesProvider(category.id));

    return subcategoriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
      data: (subcategories) {
        if (subcategories.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.paddingL,
            top: AppDimensions.spacingS,
          ),
          child: Column(
            children: subcategories
                .map((subcategory) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.spacingS),
                      child: CategoryItem(
                        category: subcategory,
                        compact: true,
                        showActions: showActions,
                        showBadge: false,
                        onTap: onTap,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onToggleStatus: onToggleStatus,
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    // This should match your existing icon mapping logic
    switch (iconName) {
      case 'category':
        return Icons.category;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'movie':
        return Icons.movie;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'business_center':
        return Icons.business_center;
      case 'trending_up':
        return Icons.trending_up;
      case 'fastfood':
        return Icons.fastfood;
      case 'local_pizza':
        return Icons.local_pizza;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'local_bar':
        return Icons.local_bar;
      case 'breakfast_dining':
        return Icons.breakfast_dining;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'dinner_dining':
        return Icons.dinner_dining;
      case 'cake':
        return Icons.cake;
      case 'icecream':
        return Icons.icecream;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'directions_subway':
        return Icons.directions_subway;
      case 'flight':
        return Icons.flight;
      case 'train':
        return Icons.train;
      case 'directions_bike':
        return Icons.directions_bike;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'motorcycle':
        return Icons.motorcycle;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'store':
        return Icons.store;
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      case 'local_mall':
        return Icons.local_mall;
      case 'checkroom':
        return Icons.checkroom;
      case 'diamond':
        return Icons.diamond;
      case 'toys':
        return Icons.toys;
      case 'book':
        return Icons.book;
      case 'computer':
        return Icons.computer;
      case 'music_note':
        return Icons.music_note;
      case 'videogame_asset':
        return Icons.videogame_asset;
      case 'sports_football':
        return Icons.sports_football;
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'theater_comedy':
        return Icons.theater_comedy;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'beach_access':
        return Icons.beach_access;
      case 'park':
        return Icons.park;
      case 'medical_services':
        return Icons.medical_services;
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'spa':
        return Icons.spa;
      case 'healing':
        return Icons.healing;
      case 'psychology':
        return Icons.psychology;
      case 'dental_services':
        return Icons.settings;
      case 'elderly':
        return Icons.elderly;
      case 'child_care':
        return Icons.child_care;
      case 'electric_bolt':
        return Icons.electric_bolt;
      case 'water_drop':
        return Icons.water_drop;
      case 'wifi':
        return Icons.wifi;
      case 'phone':
        return Icons.phone;
      case 'tv':
        return Icons.tv;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'fire_extinguisher':
        return Icons.fire_extinguisher;
      case 'description':
        return Icons.description;
      case 'receipt':
        return Icons.receipt;
      case 'savings':
        return Icons.savings;
      case 'account_balance':
        return Icons.account_balance;
      case 'monetization_on':
        return Icons.monetization_on;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'school':
        return Icons.school;
      case 'real_estate_agent':
        return Icons.real_estate_agent;
      case 'handshake':
        return Icons.handshake;
      case 'label':
        return Icons.label;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'thumb_up':
        return Icons.thumb_up;
      case 'place':
        return Icons.place;
      case 'event':
        return Icons.event;
      case 'schedule':
        return Icons.schedule;
      case 'account_circle':
        return Icons.account_circle;
      case 'settings':
        return Icons.settings;
      default:
        return Icons.category;
    }
  }
}
