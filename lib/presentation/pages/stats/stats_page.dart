import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/pages/stats/widgets/summary_stats_cards.dart';
import 'package:expense/presentation/pages/stats/widgets/category_breakdown_chart.dart';
import 'package:expense/presentation/pages/stats/widgets/monthly_overview_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String _range = 'this_month';

  @override
  void initState() {
    super.initState();
    _setRange('this_month');
  }

  void _setRange(String label) {
    final now = DateTime.now();
    DateTimeRange? range;
    switch (label) {
      case 'this_month':
        range = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
        break;
      case 'last_month':
        range = DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0, 23, 59, 59),
        );
        break;
      case 'this_year':
        range = DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
        break;
      case 'all_time':
        range = null;
        break;
    }
    setState(() => _range = label);
    if (label != 'custom') {
      context.read<ExpensesCubit>().loadExpenses(
        dateRange: range,
        amountRange: null,
      );
    }
  }

  Future<void> _pickCustom() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: context.read<ExpensesCubit>().state.dateRange,
      builder: (c, ch) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: Theme.of(
            c,
          ).colorScheme.copyWith(primary: AppTheme.primaryColor),
        ),
        child: ch!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _range = 'custom');
      if (mounted) {
        context.read<ExpensesCubit>().loadExpenses(
          dateRange: DateTimeRange(
            start: picked.start,
            end: DateTime(
              picked.end.year,
              picked.end.month,
              picked.end.day,
              23,
              59,
              59,
              999,
            ),
          ),
          amountRange: null,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('nav_analysis'.tr())),
      backgroundColor: theme.colorScheme.surface,
      body: BlocBuilder<ExpensesCubit, ExpensesState>(
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _buildRangeSelector(),
            ),
            Expanded(
              child: state.isLoading && state.expenses.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.expenses.isEmpty
                  ? _buildEmpty(theme)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 36,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SummaryStatsCards(state: state),
                          const SizedBox(height: 32),
                          _header('category_breakdown'.tr()),
                          const SizedBox(height: 16),
                          CategoryBreakdownChart(state: state),
                          const SizedBox(height: 32),
                          _header('monthly_overview'.tr()),
                          const SizedBox(height: 16),
                          MonthlyOverviewChart(state: state),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData t) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bar_chart_rounded, size: 64, color: t.disabledColor),
        const SizedBox(height: 16),
        Text(
          'no_transactions'.tr(),
          style: GoogleFonts.aBeeZee(color: Colors.grey),
        ),
      ],
    ),
  );

  Widget _buildRangeSelector() {
    final list = [
      {'l': 'this_month', 't': 'this_month'.tr()},
      {'l': 'last_month', 't': 'last_month'.tr()},
      {'l': 'this_year', 't': 'this_year'.tr()},
      {'l': 'all_time', 't': 'all_time'.tr()},
      {'l': 'custom', 't': 'custom'.tr()},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: list
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(r['t']!),
                  selected: _range == r['l'],
                  onSelected: (_) =>
                      r['l'] == 'custom' ? _pickCustom() : _setRange(r['l']!),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _header(String t) => Text(
    t,
    style: GoogleFonts.aBeeZee(fontSize: 18, fontWeight: FontWeight.bold),
  );
}
