import 'package:expense/presentation/widgets/expense_attachments.dart';
import 'package:expense/presentation/widgets/form_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
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
  final Expense? expense;
  const AddExpenseModal({super.key, this.expense});

  @override
  State<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _saving = false;
  String? _savedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height,
        ),
        child: Container(
          padding: EdgeInsets.only(bottom: 24, left: 24, right: 24, top: 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
                'project_id':
                    widget.expense?.projectId ??
                    context.read<ProjectsCubit>().state.currentProject?.id ??
                    '',
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  if (widget.expense == null) ...[
                    BlocBuilder<ProjectsCubit, ProjectsState>(
                      builder: (context, state) => FormBuilderDropdown<String>(
                        style: Theme.of(context).textTheme.bodyMedium,
                        name: 'project_id',
                        decoration: InputDecoration(labelText: 'projects'.tr()),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text('personal_workspace'.tr()),
                          ),
                          ...{
                            for (final p in [
                              ...state.projects,
                              ...state.sharedProjects,
                            ])
                              p.id: p,
                          }.values.map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildLabel('date'.tr()),
                  const SizedBox(height: 8),
                  FormBuilderDateTimePicker(
                    name: 'date',
                    inputType: InputType.date,
                    format: DateFormat(
                      'dd MMM yyyy',
                      context.locale.toString(),
                    ),
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
                  OutlinedButton.icon(
                    onPressed: _saving ? null : () => _submit(attach: true),
                    icon: const Icon(Icons.attach_file),
                    label: Text('save_and_attach'.tr()),
                  ),
                  const SizedBox(height: 12),
                  _buildSubmitButton(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: GoogleFonts.aBeeZee(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.grey,
    ),
  );

  Widget _buildAmountRow(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('amount'.tr(), style: theme.textTheme.bodySmall),
      FormBuilderTextField(
        name: 'amount',
        style: GoogleFonts.aBeeZee(
          fontSize: 36,
          color: theme.colorScheme.onSurface,
        ),
        decoration: const InputDecoration(
          hintText: '0',
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(),
          FormBuilderValidators.numeric(),
          FormBuilderValidators.min(.01),
        ]),
      ),
      Text(
        context.read<SettingsCubit>().state.currencySymbol,
        style: theme.textTheme.bodySmall,
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
    fillColor: theme.inputDecorationTheme.fillColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: theme.dividerColor),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: padding),
  );

  Widget _buildSubmitButton(ThemeData theme) => ElevatedButton(
    onPressed: _saving ? null : () => _submit(),
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      backgroundColor: const Color(0xFF35652A),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    child: Text(
      'save'.tr(),
      style: GoogleFonts.aBeeZee(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );

  Future<void> _submit({bool attach = false}) async {
    if (_saving) return;
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final v = _formKey.currentState!.value;
      final amount = double.tryParse(v['amount'].toString()) ?? 0.0;
      if (!amount.isFinite || amount <= 0) return;
      final note = (v['note'] as String?)?.trim();
      final cubit = context.read<ExpensesCubit>();
      setState(() => _saving = true);
      try {
        if (widget.expense == null && _savedId == null) {
          _savedId = await cubit.addExpense(
            amount: amount,
            date: v['date'],
            note: note?.isEmpty ?? true ? null : note,
            categoryId: v['category_id'],
            projectId: v['project_id'] == '' ? null : v['project_id'],
            type: v['type'],
          );
        } else {
          await cubit.updateExpense(
            id: widget.expense?.id ?? _savedId!,
            amount: amount,
            date: v['date'],
            note: note?.isEmpty ?? true ? null : note,
            categoryId: v['category_id'],
            type: v['type'],
          );
        }
        if (!mounted) return;
        if (attach) {
          await openFormPage(
            context,
            ExpenseAttachments(
              expenseId: widget.expense?.id ?? _savedId!,
              canEdit: true,
            ),
            title: 'receipts'.tr(),
          );
        }
        if (mounted) context.pop();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('expense_save_error'.tr())));
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }
}
