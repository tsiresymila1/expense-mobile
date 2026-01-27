import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'projects'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocBuilder<ProjectsBloc, ProjectsState>(
        builder: (context, state) {
          if (state.isLoading && state.projects.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProjects = [...state.projects, ...state.sharedProjects];

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: allProjects.length,
            itemBuilder: (context, index) {
              final project = allProjects[index];
              final isOwner = project.ownerId == currentUserId;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withAlpha(20),
                    child: Icon(
                      isOwner ? Icons.folder_rounded : Icons.folder_shared_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    project.name.tr(),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    project.description ?? (isOwner ? 'personal_project_desc' : 'shared_project_desc'),
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ).tr(),
                  onTap: () {
                    context.read<ProjectsBloc>().add(SwitchProject(project.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('switched_to'.tr(args: [project.name])),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.currentProject?.id == project.id)
                        Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
                      if (isOwner)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditProject(context, project);
                            } else if (value == 'delete') {
                              _confirmDelete(context, project);
                            } else if (value == 'share') {
                              _showShareProject(context, project);
                            }
                          },
                          itemBuilder: (context) => [
                            if (!project.isDefault)
                              PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    const Icon(Icons.share_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text('share'.tr()),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text('edit'.tr()),
                                ],
                              ),
                            ),
                            if (!project.isDefault)
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              )
                  .animate(delay: (100 * index).ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProject(context),
        label: Text('new_project'.tr()),
        icon: const Icon(Icons.add_rounded),
      ),
    );
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
    final bloc = context.read<ProjectsBloc>();

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
          TextButton(onPressed: () => Navigator.pop(c), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                if (project == null) {
                  bloc.add(AddProject(
                        name: nameController.text,
                        description: descController.text,
                      ));
                } else {
                  bloc.add(UpdateProject(
                        id: project.id,
                        name: nameController.text,
                        description: descController.text,
                      ));
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
          TextButton(onPressed: () => Navigator.pop(c), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () {
              context.read<ProjectsBloc>().add(DeleteProject(project.id));
              Navigator.pop(c);
            },
            child: Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
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
        projectsBloc: context.read<ProjectsBloc>(),
      ),
    );
  }
}

class _ShareProjectDialog extends StatefulWidget {
  final dynamic project;
  final ProjectsBloc projectsBloc;

  const _ShareProjectDialog({
    required this.project,
    required this.projectsBloc,
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
    widget.projectsBloc.add(LoadProjectMembers(widget.project.id));
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

    return BlocBuilder<ProjectsBloc, ProjectsState>(
      bloc: widget.projectsBloc,
      builder: (context, state) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('share_project'.tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.projectMembers.isNotEmpty)
                   ...[
                    Text(
                      'current_members'.tr(),
                      style: GoogleFonts.outfit(
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
                          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                          final isOwner = widget.project.ownerId == currentUserId;
                          final isMemberThemselves = member['user_id'] == currentUserId;
                          final invitedByCurrentUser = member['invited_by'] == currentUserId;
                          final canRemove = isOwner || isMemberThemselves || invitedByCurrentUser;

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 14,
                              child: Text(
                                (member['name'] as String?)?[0].toUpperCase() ?? 'U',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            title: Text(
                              member['name'] ?? '',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member['email'] ?? '',
                                  style: GoogleFonts.outfit(fontSize: 11),
                                ),
                                if (member['accepted_at'] != null)
                                  Text(
                                    '${'joined'.tr()}: ${DateFormat('dd MMM yyyy', context.locale.toString()).format(DateTime.parse(member['accepted_at']))}',
                                    style: GoogleFonts.outfit(fontSize: 10, color: theme.colorScheme.primary),
                                  )
                                else
                                  Text(
                                    'pending'.tr(),
                                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.orange),
                                  ),
                              ],
                            ),
                            trailing: canRemove
                                ? IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                                    onPressed: () {
                                      widget.projectsBloc.add(RemoveProjectMember(member['member_id']));
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
                  Text('invite_member_hint'.tr(), style: GoogleFonts.outfit(fontSize: 14)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      widget.projectsBloc.add(SearchProfiles(value));
                    },
                    decoration: InputDecoration(
                      hintText: 'search_users'.tr(),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: state.isSearching
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              width: 20,
                              height: 20,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
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
                          final isAlreadyMember = _isAlreadyMember(state, email);
                          final isSelected = _selectedEmails.contains(email) || isAlreadyMember;

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
                            title: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            subtitle: Row(
                              children: [
                                Expanded(child: Text(email, style: GoogleFonts.outfit(fontSize: 12))),
                                if (isAlreadyMember)
                                  Text(
                                    'already_member'.tr(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            contentPadding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else if (_searchController.text.length >= 2 && !state.isSearching)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'no_users_found'.tr(),
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                      ),
                    ),
                  if (_selectedEmails.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'selected_members'.tr(args: [_selectedEmails.length.toString()]),
                        style: GoogleFonts.outfit(
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
                        widget.projectsBloc.add(InviteToProject(
                          projectId: widget.project.id,
                          email: email,
                        ));
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('invitation_sent'.tr())),
                      );
                    },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
