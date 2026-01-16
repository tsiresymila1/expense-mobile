import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class SummaryStatsCards extends StatelessWidget {
  final ExpensesState state;

  const SummaryStatsCards({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settings) {
        return Row(
          children: [
            Expanded(
              child: _buildCard(
                context,
                'income'.tr(),
                AppTheme.formatMoney(
                  state.filteredIncome,
                  settings.currencySymbol,
                ),
                Colors.green,
                Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCard(
                context,
                'expense'.tr(),
                AppTheme.formatMoney(
                  state.filteredExpense,
                  settings.currencySymbol,
                ),
                Colors.red,
                Icons.arrow_downward_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
