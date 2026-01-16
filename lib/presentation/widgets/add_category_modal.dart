import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

class AddCategoryModal extends StatefulWidget {
  const AddCategoryModal({super.key});
  @override
  State<AddCategoryModal> createState() => _AddCategoryModalState();
}

class _AddCategoryModalState extends State<AddCategoryModal> {
  final _key = GlobalKey<FormBuilderState>();
  final _icons = [
    {'n': 'Shopping', 'i': Icons.shopping_bag_rounded},
    {'n': 'Food', 'i': Icons.restaurant_rounded},
    {'n': 'Transport', 'i': Icons.directions_car_rounded},
    {'n': 'Health', 'i': Icons.medical_services_rounded},
    {'n': 'Education', 'i': Icons.school_rounded},
    {'n': 'Entertainment', 'i': Icons.movie_rounded},
    {'n': 'Other', 'i': Icons.category_rounded},
  ];
  final _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: FormBuilder(
            key: _key,
            initialValue: {'icon': 'Shopping', 'color': Colors.blue.toARGB32()},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'new_category'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                FormBuilderTextField(
                  name: 'name',
                  decoration: InputDecoration(
                    labelText: 'category_name'.tr(),
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.03,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(2),
                  ]),
                ),
                const SizedBox(height: 24),
                _label('icon'.tr(), theme),
                const SizedBox(height: 8),
                FormBuilderField<String>(
                  name: 'icon',
                  builder: (field) => SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _icons.length,
                      itemBuilder: (context, index) {
                        final it = _icons[index];
                        final isS = field.value == it['n'];
                        return GestureDetector(
                          onTap: () => field.didChange(it['n'] as String),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 64,
                            decoration: BoxDecoration(
                              color: isS
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    )
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.03,
                                    ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isS
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  it['i'] as IconData,
                                  color: isS
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  it['n'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: isS
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _label('color'.tr(), theme),
                const SizedBox(height: 8),
                FormBuilderField<int>(
                  name: 'color',
                  builder: (field) => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _colors
                        .map(
                          (c) => GestureDetector(
                            onTap: () => field.didChange(c.toARGB32()),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: field.value == c.toARGB32()
                                    ? Border.all(
                                        color: theme.colorScheme.onSurface,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: field.value == c.toARGB32()
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'save_category'.tr(),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t, ThemeData theme) => Text(
    t,
    style: GoogleFonts.outfit(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    ),
  );

  void _submit() {
    if (_key.currentState?.saveAndValidate() ?? false) {
      final v = _key.currentState!.value;
      context.read<CategoriesBloc>().add(
        AddCategory(
          name: (v['name'] as String).trim(),
          icon: v['icon'] as String,
          color: (v['color'] as int).toRadixString(16).toUpperCase(),
        ),
      );
      Navigator.pop(context);
    }
  }
}
