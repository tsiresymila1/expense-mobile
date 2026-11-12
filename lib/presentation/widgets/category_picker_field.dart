import 'dart:ui' show PathMetric;

import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/widgets/add_category_modal.dart';
import 'package:expense/presentation/widgets/category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pill used for category and date choices in the transaction sheet.
/// Selection is conveyed by tint, border AND a check mark (not colour alone).
class PickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final bool dashed;

  const PickChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.leading,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = selected
        ? scheme.primary
        : dashed
        ? scheme.onSurfaceVariant
        : theme.dividerColor;
    final content = Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: dashed ? scheme.onSurfaceVariant : null,
              ),
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 6),
            Icon(Icons.check_rounded, size: 16, color: scheme.primary),
          ],
        ],
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: dashed
          ? CustomPaint(
              foregroundPainter: _DashedStadiumPainter(borderColor),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: content,
              ),
            )
          : Material(
              color: selected
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerLow,
              shape: StadiumBorder(
                side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}

class _DashedStadiumPainter extends CustomPainter {
  final Color color;
  _DashedStadiumPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.height / 2),
        ),
      );
    for (final PathMetric m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 8) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedStadiumPainter old) => old.color != color;
}

/// Optional category choice as wrapping chips. Tapping the selected chip
/// clears the choice. The dashed "+ Nouvelle" chip opens the category editor
/// and selects the created category.
class CategoryPickerField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const CategoryPickerField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, state) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in state.categories)
              PickChip(
                label: c.name,
                selected: c.id == value,
                leading: CategoryGlyph(
                  icon: c.icon,
                  color: AppTheme.parseColor(c.color).withValues(alpha: 1.0),
                  size: 16,
                  padding: 4,
                  radius: 8,
                ),
                onTap: () => onChanged(c.id == value ? null : c.id),
              ),
            PickChip(
              dashed: true,
              label: 'new_short'.tr(),
              leading: const Icon(Icons.add_rounded, size: 18),
              onTap: () async {
                final id = await showCategoryEditor(context);
                if (id != null) onChanged(id);
              },
            ),
          ],
        ),
      );
}
