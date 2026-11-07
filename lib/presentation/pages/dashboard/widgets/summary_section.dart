import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class SummarySection extends StatelessWidget {
  final ExpensesState state;
  final SettingsState settings;
  const SummarySection({
    super.key,
    required this.state,
    required this.settings,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String money(double n) => AppTheme.formatMoney(
      n,
      settings.currencySymbol,
      locale: context.locale.toString(),
    );
    final incomeTotal = state.dateRange == null
        ? state.thisMonthIncome
        : state.filteredIncome;
    final expenseTotal = state.dateRange == null
        ? state.thisMonthExpense
        : state.filteredExpense;
    final ratio = incomeTotal > 0 ? expenseTotal / incomeTotal : 0.0;
    Widget metric(String label, double amount, bool income) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                income ? Icons.south_west : Icons.north_east,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(label.tr(), style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${income ? '+' : '−'}${money(amount)}',
              style: GoogleFonts.aBeeZee(
                fontSize: 13,
                color: income
                    ? AppTheme.link(context)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'balance_this_month'.tr(),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  useRootNavigator: true,
                  useSafeArea: true,
                  builder: (sheet) => SafeArea(
                    minimum: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (offset) {
                        final now = DateTime.now();
                        final start = DateTime(now.year, now.month - offset);
                        return ListTile(
                          title: Text(
                            DateFormat.yMMMM(
                              context.locale.toString(),
                            ).format(start),
                          ),
                          onTap: () {
                            context.read<ExpensesCubit>().loadExpenses(
                              dateRange: DateTimeRange(
                                start: start,
                                end: DateTime(
                                  start.year,
                                  start.month + 1,
                                ).subtract(const Duration(microseconds: 1)),
                              ),
                              amountRange: null,
                            );
                            Navigator.pop(sheet);
                          },
                        );
                      }),
                    ),
                  ),
                ),
                child: Text(
                  DateFormat.yMMMM(
                    context.locale.toString(),
                  ).format(state.dateRange?.start ?? DateTime.now()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: NumberFormat.decimalPattern(
                      context.locale.toString(),
                    ).format(incomeTotal - expenseTotal),
                  ),
                  TextSpan(
                    text: ' ${settings.currencySymbol}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              style: GoogleFonts.aBeeZee(fontSize: 34, letterSpacing: -1),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                metric('income', incomeTotal, true),
                Container(
                  height: 42,
                  width: 1,
                  color: theme.dividerColor,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                metric('expense', expenseTotal, false),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            incomeTotal > 0
                ? 'income_used'.tr(args: ['${(ratio * 100).round()}'])
                : 'no_income_yet'.tr(),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: ratio.clamp(0, 1),
            minHeight: 4,
            color: AppTheme.link(context),
            backgroundColor: theme.dividerColor,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
