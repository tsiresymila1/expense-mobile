import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class ProjectShortcuts extends StatelessWidget {
  const ProjectShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ProjectsBloc, ProjectsState>(
      builder: (context, state) {
        final all = [...state.projects, ...state.sharedProjects];
        if (all.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: all.length + 1,
            itemBuilder: (context, index) {
              if (index == all.length) {
                return _buildAddShortcut(context, theme);
              }

              final project = all[index];
              final isSelected = project.id == state.currentProject?.id;

              return _buildProjectShortcut(context, theme, project, isSelected)
                  .animate()
                  .fadeIn(delay: (index * 50).ms, duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutExpo)
                  .moveX(begin: 20, end: 0, curve: Curves.easeOutExpo);
            },
          ),
        );
      },
    );
  }

  Widget _buildProjectShortcut(
    BuildContext context,
    ThemeData theme,
    dynamic project,
    bool isSelected,
  ) {
    final color = project.color != null 
        ? _parseColor(project.color!) 
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          context.read<ProjectsBloc>().add(SwitchProject(project.id));
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                (project.icon ?? project.name[0]).toUpperCase(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  project.name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddShortcut(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          context.push('/projects');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.add_rounded,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      }
      return Color(int.parse(colorStr));
    } catch (_) {
      return Colors.blue;
    }
  }
}
