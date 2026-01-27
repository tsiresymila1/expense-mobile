import 'package:expense/data/local/database.dart';

class ProjectsState {
  final List<LocalProject> projects;
  final List<LocalProject> sharedProjects;
  final LocalProject? currentProject;
  final List<Map<String, dynamic>> searchResults;
  final bool isLoading;
  final bool isSearching;
  final String? error;

  ProjectsState({
    this.projects = const [],
    this.sharedProjects = const [],
    this.currentProject,
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
  });

  ProjectsState copyWith({
    List<LocalProject>? projects,
    List<LocalProject>? sharedProjects,
    LocalProject? currentProject,
    List<Map<String, dynamic>>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? error,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      sharedProjects: sharedProjects ?? this.sharedProjects,
      currentProject: currentProject ?? this.currentProject,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}
