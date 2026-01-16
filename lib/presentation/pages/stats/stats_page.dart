import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expense/data/local/database.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String _selectedRangeLabel = 'this_month';

  @override
  void initState() {
    super.initState();
    // Default load is this month (handled by bloc on start, but we can be explicit)
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

    setState(() {
      _selectedRangeLabel = label;
    });

    if (label != 'custom') {
      context.read<ExpensesBloc>().add(LoadExpenses(dateRange: range));
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: context.read<ExpensesBloc>().state.dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedRangeLabel = 'custom';
      });
      if (mounted) {
        context.read<ExpensesBloc>().add(LoadExpenses(dateRange: picked));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'statistics'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocBuilder<ExpensesBloc, ExpensesState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: _buildRangeSelector(),
              ),
              Expanded(
                child: state.isLoading && state.expenses.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.expenses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bar_chart_rounded, size: 64, color: theme.disabledColor),
                                const SizedBox(height: 16),
                                Text('no_transactions'.tr(), style: GoogleFonts.outfit(color: Colors.grey)),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSummaryCards(context, state),
                                const SizedBox(height: 32),
                                _buildSectionHeader('category_breakdown'.tr()),
                                const SizedBox(height: 16),
                                _buildCategoryPieChart(context, state),
                                const SizedBox(height: 32),
                                _buildSectionHeader('monthly_overview'.tr()),
                                const SizedBox(height: 16),
                                _buildMonthlyBarChart(context, state),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRangeSelector() {
    final ranges = [
      {'label': 'this_month', 'title': 'this_month'.tr()},
      {'label': 'last_month', 'title': 'last_month'.tr()},
      {'label': 'this_year', 'title': 'this_year'.tr()},
      {'label': 'all_time', 'title': 'all_time'.tr()},
      {'label': 'custom', 'title': 'custom'.tr()},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ranges.map((range) {
          final isSelected = _selectedRangeLabel == range['label'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(range['title']!),
              selected: isSelected,
              onSelected: (selected) {
                if (range['label'] == 'custom') {
                  _pickCustomRange();
                } else {
                  _setRange(range['label']!);
                }
              },
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              labelStyle: GoogleFonts.outfit(
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              showCheckmark: false,
              backgroundColor: Colors.transparent,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, ExpensesState state) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'income'.tr(),
                AppTheme.formatMoney(state.filteredIncome, settings.currencySymbol),
                Colors.green,
                Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'expense'.tr(),
                AppTheme.formatMoney(state.filteredExpense, settings.currencySymbol),
                Colors.red,
                Icons.arrow_downward_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart(BuildContext context, ExpensesState state) {
    final theme = Theme.of(context);
    final categoriesState = context.read<CategoriesBloc>().state;
    final settings = context.read<SettingsBloc>().state;
    
    // Group expenses by category
    final categoryTotals = <String, double>{};
    for (var expense in state.expenses.where((e) => e.type == 'expense')) {
      final catId = expense.categoryId ?? 'other';
      categoryTotals[catId] = (categoryTotals[catId] ?? 0) + expense.amount;
    }

    if (categoryTotals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('no_data'.tr(), style: const TextStyle(color: Colors.grey)),
        ),
      );
    }
       
    final totalExpense = categoryTotals.values.fold(0.0, (sum, val) => sum + val);

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
                sections: categoryTotals.entries.map((entry) {
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
                    title: '${(entry.value / totalExpense * 100).toStringAsFixed(0)}%',
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
              children: categoryTotals.entries.map((entry) {
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
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                cat.name,
                                style: GoogleFonts.outfit(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              AppTheme.formatMoney(entry.value, settings.currencySymbol),
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart(BuildContext context, ExpensesState state) {
    final theme = Theme.of(context);
    
    // Group by month (last 6 months)
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - i, 1)).reversed.toList();
    
    final monthlyData = months.map((month) {
      double income = 0;
      double expense = 0;
      for (var e in state.expenses) {
        if (e.date.month == month.month && e.date.year == month.year) {
          if (e.type == 'income') {
            income += e.amount;
          } else {
            expense += e.amount;
          }
        }
      }
      return {'income': income, 'expense': expense, 'month': DateFormat('MMM').format(month)};
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
          maxY: monthlyData.map((d) => (d['income'] as double) > (d['expense'] as double) ? (d['income'] as double) : (d['expense'] as double)).fold(0.0, (m, v) => v > m ? v : m) * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final currency = context.read<SettingsBloc>().state.currencySymbol;
                return BarTooltipItem(
                  AppTheme.formatMoney(rod.toY, currency),
                  GoogleFonts.outfit(
                    color: rod.color ?? (rodIndex == 0 ? Colors.green : Colors.red),
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
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                    return Text(monthlyData[value.toInt()]['month'] as String, style: const TextStyle(fontSize: 10));
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: monthlyData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value['income'] as double,
                  color: Colors.green,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: entry.value['expense'] as double,
                  color: Colors.red,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
