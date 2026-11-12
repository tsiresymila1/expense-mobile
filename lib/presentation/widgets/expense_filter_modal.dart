import 'package:easy_localization/easy_localization.dart';
import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/widgets/category_icon.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';

/// Category + price criteria shared by Activity and Analysis. Each screen
/// keeps its own instance; an empty set / null bound means "no constraint".
class ExpenseFilter {
  final Set<String> categories;
  final double? min;
  final double? max;
  const ExpenseFilter({this.categories = const {}, this.min, this.max});

  static const empty = ExpenseFilter();

  bool get hasPrice => min != null || max != null;
  int get activeCount => (categories.isNotEmpty ? 1 : 0) + (hasPrice ? 1 : 0);
  bool get isActive => activeCount > 0;

  ExpenseFilter withoutCategories() =>
      ExpenseFilter(categories: const {}, min: min, max: max);
  ExpenseFilter withoutPrice() => ExpenseFilter(categories: categories);

  bool matches(Expense e) =>
      (categories.isEmpty || categories.contains(e.categoryId)) &&
      (min == null || e.amount >= min!) &&
      (max == null || e.amount <= max!);
}

/// Opens the filter sheet. Returns the applied filter, or null when dismissed.
/// [showPrice] is false for Analysis (categories only).
Future<ExpenseFilter?> showExpenseFilterSheet(
  BuildContext context, {
  required ExpenseFilter initial,
  required List<Category> categories,
  required String currencySymbol,
  bool showPrice = true,
}) => showAppSheet<ExpenseFilter>(
  context,
  builder: (_) => ExpenseFilterSheet(
    initial: initial,
    categories: categories,
    currencySymbol: currencySymbol,
    showPrice: showPrice,
  ),
);

class ExpenseFilterSheet extends StatefulWidget {
  final ExpenseFilter initial;
  final List<Category> categories;
  final String currencySymbol;
  final bool showPrice;
  const ExpenseFilterSheet({
    super.key,
    required this.initial,
    required this.categories,
    required this.currencySymbol,
    this.showPrice = true,
  });
  @override
  State<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<ExpenseFilterSheet> {
  late final Set<String> _cats = {...widget.initial.categories};
  late final _min = TextEditingController(text: _fmt(widget.initial.min));
  late final _max = TextEditingController(text: _fmt(widget.initial.max));

  static String _fmt(double? v) => v == null
      ? ''
      : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  /// Parsed bound; `null` for empty. Sets [ok] false when the text is not a
  /// finite, non-negative number.
  (double?, bool) _parse(String raw) {
    final text = raw.trim().replaceAll(',', '.');
    if (text.isEmpty) return (null, true);
    final v = double.tryParse(text);
    if (v == null || !v.isFinite || v < 0) return (null, false);
    return (v, true);
  }

  bool get _valid {
    final (min, okMin) = _parse(_min.text);
    final (max, okMax) = _parse(_max.text);
    if (!okMin || !okMax) return false;
    return min == null || max == null || max >= min;
  }

  void _reset() => setState(() {
    _cats.clear();
    _min.clear();
    _max.clear();
  });

  void _apply() {
    if (!_valid) return;
    final (min, _) = _parse(_min.text);
    final (max, _) = _parse(_max.text);
    Navigator.pop(
      context,
      widget.showPrice
          ? ExpenseFilter(categories: {..._cats}, min: min, max: max)
          : ExpenseFilter(
              categories: {..._cats},
              min: widget.initial.min,
              max: widget.initial.max,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = _cats.length;
    final selectedLabel = n == 0
        ? 'all_categories'.tr()
        : (n == 1 ? 'selected_one'.tr() : 'selected_n'.tr(args: ['$n']));
    final valid = _valid;
    return SheetBody(
      title: widget.showPrice ? 'filters'.tr() : 'filter_analysis'.tr(),
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(onPressed: _reset, child: Text('reset'.tr())),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: valid ? _apply : null,
              child: Text('apply'.tr()),
            ),
          ),
        ],
      ),
      children: [
        Text.rich(
          TextSpan(
            text: 'categories'.tr(),
            style: theme.textTheme.titleMedium,
            children: [
              TextSpan(
                text: ' · $selectedLabel',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (widget.categories.isEmpty)
          Text('no_categories'.tr(), style: theme.textTheme.bodySmall)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in widget.categories)
                _CategoryChip(
                  category: c,
                  selected: _cats.contains(c.id),
                  onTap: () => setState(() {
                    if (!_cats.remove(c.id)) _cats.add(c.id);
                  }),
                ),
            ],
          ),
        if (widget.showPrice) ...[
          const SizedBox(height: 24),
          Text(
            '${'amount_range'.tr()} (${widget.currencySymbol})',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PriceField(
                  controller: _min,
                  label: 'minimum_amount'.tr(),
                  invalid: !valid,
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PriceField(
                  controller: _max,
                  label: 'maximum_amount'.tr(),
                  invalid: !valid,
                  onChanged: () => setState(() {}),
                ),
              ),
            ],
          ),
          if (!valid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  'invalid_amount_range'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool invalid;
  final VoidCallback onChanged;
  const _PriceField({
    required this.controller,
    required this.label,
    required this.invalid,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    OutlineInputBorder border() => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: error, width: 1.5),
    );
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      onChanged: (_) => onChanged(),
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
      decoration: InputDecoration(
        labelText: label,
        enabledBorder: invalid ? border() : null,
        focusedBorder: invalid ? border() : null,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLow,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? primary : theme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryIcon(categoryId: category.id, size: 16, padding: 6),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check_rounded, size: 16, color: primary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "1 catégorie" / "3 catégories" label used by the removable filter chips.
String categoryCountLabel(int n) =>
    n == 1 ? 'one_category'.tr() : 'n_categories'.tr(args: ['$n']);

/// 48px filter trigger with an "active" dot. [label] is the spoken name.
class FilterIconButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onPressed;
  const FilterIconButton({
    super.key,
    required this.label,
    required this.active,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: Tooltip(
        message: label,
        child: Material(
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: active ? theme.colorScheme.primary : theme.dividerColor,
              width: active ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onTap: onPressed,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.tune_rounded, color: theme.colorScheme.onSurface),
                  if (active)
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surfaceContainerLow,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
