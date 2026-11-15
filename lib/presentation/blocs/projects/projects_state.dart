import 'package:expense/data/models/models.dart';

const _currentProjectNotProvided = Object();

class ProjectsState {
  final List<Project> projects;
  final List<Project> sharedProjects;
  final Project? currentProject;
  final List<Map<String, dynamic>> searchResults;
  final List<Map<String, dynamic>> projectMembers;

  /// Invitations addressed to the signed-in user, waiting for a decision.
  final List<Map<String, dynamic>> pendingInvitations;
  final bool isLoading;
  final bool isSearching;
  final bool isLoadingMembers;
  final String? error;

  ProjectsState({
    this.projects = const [],
    this.sharedProjects = const [],
    this.currentProject,
    this.searchResults = const [],
    this.projectMembers = const [],
    this.pendingInvitations = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.isLoadingMembers = false,
    this.error,
  });

  ProjectsState copyWith({
    List<Project>? projects,
    List<Project>? sharedProjects,
    Object? currentProject = _currentProjectNotProvided,
    List<Map<String, dynamic>>? searchResults,
    List<Map<String, dynamic>>? projectMembers,
    List<Map<String, dynamic>>? pendingInvitations,
    bool? isLoading,
    bool? isSearching,
    bool? isLoadingMembers,
    String? error,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      sharedProjects: sharedProjects ?? this.sharedProjects,
      currentProject: identical(currentProject, _currentProjectNotProvided)
          ? this.currentProject
          : currentProject as Project?,
      searchResults: searchResults ?? this.searchResults,
      projectMembers: projectMembers ?? this.projectMembers,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      isLoadingMembers: isLoadingMembers ?? this.isLoadingMembers,
      error: error,
    );
  }
}
