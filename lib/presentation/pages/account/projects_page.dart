import 'package:easy_localization/easy_localization.dart';
import 'package:expense/core/theme.dart';
import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/widgets/settings_widgets.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';

/// Colour of a project: its stored colour, else the theme primary.
Color projectColor(Project? project, ThemeData theme) =>
    project?.color == null
    ? theme.colorScheme.primary
    : AppTheme.parseColor(project!.color);

/// Pill with a check: marks the currently selected project.
class ProjectActiveBadge extends StatelessWidget {
  const ProjectActiveBadge({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            'active'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats {
  final int count;
  final double income;
  final double expense;
  const _Stats(this.count, this.income, this.expense);
}

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = InstantProvider.of(context).auth.currentUser.value?.id;
    final state = context.watch<ProjectsCubit>().state;
    final expenses = context.watch<ExpensesCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    final locale = context.locale.toString();
    final all = {
      for (final p in [...state.projects, ...state.sharedProjects]) p.id: p,
    }.values.toList();

    // Only the active project's transactions are loaded, so meters are
    // computed for that one card; the others keep their descriptive subtitle.
    _Stats? statsFor(String? projectId) {
      if (expenses.currentProjectId != projectId) return null;
      final list = expenses.allExpenses;
      double income = 0, expense = 0;
      for (final e in list) {
        if (e.type == 'income') {
          income += e.amount;
        } else {
          expense += e.amount;
        }
      }
      return _Stats(list.length, income, expense);
    }

    String money(double v) => AppTheme.formatMoney(
      v.abs(),
      settings.currencySymbol,
      locale: locale,
    );

    Widget card({
      required String name,
      required String subtitle,
      required Color color,
      required bool active,
      required _Stats? stats,
      required VoidCallback onTap,
      required VoidCallback onMore,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _ProjectCard(
        name: name,
        subtitle: stats == null
            ? subtitle
            : (stats.count == 1
                  ? 'one_transaction'.tr()
                  : 'n_transactions'.tr(args: ['${stats.count}'])),
        color: color,
        active: active,
        stats: stats,
        money: money,
        onTap: onTap,
        onMore: onMore,
      ),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 128),
          children: [
            if (state.isLoading) const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'projects'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 28,
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => showProjectEditor(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text('new_short'.tr()),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'projects_intro'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            card(
              name: 'personal_workspace'.tr(),
              subtitle: 'personal_project_desc'.tr(),
              color: theme.colorScheme.primary,
              active: state.currentProject == null,
              stats: statsFor(null),
              onTap: () => context.read<ProjectsCubit>().switchProject(''),
              onMore: () => _showPersonalActions(context),
            ),
            for (final p in all)
              card(
                name: p.name,
                subtitle:
                    p.description ??
                    (p.ownerId == userId ? 'owner' : 'member').tr(),
                color: projectColor(p, theme),
                active: state.currentProject?.id == p.id,
                stats: statsFor(p.id),
                onTap: () => context.read<ProjectsCubit>().switchProject(p.id),
                onMore: () => _showProjectDetails(context, p),
              ),
          ],
        ),
      ),
    );
  }

  void _showPersonalActions(BuildContext context) {
    final cubit = context.read<ProjectsCubit>();
    showAppSheet<void>(
      context,
      builder: (sheet) => SheetBody(
        title: 'personal_workspace'.tr(),
        footer: FilledButton(
          onPressed: () {
            Navigator.pop(sheet);
            cubit.switchProject('');
          },
          child: Text('select_project'.tr()),
        ),
        children: [
          SettingsCard(
            children: [
              SettingsListTile(
                title: 'rename_personal'.tr(),
                icon: Icons.drive_file_move_outline,
                onTap: () {
                  Navigator.pop(sheet);
                  _convertPersonal(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProjectDetails(BuildContext context, Project project) {
    final cubit = context.read<ProjectsCubit>();
    final owner =
        project.ownerId ==
        InstantProvider.of(context).auth.currentUser.value?.id;
    showAppSheet<void>(
      context,
      builder: (sheet) {
        final theme = Theme.of(sheet);
        final actions = <Widget>[
          if (!project.isDefault)
            SettingsListTile(
              title: 'current_members'.tr(),
              icon: Icons.group_outlined,
              onTap: () {
                Navigator.pop(sheet);
                _showShareProject(context, project);
              },
            ),
          if (owner)
            SettingsListTile(
              title: 'edit_project'.tr(),
              icon: Icons.edit_outlined,
              onTap: () {
                Navigator.pop(sheet);
                showProjectEditor(context, project: project);
              },
            ),
          if (owner && !project.isDefault)
            SettingsListTile(
              title: 'delete_project'.tr(),
              icon: Icons.delete_outline_rounded,
              color: theme.colorScheme.error,
              onTap: () {
                Navigator.pop(sheet);
                _confirmDelete(context, project);
              },
            ),
        ];
        return SheetBody(
          title: project.name,
          footer: FilledButton(
            onPressed: () {
              Navigator.pop(sheet);
              cubit.switchProject(project.id);
            },
            child: Text('select_project'.tr()),
          ),
          children: [
            if ((project.description ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  project.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (actions.isNotEmpty) SettingsCard(children: actions),
          ],
        );
      },
    );
  }

  Future<void> _convertPersonal(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('convert_personal_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('convert_personal_message'.tr()),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: 'name'.tr()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(c, controller.text.trim());
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && context.mounted) {
      final ok = await context.read<ProjectsCubit>().convertPersonalToProject(
        name,
      );
      if (context.mounted && !ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_personal_expenses_to_convert'.tr())),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Project project) async {
    final cubit = context.read<ProjectsCubit>();
    final ok = await showConfirmSheet(
      context,
      title: 'delete_project'.tr(),
      message: 'delete_project_confirmation'.tr(args: [project.name]),
      confirmLabel: 'delete'.tr(),
      destructive: true,
    );
    if (ok) cubit.deleteProject(project.id);
  }

  void _showShareProject(BuildContext context, Project project) {
    final cubit = context.read<ProjectsCubit>();
    showAppSheet<void>(
      context,
      builder: (_) => _ShareProjectSheet(project: project, projectsCubit: cubit),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color color;
  final bool active;
  final _Stats? stats;
  final String Function(double) money;
  final VoidCallback onTap;
  final VoidCallback onMore;
  const _ProjectCard({
    required this.name,
    required this.subtitle,
    required this.color,
    required this.active,
    required this.stats,
    required this.money,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      side: BorderSide(
        color: active ? scheme.primary : theme.dividerColor,
        width: 1.5,
      ),
    );
    final s = stats;
    final pct = s != null && s.income > 0
        ? (s.expense / s.income * 100).round().clamp(0, 100)
        : null;
    final balance = s == null ? null : s.income - s.expense;
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        color: Color.lerp(color, scheme.onSurface, .28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(width: 8),
                      const ProjectActiveBadge(),
                    ],
                    IconButton(
                      tooltip: 'manage_projects'.tr(),
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
                      ),
                      icon: const Icon(Icons.more_horiz_rounded),
                      onPressed: onMore,
                    ),
                  ],
                ),
                if (s != null && balance != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (pct != null) ...[
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'spent_pct_income'.tr(args: ['$pct']),
                            excludeSemantics: true,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: Container(
                                height: 8,
                                color: scheme.primaryContainer,
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: pct / 100,
                                  child: ColoredBox(color: scheme.primary),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (pct != null)
                              Text(
                                'spent_pct_income'.tr(args: ['$pct']),
                                style: theme.textTheme.bodySmall,
                              ),
                            Text.rich(
                              TextSpan(
                                text: '${'balance_short'.tr()} ',
                                children: [
                                  TextSpan(
                                    text:
                                        '${balance < 0 ? '−' : ''}${money(balance)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Palette offered when creating/editing a project. User data colours (stored
/// on the project), not theme tokens.
const _projectPalette = <Color>[
  Color(0xFF287344),
  Color(0xFF2F6FB0),
  Color(0xFFC9852B),
  Color(0xFF8A5CC2),
  Color(0xFFCF4E6C),
  Color(0xFF1F9C9C),
];

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Create (project == null) or edit a project in a bottom sheet.
Future<void> showProjectEditor(BuildContext context, {Project? project}) {
  final cubit = context.read<ProjectsCubit>();
  return showAppSheet<void>(
    context,
    builder: (_) => _ProjectEditorSheet(project: project, cubit: cubit),
  );
}

class _ProjectEditorSheet extends StatefulWidget {
  final Project? project;
  final ProjectsCubit cubit;
  const _ProjectEditorSheet({required this.project, required this.cubit});
  @override
  State<_ProjectEditorSheet> createState() => _ProjectEditorSheetState();
}

class _ProjectEditorSheetState extends State<_ProjectEditorSheet> {
  late final _name = TextEditingController(text: widget.project?.name);
  late final _desc = TextEditingController(text: widget.project?.description);
  late Color? _color = widget.project?.color == null
      ? _projectPalette.first
      : AppTheme.parseColor(widget.project!.color);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'name_required'.tr());
      return;
    }
    final desc = _desc.text.trim();
    final p = widget.project;
    final colour = _color == null ? p?.color : _hex(_color!);
    if (p == null) {
      widget.cubit.addProject(name: name, description: desc, color: colour);
    } else {
      widget.cubit.updateProject(
        id: p.id,
        name: name,
        description: desc,
        color: colour,
        icon: p.icon,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final editing = widget.project != null;
    return SheetBody(
      title: (editing ? 'edit_project' : 'new_project').tr(),
      footer: FilledButton(
        onPressed: _save,
        child: Text((editing ? 'save' : 'create_project_cta').tr()),
      ),
      children: [
        Text(
          'project_name'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _name,
          maxLength: 30,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'project_name_hint'.tr(),
            counterText: '',
            errorText: _error,
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 16),
        Text(
          'description'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _desc,
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        Text(
          'color'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < _projectPalette.length; i++)
              Semantics(
                button: true,
                selected: _color == _projectPalette[i],
                label: '${'color'.tr()} ${i + 1}',
                excludeSemantics: true,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _color = _projectPalette[i]),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _projectPalette[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == _projectPalette[i]
                            ? scheme.onSurface
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: _color == _projectPalette[i]
                        ? const Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ShareProjectSheet extends StatefulWidget {
  final Project project;
  final ProjectsCubit projectsCubit;

  const _ShareProjectSheet({
    required this.project,
    required this.projectsCubit,
  });

  @override
  State<_ShareProjectSheet> createState() => _ShareProjectSheetState();
}

class _ShareProjectSheetState extends State<_ShareProjectSheet> {
  final _searchController = TextEditingController();
  final Set<String> _selectedEmails = {};

  @override
  void initState() {
    super.initState();
    widget.projectsCubit.loadProjectMembers(widget.project.id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isAlreadyMember(ProjectsState state, String email) {
    return state.projectMembers.any((m) => m['email'] == email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currentUserId = InstantProvider.of(
      context,
    ).auth.currentUser.value?.id;

    return BlocBuilder<ProjectsCubit, ProjectsState>(
      bloc: widget.projectsCubit,
      builder: (context, state) {
        return SheetBody(
          title: 'share_project'.tr(),
          footer: FilledButton(
            onPressed: _selectedEmails.isEmpty
                ? null
                : () {
                    for (final email in _selectedEmails) {
                      widget.projectsCubit.inviteToProject(
                        projectId: widget.project.id,
                        email: email,
                      );
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('invitation_sent'.tr())),
                    );
                  },
            child: Text('invite'.tr()),
          ),
          children: [
            if (state.projectMembers.isNotEmpty) ...[
              Text(
                'current_members'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GroupedList(
                children: [
                  for (final member in state.projectMembers)
                    _memberTile(context, member, currentUserId),
                ],
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'invite_member_hint'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: widget.projectsCubit.searchProfiles,
              decoration: InputDecoration(
                hintText: 'search_users'.tr(),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: state.isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            if (state.searchResults.isNotEmpty)
              GroupedList(
                children: [
                  for (final profile in state.searchResults)
                    _resultTile(state, profile),
                ],
              )
            else if (_searchController.text.length >= 2 && !state.isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'no_users_found'.tr(),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            if (_selectedEmails.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'selected_members'.tr(
                    args: [_selectedEmails.length.toString()],
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.link(context),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _memberTile(
    BuildContext context,
    Map<String, dynamic> member,
    String? currentUserId,
  ) {
    final theme = Theme.of(context);
    final isOwner = widget.project.ownerId == currentUserId;
    final canRemove =
        isOwner ||
        member['user_id'] == currentUserId ||
        member['invited_by'] == currentUserId;
    final accepted = member['accepted_at'] as String?;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
      child: Row(
        children: [
          InitialsAvatar(name: member['name'] as String?, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  member['email'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  accepted != null
                      ? '${'joined'.tr()}: ${DateFormat('dd MMM yyyy', context.locale.toString()).format(DateTime.parse(accepted))}'
                      : 'pending'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accepted != null
                        ? AppTheme.link(context)
                        : AppTheme.expenseAccent(context),
                  ),
                ),
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              tooltip: 'delete'.tr(),
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: Icon(
                Icons.remove_circle_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
              onPressed: () => widget.projectsCubit.removeProjectMember(
                member['member_id'],
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultTile(ProjectsState state, Map<String, dynamic> profile) {
    final theme = Theme.of(context);
    final email = profile['email'] as String;
    final name = profile['name'] as String;
    final already = _isAlreadyMember(state, email);
    return CheckboxListTile(
      value: _selectedEmails.contains(email) || already,
      onChanged: already
          ? null
          : (checked) => setState(() {
              if (checked == true) {
                _selectedEmails.add(email);
              } else {
                _selectedEmails.remove(email);
              }
            }),
      title: Text(
        name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        already ? '$email · ${'already_member'.tr()}' : email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    );
  }
}
