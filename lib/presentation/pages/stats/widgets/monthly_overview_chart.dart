import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthlyOverviewChart extends StatelessWidget {
  final ExpensesState state;

  const MonthlyOverviewChart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - i, 1),
    ).reversed.toList();

    final data = months.map((month) {
      double income = 0, expense = 0;
      for (var e in state.expenses) {
        if (e.date.month == month.month && e.date.year == month.year) {
          if (e.type == 'income') {
            income += e.amount;
          } else {
            expense += e.amount;
          }
        }
      }
      return {
        'income': income,
        'expense': expense,
        'month': DateFormat('MMM').format(month),
      };
    }).toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              data
                  .map(
                    (d) => (d['income'] as double) > (d['expense'] as double)
                        ? (d['income'] as double)
                        : (d['expense'] as double),
                  )
                  .fold(0.0, (m, v) => v > m ? v : m) *
              1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gi, rod, ri) {
                final cur = context.read<SettingsBloc>().state.currencySymbol;
                return BarTooltipItem(
                  AppTheme.formatMoney(rod.toY, cur),
                  GoogleFonts.outfit(
                    color: rod.color ?? (ri == 0 ? Colors.green : Colors.red),
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) =>
                    v.toInt() >= 0 && v.toInt() < data.length
                    ? Text(
                        data[v.toInt()]['month'] as String,
                        style: const TextStyle(fontSize: 10),
                      )
                    : const SizedBox(),
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: data
              .asMap()
              .entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value['income'] as double,
                      color: Colors.green,
                      width: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: e.value['expense'] as double,
                      color: Colors.red,
                      width: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
