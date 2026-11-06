import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:flutter/material.dart';

class SpendingChart extends StatelessWidget {
  final ExpensesState state;
  const SpendingChart({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final days = state.dailySpending
        .asMap()
        .entries
        .where((e) => e.value > 0)
        .toList();
    if (days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'no_data'.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    final shown = days.length > 7 ? days.sublist(days.length - 7) : days;
    final max = shown.fold(0.0, (v, e) => e.value > v ? e.value : v);
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: shown
            .map(
              (e) => Expanded(
                child: Semantics(
                  label: '${e.key + 1}: ${e.value}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 22,
                        height: e.value / max * 110,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${e.key + 1}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
