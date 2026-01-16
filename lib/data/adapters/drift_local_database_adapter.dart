import 'package:drift/drift.dart';
import 'package:expense/core/adapters/adapters.dart';
import 'package:expense/data/local/database.dart';

class DriftLocalDatabaseAdapter implements LocalDatabaseAdapter {
  final AppDatabase _db;

  DriftLocalDatabaseAdapter(this._db);

  TableInfo<Table, dynamic> _getTable(String table) {
    switch (table) {
      case 'expenses': return _db.localExpenses;
      case 'categories': return _db.localCategories;
      default: throw Exception('Table $table not supported for sync');
    }
  }

  @override
  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final tableInfo = _getTable(table);
    final query = _db.select(tableInfo)..where((t) => (t as dynamic).id.equals(id));
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
    } else {
      throw Exception('Table $table not supported for sync upsert');
    }
    await _db.into(_getTable(table)).insertOnConflictUpdate(dataClass);
  }

  Map<String, dynamic> _normalizeData(String table, Map<String, dynamic> data) {
    final Map<String, dynamic> result = Map.from(data);
    
    if (table == 'expenses') {
      if (data.containsKey('user_id')) result['userId'] = data['user_id'];
      if (data.containsKey('category_id')) result['categoryId'] = data['category_id'];
      if (data.containsKey('updated_at')) result['updatedAt'] = data['updated_at'];
      if (data.containsKey('created_at')) result['createdAt'] = data['created_at'];
    } else if (table == 'categories') {
      if (data.containsKey('user_id')) result['userId'] = data['user_id'];
      if (data.containsKey('is_default')) result['isDefault'] = data['is_default'];
      if (data.containsKey('updated_at')) result['updatedAt'] = data['updated_at'];
    }
    
    return result;
  }

  Map<String, dynamic> _denormalizeData(String table, Map<String, dynamic> data) {
    final Map<String, dynamic> result = Map.from(data);
    
    if (table == 'expenses') {
      if (data.containsKey('userId')) result['user_id'] = data['userId'];
      if (data.containsKey('categoryId')) result['category_id'] = data['categoryId'];
      if (data.containsKey('updatedAt')) result['updated_at'] = _toIso(data['updatedAt']);
      if (data.containsKey('createdAt')) result['created_at'] = _toIso(data['createdAt']);
      if (data.containsKey('date')) result['date'] = _toIso(data['date']);
      
      // Remove camelCase keys
      result.remove('userId');
      result.remove('categoryId');
      result.remove('updatedAt');
      result.remove('createdAt');
    } else if (table == 'categories') {
      if (data.containsKey('userId')) result['user_id'] = data['userId'];
      if (data.containsKey('isDefault')) result['is_default'] = data['isDefault'];
      if (data.containsKey('updatedAt')) result['updated_at'] = _toIso(data['updatedAt']);
      
      result.remove('userId');
      result.remove('isDefault');
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
    await (_db.delete(tableInfo)..where((t) => (t as dynamic).id.equals(id))).go();
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
  Future<void> addToSyncQueue(String userId, String table, String id, String operation, {String? payload}) {
    return _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
      userId: userId,
      targetTable: table,
      rowId: id,
      operation: operation,
      payload: Value(payload),
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<void> removeFromSyncQueue(int queueId) => (_db.delete(_db.syncQueue)..where((t) => t.id.equals(queueId))).go();

  @override
  Future<void> incrementRetryCount(int queueId) async {
    final entry = await (_db.select(_db.syncQueue)..where((t) => t.id.equals(queueId))).getSingle();
    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(queueId))).write(SyncQueueCompanion(
      retryCount: Value(entry.retryCount + 1),
    ));
  }
}
