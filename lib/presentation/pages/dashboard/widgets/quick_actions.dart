import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/widgets/category_management_modal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            _buildActionItem(
              context,
              theme,
              'transactions'.tr(),
              Icons.receipt_long_rounded,
              theme.colorScheme.secondary,
              () => context.push('/expenses'),
            ),
            const SizedBox(width: 12),
            _buildActionItem(
              context,
              theme,
              'statistics'.tr(),
              Icons.bar_chart_rounded,
              theme.colorScheme.primary,
              () => context.push('/stats'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionItem(
              context,
              theme,
              'manage_categories'.tr(),
              Icons.category_rounded,
              theme.colorScheme.tertiary,
              () => _showCategories(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showCategories(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CategoryManagementModal(),
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
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.05),
            ),
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
                  style: GoogleFonts.aBeeZee(
                    fontWeight: FontWeight.w500,
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
