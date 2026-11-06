import 'package:expense/data/models/models.dart';

Project? resolveCurrentProject({
  required List<Project> ownedProjects,
  required List<Project> sharedProjects,
  required String? selectedId,
  required bool personalWorkspaceSelected,
}) {
  if (personalWorkspaceSelected) return null;

  final allProjects = [...ownedProjects, ...sharedProjects];
  if (selectedId != null) {
    for (final project in allProjects) {
      if (project.id == selectedId) return project;
    }
  }

  for (final project in ownedProjects) {
    if (project.isDefault) return project;
  }
  if (ownedProjects.isNotEmpty) return ownedProjects.first;
  if (sharedProjects.isNotEmpty) return sharedProjects.first;
  return null;
}
