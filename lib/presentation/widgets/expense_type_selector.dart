import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpenseTypeSelector extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const ExpenseTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildItem(context, 'expense', Colors.red),
          _buildItem(context, 'income', Colors.green),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String type, Color color) {
    final theme = Theme.of(context);
    final isSelected = value == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: color.withValues(alpha: 0.5))
                : null,
          ),
          child: Center(
            child: Text(
              type.tr(),
              style: GoogleFonts.outfit(
                color: isSelected
                    ? color
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
