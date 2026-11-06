import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/auth/auth_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ExpenseBrand extends StatelessWidget {
  const ExpenseBrand({super.key});
  @override
  Widget build(BuildContext context) =>
      Text('G-spend', style: Theme.of(context).textTheme.titleLarge);
}

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;
  const AppShell({super.key, required this.child, required this.location});
  @override
  Widget build(BuildContext context) {
    if (!['/', '/expenses', '/stats', '/projects'].contains(location)) {
      return child;
    }
    final theme = Theme.of(context);
    final name = context.watch<AuthCubit>().state.displayName ?? '';
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s.characters.first.toUpperCase())
        .join();
    return BlocListener<ProjectsCubit, ProjectsState>(
      listenWhen: (a, b) => a.currentProject?.id != b.currentProject?.id,
      listener: (context, state) => context.read<ExpensesCubit>().loadExpenses(
        projectId: state.currentProject?.id,
      ),
      child: Scaffold(
        appBar: location != '/'
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                toolbarHeight: location == '/' ? 88 : 64,
                title: location == '/'
                    ? const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [ExpenseBrand(), ProjectContext()],
                      )
                    : Text(
                        ({
                          '/expenses': 'nav_activity',
                          '/stats': 'nav_analysis',
                          '/projects': 'projects',
                        }[location]!).tr(),
                      ),
                actions: [
                  IconButton(
                    tooltip: 'theme'.tr(),
                    icon: Icon(
                      theme.brightness == Brightness.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 19,
                    ),
                    onPressed: () => context.read<SettingsCubit>().changeTheme(
                      theme.brightness == Brightness.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: IconButton(
                      tooltip: 'account'.tr(),
                      onPressed: () => context.push('/account'),
                      icon: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Text(
                          initials.isEmpty ? '•' : initials,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        body: Column(children: [Expanded(child: child)]),
        bottomNavigationBar: ExpenseNavigation(
          location: location,
          onSelect: (path) => context.go(path),
        ),
      ),
    );
  }
}

class ExpenseNavigation extends StatelessWidget {
  final String location;
  final ValueChanged<String> onSelect;
  const ExpenseNavigation({
    super.key,
    required this.location,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('/', 'nav_home', Icons.grid_view_outlined),
      ('/expenses', 'nav_activity', Icons.swap_vert),
      ('/stats', 'nav_analysis', Icons.bar_chart_outlined),
      ('/projects', 'projects', Icons.folder_outlined),
    ];
    return NavigationBar(
      selectedIndex: tabs
          .indexWhere((tab) => tab.$1 == location)
          .clamp(0, tabs.length - 1),
      onDestinationSelected: (index) => onSelect(tabs[index].$1),
      destinations: tabs
          .map(
            (tab) =>
                NavigationDestination(icon: Icon(tab.$3), label: tab.$2.tr()),
          )
          .toList(),
    );
  }
}

class ProjectContext extends StatelessWidget {
  const ProjectContext({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProjectsCubit>().state;
    final projects = {
      ...{for (final p in state.projects) p.id: p},
      ...{for (final p in state.sharedProjects) p.id: p},
    }.values.toList();
    final selected = projects.any((p) => p.id == state.currentProject?.id)
        ? state.currentProject!.id
        : 'personal';
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        label: Text(
          state.currentProject?.name ?? 'personal_workspace'.tr(),
          overflow: TextOverflow.ellipsis,
        ),
        icon: const Icon(Icons.expand_more, size: 16),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          useRootNavigator: true,
          useSafeArea: true,
          builder: (sheet) => SafeArea(
            minimum: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('personal_workspace'.tr()),
                  trailing: selected == 'personal'
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    context.read<ProjectsCubit>().switchProject('');
                    Navigator.pop(sheet);
                  },
                ),
                ...projects.map(
                  (p) => ListTile(
                    title: Text(p.name),
                    trailing: selected == p.id ? const Icon(Icons.check) : null,
                    onTap: () {
                      context.read<ProjectsCubit>().switchProject(p.id);
                      Navigator.pop(sheet);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
