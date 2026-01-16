import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, state) {
        final cat = state.categories
            .where((c) => c.id == categoryId)
            .firstOrNull;
        final colorStr = cat?.color;
        final catColor = AppTheme.parseColor(colorStr).withValues(alpha: 1.0);

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(_getIconData(cat?.icon), color: catColor, size: size),
        );
      },
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'Health':
        return Icons.medical_services_rounded;
      case 'Education':
        return Icons.school_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
