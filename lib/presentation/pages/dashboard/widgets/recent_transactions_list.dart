import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/data/local/database.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/widgets/add_expense_modal.dart';
import 'package:expense/presentation/widgets/category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecentTransactionsList extends StatelessWidget {
  final ExpensesState state;
  final SettingsState settings;

  const RecentTransactionsList({
    super.key,
    required this.state,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = state.expenses.take(5).toList();
    final projectsState = context.watch<ProjectsBloc>().state;

    if (recent.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          'no_transactions'.tr(),
          style: GoogleFonts.outfit(color: theme.disabledColor),
        ),
      ).animate().fadeIn(duration: 600.ms);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final expense = recent[index];

        // Find creator name if shared project
        String? creatorName;
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        final effectiveCreatorId = expense.createdBy ?? expense.userId;

        if (expense.projectId != null) {
          if (effectiveCreatorId == currentUserId) {
            final user = Supabase.instance.client.auth.currentUser;
            creatorName = user?.userMetadata?['name'] ?? 'Me';
          } else {
            final member = projectsState.projectMembers
                .where((m) => m['user_id'] == effectiveCreatorId)
                .firstOrNull;
            if (member != null) {
              creatorName = member['name'];
            } else {
              creatorName = 'unknown_user'.tr();
            }
          }
        }

        return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ListTile(
                shape: ShapeBorder.lerp(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  0.5,
                ),
                onTap: () => _showExpenseOptions(context, expense),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CategoryIcon(categoryId: expense.categoryId),
                title: Text(
                  expense.note ?? 'no_description',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ).tr(),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'EEEE dd MMM yyyy  HH:mm',
                        context.locale.toString(),
                      ).format(expense.date),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (creatorName != null)
                      Text(
                        '${'created_by'.tr()} $creatorName',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                trailing: Text(
                  '${expense.type == 'income' ? '+' : '-'}${AppTheme.formatMoney(expense.amount, settings.currencySymbol, locale: context.locale.toString())}',
                  style: GoogleFonts.outfit(
                    color: expense.type == 'income'
                        ? Colors.green
                        : const Color(0xFFE57373), // Subtle Red
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            )
            .animate(delay: (20 * index).ms) // Faster stagger for long lists
            .fadeIn(duration: 800.ms, curve: Curves.easeOutExpo)
            .moveX(
              begin: 30,
              end: 0,
              duration: 800.ms,
              curve: Curves.easeOutExpo,
            );
      },
    );
  }

  void _showExpenseOptions(BuildContext context, LocalExpense expense) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final projectsState = context.read<ProjectsBloc>().state;
    final isProjectOwner =
        projectsState.currentProject?.ownerId == currentUserId;

    // Check if creator. Fallback to userId if createdBy is null (legacy).
    final effectiveCreatorId = expense.createdBy ?? expense.userId;
    // If effectiveCreatorId is ME, I can edit.
    // If effectiveCreatorId is NOT ME:
    //   - If I am Owner -> I logic can edit? Usually yes.
    //   - If I am Viewer -> Cannot edit.

    final isCreator = effectiveCreatorId == currentUserId;
    final canEdit = isProjectOwner || isCreator;

    if (!canEdit) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('viewer_cannot_edit'.tr())));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(
                  'edit_transaction'.tr(),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddExpenseModal(expense: expense),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: Text(
                  'delete_transaction'.tr(),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, expense);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, LocalExpense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'delete_confirmation_title'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'delete_confirmation_message'.tr(),
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr(),
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<ExpensesBloc>().add(DeleteExpense(expense.id));
              Navigator.pop(context);
            },
            child: Text(
              'delete_transaction'.tr(),
              style: GoogleFonts.outfit(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
