import 'package:expense/presentation/widgets/form_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/pages/dashboard/widgets/summary_section.dart';
import 'package:expense/presentation/pages/dashboard/widgets/recent_transactions_list.dart';
import 'package:expense/presentation/widgets/add_expense_modal.dart';
import 'package:expense/presentation/widgets/category_management_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<ExpensesCubit>().loadExpenses(
      dateRange: null,
      amountRange: null,
      projectId: context.read<ProjectsCubit>().state.currentProject?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExpensesCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    Widget heading(String label, String route) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: () => context.go(route),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('see_all'.tr()),
                const SizedBox(width: 4),
                const Icon(Icons.north_east, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'new_expense'.tr(),
        onPressed: () => openFormPage(
          context,
          const AddExpenseModal(),
          title: 'new_expense'.tr(),
        ),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => context.read<ExpensesCubit>().loadExpenses(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            if (state.isLoading && state.expenses.isEmpty)
              const LinearProgressIndicator(),
            SummarySection(state: state, settings: settings),
            heading('recent_transactions', '/expenses'),
            RecentTransactionsList(state: state, settings: settings),
            TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const CategoryManagementModal(),
              ),
              child: Text('manage_categories'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
