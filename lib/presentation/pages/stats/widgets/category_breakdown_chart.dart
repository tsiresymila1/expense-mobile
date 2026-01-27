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

class CategoryBreakdownChart extends StatefulWidget {
  final ExpensesState state;

  const CategoryBreakdownChart({super.key, required this.state});

  @override
  State<CategoryBreakdownChart> createState() => _CategoryBreakdownChartState();
}

class _CategoryBreakdownChartState extends State<CategoryBreakdownChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesState = context.read<CategoriesBloc>().state;
    final settings = context.read<SettingsBloc>().state;

    final totals = <String, double>{};
    for (var e in widget.state.expenses.where((e) => e.type == 'expense')) {
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: totals.entries.toList().asMap().entries.map((chartEntry) {
                  final index = chartEntry.key;
                  final entry = chartEntry.value;
                  final isTouched = index == touchedIndex;
                  final fontSize = isTouched ? 16.0 : 12.0;
                  final radius = isTouched ? 70.0 : 60.0;

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
                    title: isTouched 
                      ? '${AppTheme.formatMoney(entry.value, settings.currencySymbol)}'
                      : '${(entry.value / totalExpense * 100).toStringAsFixed(0)}%',
                    radius: radius,
                    titleStyle: GoogleFonts.outfit(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 12, 
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppTheme.formatMoney(value, currency),
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
