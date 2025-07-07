import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';

class CategoryIconPicker extends StatefulWidget {
  final String selectedIcon;
  final Function(String) onIconSelected;

  const CategoryIconPicker({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  State<CategoryIconPicker> createState() => _CategoryIconPickerState();
}

class _CategoryIconPickerState extends State<CategoryIconPicker> {
  String? _searchQuery;
  String _selectedCategory = 'all';

  // Predefined categories and their icons
  static const Map<String, List<CategoryIcon>> _iconCategories = {
    'all': [],
    'food': [
      CategoryIcon('restaurant', Icons.restaurant, 'Food & Dining'),
      CategoryIcon('fastfood', Icons.fastfood, 'Fast Food'),
      CategoryIcon('local_pizza', Icons.local_pizza, 'Pizza'),
      CategoryIcon('local_cafe', Icons.local_cafe, 'Cafe'),
      CategoryIcon('local_bar', Icons.local_bar, 'Bar'),
      CategoryIcon('breakfast_dining', Icons.breakfast_dining, 'Breakfast'),
      CategoryIcon('lunch_dining', Icons.lunch_dining, 'Lunch'),
      CategoryIcon('dinner_dining', Icons.dinner_dining, 'Dinner'),
      CategoryIcon('cake', Icons.cake, 'Dessert'),
      CategoryIcon('icecream', Icons.icecream, 'Ice Cream'),
    ],
    'transport': [
      CategoryIcon('directions_car', Icons.directions_car, 'Car'),
      CategoryIcon('directions_bus', Icons.directions_bus, 'Bus'),
      CategoryIcon('directions_subway', Icons.directions_subway, 'Subway'),
      CategoryIcon('flight', Icons.flight, 'Flight'),
      CategoryIcon('train', Icons.train, 'Train'),
      CategoryIcon('directions_bike', Icons.directions_bike, 'Bike'),
      CategoryIcon('directions_walk', Icons.directions_walk, 'Walk'),
      CategoryIcon('local_taxi', Icons.local_taxi, 'Taxi'),
      CategoryIcon('local_shipping', Icons.local_shipping, 'Shipping'),
      CategoryIcon('motorcycle', Icons.motorcycle, 'Motorcycle'),
    ],
    'shopping': [
      CategoryIcon('shopping_cart', Icons.shopping_cart, 'Shopping'),
      CategoryIcon('shopping_bag', Icons.shopping_bag, 'Shopping Bag'),
      CategoryIcon('store', Icons.store, 'Store'),
      CategoryIcon('local_grocery_store', Icons.local_grocery_store, 'Grocery'),
      CategoryIcon('local_mall', Icons.local_mall, 'Mall'),
      CategoryIcon('checkroom', Icons.checkroom, 'Clothing'),
      CategoryIcon('diamond', Icons.diamond, 'Jewelry'),
      CategoryIcon('toys', Icons.toys, 'Toys'),
      CategoryIcon('book', Icons.book, 'Books'),
      CategoryIcon('computer', Icons.computer, 'Electronics'),
    ],
    'entertainment': [
      CategoryIcon('movie', Icons.movie, 'Movies'),
      CategoryIcon('music_note', Icons.music_note, 'Music'),
      CategoryIcon('videogame_asset', Icons.videogame_asset, 'Games'),
      CategoryIcon('sports_football', Icons.sports_football, 'Sports'),
      CategoryIcon('sports_basketball', Icons.sports_basketball, 'Basketball'),
      CategoryIcon('sports_soccer', Icons.sports_soccer, 'Soccer'),
      CategoryIcon('theater_comedy', Icons.theater_comedy, 'Theater'),
      CategoryIcon('camera_alt', Icons.camera_alt, 'Photography'),
      CategoryIcon('beach_access', Icons.beach_access, 'Beach'),
      CategoryIcon('park', Icons.park, 'Park'),
    ],
    'health': [
      CategoryIcon('local_hospital', Icons.local_hospital, 'Hospital'),
      CategoryIcon('medical_services', Icons.medical_services, 'Medical'),
      CategoryIcon('local_pharmacy', Icons.local_pharmacy, 'Pharmacy'),
      CategoryIcon('fitness_center', Icons.fitness_center, 'Gym'),
      CategoryIcon('spa', Icons.spa, 'Spa'),
      CategoryIcon('healing', Icons.healing, 'Healthcare'),
      CategoryIcon('psychology', Icons.psychology, 'Mental Health'),
      CategoryIcon('dental_services', Icons.settings, 'Dental'),
      CategoryIcon('elderly', Icons.elderly, 'Elderly Care'),
      CategoryIcon('child_care', Icons.child_care, 'Child Care'),
    ],
    'bills': [
      CategoryIcon('home', Icons.home, 'Housing'),
      CategoryIcon('electric_bolt', Icons.electric_bolt, 'Electricity'),
      CategoryIcon('water_drop', Icons.water_drop, 'Water'),
      CategoryIcon('wifi', Icons.wifi, 'Internet'),
      CategoryIcon('phone', Icons.phone, 'Phone'),
      CategoryIcon('tv', Icons.tv, 'Cable TV'),
      CategoryIcon('local_gas_station', Icons.local_gas_station, 'Gas'),
      CategoryIcon('fire_extinguisher', Icons.fire_extinguisher, 'Insurance'),
      CategoryIcon('description', Icons.description, 'Documents'),
      CategoryIcon('receipt', Icons.receipt, 'Bills'),
    ],
    'income': [
      CategoryIcon('work', Icons.work, 'Work'),
      CategoryIcon('business_center', Icons.business_center, 'Business'),
      CategoryIcon('trending_up', Icons.trending_up, 'Investment'),
      CategoryIcon('savings', Icons.savings, 'Savings'),
      CategoryIcon('account_balance', Icons.account_balance, 'Bank'),
      CategoryIcon('monetization_on', Icons.monetization_on, 'Money'),
      CategoryIcon('card_giftcard', Icons.card_giftcard, 'Gift'),
      CategoryIcon('school', Icons.school, 'Education'),
      CategoryIcon('real_estate_agent', Icons.real_estate_agent, 'Real Estate'),
      CategoryIcon('handshake', Icons.handshake, 'Contract'),
    ],
    'general': [
      CategoryIcon('category', Icons.category, 'Category'),
      CategoryIcon('label', Icons.label, 'Label'),
      CategoryIcon('star', Icons.star, 'Star'),
      CategoryIcon('favorite', Icons.favorite, 'Favorite'),
      CategoryIcon('thumb_up', Icons.thumb_up, 'Like'),
      CategoryIcon('place', Icons.place, 'Location'),
      CategoryIcon('event', Icons.event, 'Event'),
      CategoryIcon('schedule', Icons.schedule, 'Schedule'),
      CategoryIcon('account_circle', Icons.account_circle, 'Profile'),
      CategoryIcon('settings', Icons.settings, 'Settings'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final allIcons = _getAllIcons();
    final filteredIcons = _filterIcons(allIcons);

    return SizedBox(
      height: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          ShadInput(
            placeholder: Text('categories.searchIcons'.tr()),
            leading: const Icon(Icons.search, size: 18),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.isNotEmpty ? value.toLowerCase() : null;
              });
            },
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Category Tabs
          _buildCategoryTabs(),
          const SizedBox(height: AppDimensions.spacingM),

          // Icons Grid
          Expanded(
            child: _buildIconsGrid(filteredIcons),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      ('all', 'categories.all'.tr()),
      ('food', 'categories.food'.tr()),
      ('transport', 'categories.transport'.tr()),
      ('shopping', 'categories.shopping'.tr()),
      ('entertainment', 'categories.entertainment'.tr()),
      ('health', 'categories.health'.tr()),
      ('bills', 'categories.bills'.tr()),
      ('income', 'categories.income'.tr()),
      ('general', 'categories.general'.tr()),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedCategory == category.$1;
          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacingS),
            child: ShadButton.ghost(
              onPressed: () {
                setState(() {
                  _selectedCategory = category.$1;
                });
              },
              backgroundColor:
                  isSelected ? AppColors.primary.withOpacity(0.1) : null,
              child: Text(
                category.$2,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : null,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIconsGrid(List<CategoryIcon> icons) {
    if (icons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: AppColors.lightDisabled,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'categories.noIconsFound'.tr(),
              style: TextStyle(
                color: AppColors.lightDisabled,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: AppDimensions.spacingS,
        mainAxisSpacing: AppDimensions.spacingS,
        childAspectRatio: 1,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final icon = icons[index];
        final isSelected = icon.name == widget.selectedIcon;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onIconSelected(icon.name),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                border: isSelected
                    ? Border.all(
                        color: AppColors.primary,
                        width: 2,
                      )
                    : Border.all(
                        color: AppColors.lightBorder,
                        width: 1,
                      ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon.iconData,
                    size: 24,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.lightOnSurface,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      icon.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.lightOnSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<CategoryIcon> _getAllIcons() {
    final Set<CategoryIcon> allIcons = {};

    for (final categoryIcons in _iconCategories.values) {
      allIcons.addAll(categoryIcons);
    }

    return allIcons.toList()..sort((a, b) => a.label.compareTo(b.label));
  }

  List<CategoryIcon> _filterIcons(List<CategoryIcon> allIcons) {
    List<CategoryIcon> icons;

    // Filter by category
    if (_selectedCategory == 'all') {
      icons = allIcons;
    } else {
      icons = _iconCategories[_selectedCategory] ?? [];
    }

    // Filter by search query
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      icons = icons.where((icon) {
        return icon.name.toLowerCase().contains(_searchQuery!) ||
            icon.label.toLowerCase().contains(_searchQuery!);
      }).toList();
    }

    return icons;
  }
}

class CategoryIcon {
  final String name;
  final IconData iconData;
  final String label;

  const CategoryIcon(this.name, this.iconData, this.label);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryIcon &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
