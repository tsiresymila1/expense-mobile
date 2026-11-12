import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';

class MonthTotals {
  final DateTime month;
  final double income;
  final double expense;
  const MonthTotals({
    required this.month,
    required this.income,
    required this.expense,
  });
}

/// Six grouped bars (income vs expense). Expense bars are hatched and use the
/// expense accent so the two series differ without relying on colour alone.
class MonthlyBars extends StatelessWidget {
  final List<MonthTotals> months;
  final int selected;
  final ValueChanged<int> onSelect;
  final String currencySymbol;
  const MonthlyBars({
    super.key,
    required this.months,
    required this.selected,
    required this.onSelect,
    required this.currencySymbol,
  });

  static const _barsHeight = 112.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.locale.toString();
    String money(double v) =>
        AppTheme.formatMoney(v, currencySymbol, locale: locale);
    String name(DateTime m, [bool long = true]) => toBeginningOfSentenceCase(
      (long ? DateFormat.MMMM(locale) : DateFormat.MMM(locale)).format(m),
      locale,
    );
    final maxValue = months.fold<double>(
      0,
      (m, e) => [m, e.income, e.expense].reduce((a, b) => a > b ? a : b),
    );
    final cur = months[selected];
    final income = AppTheme.link(context);
    final expense = AppTheme.expenseAccent(context);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                Text(
                  name(cur.month),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'spent_received'.tr(
                    args: [money(cur.expense), money(cur.income)],
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < months.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selected,
                    label: 'month_semantics'.tr(
                      args: [
                        name(months[i].month),
                        money(months[i].income),
                        money(months[i].expense),
                      ],
                    ),
                    excludeSemantics: true,
                    onTap: () => onSelect(i),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onSelect(i),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: i == selected ? 1 : .55,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: _barsHeight,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _Bar(
                                    height: _height(months[i].income, maxValue),
                                    color: income,
                                  ),
                                  const SizedBox(width: 3),
                                  _Bar(
                                    height: _height(
                                      months[i].expense,
                                      maxValue,
                                    ),
                                    color: expense,
                                    hatch:
                                        theme.colorScheme.surfaceContainerLow,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 28),
                              child: Center(
                                child: Text(
                                  name(months[i].month, false),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: i == selected
                                        ? FontWeight.w700
                                        : null,
                                    color: i == selected
                                        ? theme.colorScheme.onSurface
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _Key(color: income, label: 'incomes'.tr()),
              _Key(
                color: expense,
                label: 'expenses'.tr(),
                hatch: theme.colorScheme.surfaceContainerLow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static double _height(double v, double max) =>
      max <= 0 ? 4 : (v / max * _barsHeight).clamp(4, _barsHeight).toDouble();
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  final Color? hatch;
  const _Bar({required this.height, required this.color, this.hatch});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 240),
    curve: Curves.easeOut,
    width: 12,
    height: height,
    child: ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(5),
        bottom: Radius.circular(2),
      ),
      child: CustomPaint(painter: _BarPainter(color, hatch)),
    ),
  );
}

class _BarPainter extends CustomPainter {
  final Color color;
  final Color? hatch;
  const _BarPainter(this.color, this.hatch);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final h = hatch;
    if (h == null) return;
    final line = Paint()
      ..color = h.withValues(alpha: .55)
      ..strokeWidth = 1.5;
    for (double y = -size.width; y < size.height + size.width; y += 6) {
      canvas.drawLine(Offset(0, y + size.width), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.color != color || old.hatch != hatch;
}

class _Key extends StatelessWidget {
  final Color color;
  final String label;
  final Color? hatch;
  const _Key({required this.color, required this.label, this.hatch});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 12,
        height: 12,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CustomPaint(painter: _BarPainter(color, hatch)),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
