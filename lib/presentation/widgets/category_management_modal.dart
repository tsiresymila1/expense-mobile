import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/widgets/add_category_modal.dart';
import 'package:expense/presentation/widgets/category_icon.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

String _countLabel(int n) =>
    n == 1 ? 'n_transactions_one'.tr() : 'n_transactions'.tr(args: ['$n']);

/// Tall sheet: pinned search + "Nouvelle" toolbar, then the scrolling list.
class CategoryManagementModal extends StatefulWidget {
  /// Show a back arrow (when opened from the add-transaction sheet).
  final bool showBack;
  const CategoryManagementModal({super.key, this.showBack = false});

  @override
  State<CategoryManagementModal> createState() =>
      _CategoryManagementModalState();
}

class _CategoryManagementModalState extends State<CategoryManagementModal> {
  final _query = TextEditingController();
  late final CategoriesCubit _cubit;
  ScaffoldMessengerState? _messenger;
  Category? _undo; // last deleted category, restorable for a few seconds
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<CategoriesCubit>();
    _query.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    // The sheet is closing: hand the pending undo over to a SnackBar.
    final pending = _undo;
    if (pending != null) {
      final messenger = _messenger;
      final cubit = _cubit;
      final message = 'category_deleted'.tr(args: [pending.name]);
      final label = 'undo'.tr();
      // Not while the tree is locked for unmounting.
      scheduleMicrotask(
        () => messenger?.showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: label,
              onPressed: () => cubit.restoreCategory(pending),
            ),
          ),
        ),
      );
    }
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim();
    return Stack(
      children: [
        SheetBody(
          title: 'manage_categories'.tr(),
          expand: true,
          onBack: widget.showBack ? () => Navigator.pop(context) : null,
          toolbar: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'search'.tr(),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: q.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'clear'.tr(),
                            icon: const Icon(Icons.close_rounded),
                            onPressed: _query.clear,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => showCategoryEditor(context),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text('new_short'.tr()),
              ),
            ],
          ),
          children: [_list(context, q)],
        ),
        if (_undo != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
            child: _UndoBar(
              message: 'category_deleted'.tr(args: [_undo!.name]),
              onUndo: _restore,
            ),
          ),
      ],
    );
  }

  Widget _list(BuildContext context, String q) =>
      BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, state) {
          if (state.isLoading && state.categories.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.categories.isEmpty) {
            return EmptyState(
              icon: Icons.sell_rounded,
              title: 'no_categories'.tr(),
              message: 'no_categories_hint'.tr(),
            );
          }
          final lower = q.toLowerCase();
          final rows = state.categories
              .where(
                (c) => lower.isEmpty || c.name.toLowerCase().contains(lower),
              )
              .toList();
          if (rows.isEmpty) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: 'no_results'.tr(),
              message: 'no_category_match'.tr(args: [q]),
              action: TextButton(
                onPressed: () => showCategoryEditor(context, initialName: q),
                child: Text('create_named'.tr(args: [q])),
              ),
            );
          }
          return BlocBuilder<ExpensesCubit, ExpensesState>(
            buildWhen: (a, b) => a.allExpenses != b.allExpenses,
            builder: (context, ex) {
              final counts = <String, int>{};
              for (final e in ex.allExpenses) {
                final id = e.categoryId;
                if (id != null) counts[id] = (counts[id] ?? 0) + 1;
              }
              return Padding(
                // Keep the last row clear of the undo bar.
                padding: EdgeInsets.only(bottom: _undo != null ? 72 : 0),
                child: GroupedList(
                  children: [
                    for (final c in rows)
                      _CategoryRow(
                        category: c,
                        count: counts[c.id] ?? 0,
                        onEdit: () => showCategoryEditor(context, category: c),
                        onDelete: () => _askDelete(c, counts[c.id] ?? 0),
                      ),
                  ],
                ),
              );
            },
          );
        },
      );

  Future<void> _askDelete(Category cat, int count) async {
    if (count > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text('delete_category_title'.tr(args: [cat.name])),
          content: Text('category_delete_used'.tr(args: [_countLabel(count)])),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text('keep'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(d, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(d).colorScheme.error,
                foregroundColor: Theme.of(d).colorScheme.onError,
              ),
              child: Text('delete'.tr()),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await _cubit.deleteCategory(cat.id);
    if (!mounted) return;
    _timer?.cancel();
    setState(() => _undo = cat);
    _timer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _undo = null);
    });
  }

  Future<void> _restore() async {
    final cat = _undo;
    if (cat == null) return;
    _timer?.cancel();
    setState(() => _undo = null);
    await _cubit.restoreCategory(cat);
  }
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  final int count;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CategoryRow({
    required this.category,
    required this.count,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.parseColor(category.color).withValues(alpha: 1.0);
    final locked = category.isDefault; // shared defaults are read-only
    final main = Row(
      children: [
        CategoryGlyph(icon: category.icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                count == 0 ? 'no_transactions'.tr() : _countLabel(count),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (!locked)
          Icon(
            Icons.edit_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
      ],
    );
    return Row(
      children: [
        Expanded(
          child: locked
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: main,
                )
              : Semantics(
                  button: true,
                  label: '${'edit'.tr()} ${category.name}',
                  excludeSemantics: true,
                  onTap: onEdit,
                  child: InkWell(
                    onTap: onEdit,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 68),
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                      alignment: Alignment.centerLeft,
                      child: main,
                    ),
                  ),
                ),
        ),
        if (!locked)
          IconButton(
            tooltip: '${'delete'.tr()} ${category.name}',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 22,
              color: theme.colorScheme.error,
            ),
            onPressed: onDelete,
          )
        else
          const SizedBox(width: 8),
      ],
    );
  }
}

class _UndoBar extends StatelessWidget {
  final String message;
  final VoidCallback onUndo;
  const _UndoBar({required this.message, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: scheme.inverseSurface,
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onInverseSurface),
                ),
              ),
              TextButton(
                onPressed: onUndo,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.inversePrimary,
                  minimumSize: const Size(64, 48),
                ),
                child: Text('undo'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entry point used by Settings (and the add-transaction sheet's "Manage").
Future<void> showCategoryManagement(
  BuildContext context, {
  bool showBack = false,
}) => showAppSheet<void>(
  context,
  builder: (_) => CategoryManagementModal(showBack: showBack),
);
