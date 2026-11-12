import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Key used for expenses that have no category.
const kUncategorizedKey = '_uncategorized';

class CategorySlice {
  final String key; // category id, or [kUncategorizedKey]
  final String name;
  final Color color;
  final double value;
  const CategorySlice({
    required this.key,
    required this.name,
    required this.color,
    required this.value,
  });
}

/// Donut of expenses by category + tappable legend. The legend doubles as the
/// accessible table alternative of the chart.
class CategoryDonut extends StatelessWidget {
  final List<CategorySlice> slices;
  final String? selectedKey;
  final ValueChanged<String> onToggle;
  final String currencySymbol;
  const CategoryDonut({
    super.key,
    required this.slices,
    required this.selectedKey,
    required this.onToggle,
    required this.currencySymbol,
  });

  static const _holeRadius = 58.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.locale.toString();
    String money(double v) =>
        AppTheme.formatMoney(v, currencySymbol, locale: locale);
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    final selected = slices.where((s) => s.key == selectedKey).firstOrNull;
    int pct(double v) => (v / total * 100).round();
    final summary =
        '${'chart_summary'.tr()} : ${slices.map((s) => '${s.name} ${pct(s.value)} %').join(', ')}';

    final sections = [
      for (final s in slices)
        PieChartSectionData(
          value: s.value,
          color: selected == null || selected.key == s.key
              ? s.color
              : s.color.withValues(alpha: .3),
          radius: selected?.key == s.key ? 28 : 20,
          showTitle: false,
        ),
    ];

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Column(
        children: [
          Semantics(
            image: true,
            label: summary,
            excludeSemantics: true,
            child: SizedBox(
              width: 176,
              height: 176,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: _holeRadius,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                      borderData: FlBorderData(show: false),
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (event is! FlTapUpEvent) return;
                          final i =
                              response?.touchedSection?.touchedSectionIndex ??
                              -1;
                          if (i >= 0 && i < slices.length) {
                            onToggle(slices[i].key);
                          }
                        },
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: SizedBox(
                      width: _holeRadius * 1.6,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                selected?.name ?? 'total_expense'.tr(),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              money(selected?.value ?? total),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final s in slices)
            _LegendRow(
              slice: s,
              percent: pct(s.value),
              amount: money(s.value),
              selected: s.key == selected?.key,
              onTap: () => onToggle(s.key),
            ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final CategorySlice slice;
  final int percent;
  final String amount;
  final bool selected;
  final VoidCallback onTap;
  const _LegendRow({
    required this.slice,
    required this.percent,
    required this.amount,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const tabular = [FontFeature.tabularFigures()];
    return Semantics(
      button: true,
      selected: selected,
      label: '${slice.name}, $percent %, $amount',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: slice.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      slice.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$percent %',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFeatures: tabular,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    amount,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: tabular,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
