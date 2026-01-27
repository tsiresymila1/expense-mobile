import 'package:expense/data/local/database.dart';

class ProjectsState {
  final List<LocalProject> projects;
  final List<LocalProject> sharedProjects;
  final LocalProject? currentProject;
  final List<Map<String, dynamic>> searchResults;
  final List<Map<String, dynamic>> projectMembers;
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
    this.isLoading = false,
    this.isSearching = false,
    this.isLoadingMembers = false,
    this.error,
  });

  ProjectsState copyWith({
    List<LocalProject>? projects,
    List<LocalProject>? sharedProjects,
    LocalProject? currentProject,
    List<Map<String, dynamic>>? searchResults,
    List<Map<String, dynamic>>? projectMembers,
    bool? isLoading,
    bool? isSearching,
    bool? isLoadingMembers,
    String? error,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      sharedProjects: sharedProjects ?? this.sharedProjects,
      currentProject: currentProject ?? this.currentProject,
      searchResults: searchResults ?? this.searchResults,
      projectMembers: projectMembers ?? this.projectMembers,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      isLoadingMembers: isLoadingMembers ?? this.isLoadingMembers,
      error: error,
    );
  }
}
