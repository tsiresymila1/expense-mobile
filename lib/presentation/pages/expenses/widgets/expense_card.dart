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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              CategoryIcon(
                categoryId: expense.categoryId,
                size: 16,
                padding: 8,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.note ?? 'no_description'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${cat?.name ?? 'uncategorized'.tr()} · ${DateFormat('dd/MM').format(expense.date)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (creatorName != null)
                      Text(
                        '${'created_by'.tr()} $creatorName',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${expense.type == 'income' ? '+' : '−'}${AppTheme.formatMoney(expense.amount, settings.currencySymbol, locale: context.locale.toString())}',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.aBeeZee(
                    fontSize: 13,
                    color: expense.type == 'income'
                        ? AppTheme.link(context)
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
