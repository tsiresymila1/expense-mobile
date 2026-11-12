import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:flutter/material.dart';

/// Gradient hero: month balance (income − expense), expense trend chip versus
/// last month and the Revenus / Dépenses tiles. Text is white on both themes.
class BalanceHero extends StatelessWidget {
  final String? firstName;
  final double income;
  final double expense;

  /// Expenses of the previous calendar month; the trend chip is hidden at 0.
  final double lastMonthExpense;
  final String currencySymbol;
  final DateTime now;

  const BalanceHero({
    super.key,
    required this.firstName,
    required this.income,
    required this.expense,
    required this.lastMonthExpense,
    required this.currencySymbol,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.locale.toString();
    final dark = theme.brightness == Brightness.dark;
    final colors = dark ? AppTheme.heroDark : AppTheme.heroLight;
    final white = Colors.white;
    final month = DateFormat.MMMM(locale).format(now);
    final lastMonth = DateFormat.MMMM(
      locale,
    ).format(DateTime(now.year, now.month - 1));
    final balance = income - expense;
    String money(double v) =>
        AppTheme.formatMoney(v.abs(), currencySymbol, locale: locale);
    final tabular = const [FontFeature.tabularFigures()];

    final hasName = (firstName ?? '').isNotEmpty;
    final greeting = hasName
        ? 'hero_greeting'.tr(args: [firstName!, month])
        : 'hero_balance_of'.tr(args: [month]);

    int? pct;
    if (lastMonthExpense > 0) {
      pct = ((expense - lastMonthExpense) / lastMonthExpense * 100).round();
    }
    String? chipText;
    IconData chipIcon = Icons.arrow_downward_rounded;
    if (pct != null) {
      chipIcon = pct > 0
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded;
      final signed = pct > 0 ? '+$pct %' : (pct < 0 ? '−${pct.abs()} %' : '0 %');
      chipText = 'expenses_vs_last_month'.tr(args: [signed, lastMonth]);
    }

    Widget flow(IconData icon, String label, double value) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: white.withValues(alpha: .86)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: white.withValues(alpha: .86),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                money(value),
                maxLines: 1,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFeatures: tabular,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      label: 'balance_this_month'.tr(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.prominentCardRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.3,
              colors: colors,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: IgnorePointer(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: white.withValues(alpha: .07),
                        width: 28,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: white.withValues(alpha: .86),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${balance < 0 ? '−' : ''}${money(balance)}',
                        maxLines: 1,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: white,
                          fontSize: 38,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1.5,
                          fontFeatures: tabular,
                        ),
                      ),
                    ),
                    if (chipText != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(minHeight: 26),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: white.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(chipIcon, size: 13, color: white),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                chipText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        flow(
                          Icons.south_west_rounded,
                          'incomes_label'.tr(),
                          income,
                        ),
                        const SizedBox(width: 10),
                        flow(
                          Icons.north_east_rounded,
                          'expenses_label'.tr(),
                          expense,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
