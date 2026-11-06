import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
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
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ExcludeSemantics(
        child: Container(
          width: 29,
          height: 29,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Text(
            'e',
            style: TextStyle(
              color: Color(0xFF10291D),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      const SizedBox(width: 7),
      const Text(
        'expense',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w500,
          letterSpacing: -.8,
        ),
      ),
    ],
  );
}

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;
  const AppShell({super.key, required this.child, required this.location});
  @override
  Widget build(BuildContext context) {
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
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 68,
          title: const ExpenseBrand(),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(),
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
        body: Column(
          children: [
            const ProjectContext(),
            Expanded(child: child),
          ],
        ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: tabs.map((tab) {
              final selected = location == tab.$1;
              final color = selected
                  ? AppTheme.link(context)
                  : Theme.of(context).colorScheme.onSurfaceVariant;
              return Expanded(
                child: Semantics(
                  selected: selected,
                  child: InkWell(
                    onTap: () => onSelect(tab.$1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab.$3, size: 20, color: color),
                          const SizedBox(height: 7),
                          Text(
                            tab.$2.tr(),
                            style: TextStyle(fontSize: 10, color: color),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            width: 14,
                            height: 2,
                            color: selected
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selected,
                iconSize: 16,
                style: Theme.of(context).textTheme.bodySmall,
                items: [
                  DropdownMenuItem(
                    value: 'personal',
                    child: Text('personal_workspace'.tr()),
                  ),
                  ...projects.map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name.tr(), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (id) {
                  if (id != null) {
                    context.read<ProjectsCubit>().switchProject(
                      id == 'personal' ? '' : id,
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            DateFormat.yMMMM(context.locale.toString()).format(DateTime.now()),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
