import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/data/local/database.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryBreakdownChart extends StatelessWidget {
  final ExpensesState state;

  const CategoryBreakdownChart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesState = context.read<CategoriesBloc>().state;
    final settings = context.read<SettingsBloc>().state;

    final totals = <String, double>{};
    for (var e in state.expenses.where((e) => e.type == 'expense')) {
      totals[e.categoryId ?? 'other'] =
          (totals[e.categoryId ?? 'other'] ?? 0) + e.amount;
    }

    if (totals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'no_data'.tr(),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    final totalExpense = totals.values.fold(0.0, (sum, val) => sum + val);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: totals.entries.map((entry) {
                  final cat = categoriesState.categories.firstWhere(
                    (c) => c.id == entry.key,
                    orElse: () => LocalCategory(
                      id: 'other',
                      name: 'Other',
                      updatedAt: DateTime.now(),
                      isDefault: true,
                    ),
                  );
                  final color = AppTheme.parseColor(cat.color);
                  return PieChartSectionData(
                    color: color,
                    value: entry.value,
                    title:
                        '${(entry.value / totalExpense * 100).toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: totals.entries.map((entry) {
                final cat = categoriesState.categories.firstWhere(
                  (c) => c.id == entry.key,
                  orElse: () => LocalCategory(
                    id: 'other',
                    name: 'Other',
                    updatedAt: DateTime.now(),
                    isDefault: true,
                  ),
                );
                return _buildLegendItem(
                  cat.name,
                  entry.value,
                  AppTheme.parseColor(cat.color),
                  settings.currencySymbol,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    String name,
    double value,
    Color color,
    String currency,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: GoogleFonts.outfit(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  AppTheme.formatMoney(value, currency),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
