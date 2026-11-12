import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/pages/expenses/widgets/expense_card.dart';
import 'package:expense/presentation/widgets/app_shell.dart';
import 'package:expense/presentation/widgets/expense_details.dart';
import 'package:expense/presentation/widgets/expense_filter_modal.dart';
import 'package:expense/presentation/widgets/period_filter.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Activity: every transaction of the current project, grouped by day.
/// Search / type / period / category / price filters are local to this page and
/// applied on top of [ExpensesState.allExpenses].
class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});
  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final _search = TextEditingController();
  String _query = '';
  String _type = 'all';
  PeriodFilter _period = PeriodFilter.all;
  ExpenseFilter _filter = ExpenseFilter.empty;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _hasNarrowing =>
      _query.trim().isNotEmpty ||
      _type != 'all' ||
      _period != PeriodFilter.all ||
      _filter.isActive;

  void _resetAll() {
    _search.clear();
    setState(() {
      _query = '';
      _type = 'all';
      _period = PeriodFilter.all;
      _filter = ExpenseFilter.empty;
    });
  }

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
    );
    if (res != null && mounted) setState(() => _filter = res);
  }

  List<Expense> _visible(List<Expense> all, Map<String, String> names) {
    final q = _query.trim().toLowerCase();
    final fallback = 'uncategorized'.tr().toLowerCase();
    final rows = all.where((e) {
      if (_type != 'all' && e.type != _type) return false;
      if (!_period.contains(e.date)) return false;
      if (!_filter.matches(e)) return false;
      if (q.isEmpty) return true;
      final cat = (names[e.categoryId] ?? '').toLowerCase();
      return (e.note ?? '').toLowerCase().contains(q) ||
          cat.contains(q) ||
          (cat.isEmpty && fallback.contains(q));
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<ExpensesCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    final categories = context.watch<CategoriesCubit>().state.categories;
    final names = {for (final c in categories) c.id: c.name};
    final all = state.allExpenses;
    final rows = _visible(all, names);

    // Group by calendar day (rows are already newest-first).
    final groups = <DateTime, List<Expense>>{};
    for (final e in rows) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      (groups[day] ??= []).add(e);
    }
    final days = groups.keys.toList();

    final filterCount = _filter.activeCount;
    final filterLabel = filterCount == 0
        ? 'filters'.tr()
        : '${'filters'.tr()}, ${filterCount == 1 ? 'filter_active_one'.tr() : 'filter_active_n'.tr(args: ['$filterCount'])}';
    final locale = context.locale.toString();
    final numberFormat = NumberFormat.decimalPattern(locale);
    String bound(double? v) => v == null ? '∞' : numberFormat.format(v);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async => context.read<ExpensesCubit>().loadExpenses(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              'nav_activity'.tr(),
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
                          child: TextField(
                            controller: _search,
                            onChanged: (v) => setState(() => _query = v),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'search_transactions'.tr(),
                              constraints: const BoxConstraints(minHeight: 48),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                              ),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'clear_search'.tr(),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _search.clear();
                                        setState(() => _query = '');
                                      },
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilterIconButton(
                          label: filterLabel,
                          active: filterCount > 0,
                          onPressed: () =>
                              _openFilters(categories, settings.currencySymbol),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppSegmented<String>(
                      items: [
                        ('all', 'all_transactions'.tr()),
                        ('expense', 'expenses'.tr()),
                        ('income', 'incomes'.tr()),
                      ],
                      value: _type,
                      onChanged: (v) => setState(() => _type = v),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PeriodChip(
                          label: _period.label(context),
                          onTap: () => _pickPeriod(all),
                        ),
                        if (_filter.categories.isNotEmpty)
                          RemovableChip(
                            label: categoryCountLabel(
                              _filter.categories.length,
                            ),
                            removeTooltip: 'remove_filter_x'.tr(
                              args: [
                                categoryCountLabel(_filter.categories.length),
                              ],
                            ),
                            onRemoved: () => setState(
                              () => _filter = _filter.withoutCategories(),
                            ),
                          ),
                        if (_filter.hasPrice)
                          RemovableChip(
                            label:
                                '${_filter.min == null ? '0' : bound(_filter.min)} – ${bound(_filter.max)} ${settings.currencySymbol}',
                            removeTooltip: 'remove_filter_x'.tr(
                              args: ['amount_range'.tr()],
                            ),
                            onRemoved: () => setState(
                              () => _filter = _filter.withoutPrice(),
                            ),
                          ),
                      ],
                    ),
                    if (state.isLoading && all.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            if (rows.isEmpty && !(state.isLoading && all.isEmpty))
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                sliver: SliverToBoxAdapter(
                  child: SurfaceCard(
                    child: all.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_rounded,
                            title: 'no_transactions'.tr(),
                            message: 'no_transactions_hint'.tr(),
                          )
                        : EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'no_results'.tr(),
                            message: 'no_results_hint'.tr(),
                            action: _hasNarrowing
                                ? TextButton(
                                    onPressed: _resetAll,
                                    child: Text('reset_filters'.tr()),
                                  )
                                : null,
                          ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList.builder(
                  itemCount: days.length,
                  itemBuilder: (context, i) {
                    final day = days[i];
                    final items = groups[day]!;
                    final spent = items
                        .where((e) => e.type != 'income')
                        .fold<double>(0, (s, e) => s + e.amount);
                    return _DayGroup(
                      label: _dayLabel(context, day),
                      total: spent == 0
                          ? ''
                          : AppTheme.formatMoney(
                              spent,
                              settings.currencySymbol,
                              locale: locale,
                            ),
                      children: [
                        for (final e in items)
                          ExpenseCard(
                            expense: e,
                            settings: settings,
                            onTap: () => showExpenseDetails(context, e),
                          ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _dayLabel(BuildContext context, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'today_title'.tr();
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return 'yesterday_title'.tr();
    }
    final text = DateFormat.MMMEd(context.locale.toString()).format(day);
    return toBeginningOfSentenceCase(text, context.locale.toString());
  }
}

class _DayGroup extends StatelessWidget {
  final String label;
  final String total;
  final List<Widget> children;
  const _DayGroup({
    required this.label,
    required this.total,
    required this.children,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                total,
                style: muted?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        GroupedList(children: children),
      ],
    );
  }
}
