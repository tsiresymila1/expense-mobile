import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/pages/dashboard/widgets/dashboard_app_bar.dart';
import 'package:expense/presentation/pages/dashboard/widgets/quick_actions.dart';
import 'package:expense/presentation/pages/dashboard/widgets/recent_transactions_list.dart';
import 'package:expense/presentation/pages/dashboard/widgets/spending_chart.dart';
import 'package:expense/presentation/pages/dashboard/widgets/summary_section.dart';
import 'package:expense/presentation/router.dart';
import 'package:expense/presentation/widgets/add_expense_modal.dart';
import 'package:expense/sync_engine/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppRouter.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() => _onFocus();

  @override
  void didPopNext() => _onFocus();

  void _onFocus() async {
    if (mounted) {
      context.read<ExpensesBloc>().add(LoadExpenses());
      context.read<CategoriesBloc>().add(LoadCategories());
      await context.read<SyncEngine>().triggerSync();
      if (mounted) {
        context.read<ExpensesBloc>().add(LoadExpenses());
        context.read<CategoriesBloc>().add(LoadCategories());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syncEngine = context.read<SyncEngine>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settings) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ExpensesBloc>().add(LoadExpenses());
              await syncEngine.triggerSync();
            },
            child: BlocBuilder<ExpensesBloc, ExpensesState>(
              builder: (context, state) {
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    DashboardAppBar(syncEngine: syncEngine),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            SummarySection(state: state, settings: settings),
                            const SizedBox(height: 24),
                            const QuickActions(),
                            const SizedBox(height: 32),
                            _buildSectionHeader('daily_expenses'.tr(), theme),
                            const SizedBox(height: 16),
                            SpendingChart(state: state),
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                              'recent_transactions'.tr(),
                              theme,
                              actionLabel: 'see_all'.tr(),
                              onAction: () => context.go('/expenses'),
                            ),
                            const SizedBox(height: 16),
                            RecentTransactionsList(
                              state: state,
                              settings: settings,
                            ),
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

  Widget _buildSectionHeader(
    String title,
    ThemeData theme, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
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

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseModal(),
    );
  }
}
