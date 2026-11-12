import 'package:easy_localization/easy_localization.dart';
import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/auth/auth_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/pages/dashboard/widgets/balance_hero.dart';
import 'package:expense/presentation/pages/dashboard/widgets/week_spending_card.dart';
import 'package:expense/presentation/pages/expenses/widgets/expense_card.dart';
import 'package:expense/presentation/widgets/app_shell.dart';
import 'package:expense/presentation/widgets/expense_details.dart';
import 'package:expense/presentation/widgets/settings_widgets.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
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

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExpensesCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    final name = context.watch<AuthCubit>().state.displayName;
    final firstName = (name ?? '').trim().split(RegExp(r'\s+')).first;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastMonth = DateTime(now.year, now.month - 1);
    double income = 0, expense = 0, lastExpense = 0;
    final week = List<double>.filled(7, 0);
    for (final e in state.allExpenses) {
      final isExpense = e.type != 'income';
      if (e.date.year == now.year && e.date.month == now.month) {
        if (isExpense) {
          expense += e.amount;
        } else {
          income += e.amount;
        }
      } else if (isExpense &&
          e.date.year == lastMonth.year &&
          e.date.month == lastMonth.month) {
        lastExpense += e.amount;
      }
      if (isExpense) {
        for (var i = 0; i < 7; i++) {
          if (_sameDay(e.date, today.subtract(Duration(days: 6 - i)))) {
            week[i] += e.amount;
            break;
          }
        }
      }
    }
    final List<Expense> recent = [...state.allExpenses]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => context.read<ExpensesCubit>().loadExpenses(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 128),
          children: [
            if (state.isLoading && state.allExpenses.isEmpty)
              const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Expanded(child: ProjectContext()),
                  const SizedBox(width: 12),
                  Semantics(
                    button: true,
                    label: 'account'.tr(),
                    excludeSemantics: true,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.push('/account'),
                      child: InitialsAvatar(name: name),
                    ),
                  ),
                ],
              ),
            ),
            BalanceHero(
              firstName: firstName,
              income: income,
              expense: expense,
              lastMonthExpense: lastExpense,
              currencySymbol: settings.currencySymbol,
              now: now,
            ),
            SectionHeader(title: 'period_7d'.tr()),
            WeekSpendingCard(
              totals: week,
              today: today,
              currencySymbol: settings.currencySymbol,
            ),
            SectionHeader(
              title: 'recent_section'.tr(),
              actionLabel: 'see_all'.tr(),
              onAction: () => context.go('/expenses'),
            ),
            if (recent.isEmpty)
              SurfaceCard(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'no_transactions'.tr(),
                  message: 'empty_tx_hint'.tr(),
                ),
              )
            else
              GroupedList(
                children: [
                  for (final expense in recent.take(5))
                    ExpenseCard(
                      expense: expense,
                      settings: settings,
                      onTap: () => showExpenseDetails(context, expense),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
