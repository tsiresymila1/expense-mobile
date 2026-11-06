import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryBreakdownChart extends StatelessWidget {
  final ExpensesState state;
  const CategoryBreakdownChart({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesCubit>().state.categories;
    final settings = context.watch<SettingsCubit>().state;
    final totals = <String?, double>{};
    for (final e in state.expenses.where((e) => e.type == 'expense')) {
      totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amount;
    }
    final total = totals.values.fold(0.0, (a, b) => a + b);
    if (total <= 0) {
      return Text('no_data'.tr(), style: Theme.of(context).textTheme.bodySmall);
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: entries.map((e) {
        final name =
            categories.where((c) => c.id == e.key).firstOrNull?.name ??
            'uncategorized'.tr();
        return Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text(name)),
                  const SizedBox(width: 12),
                  Text(
                    '${AppTheme.formatMoney(e.value, settings.currencySymbol, locale: context.locale.toString())} · ${(e.value / total * 100).round()} %',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: e.value / total,
                minHeight: 6,
                backgroundColor: Theme.of(context).dividerColor,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
