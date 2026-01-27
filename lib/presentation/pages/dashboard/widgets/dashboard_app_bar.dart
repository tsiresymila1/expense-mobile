import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/pages/dashboard/widgets/sync_indicator.dart';
import 'package:expense/sync_engine/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardAppBar extends StatelessWidget {
  final SyncEngine syncEngine;

  const DashboardAppBar({super.key, required this.syncEngine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'user_profile_fallback'.tr();

    return BlocBuilder<ProjectsBloc, ProjectsState>(
      builder: (context, state) {
        final currentProject = state.currentProject;

        return SliverAppBar(
          expandedHeight: 140,
          floating: false,
          pinned: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            title: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [ 
                      Text(
                        '${'welcome_back'.tr()} ${userName.toString().padRight(10, '.').substring(0,10)}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: () => _showProjectPicker(context, state),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  currentProject?.name.tr() ?? 'G-spend'.tr(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                            if (state.projectMembers.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: InkWell(
                                  onTap: () => _showMembersList(context, state),
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    height: 20,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width:
                                              (state.projectMembers.length > 5
                                                      ? 5
                                                      : state
                                                            .projectMembers
                                                            .length) *
                                                  15.0 +
                                              10,
                                          child: Stack(
                                            children: List.generate(
                                              state.projectMembers.length > 5
                                                  ? 5
                                                  : state.projectMembers.length,
                                              (i) => Positioned(
                                                left: i * 15.0,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: theme
                                                          .scaffoldBackgroundColor,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 8,
                                                    backgroundColor: theme
                                                        .colorScheme
                                                        .primaryContainer,
                                                    child: Text(
                                                      (state.projectMembers[i]['name']
                                                                  as String?)?[0]
                                                              .toUpperCase() ??
                                                          'U',
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: theme
                                                            .colorScheme
                                                            .onPrimaryContainer,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (state.projectMembers.length > 5)
                                          Text(
                                            '+${state.projectMembers.length - 5}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            titlePadding: EdgeInsets.zero,
            centerTitle: false,
          ),
          actions: [
            StreamBuilder<SyncState>(
              stream: syncEngine.syncState,
              builder: (context, snapshot) {
                final status = snapshot.data?.status ?? SyncStatus.idle;
                return SyncIndicator(status: status);
              },
            ),
            const SizedBox(width: 12),
            _buildActionIcon(theme, Icons.sync, () => syncEngine.triggerSync()),
            const SizedBox(width: 12),
            _buildActionIcon(
              theme,
              Icons.person_outline_rounded,
              () => context.push('/account'),
            ),
            const SizedBox(width: 12),
          ],
        );
      },
    );
  }

  void _showMembersList(BuildContext context, ProjectsState initialState) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => BlocBuilder<ProjectsBloc, ProjectsState>(
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'current_members'.tr(),
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.projectMembers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'no_members'.tr(),
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.projectMembers.length,
                        itemBuilder: (context, index) {
                          final member = state.projectMembers[index];
                          final currentUserId =
                              Supabase.instance.client.auth.currentUser?.id;
                          final isOwner =
                              state.currentProject?.ownerId == currentUserId;
                          final isMemberThemselves =
                              member['user_id'] == currentUserId;
                          final invitedByCurrentUser =
                              member['invited_by'] == currentUserId;

                          final isTargetOwner =
                              member['user_id'] == state.currentProject?.ownerId;

                          final canRemove = !isTargetOwner &&
                              (isOwner ||
                                  isMemberThemselves ||
                                  invitedByCurrentUser);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withAlpha(20),
                              child: Text(
                                (member['name'] as String?)?[0].toUpperCase() ??
                                    'U',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              member['name'] ?? '',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member['email'] ?? '',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (member['accepted_at'] != null)
                                  Text(
                                    '${'joined'.tr()}: ${DateFormat('dd MMM yyyy', context.locale.toString()).format(DateTime.parse(member['accepted_at']))}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                else
                                  Text(
                                    'pending'.tr(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: Colors.orange,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (member['user_id'] ==
                                            state.currentProject?.ownerId)
                                        ? theme.colorScheme.secondary.withAlpha(
                                            20,
                                          )
                                        : theme.colorScheme.primary.withAlpha(
                                            10,
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (member['user_id'] ==
                                            state.currentProject?.ownerId)
                                        ? 'owner'.tr()
                                        : (member['role'] as String).tr(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          (member['user_id'] ==
                                              state.currentProject?.ownerId)
                                          ? theme.colorScheme.secondary
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                if (canRemove)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      context.read<ProjectsBloc>().add(
                                        RemoveProjectMember(
                                          member['member_id'],
                                        ),
                                      );
                                      if (isMemberThemselves) {
                                        Navigator.pop(
                                          context,
                                        ); // Close sheet if leaving
                                      }
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionIcon(ThemeData theme, IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
      ),
    );
  }

  void _showProjectPicker(BuildContext context, ProjectsState state) {
    final theme = Theme.of(context);
    final allProjects = [...state.projects, ...state.sharedProjects];
    final bloc = context.read<ProjectsBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'select_project'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: allProjects.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = state.currentProject == null;
                      return ListTile(
                        leading: Icon(
                          Icons.person_pin_rounded,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                        title: Text(
                          'personal_workspace'.tr(),
                          style: GoogleFonts.outfit(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? theme.colorScheme.primary : null,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.drive_file_rename_outline_rounded,
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.pop(bottomSheetContext);
                                _showRenamePersonalDialog(context, bloc);
                              },
                              tooltip: 'rename_personal'.tr(),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_rounded,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                        onTap: () {
                          bloc.add(SwitchProject(''));
                          Navigator.pop(bottomSheetContext);
                        },
                      );
                    }
                    if (index == allProjects.length + 1) {
                      return ListTile(
                        leading: const Icon(Icons.add_rounded),
                        title: Text('create_new_project'.tr()),
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _showCreateProjectDialog(context, bloc);
                        },
                      );
                    }
                    final project = allProjects[index - 1];
                    final isSelected = project.id == state.currentProject?.id;
                    return ListTile(
                      leading: Icon(
                        project.ownerId ==
                                Supabase.instance.client.auth.currentUser?.id
                            ? Icons.folder_rounded
                            : Icons.folder_shared_rounded,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                      title: Text(
                        project.name.tr(),
                        style: GoogleFonts.outfit(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        bloc.add(SwitchProject(project.id));
                        Navigator.pop(bottomSheetContext);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenamePersonalDialog(BuildContext context, ProjectsBloc bloc) {
    final nameController = TextEditingController()
      ..text = 'G-spend'.tr(); // Default name

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('convert_personal_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'convert_personal_message'.tr(),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'name'.tr(),
                hintText: 'Work, Vacation, etc.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                bloc.add(ConvertPersonalToProject(nameController.text));
                Navigator.pop(c);
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context, ProjectsBloc bloc) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('new_project'.tr()),
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
                bloc.add(
                  AddProject(
                    name: nameController.text,
                    description: descController.text,
                  ),
                );
                Navigator.pop(c);
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }
}
