import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
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
  RealtimeChannel? _realtimeChannel;

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
    on<LoadProjectMembers>(_onLoadMembers);
    on<RemoveProjectMember>(_onRemoveMember);
    on<ConvertPersonalToProject>(_onConvertPersonalToProject);
  }


  Future<void> _onConvertPersonalToProject(
    ConvertPersonalToProject event,
    Emitter<ProjectsState> emit,
  ) async {
    final userId = supabase.auth.currentUser?.id ?? '';
    final projectId = const Uuid().v4();
    final now = DateTime.now();

    try {
      emit(state.copyWith(isLoading: true));

      // 1. Create Project
      final project = LocalProject(
        id: projectId,
        ownerId: userId,
        name: event.name,
        color: Colors.blue.value.toString(),
        createdAt: now,
        updatedAt: now,
        isDefault: false,
      );

      await database.into(database.localProjects).insert(project);

      // 2. Queue Project Create
      await database.into(database.syncQueue).insert(
            SyncQueueCompanion.insert(
              userId: userId,
              targetTable: 'projects',
              rowId: projectId,
              operation: 'INSERT',
              createdAt: now,
            ),
          );

      // 3. Move Personal Expenses to this Project
      // Personal Expenses: userId == me AND projectId IS NULL (and not deleted)
      // Actually, we must be careful. We only want to move ACTIVE personal expenses?
      // Yes, usually.
      
      final personalConfig = database.select(database.localExpenses)
        ..where((t) => t.userId.equals(userId) & t.projectId.isNull() & t.deletedAt.isNull());
      
      final personalExpenses = await personalConfig.get();

      for (var expense in personalExpenses) {
        await (database.update(database.localExpenses)
              ..where((t) => t.id.equals(expense.id)))
            .write(LocalExpensesCompanion(
              projectId: Value(projectId),
              updatedAt: Value(now),
            ));
        
        // Queue Update for Expense
        await database.into(database.syncQueue).insert(
              SyncQueueCompanion.insert(
                userId: userId,
                targetTable: 'expenses',
                rowId: expense.id,
                operation: 'UPDATE',
                createdAt: now,
              ),
            );
      }

      // 4. Trigger Sync
      syncEngine.triggerSync();

      // 5. Reload projects and switch
      add(LoadProjects());
      add(SwitchProject(projectId));
      
    } catch (e) {
      debugPrint('Error converting personal to project: $e');
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  @override
  Future<void> close() {
    if (_realtimeChannel != null) {
      supabase.removeChannel(_realtimeChannel!);
    }
    return super.close();
  }

  void _setupRealtimeSubscription(String projectId) {
    if (_realtimeChannel != null) {
      supabase.removeChannel(_realtimeChannel!);
    }
    
    _realtimeChannel = supabase
        .channel('members_$projectId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'project_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'project_id',
            value: projectId,
          ),
          callback: (payload) {
            debugPrint('Realtime Change: ${payload.eventType} in project_members');
            add(LoadProjectMembers(projectId));
          },
        );
    
    _realtimeChannel!.subscribe();
  }

  Future<void> _onLoadMembers(LoadProjectMembers event, Emitter<ProjectsState> emit) async {
    debugPrint('ProjectsBloc: Loading members for project ${event.projectId} locally');
    emit(state.copyWith(isLoadingMembers: true));
    
    try {
      // Load members joined with profiles locally
      final query = database.select(database.localProjectMembers).join([
        leftOuterJoin(
          database.localProfiles,
          database.localProfiles.id.equalsExp(database.localProjectMembers.userId),
        ),
      ])..where(database.localProjectMembers.projectId.equals(event.projectId));

      final rows = await query.get();
      
      final members = rows.map((row) {
        final member = row.readTable(database.localProjectMembers);
        final profile = row.readTableOrNull(database.localProfiles);
        
        return {
          'member_id': member.id,
          'user_id': member.userId,
          'role': member.role,
          'invited_by': member.invitedBy,
          'accepted_at': member.acceptedAt?.toIso8601String(),
          'name': profile?.name ?? 'Unknown User',
          'email': profile?.email ?? 'No email',
        };
      }).toList();

      // Ensure Owner is in the list
      final currentProject = state.projects.firstWhere(
            (p) => p.id == event.projectId, 
            orElse: () => state.sharedProjects.firstWhere((p) => p.id == event.projectId),
      );
      
      final ownerInList = members.any((m) => m['user_id'] == currentProject.ownerId);
      if (!ownerInList) {
        // Fetch owner profile
        final ownerProfile = await (database.select(database.localProfiles)
          ..where((t) => t.id.equals(currentProject.ownerId)))
          .getSingleOrNull();

        if (ownerProfile != null) {
          members.insert(0, {
             'member_id': 'owner_placeholder', // Dummy ID
             'user_id': currentProject.ownerId,
             'role': 'owner',
             'invited_by': null,
             'accepted_at': currentProject.createdAt.toIso8601String(),
             'name': ownerProfile.name,
             'email': ownerProfile.email,
          });
        }
      }

      emit(state.copyWith(
        projectMembers: members,
        isLoadingMembers: false,
      ));
    } catch (e) {
      debugPrint('Error loading project members: $e');
      emit(state.copyWith(isLoadingMembers: false));
    }
  }

  Future<void> _onSearchProfiles(SearchProfiles event, Emitter<ProjectsState> emit) async {
    if (event.query.length < 2) {
      emit(state.copyWith(searchResults: []));
      return;
    }

    emit(state.copyWith(isSearching: true));
    final userId = supabase.auth.currentUser?.id;
    try {
      // Search in local profiles for offline-first
      final query = database.select(database.localProfiles)
        ..where((t) => t.name.contains(event.query) | t.email.contains(event.query))
        ..limit(10);
      
      final results = await query.get();
      final filtered = results.where((r) => r.id != userId).toList();

      emit(state.copyWith(
        searchResults: filtered.map((p) => {
          'id': p.id,
          'name': p.name,
          'email': p.email,
        }).toList(),
        isSearching: false,
      ));
      
      // Optional: Background fetch from remote to pull new profiles if online
      _backgroundFetchProfiles(event.query);
      
    } catch (e) {
      debugPrint('Error searching profiles: $e');
      emit(state.copyWith(isSearching: false));
    }
  }

  Future<void> _backgroundFetchProfiles(String query) async {
    try {
      final results = await supabase
          .from('profiles')
          .select('id, name, email, updated_at')
          .or('name.ilike.%$query%,email.ilike.%$query%')
          .limit(10);
      
      for (final r in results) {
        await database.into(database.localProfiles).insertOnConflictUpdate(
          LocalProfilesCompanion.insert(
            id: r['id'],
            name: r['name'] ?? 'Unknown',
            email: r['email'] ?? '',
            updatedAt: DateTime.parse(r['updated_at']),
          ),
        );
      }
    } catch (_) {}
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

      add(LoadProjectMembers(current.id));
      _setupRealtimeSubscription(current.id);
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSwitch(SwitchProject event, Emitter<ProjectsState> emit) async {
    if (event.projectId.isEmpty) {
      emit(state.copyWith(currentProject: null, projectMembers: []));
      if (_realtimeChannel != null) {
        supabase.removeChannel(_realtimeChannel!);
        _realtimeChannel = null;
      }
      return;
    }

    final all = [...state.projects, ...state.sharedProjects];
    try {
      final target = all.firstWhere((p) => p.id == event.projectId);
      emit(state.copyWith(currentProject: target));
      add(LoadProjectMembers(event.projectId));
      _setupRealtimeSubscription(event.projectId);
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
      // 1. Find user by email in local profiles ONLY (Offline-first)
      final localProfile = await (database.select(database.localProfiles)
            ..where((t) => t.email.equals(event.email)))
          .getSingleOrNull();

      if (localProfile == null) {
        emit(state.copyWith(error: 'user_not_found_local'.tr()));
        return;
      }

      final targetUserId = localProfile.id;
      final targetName = localProfile.name;
      final targetEmail = localProfile.email;

      if (targetUserId == currentUserId) {
        emit(state.copyWith(error: 'cannot_share_self'.tr()));
        return;
      }

      // Check if already a member locally to avoid duplicates
      final existing = await (database.select(database.localProjectMembers)
            ..where((t) => t.projectId.equals(event.projectId) & t.userId.equals(targetUserId)))
          .getSingleOrNull();

      if (existing != null) {
        emit(state.copyWith(error: 'already_member_error'.tr()));
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
              acceptedAt: Value(now), // Auto-accept to avoid pending state
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Update state immediately for instant feedback
      final newMember = {
        'member_id': id,
        'user_id': targetUserId,
        'role': event.role,
        'invited_by': currentUserId,
        'accepted_at': now.toIso8601String(),
        'name': targetName,
        'email': targetEmail,
      };
      
      final updatedMembers = [...state.projectMembers, newMember];
      emit(state.copyWith(
        projectMembers: updatedMembers,
        error: null,
      ));

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
      // Optionally reload to ensure sync went well
      add(LoadProjectMembers(event.projectId));
    } catch (e) {
      debugPrint('Error inviting to project: $e');
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRemoveMember(RemoveProjectMember event, Emitter<ProjectsState> emit) async {
    final currentUserId = supabase.auth.currentUser?.id ?? '';
    try {
      // 1. Get member details before removal to find project_id
      final member = await (database.select(database.localProjectMembers)
            ..where((t) => t.id.equals(event.memberId)))
          .getSingleOrNull();
      
      if (member == null) return;

      final projectId = member.projectId;

      // 2. Delete from local DB
      await (database.delete(database.localProjectMembers)
            ..where((t) => t.id.equals(event.memberId)))
          .go();

      // Update state immediately for instant UI feedback
      final updatedMembers = state.projectMembers
          .where((m) => m['member_id'] != event.memberId)
          .toList();
      emit(state.copyWith(projectMembers: updatedMembers));

      // 3. Add to sync queue for remote deletion
      await database.into(database.syncQueue).insert(
            SyncQueueCompanion.insert(
              userId: currentUserId,
              targetTable: 'project_members',
              rowId: event.memberId,
              operation: 'DELETE',
              createdAt: DateTime.now(),
            ),
          );

      syncEngine.triggerSync();
      
      // If the user removed themselves, we might need to refresh projects list
      if (member.userId == currentUserId) {
        add(LoadProjects());
      } else {
        // Optional: reload from remote to be sure, but we already updated UI
        add(LoadProjectMembers(projectId));
      }
    } catch (e) {
      debugPrint('Error removing member: $e');
    }
  }
}
