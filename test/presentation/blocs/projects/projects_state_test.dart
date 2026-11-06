import 'package:expense/data/models/models.dart';
import 'package:expense/presentation/blocs/projects/projects_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith can clear the current project for personal workspace', () {
    final project = Project(
      id: 'project-1',
      ownerId: 'user-1',
      name: 'Project',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final state = ProjectsState(currentProject: project);

    final personalState = state.copyWith(currentProject: null);

    expect(personalState.currentProject, isNull);
  });
}
