import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/pages/account/projects_page.dart';
import 'package:expense/presentation/widgets/add_expense_modal.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Brand lockup: rounded primary square with a "G" + the product name.
class ExpenseBrand extends StatelessWidget {
  final double markSize;
  const ExpenseBrand({super.key, this.markSize = 40});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: markSize,
            height: markSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(markSize * .325),
            ),
            child: Text(
              'G',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontSize: markSize * .45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'G-spend',
          style: theme.textTheme.titleLarge?.copyWith(letterSpacing: -.6),
        ),
      ],
    );
  }
}

const _tabRoutes = ['/', '/expenses', '/stats', '/projects'];

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;
  const AppShell({super.key, required this.child, required this.location});
  @override
  Widget build(BuildContext context) {
    if (!_tabRoutes.contains(location)) {
      return child;
    }
    return BlocListener<ProjectsCubit, ProjectsState>(
      listenWhen: (a, b) => a.currentProject?.id != b.currentProject?.id,
      listener: (context, state) => context.read<ExpensesCubit>().loadExpenses(
        projectId: state.currentProject?.id,
      ),
      child: Scaffold(
        // Pages draw their own header and scroll behind the translucent
        // central "+" slot; they reserve ~120px of bottom padding.
        extendBody: true,
        body: SafeArea(bottom: false, child: child),
        bottomNavigationBar: ExpenseNavigation(
          location: location,
          onSelect: (path) => context.go(path),
        ),
      ),
    );
  }
}

/// Bottom bar: 2 tabs, a raised central "+" (new transaction), 2 tabs.
class ExpenseNavigation extends StatelessWidget {
  final String location;
  final ValueChanged<String> onSelect;
  const ExpenseNavigation({
    super.key,
    required this.location,
    required this.onSelect,
  });

  static const _barHeight = 64.0;
  static const _overlap = 28.0;
  static const _fabSize = 60.0;
  static const _slotWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget tab(String route, String label, IconData icon, IconData active) =>
        Expanded(
          child: _NavTab(
            label: label.tr(),
            icon: icon,
            activeIcon: active,
            selected: route == location,
            onTap: () => onSelect(route),
          ),
        );
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _overlap),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: _barHeight,
                child: Row(
                  children: [
                    tab(
                      '/',
                      'nav_home',
                      Icons.home_outlined,
                      Icons.home_rounded,
                    ),
                    tab(
                      '/expenses',
                      'nav_activity',
                      Icons.swap_vert_rounded,
                      Icons.swap_vert_rounded,
                    ),
                    const SizedBox(width: _slotWidth),
                    tab(
                      '/stats',
                      'nav_analysis',
                      Icons.bar_chart_rounded,
                      Icons.bar_chart_rounded,
                    ),
                    tab(
                      '/projects',
                      'projects',
                      Icons.folder_outlined,
                      Icons.folder_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: .30),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox.square(
              dimension: _fabSize,
              child: FloatingActionButton(
                heroTag: null,
                tooltip: 'new_expense'.tr(),
                onPressed: () => showAddExpense(context),
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;
  const _NavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    final instant = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: instant
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              width: 54,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? scheme.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(selected ? activeIcon : icon, size: 22, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Project pill shown in page headers: colour dot + name + chevron. Opens the
/// project-switch sheet.
class ProjectContext extends StatelessWidget {
  const ProjectContext({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = context.watch<ProjectsCubit>().state.currentProject;
    final name = current?.name ?? 'personal_workspace'.tr();
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 236),
        child: Semantics(
          button: true,
          label: '$name. ${'switch_project'.tr()}',
          excludeSemantics: true,
          child: Material(
            color: theme.colorScheme.surfaceContainerLow,
            shape: StadiumBorder(side: BorderSide(color: theme.dividerColor)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => showProjectSwitcher(context),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Dot(color: projectColor(current, theme)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, this.size = 10});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// "Changer de projet" sheet: dot + name rows, "Actif" badge on the current one.
Future<void> showProjectSwitcher(BuildContext context) {
  final cubit = context.read<ProjectsCubit>();
  final state = cubit.state;
  final projects = {
    ...{for (final p in state.projects) p.id: p},
    ...{for (final p in state.sharedProjects) p.id: p},
  }.values.toList();
  final selected = projects.any((p) => p.id == state.currentProject?.id)
      ? state.currentProject!.id
      : 'personal';
  return showAppSheet<void>(
    context,
    builder: (sheet) {
      final theme = Theme.of(sheet);
      Widget row({
        required Color color,
        required String name,
        required bool active,
        required String projectId,
      }) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          cubit.switchProject(projectId);
          Navigator.pop(sheet);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                _Dot(color: color, size: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 8),
                  const ProjectActiveBadge(),
                ],
              ],
            ),
          ),
        ),
      );
      return SheetBody(
        title: 'switch_project'.tr(),
        footer: OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(sheet);
            showProjectEditor(context);
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text('new_project'.tr()),
        ),
        children: [
          row(
            color: theme.colorScheme.primary,
            name: 'personal_workspace'.tr(),
            active: selected == 'personal',
            projectId: '',
          ),
          for (final p in projects)
            row(
              color: projectColor(p, theme),
              name: p.name,
              active: selected == p.id,
              projectId: p.id,
            ),
        ],
      );
    },
  );
}
