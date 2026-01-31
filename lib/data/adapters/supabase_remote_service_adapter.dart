import 'package:expense/core/sync_engine/adapters.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRemoteServiceAdapter implements RemoteServiceAdapter {
  final SupabaseClient _client;

  SupabaseRemoteServiceAdapter(this._client);

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    await _client.from(table).upsert(data);
  }

  @override
  Future<void> delete(String table, String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetch(
    String table,
    DateTime since, {
    String updatedAtColumn = 'updated_at',
  }) async {
    try {
      final query = _client.from(table).select();
      
      // If since is very old, we might want to fetch everything including null updated_at
      if (since.year > 1971) {
        query.gt(updatedAtColumn, since.toIso8601String());
      }
      
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SUPABASE_ADAPTER: Error fetching $table: $e');
      rethrow;
    }
  }

  @override
  Future<void> purge(String table, String userId, DateTime olderThan, {String userIdColumn = 'user_id'}) async {
    await _client
        .from(table)
        .delete()
        .eq(userIdColumn, userId)
        .lt('deleted_at', olderThan.toIso8601String());
  }

  @override
  void subscribeToChanges(String table, void Function(dynamic payload) callback) {
    debugPrint('SUPABASE_ADAPTER: Subscribing to $table...');
    _client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (payload) {
            debugPrint('SUPABASE_ADAPTER: Change detected in $table: ${payload.eventType}');
            callback(payload);
          },
        )
        .subscribe((status, [error]) {
          debugPrint('SUPABASE_ADAPTER: Subscription status for $table: $status');
          if (error != null) {
            debugPrint('SUPABASE_ADAPTER: Subscription error for $table: $error');
          }
        });
  }

  @override
  void unsubscribeAll() {
    _client.removeAllChannels();
  }
}
