import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:flutter/material.dart';
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
    final ratio = state.thisMonthIncome > 0
        ? state.thisMonthExpense / state.thisMonthIncome
        : 0.0;
    Widget metric(String label, double amount, bool income) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${income ? '↙' : '↗'} ${label.tr()}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${income ? '+' : '−'}${money(amount)}',
              style: GoogleFonts.geistMono(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 24),
        Text(
          'balance_this_month'.tr().toUpperCase(),
          style: GoogleFonts.geistMono(
            fontSize: 10,
            letterSpacing: 1,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: NumberFormat.decimalPattern(
                    context.locale.toString(),
                  ).format(state.thisMonthTotal),
                ),
                TextSpan(
                  text: ' ${settings.currencySymbol}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    letterSpacing: 0,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            style: GoogleFonts.geist(
              fontSize: 46,
              fontWeight: FontWeight.w400,
              letterSpacing: -2.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('balance_explanation'.tr(), style: theme.textTheme.bodySmall),
        const SizedBox(height: 28),
        Row(
          children: [
            metric('income', state.thisMonthIncome, true),
            const SizedBox(width: 18),
            metric('expense', state.thisMonthExpense, false),
          ],
        ),
        const SizedBox(height: 26),
        const Divider(),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: '${(ratio * 100).round()}%',
                child: Row(
                  children: List.generate(
                    20,
                    (i) => Expanded(
                      child: Container(
                        height: 24,
                        margin: const EdgeInsets.only(right: 3),
                        color: i < (ratio * 20).ceil()
                            ? AppTheme.primaryColor
                            : theme.dividerColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                state.thisMonthIncome > 0
                    ? 'income_used'.tr(args: ['${(ratio * 100).round()}'])
                    : 'no_income_yet'.tr(),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Divider(),
      ],
    );
  }
}
