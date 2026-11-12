import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/widgets/category_icon.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The 8 category colours (order matters: new categories cycle through them).
const kCategoryColors = <Color>[
  Color(0xFF287344),
  Color(0xFF2F6FB0),
  Color(0xFFC9852B),
  Color(0xFF8A5CC2),
  Color(0xFFCF4E6C),
  Color(0xFF1F9C9C),
  Color(0xFFB5483A),
  Color(0xFF5F6B73),
];

const _colorLabelKeys = <String>[
  'color_green',
  'color_blue',
  'color_amber',
  'color_violet',
  'color_rose',
  'color_teal',
  'color_brick',
  'color_slate',
];

/// Opens the category editor sheet (create when [category] is null).
/// Resolves to the id of the created/updated category, or null when dismissed.
Future<String?> showCategoryEditor(
  BuildContext context, {
  Category? category,
  String initialName = '',
}) => showAppSheet<String>(
  context,
  builder: (_) =>
      AddCategoryModal(category: category, initialName: initialName),
);

class AddCategoryModal extends StatefulWidget {
  final Category? category;
  final String initialName;
  const AddCategoryModal({super.key, this.category, this.initialName = ''});
  @override
  State<AddCategoryModal> createState() => _AddCategoryModalState();
}

class _AddCategoryModalState extends State<AddCategoryModal> {
  late final TextEditingController _name;
  late String _icon;
  late Color _color;
  String? _error;
  bool _saving = false;

  bool get _edit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?.name ?? widget.initialName)
      ..addListener(() => setState(() => _error = null));
    _icon = canonicalCategoryIcon(c?.icon) ?? 'tag';
    final count = context.read<CategoriesCubit>().state.categories.length;
    _color = c?.color != null
        ? AppTheme.parseColor(c!.color).withValues(alpha: 1.0)
        : kCategoryColors[count % kCategoryColors.length];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = _name.text.trim();
    return SheetBody(
      title: (_edit ? 'edit_category' : 'new_category').tr(),
      onBack: () => Navigator.pop(context),
      footer: FilledButton.icon(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        icon: const Icon(Icons.check_rounded, size: 20),
        label: Text((_edit ? 'save' : 'create_category').tr()),
      ),
      children: [
        _Preview(name: name, icon: _icon, color: _color),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          autofocus: !_edit && widget.initialName.isEmpty,
          maxLength: 24,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: 'name'.tr(),
            hintText: 'category_name_hint'.tr(),
            counterText: '',
            errorText: _error,
          ),
        ),
        const SizedBox(height: 20),
        Text('icon'.tr(), style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Semantics(
          container: true,
          label: 'icon'.tr(),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in kCategoryIconOptions)
                _IconPick(
                  option: o,
                  selected: o.key == _icon,
                  onTap: () => setState(() => _icon = o.key),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('color'.tr(), style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < kCategoryColors.length; i++)
              _Swatch(
                color: kCategoryColors[i],
                label: _colorLabelKeys[i].tr(),
                selected: kCategoryColors[i].toARGB32() == _color.toARGB32(),
                ringColor: scheme.onSurface,
                onTap: () => setState(() => _color = kCategoryColors[i]),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    final cubit = context.read<CategoriesCubit>();
    if (name.isEmpty) {
      setState(() => _error = 'category_name_required'.tr());
      return;
    }
    final lower = name.toLowerCase();
    final duplicate = cubit.state.categories.any(
      (c) =>
          c.id != widget.category?.id && c.name.trim().toLowerCase() == lower,
    );
    if (duplicate) {
      setState(() => _error = 'category_name_duplicate'.tr());
      return;
    }
    final color = _color.toARGB32().toRadixString(16).toUpperCase();
    setState(() => _saving = true);
    String? id;
    if (_edit) {
      await cubit.updateCategory(
        id: widget.category!.id,
        name: name,
        icon: _icon,
        color: color,
      );
      id = widget.category!.id;
    } else {
      id = await cubit.addCategory(name: name, icon: _icon, color: color);
    }
    if (!mounted) return;
    if (id == null) {
      setState(() {
        _saving = false;
        _error = 'expense_save_error'.tr();
      });
      return;
    }
    Navigator.pop(context, id);
  }
}

class _Preview extends StatelessWidget {
  final String name;
  final String icon;
  final Color color;
  const _Preview({required this.name, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      child: Row(
        children: [
          CategoryGlyph(
            icon: icon,
            color: color,
            size: 28,
            padding: 14,
            radius: 18,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name.isEmpty ? 'category_name'.tr() : name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: name.isEmpty ? theme.colorScheme.onSurfaceVariant : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconPick extends StatelessWidget {
  final CategoryIconOption option;
  final bool selected;
  final VoidCallback onTap;
  const _IconPick({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: option.labelKey.tr(),
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? scheme.primary : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              option.icon,
              size: 24,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final Color ringColor;
  final VoidCallback onTap;
  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.ringColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    inMutuallyExclusiveGroup: true,
    checked: selected,
    button: true,
    label: label,
    excludeSemantics: true,
    onTap: onTap,
    child: InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? ringColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: selected
              ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
              : null,
        ),
      ),
    ),
  );
}
