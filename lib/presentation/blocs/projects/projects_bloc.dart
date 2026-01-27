import 'package:drift/drift.dart';
import 'package:expense/data/local/database.dart';
import 'package:expense/sync_engine/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'projects_event.dart';
import 'projects_state.dart';

export 'projects_event.dart';
export 'projects_state.dart';

class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  final AppDatabase database;
  final SyncEngine syncEngine;
  final SupabaseClient supabase;

  ProjectsBloc({
    required this.database,
    required this.syncEngine,
    required this.supabase,
  }) : super(ProjectsState()) {
    on<LoadProjects>(_onLoad);
    on<SwitchProject>(_onSwitch);
    on<AddProject>(_onAdd);
    on<UpdateProject>(_onUpdate);
    on<DeleteProject>(_onDelete);
    on<InviteToProject>(_onInvite);
    on<SearchProfiles>(_onSearchProfiles);
  }

  Future<void> _onSearchProfiles(SearchProfiles event, Emitter<ProjectsState> emit) async {
    if (event.query.length < 2) {
      emit(state.copyWith(searchResults: []));
      return;
    }

    emit(state.copyWith(isSearching: true));
    final userId = supabase.auth.currentUser?.id;
    try {
      final results = await supabase
          .from('profiles')
          .select('id, name, email')
          .or('name.ilike.%${event.query}%,email.ilike.%${event.query}%')
          .limit(10);

      final filtered = results.where((r) => r['id'] != userId).toList();

      emit(state.copyWith(
        searchResults: List<Map<String, dynamic>>.from(filtered),
        isSearching: false,
      ));
    } catch (e) {
      debugPrint('Error searching profiles: $e');
      emit(state.copyWith(isSearching: false));
    }
  }

  Future<void> _onLoad(LoadProjects event, Emitter<ProjectsState> emit) async {
    emit(state.copyWith(isLoading: true));
    final userId = supabase.auth.currentUser?.id ?? '';

    try {
      // Load owned projects
      final ownedProjects = await (database.select(database.localProjects)
            ..where((t) => t.ownerId.equals(userId) & t.deletedAt.isNull()))
          .get();

      // Load shared projects (where I am a member but not owner)
      // This requires a join or a subquery. 
      // For now, let's just use the localProjectMembers table.
      final memberships = await (database.select(database.localProjectMembers)
            ..where((t) => t.userId.equals(userId)))
          .get();
      
      final sharedProjectIds = memberships.map((m) => m.projectId).toList();
      
      final sharedProjects = await (database.select(database.localProjects)
            ..where((t) => t.id.isIn(sharedProjectIds) & t.ownerId.equals(userId).not() & t.deletedAt.isNull()))
          .get();

      LocalProject? current = state.currentProject;
      if (current == null || ![...ownedProjects, ...sharedProjects].any((p) => p.id == current!.id)) {
        // Default to the project marked as isDefault, or the first one available
        current = ownedProjects.firstWhere(
          (p) => p.isDefault,
          orElse: () => ownedProjects.isNotEmpty 
            ? ownedProjects.first 
            : sharedProjects.isNotEmpty ? sharedProjects.first : null as dynamic,
        );
      }

      emit(state.copyWith(
        projects: ownedProjects,
        sharedProjects: sharedProjects,
        currentProject: current,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSwitch(SwitchProject event, Emitter<ProjectsState> emit) async {
    final all = [...state.projects, ...state.sharedProjects];
    try {
      final target = all.firstWhere((p) => p.id == event.projectId);
      emit(state.copyWith(currentProject: target));
    } catch (_) {
      // If not found, keep current
    }
  }

  Future<void> _onAdd(AddProject event, Emitter<ProjectsState> emit) async {
    final userId = supabase.auth.currentUser?.id ?? '';
    try {
      final id = const Uuid().v4();
      final now = DateTime.now();
      
      await database.into(database.localProjects).insert(
            LocalProjectsCompanion.insert(
              id: id,
              ownerId: userId,
              name: event.name,
              description: Value(event.description),
              color: Value(event.color),
              icon: Value(event.icon),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database.into(database.syncQueue).insert(
            SyncQueueCompanion.insert(
              userId: userId,
              targetTable: 'projects',
              rowId: id,
              operation: 'INSERT',
              createdAt: now,
            ),
          );

      syncEngine.triggerSync();
      add(LoadProjects());
    } catch (e) {
      debugPrint('Error adding project: $e');
    }
  }

  Future<void> _onUpdate(UpdateProject event, Emitter<ProjectsState> emit) async {
    final userId = supabase.auth.currentUser?.id ?? '';
    try {
      final now = DateTime.now();
      await (database.update(database.localProjects)
            ..where((t) => t.id.equals(event.id)))
          .write(
        LocalProjectsCompanion(
          name: Value(event.name),
          description: Value(event.description),
          color: Value(event.color),
          icon: Value(event.icon),
          updatedAt: Value(now),
        ),
      );

      await database.into(database.syncQueue).insert(
            SyncQueueCompanion.insert(
              userId: userId,
              targetTable: 'projects',
              rowId: event.id,
              operation: 'UPDATE',
              createdAt: now,
            ),
          );

      syncEngine.triggerSync();
      add(LoadProjects());
    } catch (e) {
      debugPrint('Error updating project: $e');
    }
  }

  Future<void> _onDelete(DeleteProject event, Emitter<ProjectsState> emit) async {
    final userId = supabase.auth.currentUser?.id ?? '';
    try {
      final now = DateTime.now();
      await (database.update(database.localProjects)
            ..where((t) => t.id.equals(event.id)))
          .write(
        LocalProjectsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await database.into(database.syncQueue).insert(
            SyncQueueCompanion.insert(
              userId: userId,
              targetTable: 'projects',
              rowId: event.id,
              operation: 'UPDATE',
              createdAt: now,
            ),
          );

      syncEngine.triggerSync();
      add(LoadProjects());
    } catch (e) {
      debugPrint('Error deleting project: $e');
    }
  }

  Future<void> _onInvite(InviteToProject event, Emitter<ProjectsState> emit) async {
    final currentUserId = supabase.auth.currentUser?.id ?? '';
    try {
      // 1. Find user by email in profiles
      final response = await supabase
          .from('profiles')
          .select('id')
          .eq('email', event.email)
          .maybeSingle();

      if (response == null) {
        emit(state.copyWith(error: 'User not found'));
        return;
      }

      final targetUserId = response['id'] as String;
      if (targetUserId == currentUserId) {
        emit(state.copyWith(error: 'Cannot share with yourself'));
        return;
      }
      final id = const Uuid().v4();
      final now = DateTime.now();

      // 2. Add to project_members
      await database.into(database.localProjectMembers).insert(
            LocalProjectMembersCompanion.insert(
              id: id,
              projectId: event.projectId,
              userId: targetUserId,
              role: Value(event.role),
              invitedBy: Value(currentUserId),
              invitedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 3. Add to sync queue
      await database.into(database.syncQueue).insert(
            SyncQueueCompanion.insert(
              userId: currentUserId,
              targetTable: 'project_members',
              rowId: id,
              operation: 'INSERT',
              createdAt: now,
            ),
          );

      syncEngine.triggerSync();
      emit(state.copyWith(error: null)); // Clear error if success
    } catch (e) {
      debugPrint('Error inviting to project: $e');
      emit(state.copyWith(error: e.toString()));
    }
  }
}
