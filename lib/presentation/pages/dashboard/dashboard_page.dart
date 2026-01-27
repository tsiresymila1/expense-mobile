import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/pages/dashboard/widgets/dashboard_app_bar.dart';
import 'package:expense/presentation/pages/dashboard/widgets/project_shortcuts.dart';
import 'package:expense/presentation/pages/dashboard/widgets/quick_actions.dart';
import 'package:expense/presentation/pages/dashboard/widgets/recent_transactions_list.dart';
import 'package:expense/presentation/pages/dashboard/widgets/summary_section.dart';
import 'package:expense/presentation/pages/stats/widgets/category_breakdown_chart.dart';
import 'package:expense/presentation/router.dart';
import 'package:expense/presentation/widgets/add_expense_modal.dart';
import 'package:expense/sync_engine/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    if (ModalRoute.of(context) is PageRoute) {
      _onFocus(freshSync: true);
    }
  }

  @override
  void didPopNext() {
    if (ModalRoute.of(context) is PageRoute) {
      _onFocus(freshSync: false);
    }
  }

  void _onFocus({bool freshSync = false}) async {
    if (mounted) {
      context.read<ExpensesBloc>().add(LoadExpenses());
      context.read<CategoriesBloc>().add(LoadCategories());
      if (freshSync) {
        await context.read<SyncEngine>().triggerSync();
        if (mounted) {
          context.read<ExpensesBloc>().add(LoadExpenses());
          context.read<CategoriesBloc>().add(LoadCategories());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syncEngine = context.read<SyncEngine>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocListener<ProjectsBloc, ProjectsState>(
        listenWhen: (previous, current) =>
            previous.currentProject?.id != current.currentProject?.id,
        listener: (context, state) {
          context.read<ExpensesBloc>().add(
                LoadExpenses(projectId: state.currentProject?.id),
              );
        },
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settings) {
            return RefreshIndicator(
              onRefresh: () async {
                final currentProject = context.read<ProjectsBloc>().state.currentProject;
                context.read<ExpensesBloc>().add(
                      LoadExpenses(projectId: currentProject?.id),
                    );
                await syncEngine.triggerSync();
              },
              child: BlocBuilder<ExpensesBloc, ExpensesState>(
                builder: (context, state) {
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      DashboardAppBar(syncEngine: syncEngine),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            SummarySection(state: state, settings: settings)
                                .animate()
                                .fadeIn(duration: 800.ms, curve: Curves.easeOutExpo)
                                .moveY(begin: 30, end: 0, duration: 800.ms, curve: Curves.easeOutExpo),
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                              'projects'.tr(),
                              theme,
                              icon: Icons.folder_copy_rounded,
                              actionLabel: 'see_all'.tr(),
                              onAction: () => context.push('/projects'),
                            ).animate()
                                .fadeIn(delay: 100.ms, duration: 800.ms)
                                .moveY(begin: 30, end: 0, curve: Curves.easeOutExpo),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const ProjectShortcuts(),
                            ).animate()
                                .fadeIn(delay: 150.ms, duration: 800.ms)
                                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutExpo)
                                .moveY(begin: 20, end: 0, curve: Curves.easeOutExpo),
                            const SizedBox(height: 28),
                            _buildModule(
                              'toolkit'.tr(),
                              Icons.bolt_rounded,
                              const QuickActions(),
                              theme,
                            ).animate()
                                .fadeIn(delay: 200.ms, duration: 800.ms)
                                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutExpo)
                                .moveY(begin: 30, end: 0, curve: Curves.easeOutExpo),
                            const SizedBox(height: 32),
                            _buildBudgetSection(theme, state),
                            const SizedBox(height: 32),
                            _buildModule(
                              'category_breakdown'.tr(),
                              Icons.pie_chart_rounded,
                              CategoryBreakdownChart(state: state),
                              theme,
                            ).animate()
                                .fadeIn(delay: 400.ms, duration: 800.ms)
                                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutExpo)
                                .moveY(begin: 30, end: 0, curve: Curves.easeOutExpo),
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                              'recent_transactions'.tr(),
                              theme,
                              icon: Icons.history_rounded,
                              actionLabel: 'see_all'.tr(),
                              onAction: () => context.push('/expenses'),
                            ).animate().fadeIn(delay: 500.ms),
                            RecentTransactionsList(
                              state: state,
                              settings: settings,
                            ).animate()
                                .fadeIn(delay: 600.ms, duration: 800.ms)
                                .moveY(begin: 20, end: 0, curve: Curves.easeOutExpo),
                          ]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpense(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        label: Text(
          'new_expense'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      )
          .animate()
          .fadeIn(delay: 1000.ms, duration: 800.ms)
          .scale(begin: const Offset(0.3, 0.3), end: const Offset(1, 1), curve: Curves.easeOutBack),
    );
  }

  Widget _buildBudgetSection(ThemeData theme, ExpensesState state) {
    final income = state.thisMonthIncome;
    final expense = state.thisMonthExpense;
    final progress = income > 0 ? (expense / income).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toStringAsFixed(0);

    return _buildModule(
      'budget_status'.tr(),
      Icons.speed_rounded,
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'usage_of_income'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: progress > 0.8 ? theme.colorScheme.error : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.8 ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
      theme,
    ).animate()
        .fadeIn(delay: 300.ms, duration: 800.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutExpo)
        .moveY(begin: 30, end: 0, curve: Curves.easeOutExpo);
  }

  Widget _buildModule(String title, IconData icon, Widget content, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8), // Balanced padding
          child: content,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    ThemeData theme, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
            ],
            Text(
              title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
