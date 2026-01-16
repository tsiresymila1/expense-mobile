import 'package:expense/core/theme.dart';
import 'package:expense/data/local/database.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/widgets/add_expense_modal.dart';
import 'package:expense/presentation/widgets/category_management_modal.dart';
import 'package:expense/presentation/widgets/expense_filter_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

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
        centerTitle: false,
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
        builder: (context, settings) {
          return BlocBuilder<ExpensesBloc, ExpensesState>(
            builder: (context, state) {
              if (state.isLoading && state.expenses.isEmpty) {
                return _buildShimmer(theme);
              }

              if (state.expenses.isEmpty) {
                return _buildEmptyState(theme);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ExpensesBloc>().add(LoadExpenses());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: state.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = state.expenses[index];
                    final showHeader = index == 0 || !_isSameDay(expense.date, state.expenses[index - 1].date);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) _buildDateHeader(expense.date, theme),
                        _buildExpenseCard(expense, theme, settings, context),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpense(context),
        label: Text('new_expense'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        icon: const Icon(Icons.add_rounded),
        elevation: 4,
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Widget _buildDateHeader(DateTime date, ThemeData theme) {
    String label;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      label = 'today'.tr();
    } else if (dateOnly == yesterday) {
      label = 'yesterday'.tr();
    } else {
      label = DateFormat('MMM dd, yyyy').format(date).toUpperCase();
    }

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

  Widget _buildExpenseCard(LocalExpense expense, ThemeData theme, SettingsState settings, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: () => _showExpenseOptions(context, expense),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildCategoryIcon(expense.categoryId, theme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.note ?? 'No description',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    BlocBuilder<CategoriesBloc, CategoriesState>(
                      builder: (context, state) {
                        final cat = state.categories.where((c) => c.id == expense.categoryId).firstOrNull;
                        return Text(
                          cat?.name ?? 'General',
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Text(
                '${expense.type == 'income' ? '+' : '-'}${AppTheme.formatMoney(expense.amount, settings.currencySymbol)}',
                style: GoogleFonts.outfit(
                  color: expense.type == 'income' ? Colors.green : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String? categoryId, ThemeData theme) {
    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, state) {
        final cat = state.categories.where((c) => c.id == categoryId).firstOrNull;
        final colorStr = cat?.color;
        final catColor = AppTheme.parseColor(colorStr).withValues(alpha: 1.0);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _getIconData(cat?.icon),
            color: catColor,
            size: 20,
          ),
        );
      },
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'Shopping': return Icons.shopping_bag_rounded;
      case 'Food': return Icons.restaurant_rounded;
      case 'Transport': return Icons.directions_car_rounded;
      case 'Health': return Icons.medical_services_rounded;
      case 'Education': return Icons.school_rounded;
      case 'Entertainment': return Icons.movie_rounded;
      default: return Icons.category_rounded;
    }
  }

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseModal(),
    );
  }

  void _showCategoryManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategoryManagementModal(),
    );
  }

  void _showFilter(BuildContext context) async {
    final settings = context.read<SettingsBloc>().state;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseFilterModal(currencySymbol: settings.currencySymbol),
    );

    if (result != null && context.mounted) {
      context.read<ExpensesBloc>().add(LoadExpenses(
        dateRange: result['date_range'] as DateTimeRange?,
        amountRange: result['amount_range'] as RangeValues?,
      ));
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
                title: Text('edit_transaction'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
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
                title: Text('delete_transaction'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.red)),
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
        title: Text('delete_confirmation_title'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('delete_confirmation_message'.tr(), style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(), style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              context.read<ExpensesBloc>().add(DeleteExpense(expense.id));
              Navigator.pop(context);
            },
            child: Text('delete_transaction'.tr(), style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme) {
    return ListView.builder(
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
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 80, color: theme.disabledColor.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          Text(
            'no_transactions'.tr(),
            style: GoogleFonts.outfit(fontSize: 18, color: theme.disabledColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
