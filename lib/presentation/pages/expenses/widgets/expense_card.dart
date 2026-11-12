import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/widgets/category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final SettingsState settings;
  final VoidCallback onTap;
  final String? creatorName;
  const ExpenseCard({
    super.key,
    required this.expense,
    required this.settings,
    required this.onTap,
    this.creatorName,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = context
        .watch<CategoriesCubit>()
        .state
        .categories
        .where((c) => c.id == expense.categoryId)
        .firstOrNull;
    final income = expense.type == 'income';
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              CategoryIcon(
                categoryId: expense.categoryId,
                size: 20,
                padding: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.note ?? cat?.name ?? 'no_description'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        cat?.name ?? 'uncategorized'.tr(),
                        DateFormat('dd/MM').format(expense.date),
                        if (creatorName != null)
                          '${'created_by'.tr()} $creatorName',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${income ? '+' : '−'}${AppTheme.formatMoney(expense.amount, settings.currencySymbol, locale: context.locale.toString())}',
                textAlign: TextAlign.end,
                style: GoogleFonts.geist(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: income
                      ? AppTheme.link(context)
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
