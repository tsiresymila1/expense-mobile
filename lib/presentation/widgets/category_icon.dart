import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One entry of the category icon picker. [key] is the string persisted in
/// the `icon` field of a category; [labelKey] is its i18n semantics label.
class CategoryIconOption {
  final String key;
  final IconData icon;
  final String labelKey;
  const CategoryIconOption(this.key, this.icon, this.labelKey);
}

/// The 16 icons offered by the category editor (order = grid order).
const kCategoryIconOptions = <CategoryIconOption>[
  CategoryIconOption('cart', Icons.shopping_cart_rounded, 'icon_cart'),
  CategoryIconOption('utensils', Icons.restaurant_rounded, 'icon_utensils'),
  CategoryIconOption('coffee', Icons.local_cafe_rounded, 'icon_coffee'),
  CategoryIconOption('car', Icons.directions_car_rounded, 'icon_car'),
  CategoryIconOption('plane', Icons.flight_rounded, 'icon_plane'),
  CategoryIconOption('home', Icons.home_rounded, 'icon_home'),
  CategoryIconOption('heart', Icons.favorite_rounded, 'icon_heart'),
  CategoryIconOption('book', Icons.menu_book_rounded, 'icon_book'),
  CategoryIconOption('gamepad', Icons.sports_esports_rounded, 'icon_gamepad'),
  CategoryIconOption('shirt', Icons.checkroom_rounded, 'icon_shirt'),
  CategoryIconOption('gift', Icons.card_giftcard_rounded, 'icon_gift'),
  CategoryIconOption('wrench', Icons.build_rounded, 'icon_wrench'),
  CategoryIconOption('bolt', Icons.bolt_rounded, 'icon_bolt'),
  CategoryIconOption('laptop', Icons.laptop_mac_rounded, 'icon_laptop'),
  CategoryIconOption('piggy', Icons.savings_rounded, 'icon_piggy'),
  CategoryIconOption('tag', Icons.sell_rounded, 'icon_tag'),
];

/// Names stored before the v6 picker -> their equivalent picker key.
const _legacyIconAliases = <String, String>{
  'Shopping': 'cart',
  'Food': 'utensils',
  'Transport': 'car',
  'Health': 'heart',
  'Education': 'book',
  'Entertainment': 'gamepad',
  'Other': 'tag',
};

/// Resolves any stored icon name (legacy or new) to a picker key, or null when
/// unknown.
String? canonicalCategoryIcon(String? name) {
  if (name == null) return null;
  final key = _legacyIconAliases[name] ?? name;
  return kCategoryIconOptions.any((o) => o.key == key) ? key : null;
}

/// Icon for a stored icon name; unknown/null falls back to a generic glyph.
IconData categoryIconData(String? name) {
  final key = canonicalCategoryIcon(name);
  if (key == null) return Icons.category_rounded;
  return kCategoryIconOptions.firstWhere((o) => o.key == key).icon;
}

/// Tinted rounded tile around a category glyph (no bloc lookup).
class CategoryGlyph extends StatelessWidget {
  final String? icon;
  final Color color;
  final double size;
  final double padding;
  final double radius;

  const CategoryGlyph({
    super.key,
    required this.icon,
    required this.color,
    this.size = 20,
    this.padding = 12,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(categoryIconData(icon), color: color, size: size),
    ),
  );
}

class CategoryIcon extends StatelessWidget {
  final String? categoryId;
  final double size;
  final double padding;

  const CategoryIcon({
    super.key,
    required this.categoryId,
    this.size = 20,
    this.padding = 12,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final cat = state.categories
            .where((c) => c.id == categoryId)
            .firstOrNull;
        final catColor = AppTheme.parseColor(cat?.color).withValues(alpha: 1.0);
        return CategoryGlyph(
          icon: cat?.icon,
          color: catColor,
          size: size,
          padding: padding,
        );
      },
    );
  }
}
