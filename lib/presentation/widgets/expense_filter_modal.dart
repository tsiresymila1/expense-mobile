import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class ExpenseFilterModal extends StatefulWidget {
  final String currencySymbol;
  const ExpenseFilterModal({super.key, required this.currencySymbol});

  @override
  State<ExpenseFilterModal> createState() => _ExpenseFilterModalState();
}

class _ExpenseFilterModalState extends State<ExpenseFilterModal> {
  final _formKey = GlobalKey<FormBuilderState>();

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
      child: FormBuilder(
        key: _formKey,
        initialValue: const {
          'amount_range': RangeValues(0, 10000),
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'filters'.tr(),
              style: GoogleFonts.outfit(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            FormBuilderDateRangePicker(
              name: 'date_range',
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              decoration: InputDecoration(
                labelText: 'date_range'.tr(),
                prefixIcon: const Icon(Icons.calendar_month_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              pickerBuilder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: theme.colorScheme.brightness == Brightness.light
                        ? ColorScheme.light(
                            primary: theme.colorScheme.primary,
                            onPrimary: theme.colorScheme.onPrimary,
                            surface: theme.colorScheme.surface,
                            onSurface: theme.colorScheme.onSurface,
                          )
                        : ColorScheme.dark(
                            primary: theme.colorScheme.primary,
                            onPrimary: theme.colorScheme.onPrimary,
                            surface: theme.colorScheme.surface,
                            onSurface: theme.colorScheme.onSurface,
                          ),
                  ),
                  child: child!,
                );
              },
              onChanged: (val) => debugPrint('Date changed: $val'),
            ),
            const SizedBox(height: 16),
            Text(
              'amount_range'.tr(), 
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            FormBuilderRangeSlider(
              name: 'amount_range',
              min: 0.0,
              max: 10000.0,
              divisions: 100,
              activeColor: theme.colorScheme.primary,
              inactiveColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              decoration: const InputDecoration(border: InputBorder.none),
              displayValues: DisplayValues.current,
              numberFormat: NumberFormat.compactCurrency(
                symbol: widget.currencySymbol.isNotEmpty
                    ? '${widget.currencySymbol[0].toUpperCase()}${widget.currencySymbol.substring(1).toLowerCase()} '
                    : '',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.saveAndValidate() ?? false) {
                  // Pass data back if needed, but usually we'd handle it here
                  Navigator.pop(context, _formKey.currentState?.value);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('apply_filters'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _formKey.currentState?.reset();
              },
              child: Text('reset'.tr(), style: GoogleFonts.outfit(color: theme.colorScheme.primary)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }
}
