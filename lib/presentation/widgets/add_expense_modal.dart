import 'package:easy_localization/easy_localization.dart';
import 'package:expense/data/local/database.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/widgets/category_picker_field.dart';
import 'package:expense/presentation/widgets/expense_type_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
      builder: (context, settings) => ConstrainedBox(
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
                  _buildHandle(),
                  const SizedBox(height: 24),
                  Text(
                    widget.expense == null
                        ? 'new_expense'.tr()
                        : 'edit_transaction'.tr(),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FormBuilderField<String>(
                    name: 'type',
                    builder: (field) => ExpenseTypeSelector(
                      value: field.value!,
                      onChanged: (val) => field.didChange(val),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildAmountRow(theme),
                  const SizedBox(height: 20),
                  _buildLabel('category'.tr()),
                  const SizedBox(height: 12),
                  FormBuilderField<String?>(
                    name: 'category_id',
                    builder: (field) => CategoryPickerField(
                      value: field.value,
                      onChanged: (val) => field.didChange(val),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('date'.tr()),
                  const SizedBox(height: 8),
                  FormBuilderDateTimePicker(
                    name: 'date',
                    inputType: InputType.date,
                    format: DateFormat('MMM dd, yyyy', context.locale.toString()),
                    decoration: _inputDecoration(
                      theme,
                      Icons.calendar_today_rounded,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('note'.tr()),
                  const SizedBox(height: 8),
                  FormBuilderTextField(
                    name: 'note',
                    decoration: _inputDecoration(
                      theme,
                      null,
                      hint: 'note'.tr(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  _buildSubmitButton(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
  Widget _buildLabel(String text) => Text(
    text,
    style: GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.grey,
    ),
  );

  Widget _buildAmountRow(ThemeData theme) => Row(
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
          decoration: _inputDecoration(theme, null, padding: 20),
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
          decoration: _inputDecoration(theme, null, hint: '0.00'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
            FormBuilderValidators.numeric(),
            FormBuilderValidators.min(0.01),
          ]),
        ),
      ),
    ],
  );

  InputDecoration _inputDecoration(
    ThemeData theme,
    IconData? icon, {
    String? hint,
    double padding = 16,
  }) => InputDecoration(
    prefixIcon: icon != null ? Icon(icon) : null,
    hintText: hint,
    filled: true,
    fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: padding),
  );

  Widget _buildSubmitButton(ThemeData theme) => ElevatedButton(
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
  );

  void _submit() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final v = _formKey.currentState!.value;
      final amount = double.tryParse(v['amount'].toString()) ?? 0.0;
      final note = (v['note'] as String?)?.trim();
      final addE = AddExpense(
        amount: amount,
        date: v['date'],
        note: note?.isEmpty ?? true ? null : note,
        categoryId: v['category_id'],
        type: v['type'],
      );
      final updE = UpdateExpense(
        id: widget.expense?.id ?? '',
        amount: amount,
        date: v['date'],
        note: note?.isEmpty ?? true ? null : note,
        categoryId: v['category_id'],
        type: v['type'],
      );
      context.read<ExpensesBloc>().add(widget.expense == null ? addE : updE);
      context.pop();
    }
  }
}
