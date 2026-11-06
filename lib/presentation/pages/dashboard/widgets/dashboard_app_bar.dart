import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/auth/auth_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/pages/dashboard/widgets/sync_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardAppBar extends StatelessWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName =
        context.watch<AuthCubit>().state.displayName ??
        'user_profile_fallback'.tr();

    return BlocBuilder<ProjectsCubit, ProjectsState>(
      builder: (context, state) {
        final currentProject = state.currentProject;

        return SliverAppBar(
          expandedHeight: 140,
          floating: false,
          pinned: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          flexibleSpace: LayoutBuilder(
            builder: (context, constraints) {
              final top = constraints.biggest.height;
              const expandedHeight = 140.0;
              final toolbarHeight =
                  MediaQuery.of(context).padding.top + kToolbarHeight;

              // Collapse progress (1.0 = fully expanded, 0.0 = collapsed)
              final progress =
                  ((top - toolbarHeight) / (expandedHeight - toolbarHeight))
                      .clamp(0.0, 1.0);

              // Opacity fades out faster than the collapse
              final opacity = (progress * 2 - 1).clamp(0.0, 1.0);

              return FlexibleSpaceBar(
                title: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (opacity > 0.1)
                            Opacity(
                              opacity: opacity,
                              child: Text(
                                '${'welcome_back'.tr()} ${userName.toString().padRight(10, '.').substring(0, 10)}',
                                style: GoogleFonts.geist(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
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
                                      currentProject?.name.tr() ??
                                          'personal_workspace'.tr(),
                                      style: GoogleFonts.geist(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
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
                                if (state.projectMembers.isNotEmpty &&
                                    opacity > 0.1)
                                  Opacity(
                                    opacity: opacity,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: InkWell(
                                        onTap: () =>
                                            _showMembersList(context, state),
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox(
                                          height: 20,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width:
                                                    (state.projectMembers.length >
                                                                5
                                                            ? 5
                                                            : state
                                                                  .projectMembers
                                                                  .length) *
                                                        15.0 +
                                                    10,
                                                child: Stack(
                                                  children: List.generate(
                                                    state
                                                                .projectMembers
                                                                .length >
                                                            5
                                                        ? 5
                                                        : state
                                                              .projectMembers
                                                              .length,
                                                    (i) => Positioned(
                                                      left: i * 15.0,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
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
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (state.projectMembers.length >
                                                  5)
                                                Text(
                                                  '+${state.projectMembers.length - 5}',
                                                  style: GoogleFonts.geist(
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
              );
            },
          ),
          actions: [
            const SyncIndicator(),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => BlocBuilder<ProjectsCubit, ProjectsState>(
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
                    style: GoogleFonts.geist(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.projectMembers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'no_members'.tr(),
                          style: GoogleFonts.geist(color: Colors.grey),
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
                          final currentUserId = InstantProvider.of(
                            context,
                          ).auth.currentUser.value?.id;
                          final isOwner =
                              state.currentProject?.ownerId == currentUserId;
                          final isMemberThemselves =
                              member['user_id'] == currentUserId;
                          final invitedByCurrentUser =
                              member['invited_by'] == currentUserId;

                          final isTargetOwner =
                              member['user_id'] ==
                              state.currentProject?.ownerId;

                          final canRemove =
                              !isTargetOwner &&
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
                              style: GoogleFonts.geist(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member['email'] ?? '',
                                  style: GoogleFonts.geist(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
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
                                      context
                                          .read<ProjectsCubit>()
                                          .removeProjectMember(
                                            member['member_id'],
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
    final cubit = context.read<ProjectsCubit>();
    final currentUserId = InstantProvider.of(
      context,
    ).auth.currentUser.value?.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
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
                  style: GoogleFonts.geist(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: allProjects.length + 3,
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
                          style: GoogleFonts.geist(
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          cubit.switchProject('');
                          Navigator.pop(bottomSheetContext);
                        },
                      );
                    }
                    if (index == allProjects.length + 1) {
                      return ListTile(
                        leading: const Icon(Icons.drive_file_move_outline),
                        title: Text('convert_personal_workspace'.tr()),
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _showConvertPersonalDialog(context, cubit);
                        },
                      );
                    }
                    if (index == allProjects.length + 2) {
                      return ListTile(
                        leading: const Icon(Icons.add_rounded),
                        title: Text('create_new_project'.tr()),
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _showCreateProjectDialog(context, cubit);
                        },
                      );
                    }
                    final project = allProjects[index - 1];
                    final isSelected = project.id == state.currentProject?.id;
                    return ListTile(
                      leading: Icon(
                        project.ownerId == currentUserId
                            ? Icons.folder_rounded
                            : Icons.folder_shared_rounded,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                      title: Text(
                        project.name.tr(),
                        style: GoogleFonts.geist(
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.w500,
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
                        cubit.switchProject(project.id);
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

  void _showConvertPersonalDialog(BuildContext context, ProjectsCubit cubit) {
    var projectName = 'G-spend'.tr();
    var isSubmitting = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text('convert_personal_title'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'convert_personal_message'.tr(),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: projectName,
                onChanged: (value) => projectName = value,
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
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = projectName.trim();
                      if (name.isEmpty) return;
                      setDialogState(() => isSubmitting = true);
                      final converted = await cubit.convertPersonalToProject(
                        name,
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      if (!converted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              cubit.state.error ??
                                  'no_personal_expenses_to_convert'.tr(),
                            ),
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('save'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context, ProjectsCubit cubit) {
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
                cubit.addProject(
                  name: nameController.text,
                  description: descController.text,
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
