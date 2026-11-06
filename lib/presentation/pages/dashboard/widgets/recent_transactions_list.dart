import 'package:expense/presentation/widgets/expense_details.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:flutter/material.dart';

import 'package:expense/presentation/pages/expenses/widgets/expense_card.dart';

class RecentTransactionsList extends StatelessWidget {
  final ExpensesState state;
  final SettingsState settings;
  const RecentTransactionsList({
    super.key,
    required this.state,
    required this.settings,
  });
  @override
  Widget build(BuildContext context) {
    if (state.expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'no_transactions'.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Column(
      children: state.expenses
          .take(4)
          .map(
            (expense) => ExpenseCard(
              expense: expense,
              settings: settings,
              onTap: () => showExpenseDetails(context, expense),
            ),
          )
          .toList(),
    );
  }
}
