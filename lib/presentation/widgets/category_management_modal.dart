import 'package:expense/presentation/widgets/form_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/widgets/add_category_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryManagementModal extends StatelessWidget {
  const CategoryManagementModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'manage_categories'.tr(),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'add_category'.tr(),
                  onPressed: () {
                    Navigator.pop(context);
                    openFormPage(
                      context,
                      const AddCategoryModal(),
                      title: 'new_category'.tr(),
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: BlocBuilder<CategoriesCubit, CategoriesState>(
                builder: (context, state) {
                  if (state.isLoading && state.categories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (state.categories.isEmpty) return _empty(theme);
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.categories.length,
                    itemBuilder: (context, index) {
                      final cat = state.categories[index];
                      final color = AppTheme.parseColor(
                        cat.color,
                      ).withValues(alpha: 1.0);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppTheme.cardRadius,
                          ),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Icon(
                              _icon(cat.icon),
                              color: color,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            cat.name,
                            style: theme.textTheme.bodyMedium,
                          ),
                          trailing: cat.isDefault
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () {
                                        openFormPage(
                                          context,
                                          AddCategoryModal(category: cat),
                                          title: 'edit_category'.tr(),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _confirm(context, cat.id, cat.name),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(ThemeData t) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(Icons.category_outlined, size: 48, color: t.disabledColor),
        const SizedBox(height: 16),
        Text('no_categories'.tr(), style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );

  IconData _icon(String? n) {
    switch (n) {
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

  void _confirm(BuildContext context, String id, String name) {
    final hasE = context.read<ExpensesCubit>().state.expenses.any(
      (e) => e.categoryId == id,
    );
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('delete_category_title'.tr(args: [name])),
        content: Text(
          hasE
              ? 'delete_category_warning'.tr()
              : 'delete_confirmation_message'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              context.read<CategoriesCubit>().deleteCategory(id);
              Navigator.pop(c);
            },
            child: Text(
              'delete_transaction'.tr(),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
