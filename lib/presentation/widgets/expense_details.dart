import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/widgets/add_expense_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';

Future<void> showExpenseDetails(BuildContext context, Expense expense) async {
  final userId = InstantProvider.of(context).auth.currentUser.value?.id;
  final projects = context.read<ProjectsCubit>().state;
  final project = [
    ...projects.projects,
    ...projects.sharedProjects,
  ].where((p) => p.id == expense.projectId).firstOrNull;
  final canEdit =
      userId != null &&
      (expense.creatorId == userId || project?.ownerId == userId);
  final category = context
      .read<CategoriesCubit>()
      .state
      .categories
      .where((c) => c.id == expense.categoryId)
      .firstOrNull;
  final symbol = context.read<SettingsCubit>().state.currencySymbol;
  final creator = expense.creatorId == userId
      ? 'you'.tr()
      : projects.projectMembers
                    .where((m) => m['user_id'] == expense.creatorId)
                    .firstOrNull?['name']
                as String? ??
            'unknown_user'.tr();
  final action = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) {
      final theme = Theme.of(sheet);
      Widget line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(child: Text(label.tr())),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    expense.type.tr(),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'close'.tr(),
                  onPressed: () => Navigator.pop(sheet),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '${expense.type == 'income' ? '+' : '−'}${AppTheme.formatMoney(expense.amount, symbol, locale: context.locale.toString())}',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            line('note', expense.note ?? 'no_description'.tr()),
            const Divider(),
            line('category', category?.name ?? 'uncategorized'.tr()),
            const Divider(),
            line(
              'date',
              DateFormat.yMMMd(context.locale.toString()).format(expense.date),
            ),
            const Divider(),
            line('created_by', creator),
            const Divider(),
            line('projects', project?.name ?? 'personal_workspace'.tr()),
            const SizedBox(height: 20),
            if (canEdit) ...[
              ElevatedButton(
                onPressed: () => Navigator.pop(sheet, 'edit'),
                child: Text('edit_transaction'.tr()),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(sheet, 'delete'),
                child: Text(
                  'delete_transaction'.tr(),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ] else
              Text('viewer_cannot_edit'.tr(), style: theme.textTheme.bodySmall),
          ],
        ),
      );
    },
  );
  if (!context.mounted || !canEdit) return;
  if (action == 'edit') {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddExpenseModal(expense: expense),
    );
  }
  if (!context.mounted) return;
  if (action == 'delete') {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('delete_confirmation_title'.tr()),
        content: Text('delete_confirmation_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(
              'delete'.tr(),
              style: TextStyle(color: Theme.of(c).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ExpensesCubit>().deleteExpense(expense.id);
    }
  }
}
