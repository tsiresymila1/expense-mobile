import 'package:drift/drift.dart';
import 'package:expense/core/adapters/adapters.dart';
import 'package:expense/data/local/database.dart';

class DriftLocalDatabaseAdapter implements LocalDatabaseAdapter {
  final AppDatabase _db;

  DriftLocalDatabaseAdapter(this._db);

  TableInfo<Table, dynamic> _getTable(String table) {
    switch (table) {
      case 'expenses':
        return _db.localExpenses;
      case 'categories':
        return _db.localCategories;
      case 'projects':
        return _db.localProjects;
      case 'project_members':
        return _db.localProjectMembers;
      case 'profiles':
        return _db.localProfiles;
      default:
        throw Exception('Table $table not supported for sync');
    }
  }

  @override
  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final tableInfo = _getTable(table);
    final query = _db.select(tableInfo)
      ..where((t) => (t as dynamic).id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    // De-normalize Drift camelCase to Supabase snake_case
    return _denormalizeData(table, row.toJson());
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    Insertable dataClass;

    // Normalize Supabase snake_case to Drift camelCase
    final normalized = _normalizeData(table, data);

    if (table == 'expenses') {
      dataClass = LocalExpense.fromJson(normalized);
    } else if (table == 'categories') {
      dataClass = LocalCategory.fromJson(normalized);
    } else if (table == 'projects') {
      dataClass = LocalProject.fromJson(normalized);
    } else if (table == 'project_members') {
      dataClass = LocalProjectMember.fromJson(normalized);
    } else if (table == 'profiles') {
      dataClass = LocalProfile.fromJson(normalized);
    } else {
      throw Exception('Table $table not supported for sync upsert');
    }
    await _db.into(_getTable(table)).insertOnConflictUpdate(dataClass);
  }

  Map<String, dynamic> _normalizeData(String table, Map<String, dynamic> data) {
    final Map<String, dynamic> result = Map.from(data);

    if (table == 'expenses') {
      if (data.containsKey('user_id')) result['userId'] = data['user_id'];
      if (data.containsKey('category_id')) {
        result['categoryId'] = data['category_id'];
      }
      if (data.containsKey('updated_at')) {
        result['updatedAt'] = data['updated_at'];
      }
      if (data.containsKey('created_at')) {
        result['createdAt'] = data['created_at'];
      }
      if (data.containsKey('deleted_at')) {
        result['deletedAt'] = data['deleted_at'];
      }
      if (data.containsKey('project_id')) {
        result['projectId'] = data['project_id'];
      }
      if (data.containsKey('created_by')) {
        result['createdBy'] = data['created_by'];
      }
    } else if (table == 'categories') {
      if (data.containsKey('user_id')) result['userId'] = data['user_id'];
      if (data.containsKey('is_default')) {
        result['isDefault'] = data['is_default'];
      }
      if (data.containsKey('updated_at')) {
        result['updatedAt'] = data['updated_at'];
      }
      if (data.containsKey('deleted_at')) {
        result['deletedAt'] = data['deleted_at'];
      }
    } else if (table == 'projects') {
      if (data.containsKey('owner_id')) result['ownerId'] = data['owner_id'];
      if (data.containsKey('is_default')) {
        result['isDefault'] = data['is_default'];
      }
      if (data.containsKey('created_at')) {
        result['createdAt'] = data['created_at'];
      }
      if (data.containsKey('updated_at')) {
        result['updatedAt'] = data['updated_at'];
      }
      if (data.containsKey('deleted_at')) {
        result['deletedAt'] = data['deleted_at'];
      }
    } else if (table == 'project_members') {
      if (data.containsKey('project_id')) result['projectId'] = data['project_id'];
      if (data.containsKey('user_id')) result['userId'] = data['user_id'];
      if (data.containsKey('invited_by')) result['invitedBy'] = data['invited_by'];
      if (data.containsKey('invited_at')) result['invitedAt'] = data['invited_at'];
      if (data.containsKey('accepted_at')) result['acceptedAt'] = data['accepted_at'];
      if (data.containsKey('created_at')) {
        result['createdAt'] = data['created_at'];
      }
      if (data.containsKey('updated_at')) {
        result['updatedAt'] = data['updated_at'];
      }
    } else if (table == 'profiles') {
      if (data.containsKey('updated_at')) {
        result['updatedAt'] = data['updated_at'];
      }
    }

    return result;
  }

  Map<String, dynamic> _denormalizeData(
    String table,
    Map<String, dynamic> data,
  ) {
    final Map<String, dynamic> result = Map.from(data);

    if (table == 'expenses') {
      if (data.containsKey('userId')) result['user_id'] = data['userId'];
      if (data.containsKey('categoryId')) {
        result['category_id'] = data['categoryId'];
      }
      if (data.containsKey('updatedAt')) {
        result['updated_at'] = _toIso(data['updatedAt']);
      }
      if (data.containsKey('createdAt')) {
        result['created_at'] = _toIso(data['createdAt']);
      }
      if (data.containsKey('deletedAt')) {
        result['deleted_at'] = _toIso(data['deletedAt']);
      }
      if (data.containsKey('projectId')) {
        result['project_id'] = data['projectId'];
      }
      if (data.containsKey('date')) result['date'] = _toIso(data['date']);
      if (data.containsKey('createdBy')) {
        result['created_by'] = data['createdBy'];
      }

      // Remove camelCase keys
      result.remove('userId');
      result.remove('categoryId');
      result.remove('projectId');
      result.remove('updatedAt');
      result.remove('createdAt');
      result.remove('deletedAt');
      result.remove('createdBy');
    } else if (table == 'categories') {
      if (data.containsKey('userId')) result['user_id'] = data['userId'];
      if (data.containsKey('isDefault')) {
        result['is_default'] = data['isDefault'];
      }
      if (data.containsKey('updatedAt')) {
        result['updated_at'] = _toIso(data['updatedAt']);
      }
      if (data.containsKey('deletedAt')) {
        result['deleted_at'] = _toIso(data['deletedAt']);
      }

      result.remove('userId');
      result.remove('isDefault');
      result.remove('updatedAt');
      result.remove('deletedAt');
    } else if (table == 'projects') {
      if (data.containsKey('ownerId')) result['owner_id'] = data['ownerId'];
      if (data.containsKey('isDefault')) {
        result['is_default'] = data['isDefault'];
      }
      if (data.containsKey('createdAt')) {
        result['created_at'] = _toIso(data['createdAt']);
      }
      if (data.containsKey('updatedAt')) {
        result['updated_at'] = _toIso(data['updatedAt']);
      }
      if (data.containsKey('deletedAt')) {
        result['deleted_at'] = _toIso(data['deletedAt']);
      }

      result.remove('ownerId');
      result.remove('isDefault');
      result.remove('createdAt');
      result.remove('updatedAt');
      result.remove('deletedAt');
    } else if (table == 'project_members') {
      if (data.containsKey('projectId')) result['project_id'] = data['projectId'];
      if (data.containsKey('userId')) result['user_id'] = data['userId'];
      if (data.containsKey('invitedBy')) result['invited_by'] = data['invitedBy'];
      if (data.containsKey('invitedAt')) {
        result['invited_at'] = _toIso(data['invitedAt']);
      }
      if (data.containsKey('acceptedAt')) {
        result['accepted_at'] = _toIso(data['acceptedAt']);
      }
      if (data.containsKey('createdAt')) {
        result['created_at'] = _toIso(data['createdAt']);
      }
      if (data.containsKey('updatedAt')) {
        result['updated_at'] = _toIso(data['updatedAt']);
      }

      result.remove('projectId');
      result.remove('userId');
      result.remove('invitedBy');
      result.remove('invitedAt');
      result.remove('acceptedAt');
      result.remove('createdAt');
      result.remove('updatedAt');
    } else if (table == 'profiles') {
      if (data.containsKey('updatedAt')) {
        result['updated_at'] = _toIso(data['updatedAt']);
      }
      result.remove('updatedAt');
    }

    return result;
  }

  String? _toIso(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
    }
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  @override
  Future<void> delete(String table, String id) async {
    final tableInfo = _getTable(table);
    await (_db.delete(
      tableInfo,
    )..where((t) => (t as dynamic).id.equals(id))).go();
  }

  @override
  Future<List<SyncQueueData>> getSyncQueue({String? userId}) {
    final query = _db.select(_db.syncQueue);
    if (userId != null) {
      query.where((t) => t.userId.equals(userId));
    }
    return query.get();
  }

  @override
  Future<void> addToSyncQueue(
    String userId,
    String table,
    String id,
    String operation, {
    String? payload,
  }) {
    return _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            userId: userId,
            targetTable: table,
            rowId: id,
            operation: operation,
            payload: Value(payload),
            createdAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> removeFromSyncQueue(int queueId) =>
      (_db.delete(_db.syncQueue)..where((t) => t.id.equals(queueId))).go();

  @override
  Future<void> incrementRetryCount(int queueId) async {
    final entry = await (_db.select(
      _db.syncQueue,
    )..where((t) => t.id.equals(queueId))).getSingle();
    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(queueId))).write(
      SyncQueueCompanion(retryCount: Value(entry.retryCount + 1)),
    );
  }

  @override
  Future<void> purge(String table, DateTime olderThan) async {
    // Skip tables that don't have a deletedAt column
    if (table == 'project_members' || table == 'profiles') {
      return;
    }
    
    final tableInfo = _getTable(table);
    // Simple way to handle deleted_at column access via dynamic casting
    // In Drift, if a table has a column, it should be accessible this way if we know what we're doing
    await (_db.delete(tableInfo)
          ..where((t) {
            final deletedAt = (t as dynamic).deletedAt as Expression<DateTime>;
            return deletedAt.isSmallerThanValue(olderThan) & deletedAt.isNotNull();
          }))
        .go();
  }

  @override
  Future<bool> isProjectMember(String projectId, String userId) async {
    // Check if explicitly a member
    final query = _db.select(_db.localProjectMembers)
      ..where((t) => t.projectId.equals(projectId) & t.userId.equals(userId));
    final member = await query.getSingleOrNull();
    if (member != null) return true;

    // Check if owner of the project
    final projectQuery = _db.select(_db.localProjects)
      ..where((t) => t.id.equals(projectId));
    final project = await projectQuery.getSingleOrNull();
    return project?.ownerId == userId;
  }
}
