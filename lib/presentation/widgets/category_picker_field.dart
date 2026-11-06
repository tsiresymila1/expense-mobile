import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryPickerField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const CategoryPickerField({
    super.key,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, state) => DropdownButtonFormField<String>(
          initialValue: state.categories.any((c) => c.id == value)
              ? value
              : null,
          isExpanded: true,
          hint: Text('uncategorized'.tr()),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('uncategorized'.tr()),
            ),
            ...state.categories.map(
              (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
            ),
          ],
          onChanged: onChanged,
        ),
      );
}
