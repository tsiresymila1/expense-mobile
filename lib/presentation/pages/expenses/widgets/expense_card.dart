import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/data/local/database.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/widgets/category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpenseCard extends StatelessWidget {
  final LocalExpense expense;
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CategoryIcon(categoryId: expense.categoryId),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.note ?? 'no_description',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).tr(),
                    const SizedBox(height: 4),
                    BlocBuilder<CategoriesBloc, CategoriesState>(
                      builder: (context, state) {
                        final cat = state.categories
                            .where((c) => c.id == expense.categoryId)
                            .firstOrNull;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat?.name ?? 'General',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            if (creatorName != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${'created_by'.tr()} $creatorName',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              Text(
                '${expense.type == 'income' ? '+' : '-'}${AppTheme.formatMoney(expense.amount, settings.currencySymbol, locale: context.locale.toString())}',
                style: GoogleFonts.outfit(
                  color: expense.type == 'income'
                      ? Colors.green
                      : const Color(0xFFE57373), // Subtle Red
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
