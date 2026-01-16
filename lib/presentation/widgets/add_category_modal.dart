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
  final _formKey = GlobalKey<FormBuilderState>();
  
  final List<Map<String, dynamic>> _iconConfigs = [
    {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Food', 'icon': Icons.restaurant_rounded},
    {'name': 'Transport', 'icon': Icons.directions_car_rounded},
    {'name': 'Health', 'icon': Icons.medical_services_rounded},
    {'name': 'Education', 'icon': Icons.school_rounded},
    {'name': 'Entertainment', 'icon': Icons.movie_rounded},
    {'name': 'Other', 'icon': Icons.category_rounded},
  ];

  final List<Color> _colors = [
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
          key: _formKey,
          initialValue: {
            'icon': 'Shopping',
            'color': Colors.blue.toARGB32(),
          },
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
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              FormBuilderTextField(
                name: 'name',
                decoration: InputDecoration(
                  labelText: 'category_name'.tr(),
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.03),
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
              Text(
                'icon'.tr(), 
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              FormBuilderField<String>(
                name: 'icon',
                builder: (FormFieldState<String> field) {
                  return SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _iconConfigs.length,
                      itemBuilder: (context, index) {
                        final config = _iconConfigs[index];
                        final isSelected = field.value == config['name'];
                        return GestureDetector(
                          onTap: () => field.didChange(config['name']),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 64,
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.onSurface.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  config['icon'] as IconData,
                                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  config['name'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'color'.tr(), 
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              FormBuilderField<int>(
                name: 'color',
                builder: (FormFieldState<int> field) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _colors.map((color) => GestureDetector(
                      onTap: () => field.didChange(color.toARGB32()),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: field.value == color.toARGB32() ? Border.all(color: theme.colorScheme.onSurface, width: 3) : null,
                          boxShadow: [
                            if (field.value == color.toARGB32())
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: field.value == color.toARGB32() 
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                      ),
                    )).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text('save_category'.tr(), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      final name = values['name'] as String;
      final icon = values['icon'] as String;
      final colorValue = values['color'] as int;

      context.read<CategoriesBloc>().add(AddCategory(
        name: name.trim(),
        icon: icon,
        color: colorValue.toRadixString(16).toUpperCase(),
      ));

      Navigator.pop(context);
    }
  }
}
