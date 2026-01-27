import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _buildActionItem(
          context,
          theme,
          'transactions'.tr(),
          Icons.receipt_long_rounded,
          theme.colorScheme.secondary,
          () => context.push('/expenses'),
        ).animate().fadeIn(delay: 400.ms).moveX(begin: 20, end: 0, curve: Curves.easeOutExpo),
        const SizedBox(width: 12),
        _buildActionItem(
          context,
          theme,
          'statistics'.tr(),
          Icons.bar_chart_rounded,
          theme.colorScheme.primary,
          () => context.push('/stats'),
        ).animate().fadeIn(delay: 500.ms).moveX(begin: 20, end: 0, curve: Curves.easeOutExpo),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
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
