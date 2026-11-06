import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/projects/project_selection.dart';
import 'package:flutter_test/flutter_test.dart';

Project project(String id, {bool isDefault = false}) => Project(
  id: id,
  ownerId: 'user-1',
  name: id,
  isDefault: isDefault,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  test('explicit personal workspace selection resolves to no project', () {
    final result = resolveCurrentProject(
      ownedProjects: [project('project-1', isDefault: true)],
      sharedProjects: const [],
      selectedId: null,
      personalWorkspaceSelected: true,
    );

    expect(result, isNull);
  });

  test('uses the selected project when personal workspace is not selected', () {
    final selected = project('project-2');

    final result = resolveCurrentProject(
      ownedProjects: [project('project-1'), selected],
      sharedProjects: const [],
      selectedId: selected.id,
      personalWorkspaceSelected: false,
    );

    expect(result, same(selected));
  });
}
