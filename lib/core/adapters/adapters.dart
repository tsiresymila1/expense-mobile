import 'package:expense/data/local/database.dart';

abstract class LocalDatabaseAdapter {
  Future<Map<String, dynamic>?> getById(String table, String id);
  Future<void> upsert(String table, Map<String, dynamic> data);
  Future<void> delete(String table, String id);

  // Sync Queue
  Future<List<SyncQueueData>> getSyncQueue({String? userId});
  Future<void> addToSyncQueue(
    String userId,
    String table,
    String id,
    String operation, {
    String? payload,
  });
  Future<void> removeFromSyncQueue(int queueId);
  Future<void> incrementRetryCount(int queueId);
  Future<void> purge(String table, DateTime olderThan);
  Future<bool> isProjectMember(String projectId, String userId);
}

abstract class RemoteServiceAdapter {
  String? get currentUserId;
  Future<void> upsert(String table, Map<String, dynamic> data);
  Future<void> delete(String table, String id);
  Future<List<Map<String, dynamic>>> fetch(
    String table,
    DateTime since, {
    String updatedAtColumn = 'updated_at',
  });
  Future<void> purge(String table, String userId, DateTime olderThan, {String userIdColumn = 'user_id'});
}
