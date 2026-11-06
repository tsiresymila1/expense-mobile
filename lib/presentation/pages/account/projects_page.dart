import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';
import 'package:google_fonts/google_fonts.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = InstantProvider.of(context).auth.currentUser.value?.id;
    final state = context.watch<ProjectsCubit>().state;
    final all = {
      for (final p in [...state.projects, ...state.sharedProjects]) p.id: p,
    }.values.toList();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('projects'.tr()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 22),
            child: ElevatedButton.icon(
              onPressed: () => _showAddProject(context),
              icon: const Icon(Icons.add, size: 16),
              label: Text('add'.tr()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text('personal_workspace'.tr()),
            subtitle: Text('personal_project_desc'.tr()),
            onTap: () => context.read<ProjectsCubit>().switchProject(''),
            trailing: PopupMenuButton<String>(
              onSelected: (_) => _convertPersonal(context),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'convert',
                  child: Text('rename_personal'.tr()),
                ),
              ],
            ),
          ),
          const Divider(),
          ...all.expand(
            (p) => [
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(p.name),
                subtitle: Text(
                  p.description ??
                      (p.ownerId == userId ? 'owner' : 'member').tr(),
                ),
                onTap: () => _showProjectDetails(context, p),
                trailing: state.currentProject?.id == p.id
                    ? Icon(Icons.check, color: theme.colorScheme.secondary)
                    : const Icon(Icons.chevron_right, size: 18),
              ),
              const Divider(),
            ],
          ),
        ],
      ),
    );
  }

  void _showProjectDetails(BuildContext context, dynamic project) {
    final owner =
        project.ownerId ==
        InstantProvider.of(context).auth.currentUser.value?.id;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(project.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              project.description ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(sheet);
                context.read<ProjectsCubit>().switchProject(project.id);
              },
              child: Text('select_project'.tr()),
            ),
            const SizedBox(height: 16),
            if (!project.isDefault)
              ListTile(
                title: Text('current_members'.tr()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheet);
                  _showShareProject(context, project);
                },
              ),
            if (owner)
              ListTile(
                title: Text('edit_project'.tr()),
                onTap: () {
                  Navigator.pop(sheet);
                  _showEditProject(context, project);
                },
              ),
            if (owner && !project.isDefault)
              ListTile(
                title: Text(
                  'delete_project'.tr(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(sheet);
                  _confirmDelete(context, project);
                },
              ),
          ],
        ),
      ),
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

  void _showAddProject(BuildContext context) {
    _showProjectModal(context);
  }

  void _showEditProject(BuildContext context, dynamic project) {
    _showProjectModal(context, project: project);
  }

  void _showProjectModal(BuildContext context, {dynamic project}) {
    final nameController = TextEditingController(text: project?.name);
    final descController = TextEditingController(text: project?.description);
    final cubit = context.read<ProjectsCubit>();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(project == null ? 'new_project'.tr() : 'edit_project'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'name'.tr()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: 'description'.tr()),
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
              if (nameController.text.isNotEmpty) {
                if (project == null) {
                  cubit.addProject(
                    name: nameController.text,
                    description: descController.text,
                  );
                } else {
                  cubit.updateProject(
                    id: project.id,
                    name: nameController.text,
                    description: descController.text,
                  );
                }
                Navigator.pop(c);
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic project) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('delete_project'.tr()),
        content: Text('delete_project_confirmation'.tr(args: [project.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              context.read<ProjectsCubit>().deleteProject(project.id);
              Navigator.pop(c);
            },
            child: Text(
              'delete'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareProject(BuildContext context, dynamic project) {
    showDialog(
      context: context,
      builder: (c) => _ShareProjectDialog(
        project: project,
        projectsCubit: context.read<ProjectsCubit>(),
      ),
    );
  }
}

class _ShareProjectDialog extends StatefulWidget {
  final dynamic project;
  final ProjectsCubit projectsCubit;

  const _ShareProjectDialog({
    required this.project,
    required this.projectsCubit,
  });

  @override
  State<_ShareProjectDialog> createState() => _ShareProjectDialogState();
}

class _ShareProjectDialogState extends State<_ShareProjectDialog> {
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

    return BlocBuilder<ProjectsCubit, ProjectsState>(
      bloc: widget.projectsCubit,
      builder: (context, state) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          title: Text('share_project'.tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.projectMembers.isNotEmpty) ...[
                    Text(
                      'current_members'.tr(),
                      style: GoogleFonts.geist(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.projectMembers.length,
                        itemBuilder: (context, index) {
                          final member = state.projectMembers[index];
                          final currentUserId = InstantProvider.of(
                            context,
                          ).auth.currentUser.value?.id;
                          final isOwner =
                              widget.project.ownerId == currentUserId;
                          final isMemberThemselves =
                              member['user_id'] == currentUserId;
                          final invitedByCurrentUser =
                              member['invited_by'] == currentUserId;
                          final canRemove =
                              isOwner ||
                              isMemberThemselves ||
                              invitedByCurrentUser;

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 14,
                              child: Text(
                                (member['name'] as String?)?[0].toUpperCase() ??
                                    'U',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            title: Text(
                              member['name'] ?? '',
                              style: GoogleFonts.geist(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member['email'] ?? '',
                                  style: GoogleFonts.geist(fontSize: 11),
                                ),
                                if (member['accepted_at'] != null)
                                  Text(
                                    '${'joined'.tr()}: ${DateFormat('dd MMM yyyy', context.locale.toString()).format(DateTime.parse(member['accepted_at']))}',
                                    style: GoogleFonts.geist(
                                      fontSize: 10,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                else
                                  Text(
                                    'pending'.tr(),
                                    style: GoogleFonts.geist(
                                      fontSize: 10,
                                      color: Colors.orange,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: canRemove
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      widget.projectsCubit.removeProjectMember(
                                        member['member_id'],
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  )
                                : null,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                    const Divider(height: 32),
                  ],
                  Text(
                    'invite_member_hint'.tr(),
                    style: GoogleFonts.geist(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      widget.projectsCubit.searchProfiles(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'search_users'.tr(),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: state.isSearching
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              width: 20,
                              height: 20,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.searchResults.isNotEmpty) ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.searchResults.length,
                        itemBuilder: (context, index) {
                          final profile = state.searchResults[index];
                          final email = profile['email'] as String;
                          final name = profile['name'] as String;
                          final isAlreadyMember = _isAlreadyMember(
                            state,
                            email,
                          );
                          final isSelected =
                              _selectedEmails.contains(email) ||
                              isAlreadyMember;

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: isAlreadyMember
                                ? null
                                : (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedEmails.add(email);
                                      } else {
                                        _selectedEmails.remove(email);
                                      }
                                    });
                                  },
                            title: Text(
                              name,
                              style: GoogleFonts.geist(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    email,
                                    style: GoogleFonts.geist(fontSize: 12),
                                  ),
                                ),
                                if (isAlreadyMember)
                                  Text(
                                    'already_member'.tr(),
                                    style: GoogleFonts.geist(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            contentPadding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else if (_searchController.text.length >= 2 &&
                      !state.isSearching)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'no_users_found'.tr(),
                          style: GoogleFonts.geist(color: Colors.grey),
                        ),
                      ),
                    ),
                  if (_selectedEmails.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'selected_members'.tr(
                          args: [_selectedEmails.length.toString()],
                        ),
                        style: GoogleFonts.geist(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text('invite'.tr()),
            ),
          ],
        );
      },
    );
  }
}
