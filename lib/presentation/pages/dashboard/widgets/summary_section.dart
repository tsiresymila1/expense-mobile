import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SummarySection extends StatelessWidget {
  final ExpensesState state;
  final SettingsState settings;

  const SummarySection({
    super.key,
    required this.state,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withRed(100),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'balance_this_month'.tr(),
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppTheme.formatMoney(
                  state.thisMonthTotal,
                  settings.currencySymbol,
                  locale: context.locale.toString(),
                ),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              _buildTrendIndicator(state, settings, context),
            ],
          ),
        ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOutExpo).moveY(begin: 30, end: 0, curve: Curves.easeOutExpo),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildMetricCard(
              context,
              'total_income'.tr(),
              state.thisMonthIncome,
              Icons.arrow_upward_rounded,
              const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              context,
              'total_expense'.tr(),
              state.thisMonthExpense,
              Icons.arrow_downward_rounded,
              const Color(0xFFEF5350),
            ),
          ],
        ).animate(delay: 400.ms).fadeIn(duration: 800.ms, curve: Curves.easeOutExpo).moveY(begin: 30, end: 0, curve: Curves.easeOutExpo),
      ],
    );
  }

  Widget _buildTrendIndicator(ExpensesState state, SettingsState settings, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history_rounded, color: Colors.white70, size: 14),
          const SizedBox(width: 8),
          Text(
            '${'last_month'.tr()}: ${AppTheme.formatMoney(state.lastMonthTotal, settings.currencySymbol, locale: context.locale.toString())}',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, double amount, IconData icon, Color color) {
    final t = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: t.dividerColor.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppTheme.formatMoney(
                amount,
                settings.currencySymbol,
                locale: context.locale.toString(),
              ),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
