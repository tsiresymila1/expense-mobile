import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class ExpenseFilterModal extends StatefulWidget {
  final String currencySymbol;
  const ExpenseFilterModal({super.key, required this.currencySymbol});
  @override
  State<ExpenseFilterModal> createState() => _ExpenseFilterModalState();
}

class _ExpenseFilterModalState extends State<ExpenseFilterModal> {
  final _key = GlobalKey<FormBuilderState>();
  String? _error;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: FormBuilder(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('filters'.tr(), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            FormBuilderDateRangePicker(
              name: 'date_range',
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              decoration: InputDecoration(labelText: 'date_range'.tr()),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'min',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'minimum_amount'.tr(),
                      suffixText: widget.currencySymbol,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'max',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'maximum_amount'.tr(),
                      suffixText: widget.currencySymbol,
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _apply,
              child: Text('apply_filters'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, {
                'date_range': null,
                'amount_range': null,
              }),
              child: Text('reset'.tr()),
            ),
          ],
        ),
      ),
    ),
  );
  void _apply() {
    if (!(_key.currentState?.saveAndValidate() ?? false)) return;
    final v = _key.currentState!.value;
    final minText = (v['min'] as String? ?? '').trim(),
        maxText = (v['max'] as String? ?? '').trim();
    final min = minText.isEmpty
        ? 0.0
        : double.tryParse(minText.replaceAll(',', '.'));
    final max = maxText.isEmpty
        ? double.maxFinite
        : double.tryParse(maxText.replaceAll(',', '.'));
    if (min == null ||
        max == null ||
        !min.isFinite ||
        !max.isFinite ||
        min < 0 ||
        max < min) {
      setState(() => _error = 'invalid_amount_range'.tr());
      return;
    }
    final date = v['date_range'] as DateTimeRange?;
    Navigator.pop(context, {
      'date_range': date == null
          ? null
          : DateTimeRange(
              start: date.start,
              end: DateTime(
                date.end.year,
                date.end.month,
                date.end.day,
                23,
                59,
                59,
                999,
              ),
            ),
      'amount_range': minText.isEmpty && maxText.isEmpty
          ? null
          : RangeValues(min, max),
    });
  }
}
