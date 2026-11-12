import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/widgets/add_expense_modal.dart';
import 'package:expense/presentation/widgets/category_icon.dart';
import 'package:expense/presentation/widgets/expense_attachments.dart';
import 'package:expense/presentation/widgets/form_page.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
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
  final locale = context.locale.toString();
  final creator = expense.creatorId == userId
      ? 'you'.tr()
      : projects.projectMembers
                    .where((m) => m['user_id'] == expense.creatorId)
                    .firstOrNull?['name']
                as String? ??
            'unknown_user'.tr();
  final income = expense.type == 'income';
  final action = await showAppSheet<String>(
    context,
    builder: (sheet) {
      final theme = Theme.of(sheet);
      final dateText = toBeginningOfSentenceCase(
        DateFormat.yMMMMEEEEd(locale).format(expense.date),
        locale,
      );
      return SheetBody(
        title: 'transaction_detail'.tr(),
        footer: canEdit
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(sheet, 'edit'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text('edit'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(sheet, 'delete'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text('delete'.tr()),
                    ),
                  ),
                ],
              )
            : null,
        children: [
          Column(
            children: [
              CategoryGlyph(
                icon: category?.icon,
                color: AppTheme.parseColor(
                  category?.color,
                ).withValues(alpha: 1.0),
                size: 28,
                padding: 14,
                radius: 18,
              ),
              const SizedBox(height: 12),
              Text(
                '${category?.name ?? 'uncategorized'.tr()} · ${expense.type.tr()}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${income ? '+' : '−'}${AppTheme.formatMoney(expense.amount, symbol, locale: locale)}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 38,
                    fontWeight: FontWeight.w600,
                    color: income ? AppTheme.link(sheet) : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GroupedList(
            children: [
              _DefRow('note'.tr(), expense.note ?? 'no_description'.tr()),
              _DefRow('date'.tr(), dateText),
              _DefRow(
                'projects'.tr(),
                project?.name ?? 'personal_workspace'.tr(),
              ),
              if (expense.creatorId != userId)
                _DefRow('created_by'.tr(), creator),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(sheet, 'receipts'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
            icon: const Icon(Icons.attach_file),
            label: Text('receipts'.tr()),
          ),
          if (!canEdit) ...[
            const SizedBox(height: 12),
            Text(
              'viewer_cannot_edit'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      );
    },
  );
  if (!context.mounted) return;
  if (action == 'receipts') {
    await openFormPage(
      context,
      ExpenseAttachments(expenseId: expense.id, canEdit: canEdit),
      title: 'receipts'.tr(),
    );
    return;
  }
  if (!canEdit) return;
  if (action == 'edit') {
    await showAddExpense(context, expense: expense);
    return;
  }
  if (action == 'delete') {
    // Capture before awaiting: the caller's row disappears once deleted.
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<ExpensesCubit>();
    await cubit.deleteExpense(expense.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('transaction_deleted'.tr()),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'undo'.tr(),
            // The restored transaction gets a new id (receipts are not relinked).
            onPressed: () => cubit.addExpense(
              amount: expense.amount,
              categoryId: expense.categoryId,
              projectId: expense.projectId,
              date: expense.date,
              note: expense.note,
              type: expense.type,
            ),
          ),
        ),
      );
  }
}

class _DefRow extends StatelessWidget {
  final String label;
  final String value;
  const _DefRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
