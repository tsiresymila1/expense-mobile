// Events
abstract class ProjectsEvent {}

class LoadProjects extends ProjectsEvent {}

class SwitchProject extends ProjectsEvent {
  final String projectId;
  SwitchProject(this.projectId);
}

class AddProject extends ProjectsEvent {
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  AddProject({required this.name, this.description, this.color, this.icon});
}

class UpdateProject extends ProjectsEvent {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  UpdateProject({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.icon,
  });
}

class DeleteProject extends ProjectsEvent {
  final String id;
  DeleteProject(this.id);
}

class InviteToProject extends ProjectsEvent {
  final String projectId;
  final String email;
  final String role;
  InviteToProject({
    required this.projectId,
    required this.email,
    this.role = 'viewer',
  });
}

class SearchProfiles extends ProjectsEvent {
  final String query;
  SearchProfiles(this.query);
}

class RemoveProjectMember extends ProjectsEvent {
  final String memberId;
  RemoveProjectMember(this.memberId);
}

class LoadProjectMembers extends ProjectsEvent {
  final String projectId;
  LoadProjectMembers(this.projectId);
}

class ConvertPersonalToProject extends ProjectsEvent {
  final String name;
  ConvertPersonalToProject(this.name);
}
