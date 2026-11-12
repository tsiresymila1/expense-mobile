import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:flutter/material.dart';

/// Expenses for the 7 days ending today. One tappable bar per day (>=44px wide
/// hit area); the selected day's label and amount show in the caption row.
class WeekSpendingCard extends StatefulWidget {
  /// Expense totals for the last 7 days, oldest first; last entry is today.
  final List<double> totals;
  final DateTime today;
  final String currencySymbol;
  const WeekSpendingCard({
    super.key,
    required this.totals,
    required this.today,
    required this.currencySymbol,
  });

  @override
  State<WeekSpendingCard> createState() => _WeekSpendingCardState();
}

class _WeekSpendingCardState extends State<WeekSpendingCard> {
  static const _chartHeight = 150.0;
  static const _maxColumn = 120.0;
  int _selected = 6;

  DateTime _day(int i) => DateTime(
    widget.today.year,
    widget.today.month,
    widget.today.day - (6 - i),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = context.locale.toString();
    final instant = MediaQuery.disableAnimationsOf(context);
    final totals = widget.totals;
    final maxValue = totals.fold<double>(1, (m, v) => v > m ? v : m);
    String money(double v) =>
        AppTheme.formatMoney(v, widget.currencySymbol, locale: locale);
    String label(int i) {
      if (i == 6) return 'today_label'.tr();
      if (i == 5) return 'yesterday_label'.tr();
      return DateFormat('EEEE d MMM', locale).format(_day(i));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  label(_selected),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                money(totals[_selected]),
                maxLines: 1,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            container: true,
            label: 'daily_spending_7d'.tr(),
            child: SizedBox(
              height: _chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: _Bar(
                        selected: i == _selected,
                        fraction: (totals[i] / maxValue).clamp(.05, 1.0),
                        maxHeight: _maxColumn,
                        weekday: DateFormat('EEEEE', locale)
                            .format(_day(i))
                            .toUpperCase(),
                        semanticLabel: '${label(i)} : ${money(totals[i])}',
                        duration: instant
                            ? Duration.zero
                            : Duration(milliseconds: 420 + i * 40),
                        onTap: () => setState(() => _selected = i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final bool selected;
  final double fraction;
  final double maxHeight;
  final String weekday;
  final String semanticLabel;
  final Duration duration;
  final VoidCallback onTap;
  const _Bar({
    required this.selected,
    required this.fraction,
    required this.maxHeight,
    required this.weekday,
    required this.semanticLabel,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final column = Container(
      width: 30,
      height: fraction * maxHeight,
      decoration: BoxDecoration(
        color: selected ? scheme.primary : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(9),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: .15 + .85 * t,
                child: Transform.scale(
                  alignment: Alignment.bottomCenter,
                  scaleY: .15 + .85 * t,
                  child: child,
                ),
              ),
              child: column,
            ),
            const SizedBox(height: 6),
            Text(
              weekday,
              maxLines: 1,
              style: theme.textTheme.bodySmall?.copyWith(
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
