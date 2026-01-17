import 'package:easy_localization/easy_localization.dart';
import 'package:expense/data/local/database.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/pages/expenses/widgets/expense_card.dart';
import 'package:expense/presentation/widgets/add_expense_modal.dart';
import 'package:expense/presentation/widgets/category_management_modal.dart';
import 'package:expense/presentation/widgets/expense_filter_modal.dart';
import 'package:expense/sync_engine/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'transactions'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_rounded),
            onPressed: () => _showCategoryManagement(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilter(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settings) =>
            BlocBuilder<ExpensesBloc, ExpensesState>(
              builder: (context, state) {
                if (state.isLoading && state.expenses.isEmpty) {
                  return _buildShimmer(theme);
                }
                if (state.expenses.isEmpty) return _buildEmptyState(theme);

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<ExpensesBloc>().add(LoadExpenses());
                    await context.read<SyncEngine>().triggerSync();
                    if (context.mounted) {
                      context.read<ExpensesBloc>().add(LoadExpenses());
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: state.expenses.length,
                    itemBuilder: (context, index) {
                      final expense = state.expenses[index];
                      final showHeader =
                          index == 0 ||
                          !_isSameDay(
                            expense.date,
                            state.expenses[index - 1].date,
                          );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader) _buildDateHeader(context, expense.date, theme),
                          ExpenseCard(
                            expense: expense,
                            settings: settings,
                            onTap: () => _showExpenseOptions(context, expense),
                          ),
                        ],
                      )
                          .animate(delay: (100 * (index % 10)).ms)
                          .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            duration: 500.ms,
                            curve: Curves.easeOut,
                          );
                    },
                  ),
                );
              },
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpense(context),
        label: Text(
          'new_expense'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.add_rounded),
      )
          .animate()
          .scale(delay: 600.ms, duration: 400.ms, curve: Curves.easeOutBack)
          .shimmer(delay: 1000.ms, duration: 1200.ms),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  Widget _buildDateHeader(BuildContext context, DateTime date, ThemeData theme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String label = dateOnly == today
        ? 'today'.tr()
        : (dateOnly == yesterday
              ? 'yesterday'.tr()
              : DateFormat('MMM dd, yyyy', context.locale.toString())
                  .format(date)
                  .toUpperCase());
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: theme.disabledColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showAddExpense(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AddExpenseModal(),
  );
  void _showCategoryManagement(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const CategoryManagementModal(),
  );

  void _showFilter(BuildContext context) async {
    final settings = context.read<SettingsBloc>().state;
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ExpenseFilterModal(currencySymbol: settings.currencySymbol),
    );
    if (res != null && context.mounted) {
      context.read<ExpensesBloc>().add(
        LoadExpenses(
          dateRange: res['date_range'] as DateTimeRange?,
          amountRange: res['amount_range'] as RangeValues?,
        ),
      );
    }
  }

  void _showExpenseOptions(BuildContext context, LocalExpense expense) {
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

  Widget _buildShimmer(ThemeData theme) => ListView.builder(
    padding: const EdgeInsets.all(20),
    itemCount: 6,
    itemBuilder: (context, index) => Shimmer.fromColors(
      baseColor: theme.cardColor,
      highlightColor: theme.dividerColor,
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),
  );
  Widget _buildEmptyState(ThemeData theme) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.receipt_long_rounded,
          size: 80,
          color: theme.disabledColor.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 24),
        Text(
          'no_transactions'.tr(),
          style: GoogleFonts.outfit(
            fontSize: 18,
            color: theme.disabledColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
  );
}
