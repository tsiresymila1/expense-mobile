import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';

/// Revenus / Dépenses totals for the selected period.
class KpiCards extends StatelessWidget {
  final double income;
  final double expense;
  final String currencySymbol;
  const KpiCards({
    super.key,
    required this.income,
    required this.expense,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Kpi(
              icon: Icons.south_west_rounded,
              iconColor: AppTheme.link(context),
              label: 'incomes'.tr(),
              value: AppTheme.formatMoney(
                income,
                currencySymbol,
                locale: locale,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Kpi(
              icon: Icons.north_east_rounded,
              iconColor: AppTheme.expenseAccent(context),
              label: 'expenses'.tr(),
              value: AppTheme.formatMoney(
                expense,
                currencySymbol,
                locale: locale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _Kpi({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$label : $value',
      excludeSemantics: true,
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
