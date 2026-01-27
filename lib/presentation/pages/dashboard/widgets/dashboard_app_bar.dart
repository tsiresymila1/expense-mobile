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
    final userName = user?.userMetadata?['name'] ?? 'User';

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
                        '${'welcome_back'.tr()}, $userName',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: () => _showProjectPicker(context, state),
                        child: Row(
                          children: [
                            Text(
                              currentProject?.name ?? 'G-spend'.tr(),
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
            _buildActionIcon(
              theme,
              Icons.settings_outlined,
              () => context.push('/settings'),
            ),
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

  Widget _buildActionIcon(ThemeData theme, IconData icon, VoidCallback onTap) {
    return InkWell(
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
                  itemCount: allProjects.length + 1,
                  itemBuilder: (context, index) {
                    if (index == allProjects.length) {
                      return ListTile(
                        leading: const Icon(Icons.add_rounded),
                        title: Text('create_new_project'.tr()),
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _showCreateProjectDialog(context, bloc);
                        },
                      );
                    }
                    final project = allProjects[index];
                    final isSelected = project.id == state.currentProject?.id;
                    return ListTile(
                      leading: Icon(
                        project.ownerId == Supabase.instance.client.auth.currentUser?.id
                            ? Icons.folder_rounded
                            : Icons.folder_shared_rounded,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                      title: Text(
                        project.name,
                        style: GoogleFonts.outfit(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
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
          TextButton(onPressed: () => Navigator.pop(c), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                bloc.add(AddProject(
                  name: nameController.text,
                  description: descController.text,
                ));
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
