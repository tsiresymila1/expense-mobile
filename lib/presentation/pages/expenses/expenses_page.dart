import 'package:expense/presentation/widgets/form_page.dart';
import 'package:expense/presentation/widgets/expense_details.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/pages/expenses/widgets/expense_card.dart';
import 'package:expense/presentation/widgets/add_expense_modal.dart';
import 'package:expense/presentation/widgets/category_management_modal.dart';
import 'package:expense/presentation/widgets/expense_filter_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});
  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  String _query = '';
  bool _searchVisible = false;
  String _type = 'all';
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<ExpensesCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    final expenses = state.expenses
        .where(
          (e) =>
              (_type == 'all' || e.type == _type) &&
              (e.note ?? '').toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('nav_activity'.tr()),
        actions: [
          IconButton(
            tooltip: 'search_transactions'.tr(),
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _searchVisible = !_searchVisible),
          ),
          IconButton(
            tooltip: 'filters'.tr(),
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilter(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'new_expense'.tr(),
        onPressed: () => _showAddExpense(context),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => context.read<ExpensesCubit>().loadExpenses(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showFilter(context),
                    child: Text('filters'.tr()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCategoryManagement(context),
                    child: Text('manage_categories'.tr()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_searchVisible)
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'search_transactions'.tr(),
                  prefixIcon: const Icon(Icons.search, size: 18),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children:
                  [
                        ('all', 'all_transactions'),
                        ('expense', 'expense'),
                        ('income', 'income'),
                      ]
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: TextButton(
                            onPressed: () => setState(() => _type = t.$1),
                            style: TextButton.styleFrom(
                              foregroundColor: _type == t.$1
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.onSurfaceVariant,
                              shape: const RoundedRectangleBorder(),
                            ),
                            child: Text(t.$2.tr()),
                          ),
                        ),
                      )
                      .toList(),
            ),
            if (state.isLoading) const LinearProgressIndicator(),
            if (expenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'no_transactions'.tr(),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ...expenses.map(
              (expense) => ExpenseCard(
                expense: expense,
                settings: settings,
                onTap: () => showExpenseDetails(context, expense),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpense(BuildContext context) =>
      openFormPage(context, const AddExpenseModal(), title: 'new_expense'.tr());
  void _showCategoryManagement(BuildContext context) => showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const CategoryManagementModal(),
  );

  void _showFilter(BuildContext context) async {
    final settings = context.read<SettingsCubit>().state;
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) =>
          ExpenseFilterModal(currencySymbol: settings.currencySymbol),
    );
    if (res != null && context.mounted) {
      context.read<ExpensesCubit>().loadExpenses(
        dateRange: res['date_range'] as DateTimeRange?,
        amountRange: res['amount_range'] as RangeValues?,
      );
    }
  }

  // ... existing helpers
}
