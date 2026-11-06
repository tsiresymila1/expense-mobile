import 'dart:async';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';
import 'package:expense/data/models/models.dart';
import 'project_selection.dart';
import 'projects_state.dart';

export 'projects_state.dart';

/// Projects + membership over InstantDB. One reactive subscription over
/// projects/members/profiles; owned/shared/members are derived client-side and
/// re-emitted on any realtime change (replaces the old per-project Supabase
/// channel + sync-success reload).
class ProjectsCubit extends Cubit<ProjectsState> {
  final InstantDB db;
  void Function()? _queryDispose;
  late final StreamSubscription<AuthUser?> _authSub;

  List<Project> _allProjects = [];
  List<ProjectMember> _allMembers = [];
  List<Profile> _allProfiles = [];
  String? _selectedId;
  bool _personalWorkspaceSelected = false;
  String _search = '';

  ProjectsCubit({required this.db}) : super(ProjectsState()) {
    _subscribe();
    _authSub = db.auth.onAuthStateChange.listen((_) => _subscribe());
  }

  String? get _uid => db.auth.currentUser.value?.id;

  void _subscribe() {
    _queryDispose?.call();
    emit(state.copyWith(isLoading: true));
    final sig = db.subscribeQuery({
      'projects': {},
      'members': {},
      'profiles': {},
    });
    _queryDispose = effect(() {
      final res = sig.value;
      final data = res.data ?? {};
      _allProjects = mapList(data['projects'], Project.fromMap);
      _allMembers = mapList(data['members'], ProjectMember.fromMap);
      _allProfiles = mapList(data['profiles'], Profile.fromMap);
      _recompute();
    });
  }

  /// Kept for call-site compatibility; the subscription already keeps data live.
  void loadProjects() => _recompute();

  void _recompute() {
    final uid = _uid ?? '';
    final owned = _allProjects.where((p) => p.ownerId == uid).toList();
    final myMemberships = _allMembers
        .where((m) => m.userId == uid)
        .map((m) => m.projectId)
        .toSet();
    final shared = _allProjects
        .where((p) => p.ownerId != uid && myMemberships.contains(p.id))
        .toList();

    final current = resolveCurrentProject(
      ownedProjects: owned,
      sharedProjects: shared,
      selectedId: _selectedId,
      personalWorkspaceSelected: _personalWorkspaceSelected,
    );
    _selectedId = current?.id;

    emit(
      state.copyWith(
        projects: owned,
        sharedProjects: shared,
        currentProject: current,
        searchResults: _computeSearch(uid),
        projectMembers: current == null ? [] : _membersFor(current),
        isLoading: false,
        isLoadingMembers: false,
        isSearching: false,
      ),
    );
  }

  List<Map<String, dynamic>> _membersFor(Project project) {
    final profileById = {for (final p in _allProfiles) p.id: p};
    final members = _allMembers.where((m) => m.projectId == project.id).map((
      m,
    ) {
      final profile = profileById[m.userId];
      return {
        'member_id': m.id,
        'user_id': m.userId,
        'role': m.role,
        'invited_by': m.invitedBy,
        'accepted_at': m.acceptedAt?.toIso8601String(),
        'name': profile?.name ?? 'Unknown User',
        'email': profile?.email ?? 'No email',
      };
    }).toList();

    // Ensure the owner appears in the list.
    if (!members.any((m) => m['user_id'] == project.ownerId)) {
      final owner = profileById[project.ownerId];
      members.insert(0, {
        'member_id': 'owner_placeholder',
        'user_id': project.ownerId,
        'role': 'owner',
        'invited_by': null,
        'accepted_at': project.createdAt.toIso8601String(),
        'name': owner?.name ?? 'Unknown User',
        'email': owner?.email ?? 'No email',
      });
    }
    return members;
  }

  List<Map<String, dynamic>> _computeSearch(String uid) {
    if (_search.length < 2) return const [];
    final q = _search.toLowerCase();
    return _allProfiles
        .where(
          (p) =>
              p.id != uid &&
              (p.name.toLowerCase().contains(q) ||
                  p.email.toLowerCase().contains(q)),
        )
        .take(10)
        .map((p) => {'id': p.id, 'name': p.name, 'email': p.email})
        .toList();
  }

  void switchProject(String projectId) {
    _personalWorkspaceSelected = projectId.isEmpty;
    _selectedId = projectId.isEmpty ? null : projectId;
    _recompute();
  }

  void loadProjectMembers(String projectId) {
    _personalWorkspaceSelected = false;
    _selectedId = projectId;
    _recompute();
  }

  void searchProfiles(String query) {
    _search = query;
    emit(state.copyWith(searchResults: _computeSearch(_uid ?? '')));
  }

  Future<void> addProject({
    required String name,
    String? description,
    String? color,
    String? icon,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final id = db.id();
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      final ops = <Operation>[
        ...db.tx['projects'].create({
          'id': id,
          'ownerId': uid,
          'name': name,
          'description': description,
          'color': color,
          'icon': icon,
          'isDefault': false,
          'createdAt': now,
          'updatedAt': now,
        }).operations,
        ...db.tx['projects'][id].link({'owner': uid}).operations,
      ];
      await db.transact(ops);
    } catch (e) {
      debugPrint('Error adding project: $e');
    }
  }

  Future<void> updateProject({
    required String id,
    required String name,
    String? description,
    String? color,
    String? icon,
  }) async {
    try {
      await db.transact(
        db.tx['projects'][id].update({
          'name': name,
          'description': description,
          'color': color,
          'icon': icon,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (e) {
      debugPrint('Error updating project: $e');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await db.transact(db.tx['projects'][id].delete());
    } catch (e) {
      debugPrint('Error deleting project: $e');
    }
  }

  Future<void> inviteToProject({
    required String projectId,
    required String email,
    String role = 'viewer',
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final target = _allProfiles.where((p) => p.email == email).firstOrNull;
    if (target == null) {
      emit(state.copyWith(error: 'user_not_found_local'.tr()));
      return;
    }
    if (target.id == uid) {
      emit(state.copyWith(error: 'cannot_share_self'.tr()));
      return;
    }
    final already = _allMembers.any(
      (m) => m.projectId == projectId && m.userId == target.id,
    );
    if (already) {
      emit(state.copyWith(error: 'already_member_error'.tr()));
      return;
    }
    final id = db.id();
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      final ops = <Operation>[
        ...db.tx['members'].create({
          'id': id,
          'projectId': projectId,
          'userId': target.id,
          'role': role,
          'invitedBy': uid,
          'invitedAt': now,
          'acceptedAt': now,
        }).operations,
        ...db.tx['members'][id].link({
          'project': projectId,
          'user': target.id,
        }).operations,
      ];
      await db.transact(ops);
    } catch (e) {
      debugPrint('Error inviting to project: $e');
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> removeProjectMember(String memberId) async {
    if (memberId == 'owner_placeholder') return;
    try {
      await db.transact(db.tx['members'][memberId].delete());
    } catch (e) {
      debugPrint('Error removing member: $e');
    }
  }

  Future<bool> convertPersonalToProject(String name) async {
    final uid = _uid;
    if (uid == null) return false;
    final projectId = db.id();
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      emit(state.copyWith(isLoading: true));
      final res = await db.queryOnce({
        'expenses': {
          'where': {'creatorId': uid},
        },
      });
      final personal = mapList(
        res.data?['expenses'],
        Expense.fromMap,
      ).where((expense) => expense.projectId == null).toList();
      if (personal.isEmpty) {
        emit(
          state.copyWith(
            error: 'no_personal_expenses_to_convert'.tr(),
            isLoading: false,
          ),
        );
        return false;
      }

      final operations = <Operation>[
        ...db.tx['projects'].create({
          'id': projectId,
          'ownerId': uid,
          'name': name,
          'color': Colors.blue.toARGB32().toString(),
          'isDefault': false,
          'createdAt': now,
          'updatedAt': now,
        }).operations,
        ...db.tx['projects'][projectId].link({'owner': uid}).operations,
      ];
      for (final e in personal) {
        operations.addAll([
          ...db.tx['expenses'][e.id].update({
            'projectId': projectId,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          }).operations,
          ...db.tx['expenses'][e.id].link({'project': projectId}).operations,
        ]);
      }
      await db.transact(operations);
      _personalWorkspaceSelected = false;
      _selectedId = projectId;
      emit(state.copyWith(isLoading: false));
      return true;
    } catch (e) {
      debugPrint('Error converting personal to project: $e');
      emit(state.copyWith(error: e.toString(), isLoading: false));
      return false;
    }
  }

  @override
  Future<void> close() {
    _queryDispose?.call();
    _authSub.cancel();
    return super.close();
  }
}
