import 'package:easy_localization/easy_localization.dart';
import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/widgets/category_picker_field.dart';
import 'package:expense/presentation/widgets/category_management_modal.dart';
import 'package:expense/presentation/widgets/expense_attachments.dart';
import 'package:expense/presentation/widgets/expense_type_selector.dart';
import 'package:expense/presentation/widgets/form_page.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _maxAmountLength = 11;
const _maxDecimals = 2;

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "12.5" -> "12,5", "12.0" -> "12".
String _amountToInput(double v) {
  var s = v.toStringAsFixed(_maxDecimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}

/// "1234,5" -> "1 234,5" (narrow no-break space).
String _groupThousands(String s) {
  if (s.isEmpty) return '0';
  final parts = s.split(',');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
  return parts.length > 1 ? '$whole,${parts[1]}' : whole;
}

/// Add / edit transaction sheet content: type, numpad amount, optional
/// category, date, note, project (create only) and a sticky Save button.
class AddExpenseModal extends StatefulWidget {
  final Expense? expense;
  const AddExpenseModal({super.key, this.expense});

  @override
  State<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _note = TextEditingController();
  late String _type;
  late String _amt; // raw input, ',' as decimal separator
  late DateTime _date;
  String? _categoryId;
  late String _projectId; // '' = personal workspace
  bool _saving = false;
  String? _savedId;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _type = e?.type ?? 'expense';
    _amt = e == null ? '' : _amountToInput(e.amount);
    _date = e?.date ?? DateTime.now();
    _categoryId = e?.categoryId;
    _note.text = e?.note ?? '';
    _projectId =
        e?.projectId ??
        context.read<ProjectsCubit>().state.currentProject?.id ??
        '';
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = context.select<SettingsCubit, String>(
      (c) => c.state.currencySymbol,
    );
    final now = DateTime.now();
    final isToday = _sameDay(_date, now);
    final isYesterday = _sameDay(_date, now.subtract(const Duration(days: 1)));
    final custom = !isToday && !isYesterday;
    return SheetBody(
      title: (widget.expense == null ? 'new_transaction' : 'edit_transaction')
          .tr(),
      footer: FilledButton.icon(
        onPressed: _saving ? null : () => _submit(),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        icon: const Icon(Icons.check_rounded, size: 20),
        label: Text('save'.tr()),
      ),
      children: [
        ExpenseTypeSelector(
          value: _type,
          onChanged: (v) => setState(() => _type = v),
        ),
        const SizedBox(height: 16),
        _AmountDisplay(
          text: _groupThousands(_amt),
          empty: _amt.isEmpty,
          symbol: symbol,
        ),
        Semantics(
          liveRegion: true,
          child: _error == null
              ? const SizedBox(height: 8)
              : Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
        _Numpad(onKey: _onKey),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'category'.tr(),
                  style: theme.textTheme.titleSmall,
                  children: [
                    TextSpan(
                      text: ' · ${'optional'.tr()}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () => showCategoryManagement(context, showBack: true),
              style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
              child: Text('manage'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // A category deleted from the manager must not stay selected.
        BlocSelector<CategoriesCubit, CategoriesState, bool>(
          selector: (s) => s.categories.any((c) => c.id == _categoryId),
          builder: (context, exists) => CategoryPickerField(
            value: exists ? _categoryId : null,
            onChanged: (v) => setState(() => _categoryId = v),
          ),
        ),
        const SizedBox(height: 20),
        Text('date'.tr(), style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PickChip(
              label: 'date_today'.tr(),
              selected: isToday,
              onTap: () => setState(() => _date = DateTime.now()),
            ),
            PickChip(
              label: 'date_yesterday'.tr(),
              selected: isYesterday,
              onTap: () => setState(
                () => _date = DateTime.now().subtract(const Duration(days: 1)),
              ),
            ),
            PickChip(
              label: custom
                  ? DateFormat.yMMMd(context.locale.toString()).format(_date)
                  : 'pick_date'.tr(),
              selected: custom,
              leading: const Icon(Icons.calendar_today_rounded, size: 16),
              onTap: _pickDate,
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _note,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'note_optional'.tr(),
            hintText: 'note_hint'.tr(),
            counterText: '',
          ),
        ),
        if (widget.expense == null) ...[
          const SizedBox(height: 16),
          BlocBuilder<ProjectsCubit, ProjectsState>(
            builder: (context, state) {
              final all = {
                for (final p in [...state.projects, ...state.sharedProjects])
                  p.id: p,
              };
              return DropdownButtonFormField<String>(
                initialValue: all.containsKey(_projectId) ? _projectId : '',
                isExpanded: true,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(labelText: 'projects'.tr()),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text('personal_workspace'.tr()),
                  ),
                  ...all.values.map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _projectId = v ?? ''),
              );
            },
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _saving ? null : () => _submit(attach: true),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
          icon: const Icon(Icons.attach_file),
          label: Text('save_and_attach'.tr(), textAlign: TextAlign.center),
        ),
      ],
    );
  }

  void _onKey(String k) {
    setState(() {
      _error = null;
      if (k == '⌫') {
        if (_amt.isNotEmpty) _amt = _amt.substring(0, _amt.length - 1);
      } else if (k == ',') {
        if (_amt.contains(',')) return;
        _amt = '${_amt.isEmpty ? '0' : _amt},';
      } else {
        if (_amt.length >= _maxAmountLength) return;
        final parts = _amt.split(',');
        if (parts.length > 1 && parts[1].length >= _maxDecimals) return;
        _amt = _amt == '0' ? k : _amt + k;
      }
    });
  }

  Future<void> _pickDate() async {
    final n = DateTime.now();
    final last = DateTime(n.year, n.month, n.day);
    var initial = DateTime(_date.year, _date.month, _date.day);
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: last,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (_sameDay(picked, _date)) return;
      _date = _sameDay(picked, n) ? n : picked;
    });
  }

  Future<void> _submit({bool attach = false}) async {
    if (_saving) return;
    final amount = double.tryParse(_amt.replaceAll(',', '.')) ?? 0.0;
    if (!amount.isFinite || amount <= 0) {
      setState(() => _error = 'amount_required'.tr());
      return;
    }
    final note = _note.text.trim();
    // A category deleted meanwhile must not be saved.
    final categoryId =
        context.read<CategoriesCubit>().state.categories.any(
          (c) => c.id == _categoryId,
        )
        ? _categoryId
        : null;
    final cubit = context.read<ExpensesCubit>();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.expense == null && _savedId == null) {
        _savedId = await cubit.addExpense(
          amount: amount,
          date: _date,
          note: note.isEmpty ? null : note,
          categoryId: categoryId,
          projectId: _projectId == '' ? null : _projectId,
          type: _type,
        );
      } else {
        await cubit.updateExpense(
          id: widget.expense?.id ?? _savedId!,
          amount: amount,
          date: _date,
          note: note.isEmpty ? null : note,
          categoryId: categoryId,
          type: _type,
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
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // Inline: a SnackBar would sit behind this sheet.
      if (mounted) setState(() => _error = 'expense_save_error'.tr());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AmountDisplay extends StatelessWidget {
  final String text;
  final bool empty;
  final String symbol;
  const _AmountDisplay({
    required this.text,
    required this.empty,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      label: '${'amount'.tr()} $text $symbol',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              text,
              style: theme.textTheme.displayMedium?.copyWith(
                fontSize: 52,
                fontWeight: FontWeight.w600,
                color: empty ? scheme.onSurfaceVariant : scheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              symbol,
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final ValueChanged<String> onKey;
  const _Numpad({required this.onKey});

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    [',', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: 'numeric_keypad'.tr(),
      child: Column(
        children: [
          for (final row in _rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (var i = 0; i < row.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _key(context, theme, row[i])),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _key(BuildContext context, ThemeData theme, String k) {
    final back = k == '⌫';
    final label = back
        ? 'key_backspace'.tr()
        : k == ','
        ? 'key_decimal'.tr()
        : k;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: () => onKey(k),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onKey(k),
          child: SizedBox(
            height: 52,
            child: Center(
              child: back
                  ? const Icon(Icons.backspace_outlined, size: 22)
                  : Text(
                      k,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single entry point for "new" / "edit" transaction (shell FAB, dashboard,
/// activity and details all call it). Opens the numpad bottom sheet.
Future<void> showAddExpense(BuildContext context, {Expense? expense}) =>
    showAppSheet<void>(
      context,
      builder: (_) => AddExpenseModal(expense: expense),
    );
