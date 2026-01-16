import 'package:expense/core/theme.dart';
import 'package:expense/data/local/database.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/sync_engine/sync_engine.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/widgets/add_expense_modal.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syncEngine = context.read<SyncEngine>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settings) {
          return RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: () async {
              context.read<ExpensesBloc>().add(LoadExpenses());
              await syncEngine.triggerSync();
            },
            child: BlocBuilder<ExpensesBloc, ExpensesState>(
              builder: (context, state) {
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildAppBar(theme, syncEngine, context),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildSummarySection(state, theme, settings),
                            const SizedBox(height: 24),
                            _buildQuickActions(context, theme),
                            const SizedBox(height: 32),
                            _buildSectionHeader('daily_expenses'.tr(), theme),
                            const SizedBox(height: 16),
                            _buildChartCard(state, theme),
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                              'recent_transactions'.tr(),
                              theme,
                              actionLabel: 'see_all'.tr(),
                              onAction: () => context.go('/expenses'),
                            ),
                            const SizedBox(height: 16),
                            _buildRecentTransactions(state, theme, settings, context),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpense(context),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, SyncEngine syncEngine, BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'dashboard'.tr(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        centerTitle: false,
      ),
      actions: [
        StreamBuilder<SyncState>(
          stream: syncEngine.syncState,
          builder: (context, snapshot) {
            final status = snapshot.data?.status ?? SyncStatus.idle;
            return _buildSyncIndicator(status, theme);
          },
        ),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          onPressed: () => context.push('/account'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme, {String? actionLabel, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSyncIndicator(SyncStatus status, ThemeData theme) {
    IconData icon;
    Color color;
    bool rotating = false;

    switch (status) {
      case SyncStatus.syncing:
        icon = Icons.sync_rounded;
        color = theme.colorScheme.primary;
        rotating = true;
        break;
      case SyncStatus.error:
        icon = Icons.sync_problem_rounded;
        color = theme.colorScheme.error;
        break;
      case SyncStatus.success:
        icon = Icons.check_circle_rounded;
        color = AppTheme.primaryColor;
        break;
      default:
        icon = Icons.sync_rounded;
        color = theme.colorScheme.onSurface.withValues(alpha: 0.3);
    }

    if (rotating) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    return Icon(icon, color: color, size: 24);
  }

  Widget _buildSummarySection(ExpensesState state, ThemeData theme, SettingsState settings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withBlue(150)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'balance_this_month'.tr(),
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppTheme.formatMoney(state.thisMonthTotal, settings.currencySymbol),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                '${'last_month'.tr()}: ${AppTheme.formatMoney(state.lastMonthTotal, settings.currencySymbol)}',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(ExpensesState state, ThemeData theme) {
    if (state.dailySpending.every((v) => v == 0)) {
       return Container(
         height: 200,
         alignment: Alignment.center,
         child: Text('no_data'.tr(), style: GoogleFonts.outfit(color: theme.disabledColor)),
       );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: state.dailySpending.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                    theme.colorScheme.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(ExpensesState state, ThemeData theme, SettingsState settings, BuildContext context) {
    final recent = state.expenses.take(5).toList();
    if (recent.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text('no_transactions'.tr(), style: GoogleFonts.outfit(color: theme.disabledColor)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final expense = recent[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ListTile(
            onTap: () => _showExpenseOptions(context, expense),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: _buildCategoryIcon(expense.categoryId, theme),
            title: Text(
              expense.note ?? 'No description',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              DateFormat('EEE, MMM dd').format(expense.date),
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
            ),
            trailing: Text(
              '${expense.type == 'income' ? '+' : '-'}${AppTheme.formatMoney(expense.amount, settings.currencySymbol)}',
              style: GoogleFonts.outfit(
                color: expense.type == 'income' ? Colors.green : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
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

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            theme,
            'transactions'.tr(),
            Icons.receipt_long_rounded,
            theme.colorScheme.secondary,
            () => context.push('/expenses'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            context,
            theme,
            'statistics'.tr(),
            Icons.bar_chart_rounded,
            theme.colorScheme.primary,
            () => context.push('/stats'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseModal(),
    );
  }
}
