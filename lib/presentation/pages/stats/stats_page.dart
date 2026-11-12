import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/pages/stats/widgets/category_donut.dart';
import 'package:expense/presentation/pages/stats/widgets/kpi_cards.dart';
import 'package:expense/presentation/pages/stats/widgets/monthly_bars.dart';
import 'package:expense/presentation/widgets/app_shell.dart';
import 'package:expense/presentation/widgets/expense_filter_modal.dart';
import 'package:expense/presentation/widgets/period_filter.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Analysis: totals, category split and 6-month trend. Period and category
/// filters are local; data comes from [ExpensesState.allExpenses].
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  PeriodFilter _period = PeriodFilter.thisMonth;
  ExpenseFilter _filter = ExpenseFilter.empty;
  String? _selectedCategory;
  int _selectedMonth = 5; // current month (last of the six)

  Future<void> _pickPeriod(List<Expense> all) async {
    final res = await showPeriodSheet(
      context,
      initial: _period,
      countFor: (p) => all.where((e) => p.contains(e.date)).length,
    );
    if (res != null && mounted) setState(() => _period = res);
  }

  Future<void> _openFilters(
    List<Category> categories,
    String currencySymbol,
  ) async {
    final res = await showExpenseFilterSheet(
      context,
      initial: _filter,
      categories: categories,
      currencySymbol: currencySymbol,
      showPrice: false,
    );
    if (res != null && mounted) setState(() => _filter = res);
  }

  List<CategorySlice> _slices(
    List<Expense> expenses,
    List<Category> categories,
    Color neutral,
  ) {
    final byId = {for (final c in categories) c.id: c};
    // Expenses whose category no longer exists fold into "uncategorized".
    final totals = <String, double>{};
    for (final e in expenses.where((e) => e.type != 'income')) {
      final key = byId.containsKey(e.categoryId)
          ? e.categoryId!
          : kUncategorizedKey;
      totals[key] = (totals[key] ?? 0) + e.amount;
    }
    return [
      for (final t in totals.entries)
        if (t.value > 0)
          CategorySlice(
            key: t.key,
            name: byId[t.key]?.name ?? 'uncategorized'.tr(),
            color: byId[t.key] == null
                ? neutral
                : AppTheme.parseColor(byId[t.key]!.color).withValues(alpha: 1),
            value: t.value,
          ),
    ]..sort((a, b) => b.value.compareTo(a.value));
  }

  List<MonthTotals> _months(List<Expense> base) {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - 5 + i);
      double income = 0, expense = 0;
      for (final e in base) {
        if (e.date.year == month.year && e.date.month == month.month) {
          if (e.type == 'income') {
            income += e.amount;
          } else {
            expense += e.amount;
          }
        }
      }
      return MonthTotals(month: month, income: income, expense: expense);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<ExpensesCubit>().state;
    final symbol = context.watch<SettingsCubit>().state.currencySymbol;
    final categories = context.watch<CategoriesCubit>().state.categories;
    final all = state.allExpenses;

    // Period data honours period + categories; the 6-month trend ignores the
    // period (it always shows the last six months).
    final base = all.where(_filter.matches).toList();
    final inPeriod = base.where((e) => _period.contains(e.date)).toList();
    final income = inPeriod
        .where((e) => e.type == 'income')
        .fold<double>(0, (s, e) => s + e.amount);
    final expense = inPeriod
        .where((e) => e.type != 'income')
        .fold<double>(0, (s, e) => s + e.amount);
    final slices = _slices(inPeriod, categories, theme.colorScheme.outline);
    final selected = slices.any((s) => s.key == _selectedCategory)
        ? _selectedCategory
        : null;
    final nc = _filter.categories.length;
    final filterLabel = nc == 0
        ? 'filter_by_category'.tr()
        : '${'filter_by_category'.tr()}, ${nc == 1 ? 'filter_active_one'.tr() : 'filter_active_n'.tr(args: ['$nc'])}';

    Widget section(String title, {String? hint}) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
          ),
          if (hint != null) Text(hint, style: theme.textTheme.bodySmall),
        ],
      ),
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'nav_analysis'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(child: ProjectContext()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PeriodChip(
                  wide: true,
                  label: _period.label(context),
                  onTap: () => _pickPeriod(all),
                ),
              ),
              const SizedBox(width: 10),
              FilterIconButton(
                label: filterLabel,
                active: nc > 0,
                onPressed: () => _openFilters(categories, symbol),
              ),
            ],
          ),
          if (nc > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: RemovableChip(
                  label: categoryCountLabel(nc),
                  removeTooltip: 'remove_filter_x'.tr(
                    args: [categoryCountLabel(nc)],
                  ),
                  onRemoved: () =>
                      setState(() => _filter = _filter.withoutCategories()),
                ),
              ),
            ),
          if (state.isLoading && all.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 16),
          KpiCards(income: income, expense: expense, currencySymbol: symbol),
          section('category_breakdown'.tr()),
          if (slices.isEmpty)
            SurfaceCard(
              child: EmptyState(
                icon: Icons.donut_large_rounded,
                title: 'no_expense_period'.tr(),
                message: [
                  _period.label(context),
                  if (nc > 0) categoryCountLabel(nc),
                ].join(' · '),
                action: TextButton(
                  onPressed: () => _pickPeriod(all),
                  child: Text('change_period'.tr()),
                ),
              ),
            )
          else
            CategoryDonut(
              slices: slices,
              selectedKey: selected,
              currencySymbol: symbol,
              onToggle: (key) => setState(
                () => _selectedCategory = selected == key ? null : key,
              ),
            ),
          section('monthly_overview'.tr(), hint: 'last_6_months'.tr()),
          MonthlyBars(
            months: _months(base),
            selected: _selectedMonth,
            currencySymbol: symbol,
            onSelect: (i) => setState(() => _selectedMonth = i),
          ),
        ],
      ),
    );
  }
}
