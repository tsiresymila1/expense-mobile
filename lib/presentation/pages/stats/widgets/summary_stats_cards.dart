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
    return BlocBuilder<SettingsCubit, SettingsState>(
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
                AppTheme.link(context),
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
                Theme.of(context).colorScheme.onSurface,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: GoogleFonts.geistMono(fontSize: 16, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
