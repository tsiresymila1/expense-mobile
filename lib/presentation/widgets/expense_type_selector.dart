import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';

/// Dépense / Revenu switch. Thin wrapper over [AppSegmented] (no red/green
/// tinting in v6).
class ExpenseTypeSelector extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const ExpenseTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => AppSegmented<String>(
    items: [('expense', 'expense'.tr()), ('income', 'income'.tr())],
    value: value,
    onChanged: onChanged,
  );
}
