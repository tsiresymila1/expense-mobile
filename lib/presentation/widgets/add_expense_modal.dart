import 'package:expense/core/theme.dart';
import 'package:expense/data/local/database.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class AddExpenseModal extends StatefulWidget {
  final LocalExpense? expense;

  const AddExpenseModal({super.key, this.expense});

  @override
  State<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
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
                'type': widget.expense?.type ?? 'expense',
                'currency': settings.currencySymbol,
                'amount': widget.expense?.amount.toStringAsFixed(2) ?? '',
                'note': widget.expense?.note ?? '',
                'date': widget.expense?.date ?? DateTime.now(),
                'category_id': widget.expense?.categoryId,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.expense == null ? 'new_expense'.tr() : 'edit_transaction'.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FormBuilderField<String>(
                    name: 'type',
                    builder: (FormFieldState<String> field) {
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => field.didChange('expense'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: field.value == 'expense' ? Colors.red.withValues(alpha: 0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: field.value == 'expense' ? Border.all(color: Colors.red.withValues(alpha: 0.5)) : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'expense'.tr(),
                                      style: GoogleFonts.outfit(
                                        color: field.value == 'expense' ? Colors.red : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                        fontWeight: field.value == 'expense' ? FontWeight.w700 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => field.didChange('income'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: field.value == 'income' ? Colors.green.withValues(alpha: 0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: field.value == 'income' ? Border.all(color: Colors.green.withValues(alpha: 0.5)) : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'income'.tr(),
                                      style: GoogleFonts.outfit(
                                        color: field.value == 'income' ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                        fontWeight: field.value == 'income' ? FontWeight.w700 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 80,
                        child: FormBuilderTextField(
                          name: 'currency',
                          textAlign: TextAlign.center,
                          readOnly: true,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'amount',
                          autofocus: widget.expense == null,
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.numeric(),
                            FormBuilderValidators.min(0.01),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('category'.tr()),
                  const SizedBox(height: 12),
                  BlocBuilder<CategoriesBloc, CategoriesState>(
                    builder: (context, state) {
                      if (state.isLoading && state.categories.isEmpty) {
                        return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                      }
                      
                      if (state.categories.isEmpty) {
                        return Text('no_data'.tr(), style: const TextStyle(color: Colors.grey));
                      }

                      return FormBuilderField<String?>(
                        name: 'category_id',
                        builder: (FormFieldState<String?> field) {
                          return SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.categories.length,
                              itemBuilder: (context, index) {
                                final cat = state.categories[index];
                                final isSelected = field.value == cat.id;
                                final catColor = AppTheme.parseColor(cat.color).withValues(alpha: 1.0);
                                
                                return GestureDetector(
                                  onTap: () => field.didChange(cat.id),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 12),
                                    width: 80,
                                    decoration: BoxDecoration(
                                      color: isSelected ? catColor : catColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: isSelected ? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.2), width: 2) : null,
                                      boxShadow: [
                                        if (isSelected) 
                                          BoxShadow(
                                            color: catColor.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getIconData(cat.icon),
                                          color: isSelected ? Colors.white : catColor,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            cat.name,
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('date'.tr()),
                  const SizedBox(height: 8),
                  FormBuilderDateTimePicker(
                    name: 'date',
                    inputType: InputType.date,
                    format: DateFormat('MMM dd, yyyy'),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.calendar_today_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('note'.tr()),
                  const SizedBox(height: 8),
                  FormBuilderTextField(
                    name: 'note',
                    decoration: InputDecoration(
                      hintText: 'note'.tr(),
                      filled: true,
                      fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'save'.tr(),
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'Shopping': return Icons.shopping_bag_rounded;
      case 'Food': return Icons.restaurant_rounded;
      case 'Transport': return Icons.directions_car_rounded;
      case 'Health': return Icons.medical_services_rounded;
      case 'Education': return Icons.school_rounded;
      case 'Entertainment': return Icons.movie_rounded;
      default: return Icons.category_rounded;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      final amount = double.tryParse(values['amount'].toString()) ?? 0.0;
      final date = values['date'] as DateTime;
      final note = (values['note'] as String?)?.trim();
      final categoryId = values['category_id'] as String?;
      final type = values['type'] as String;

      if (widget.expense == null) {
        context.read<ExpensesBloc>().add(AddExpense(
              amount: amount,
              date: date,
              note: note?.isEmpty ?? true ? null : note,
              categoryId: categoryId,
              type: type,
            ));
      } else {
        context.read<ExpensesBloc>().add(UpdateExpense(
              id: widget.expense!.id,
              amount: amount,
              date: date,
              note: note?.isEmpty ?? true ? null : note,
              categoryId: categoryId,
              type: type,
            ));
      }

      context.pop();
    }
  }
}
